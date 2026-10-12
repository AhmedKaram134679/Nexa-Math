import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/core/result/math_warning.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/matrix/default_matrix_engine.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/statistics/models/paired_dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_type.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/regression_diagnostic_calculator.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/regression_model.dart';

/// Polynomial least-squares regression solver for Quadratic ($d = 2$) and Cubic ($d = 3$) models.
///
/// Implements:
/// - Predictor centering $u_i = x_i - \bar{x}$ during matrix setup to mitigate condition number inflation.
/// - Moment matrix normal equations $(\tilde{\mathbf{X}}^T \tilde{\mathbf{X}}) \tilde{\boldsymbol{\theta}} = \tilde{\mathbf{X}}^T \mathbf{y}$.
/// - Full column rank requirement (at least $d + 1$ distinct $x$ coordinates).
/// - Relative pivot decay monitoring ($\rho < 10^{-15} \implies$ PrecisionLossWarning).
/// - Algebraic reconstruction to canonical coefficients $c_0 + c_1 x + \dots + c_d x^d$.
/// - Deterministic warning ordering:
///   1. NearZeroWarning (for SST = 0)
///   2. PrecisionLossWarning (for ill-conditioned matrix)
final class PolynomialRegression implements RegressionModel {
  final int degree;
  final PrecisionContext context;
  final MatrixEngine matrixEngine;
  final RegressionDiagnosticCalculator diagnosticCalculator;

  PolynomialRegression({
    required this.degree,
    this.context = PrecisionContext.standard,
    MatrixEngine? matrixEngine,
  }) : assert(
         degree == 2 || degree == 3,
         'Degree must be 2 (quadratic) or 3 (cubic).',
       ),
       matrixEngine = matrixEngine ?? DefaultMatrixEngine(),
       diagnosticCalculator = const RegressionDiagnosticCalculator();

