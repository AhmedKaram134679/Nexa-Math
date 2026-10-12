import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/statistics/models/paired_dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_type.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/regression_diagnostic_calculator.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/regression_model.dart';

/// Non-linear transformed regression models:
/// 1. Logarithmic: $y = a + b \ln(x)$ (requires $x_i > 0$).
/// 2. Exponential: $y = a e^{b x}$ (requires $y_i > 0$, with $a = e^\alpha > 0$).
/// 3. Power: $y = a x^b$ (requires $x_i > 0, y_i > 0$, with $a = e^\alpha > 0$).
///
/// Invariants:
/// - Canonical public coefficients are $[a, b]$.
/// - Transformed parameter $\alpha = \ln(a)$ is never exposed.
/// - Parameter overflow ($\alpha > 709.78$) triggers [OverflowError].
/// - Parameter underflow ($a \le 0$ when $\alpha < -745$) triggers [UnderflowError].
/// - Prediction, residuals, SSE, SST, and $R^2$ are computed strictly in original physical $y$-space.
/// - $R^2$ is never clamped to zero; negative values are preserved when $\text{SSE} > \text{SST}$.
/// - `correlation` is strictly null for all transformed regressions.
final class TransformedRegression implements RegressionModel {
  final RegressionType type;
  final PrecisionContext context;
  final RegressionDiagnosticCalculator diagnosticCalculator;

  const TransformedRegression({
    required this.type,
    this.context = PrecisionContext.standard,
  }) : assert(
         type == RegressionType.logarithmic ||
             type == RegressionType.exponential ||
             type == RegressionType.power,
         'TransformedRegression supports only logarithmic, exponential, and power.',
       ),
       diagnosticCalculator = const RegressionDiagnosticCalculator();

  @override
  MathResult<RegressionResult> fit(PairedDataset dataset) {
    final validation = dataset.validateMinPairs<RegressionResult>(
      2,
      operation: '${type.name}Regression',
    );
    if (validation != null) return validation;

    final xVals = dataset.x.toDoubles();
    final yVals = dataset.y.toDoubles();
    final n = dataset.length;

    // 1. Domain Pre-Checks
    switch (type) {
      case RegressionType.logarithmic:
        for (var i = 0; i < n; i++) {
          if (xVals[i] <= 0.0) {
            return const MathFailure(
              DomainError(
                functionName: 'logarithmicRegression',
                message: 'Logarithmic regression requires strictly positive x values (x > 0).',
              ),
            );
          }
        }
        break;
      case RegressionType.exponential:
        for (var i = 0; i < n; i++) {
          if (yVals[i] <= 0.0) {
            return const MathFailure(
              DomainError(
                functionName: 'exponentialRegression',
                message: 'Exponential regression via log-linear transformation requires strictly positive y values (y > 0).',
              ),
            );
          }
        }
        break;
      case RegressionType.power:
        for (var i = 0; i < n; i++) {
          if (xVals[i] <= 0.0 || yVals[i] <= 0.0) {
            return const MathFailure(
              DomainError(
                functionName: 'powerRegression',
                message: 'Power regression requires strictly positive x and y values (x > 0, y > 0).',
              ),
            );
          }
        }
        break;
      default:
        break;
    }

    // 2. Coordinate Transformation
    final uVals = List<double>.filled(n, 0.0);
    final vVals = List<double>.filled(n, 0.0);

    for (var i = 0; i < n; i++) {
      switch (type) {
        case RegressionType.logarithmic:
          uVals[i] = math.log(xVals[i]);
          vVals[i] = yVals[i];
          break;
        case RegressionType.exponential:
          uVals[i] = xVals[i];
          vVals[i] = math.log(yVals[i]);
          break;
        case RegressionType.power:
          uVals[i] = math.log(xVals[i]);
          vVals[i] = math.log(yVals[i]);
          break;
        default:
          break;
      }
    }

    // 3. Analytic OLS on Transformed Coordinates (u, v) -> v = intercept + slope * u
    double sumU = 0.0;
    double sumV = 0.0;
    for (var i = 0; i < n; i++) {
      sumU += uVals[i];
      sumV += vVals[i];
    }
    final meanU = sumU / n;
    final meanV = sumV / n;

    double varU = 0.0;
    double covUV = 0.0;
    for (var i = 0; i < n; i++) {
      final du = uVals[i] - meanU;
      final dv = vVals[i] - meanV;
      varU += du * du;
      covUV += du * dv;
    }

    if (varU <= context.zeroTolerance) {
      return const MathFailure(
        SingularMatrixError(
          message: 'Cannot fit transformed regression: zero variance in transformed predictor variable.',
        ),
      );
    }

    final slope = covUV / varU;
    final intercept = meanV - slope * meanU;

    // 4. Parameter Reconstruction & Overflow/Underflow Safeguards
    double a;
    double b;

    switch (type) {
      case RegressionType.logarithmic:
        // y = a + b * ln(x)
        a = intercept;
        b = slope;
        break;
      case RegressionType.exponential:
        // ln(y) = alpha + b * x => a = exp(alpha), b = slope
        final alpha = intercept;
        if (alpha > 709.78) {
          return const MathFailure(
            OverflowError(
              message: 'Numerical calculation overflowed maximum representable finite bound.',
            ),
          );
        }
        a = math.exp(alpha);
        if (a <= 0.0 || a.isInfinite) {
          if (a <= 0.0) {
            return const MathFailure(
              UnderflowError(
                message: 'Scale parameter underflowed below minimum representable positive bound.',
              ),
            );
          }
          return const MathFailure(
            OverflowError(
              message: 'Numerical calculation overflowed maximum representable finite bound.',
            ),
          );
        }
        b = slope;
        break;
      case RegressionType.power:
        // ln(y) = alpha + b * ln(x) => a = exp(alpha), b = slope
        final alpha = intercept;
        if (alpha > 709.78) {
          return const MathFailure(
            OverflowError(
              message: 'Numerical calculation overflowed maximum representable finite bound.',
            ),
          );
        }
        a = math.exp(alpha);
        if (a <= 0.0 || a.isInfinite) {
          if (a <= 0.0) {
            return const MathFailure(
              UnderflowError(
                message: 'Scale parameter underflowed below minimum representable positive bound.',
              ),
            );
          }
          return const MathFailure(
            OverflowError(
              message: 'Numerical calculation overflowed maximum representable finite bound.',
            ),
          );
        }
        b = slope;
        break;
      default:
        a = 0.0;
        b = 0.0;
    }

    // 5. Predictions & Residuals Evaluated strictly in ORIGINAL RESPONSE SPACE
    final predictionsDbl = <double>[];
    final residualsDbl = <double>[];

    for (var i = 0; i < n; i++) {
      double yHat;
      switch (type) {
        case RegressionType.logarithmic:
          yHat = a + b * math.log(xVals[i]);
          break;
        case RegressionType.exponential:
          final exponent = b * xVals[i];
          if (exponent > 709.78) {
            return const MathFailure(
              OverflowError(
                message: 'Prediction calculation overflowed maximum representable finite bound.',
              ),
            );
          }
          yHat = a * math.exp(exponent);
          break;
        case RegressionType.power:
          yHat = a * math.pow(xVals[i], b);
          break;
        default:
          yHat = 0.0;
      }

      if (yHat.isInfinite) {
        return const MathFailure(
          OverflowError(
            message: 'Prediction calculation overflowed maximum representable finite bound.',
          ),
        );
      }
      if (yHat.isNaN) {
        return const MathFailure(
          PrecisionLossError(
            message: 'Prediction calculation resulted in indeterminate numerical value.',
          ),
        );
      }

      predictionsDbl.add(yHat);
      residualsDbl.add(yVals[i] - yHat);
    }

    // 6. Diagnostics in Original Response Space (SSE, SST, R^2, NearZeroWarning)
    final diag = diagnosticCalculator.evaluateDiagnostics(
      yVals,
      predictionsDbl,
    );

    // 7. AST Construction
    final aDec = DecimalValue.parse(a.toString(), isExact: false);
    final bDec = DecimalValue.parse(b.toString(), isExact: false);
    final equationAst = _buildAst(aDec, bDec);

    return MathSuccess(
      RegressionResult(
        type: type,
        coefficients: [aDec, bDec], // Canonical [a, b]
        equation: equationAst,
        correlation: null, // Strictly null for non-linear transformed models
        rSquared: DecimalValue.parse(diag.rSquared.toString(), isExact: false),
        predictions: predictionsDbl
            .map((p) => DecimalValue.parse(p.toString(), isExact: false))
            .toList(),
        residuals: residualsDbl
            .map((r) => DecimalValue.parse(r.toString(), isExact: false))
            .toList(),
        sse: DecimalValue.parse(diag.sse.toString(), isExact: false),
        sst: DecimalValue.parse(diag.sst.toString(), isExact: false),
        metadata: CalculationMetadata(
          isExact: false,
          warnings: diag.warnings,
          approximation: ApproximationMetadata(
            method: 'transformedRegression',
            precision: context.precisionDigits,
            converged: true,
          ),
        ),
      ),
    );
  }

