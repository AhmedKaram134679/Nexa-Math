import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/statistics/bivariate/bivariate_calculator.dart';
import 'package:nexa_math/mathematical_core/statistics/models/paired_dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_type.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/regression_diagnostic_calculator.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/regression_model.dart';

/// Ordinary Least Squares (OLS) Linear Regression: $y = a x + b$.
///
/// Public coefficients: `[b, a]` (ascending power order: intercept $b$ at index 0, slope $a$ at index 1).
/// Populates Pearson correlation $r$. Detects vertical line singularity (zero variance in $X$).
final class LinearRegression implements RegressionModel {
  final PrecisionContext context;
  final BivariateCalculator bivariateCalculator;
  final RegressionDiagnosticCalculator diagnosticCalculator;

  const LinearRegression({this.context = PrecisionContext.standard})
    : bivariateCalculator = const BivariateCalculator(),
      diagnosticCalculator = const RegressionDiagnosticCalculator();

  @override
  MathResult<RegressionResult> fit(PairedDataset dataset) {
    final validation = dataset.validateMinPairs<RegressionResult>(
      2,
      operation: 'linearRegression',
    );
    if (validation != null) return validation;

    final xVals = dataset.x.toDoubles();
    final yVals = dataset.y.toDoubles();
    final n = dataset.length;

    double sumX = 0.0;
    double sumY = 0.0;
    for (var i = 0; i < n; i++) {
      sumX += xVals[i];
      sumY += yVals[i];
    }
    final meanX = sumX / n;
    final meanY = sumY / n;

    double varX = 0.0;
    double covXY = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xVals[i] - meanX;
      final dy = yVals[i] - meanY;
      varX += dx * dx;
      covXY += dx * dy;
    }

    if (varX <= context.zeroTolerance) {
      return const MathFailure(
        SingularMatrixError(
          message: 'Cannot fit linear regression: zero variance in predictor variable X (vertical line).',
        ),
      );
    }

    // Slope a and intercept b
    final a = covXY / varX;
    final b = meanY - a * meanX;

    // Predictions and residuals
    final predictionsDbl = <double>[];
    final residualsDbl = <double>[];
    for (var i = 0; i < n; i++) {
      final yHat = a * xVals[i] + b;
      predictionsDbl.add(yHat);
      residualsDbl.add(yVals[i] - yHat);
    }

    // Diagnostics (SSE, SST, R^2, warnings)
    final diag = diagnosticCalculator.evaluateDiagnostics(
      yVals,
      predictionsDbl,
    );

    // Pearson correlation r
    final corrRes = bivariateCalculator.pearsonCorrelation(dataset);
    DecimalValue? corrVal;
    if (corrRes.isSuccess) {
      corrVal = corrRes.valueOrNull;
    }

    // Build ExpressionNode: a * x + b
    final aDec = DecimalValue.parse(a.toString(), isExact: false);
    final bDec = DecimalValue.parse(b.toString(), isExact: false);

    final equationAst = BinaryOpNode(
      position: SourcePosition.start,
      operator: BinaryOperator.add,
      left: BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.multiply,
        left: NumberLiteralNode(position: SourcePosition.start, value: aDec),
        right: const VariableNode(position: SourcePosition.start, name: 'x'),
      ),
      right: NumberLiteralNode(position: SourcePosition.start, value: bDec),
    );

    return MathSuccess(
      RegressionResult(
        type: RegressionType.linear,
        coefficients: [bDec, aDec], // [b, a] ascending power order
        equation: equationAst,
        correlation: corrVal,
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
            method: 'olsLinearRegression',
            precision: context.precisionDigits,
            converged: true,
          ),
        ),
      ),
    );
  }
}