  @override
  MathResult<RegressionResult> fit(PairedDataset dataset) {
    final minObs = degree + 1;
    final validation = dataset.validateMinPairs<RegressionResult>(
      minObs,
      operation: 'polynomialRegression',
    );
    if (validation != null) return validation;

    final xVals = dataset.x.toDoubles();
    final yVals = dataset.y.toDoubles();
    final n = dataset.length;

    // Check distinct x values
    final distinctX = <double>{};
    for (final x in xVals) {
      distinctX.add(x);
    }
    if (distinctX.length < minObs) {
      return MathFailure(
        SingularMatrixError(
          message:
              'Polynomial regression of degree $degree requires at least $minObs distinct x coordinates for full column rank.',
        ),
      );
    }

    // 1. Compute predictor mean for centering: u_i = x_i - xMean
    double sumX = 0.0;
    for (var i = 0; i < n; i++) {
      sumX += xVals[i];
    }
    final xMean = sumX / n;

    final uVals = List<double>.generate(n, (i) => xVals[i] - xMean);

    // 2. Set up centered moment matrix M = X_tilde^T * X_tilde and vector v = X_tilde^T * y
    // Size is (d + 1) x (d + 1)
    final mSize = degree + 1;
    final mMatrix = List<List<double>>.generate(
      mSize,
      (_) => List<double>.filled(mSize, 0.0),
    );
    final vVector = List<double>.filled(mSize, 0.0);

    for (var i = 0; i < n; i++) {
      final ui = uVals[i];
      final yi = yVals[i];

      // powers: u^0, u^1, ..., u^(2*degree)
      final powers = List<double>.filled(2 * degree + 1, 1.0);
      for (var p = 1; p <= 2 * degree; p++) {
        powers[p] = powers[p - 1] * ui;
      }

      for (var r = 0; r < mSize; r++) {
        for (var c = 0; c < mSize; c++) {
          mMatrix[r][c] += powers[r + c];
        }
        vVector[r] += powers[r] * yi;
      }
    }

    // 3. Monitor relative pivot decay during elimination on M
    final (solvedThetaTilde, isSingular, isIllConditioned) =
        _solveWithPivotMonitor(mMatrix, vVector);

    if (isSingular) {
      return const MathFailure(
        SingularMatrixError(
          message: 'Polynomial regression moment matrix is singular and cannot be inverted.',
        ),
      );
    }

    // 4. Algebraic Reconstruction from centered theta_tilde to canonical coefficients
    // Ascending power coefficients: [c0, c1, ..., cd]
    final canonicalCoeffs = _reconstructCanonicalCoefficients(
      solvedThetaTilde,
      xMean,
    );

    // 5. Compute predictions and residuals in original space
    final predictionsDbl = <double>[];
    final residualsDbl = <double>[];
    for (var i = 0; i < n; i++) {
      final xi = xVals[i];
      var yHat = 0.0;
      var xPow = 1.0;
      for (var k = 0; k < canonicalCoeffs.length; k++) {
        yHat += canonicalCoeffs[k] * xPow;
        xPow *= xi;
      }
      predictionsDbl.add(yHat);
      residualsDbl.add(yVals[i] - yHat);
    }

    // 6. Diagnostics (SSE, SST, R^2, NearZeroWarning)
    final diag = diagnosticCalculator.evaluateDiagnostics(
      yVals,
      predictionsDbl,
    );

    // 7. Deterministic Warning Ordering:
    // 1. Structural warnings (e.g. NearZeroWarning for SST = 0)
    // 2. Solver conditioning warnings (e.g. PrecisionLossWarning for rho < 1e-15)
    final allWarnings = <MathWarning>[];
    allWarnings.addAll(diag.warnings);
    if (isIllConditioned) {
      allWarnings.add(
        const PrecisionLossWarning(
          message: 'Design matrix is ill-conditioned; regression coefficients may suffer precision loss.',
        ),
      );
    }

    // Convert coefficients to DecimalValue
    final coeffDecs = canonicalCoeffs
        .map((c) => DecimalValue.parse(c.toString(), isExact: false))
        .toList();

    // 8. AST Generation
    final equationAst = _buildPolynomialAst(coeffDecs);

    final regType = degree == 2
        ? RegressionType.quadratic
        : RegressionType.cubic;

    return MathSuccess(
      RegressionResult(
        type: regType,
        coefficients: coeffDecs, // Ascending power order: [c0, c1, ..., cd]
        equation: equationAst,
        correlation: null, // Strictly null for polynomial regressions
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
          warnings: allWarnings,
          approximation: ApproximationMetadata(
            method: 'olsPolynomialRegression',
            precision: context.precisionDigits,
            converged: true,
          ),
        ),
      ),
    );
  }

  // --- Pivot Monitoring & Gauss-Jordan Solver ---

  (List<double> solution, bool isSingular, bool isIllConditioned)
  _solveWithPivotMonitor(List<List<double>> aOrig, List<double> bOrig) {
    final n = aOrig.length;
    // Copy into augmented matrix [A | b]
    final aug = List<List<double>>.generate(
      n,
      (r) =>
          List<double>.generate(n + 1, (c) => c < n ? aOrig[r][c] : bOrig[r]),
    );

    final pivots = <double>[];
    final zeroTol = context.zeroTolerance; // 1e-15

    for (var col = 0; col < n; col++) {
      // Partial pivoting
      var maxRow = col;
      var maxVal = aug[col][col].abs();
      for (var r = col + 1; r < n; r++) {
        final val = aug[r][col].abs();
        if (val > maxVal) {
          maxVal = val;
          maxRow = r;
        }
      }

      if (maxVal <= zeroTol) {
        return (const [], true, false);
      }

      if (maxRow != col) {
        final temp = aug[col];
        aug[col] = aug[maxRow];
        aug[maxRow] = temp;
      }

      final pivot = aug[col][col];
      pivots.add(pivot.abs());

      // Normalize row col
      for (var c = col; c <= n; c++) {
        aug[col][c] /= pivot;
      }

      // Eliminate other rows
      for (var r = 0; r < n; r++) {
        if (r == col) continue;
        final factor = aug[r][col];
        if (factor.abs() <= zeroTol) continue;
        for (var c = col; c <= n; c++) {
          aug[r][c] -= factor * aug[col][c];
        }
      }
    }

    // Check near-singularity heuristic: rho = min(|p|) / max(|p|) < 1e-15
    var minPivot = pivots.first;
    var maxPivot = pivots.first;
    for (final p in pivots) {
      if (p < minPivot) minPivot = p;
      if (p > maxPivot) maxPivot = p;
    }

    final bool isIllConditioned;
    if (maxPivot > zeroTol) {
      final rho = minPivot / maxPivot;
      isIllConditioned = rho < 1e-15;
    } else {
      isIllConditioned = false;
    }

    final sol = List<double>.generate(n, (r) => aug[r][n]);
    return (sol, false, isIllConditioned);
  }

  // --- Algebraic Reconstruction of Centered Coefficients ---

  List<double> _reconstructCanonicalCoefficients(
    List<double> thetaTilde,
    double xBar,
  ) {
    if (degree == 2) {
      // Quadratic: y = c0_tilde + c1_tilde*(x - xBar) + c2_tilde*(x - xBar)^2
      // c2 = c2_tilde
      // c1 = c1_tilde - 2 * c2_tilde * xBar
      // c0 = c0_tilde - c1_tilde * xBar + c2_tilde * xBar^2
      final t0 = thetaTilde[0];
      final t1 = thetaTilde[1];
      final t2 = thetaTilde[2];

      final c2 = t2;
      final c1 = t1 - 2.0 * t2 * xBar;
      final c0 = t0 - t1 * xBar + t2 * xBar * xBar;

      return [c0, c1, c2]; // Ascending power order
    } else {
      // Cubic: y = t0 + t1*(x - xBar) + t2*(x - xBar)^2 + t3*(x - xBar)^3
      // c3 = t3
      // c2 = t2 - 3 * t3 * xBar
      // c1 = t1 - 2 * t2 * xBar + 3 * t3 * xBar^2
      // c0 = t0 - t1 * xBar + t2 * xBar^2 - t3 * xBar^3
      final t0 = thetaTilde[0];
      final t1 = thetaTilde[1];
      final t2 = thetaTilde[2];
      final t3 = thetaTilde[3];

      final x2 = xBar * xBar;
      final x3 = x2 * xBar;

      final c3 = t3;
      final c2 = t2 - 3.0 * t3 * xBar;
      final c1 = t1 - 2.0 * t2 * xBar + 3.0 * t3 * x2;
      final c0 = t0 - t1 * xBar + t2 * x2 - t3 * x3;

      return [c0, c1, c2, c3]; // Ascending power order
    }
  }

  // --- AST Builder ---

  ExpressionNode _buildPolynomialAst(List<DecimalValue> coeffs) {
    // Canonical form:
    // Quadratic: a*x^2 + b*x + c  (where coeffs = [c, b, a])
    // Cubic: a*x^3 + b*x^2 + c*x + d (where coeffs = [d, c, b, a])
    if (degree == 2) {
      final c = coeffs[0];
      final b = coeffs[1];
      final a = coeffs[2];

      // a * x^2
      final term2 = BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.multiply,
        left: NumberLiteralNode(position: SourcePosition.start, value: a),
        right: BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.power,
          left: const VariableNode(position: SourcePosition.start, name: 'x'),
          right: NumberLiteralNode(
            position: SourcePosition.start,
            value: DecimalValue.two,
          ),
        ),
      );

      // b * x
      final term1 = BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.multiply,
        left: NumberLiteralNode(position: SourcePosition.start, value: b),
        right: const VariableNode(position: SourcePosition.start, name: 'x'),
      );

      // (a * x^2 + b * x) + c
      return BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.add,
        left: BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.add,
          left: term2,
          right: term1,
        ),
        right: NumberLiteralNode(position: SourcePosition.start, value: c),
      );
    } else {
      final d = coeffs[0];
      final c = coeffs[1];
      final b = coeffs[2];
      final a = coeffs[3];

      // a * x^3
      final term3 = BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.multiply,
        left: NumberLiteralNode(position: SourcePosition.start, value: a),
        right: BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.power,
          left: const VariableNode(position: SourcePosition.start, name: 'x'),
          right: NumberLiteralNode(
            position: SourcePosition.start,
            value: DecimalValue.fromInt(3),
          ),
        ),
      );

      // b * x^2
      final term2 = BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.multiply,
        left: NumberLiteralNode(position: SourcePosition.start, value: b),
        right: BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.power,
          left: const VariableNode(position: SourcePosition.start, name: 'x'),
          right: NumberLiteralNode(
            position: SourcePosition.start,
            value: DecimalValue.two,
          ),
        ),
      );

      // c * x
      final term1 = BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.multiply,
        left: NumberLiteralNode(position: SourcePosition.start, value: c),
        right: const VariableNode(position: SourcePosition.start, name: 'x'),
      );

      // ((a * x^3 + b * x^2) + c * x) + d
      return BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.add,
        left: BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.add,
          left: BinaryOpNode(
            position: SourcePosition.start,
            operator: BinaryOperator.add,
            left: term3,
            right: term2,
          ),
          right: term1,
        ),
        right: NumberLiteralNode(position: SourcePosition.start, value: d),
      );
    }
  }
}