  ExpressionNode _buildAst(DecimalValue a, DecimalValue b) {
    switch (type) {
      case RegressionType.logarithmic:
        // a + b * ln(x)
        return BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.add,
          left: NumberLiteralNode(position: SourcePosition.start, value: a),
          right: BinaryOpNode(
            position: SourcePosition.start,
            operator: BinaryOperator.multiply,
            left: NumberLiteralNode(position: SourcePosition.start, value: b),
            right: const FunctionCallNode(
              position: SourcePosition.start,
              name: 'ln',
              arguments: [
                VariableNode(position: SourcePosition.start, name: 'x'),
              ],
            ),
          ),
        );
      case RegressionType.exponential:
        // a * exp(b * x)
        return BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.multiply,
          left: NumberLiteralNode(position: SourcePosition.start, value: a),
          right: FunctionCallNode(
            position: SourcePosition.start,
            name: 'exp',
            arguments: [
              BinaryOpNode(
                position: SourcePosition.start,
                operator: BinaryOperator.multiply,
                left: NumberLiteralNode(
                  position: SourcePosition.start,
                  value: b,
                ),
                right: const VariableNode(
                  position: SourcePosition.start,
                  name: 'x',
                ),
              ),
            ],
          ),
        );
      case RegressionType.power:
        // a * x^b
        return BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.multiply,
          left: NumberLiteralNode(position: SourcePosition.start, value: a),
          right: BinaryOpNode(
            position: SourcePosition.start,
            operator: BinaryOperator.power,
            left: const VariableNode(position: SourcePosition.start, name: 'x'),
            right: NumberLiteralNode(position: SourcePosition.start, value: b),
          ),
        );
      default:
        throw UnsupportedError('Unsupported regression type: $type');
    }
  }
}
