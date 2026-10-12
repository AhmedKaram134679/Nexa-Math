import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_type.dart';

/// Immutable model representing the comprehensive output of a mathematical regression fit.
///
/// Invariants:
/// 1. [coefficients] follows deterministic ascending-power order for polynomials ($[c_0, c_1, \dots, c_d]$),
///    and canonical parameter mapping $[a, b]$ for transformed and linear models.
/// 2. [correlation] is populated exclusively for [RegressionType.linear]; strictly null for all others.
/// 3. [rSquared] is non-nullable, computed in original response space ($y$-space), and NEVER clamped.
/// 4. [residuals] are signed differences: $e_i = y_i - \hat{y}_i$ (observed minus predicted).
final class RegressionResult {
  /// Regression model type.
  final RegressionType type;

  /// Model coefficients in deterministic order.
  final List<DecimalValue> coefficients;

  /// Exact AST representation of the regression equation $f(x)$ for downstream evaluation.
  final ExpressionNode equation;

  /// Pearson correlation $r$. Populated ONLY for linear regression; strictly null for all other models.
  final DecimalValue? correlation;

  /// Unified coefficient of determination $R^2 = 1 - \frac{\text{SSE}}{\text{SST}}$ in original $y$-space.
  final DecimalValue rSquared;

  /// Model predictions $\hat{y}_i = f(x_i)$ in original $y$-space.
  final List<DecimalValue> predictions;

  /// Observed minus predicted residuals $e_i = y_i - \hat{y}_i$ in original $y$-space.
  final List<DecimalValue> residuals;

  /// Sum of squared errors $\text{SSE} = \sum e_i^2$.
  final DecimalValue sse;

  /// Total sum of squares $\text{SST} = \sum (y_i - \bar{y})^2$.
  final DecimalValue sst;

  /// Calculation metadata and non-fatal warnings (e.g., NearZeroWarning, PrecisionLossWarning).
  final CalculationMetadata metadata;

  const RegressionResult({
    required this.type,
    required this.coefficients,
    required this.equation,
    this.correlation,
    required this.rSquared,
    required this.predictions,
    required this.residuals,
    required this.sse,
    required this.sst,
    required this.metadata,
  });

  @override
  String toString() =>
      'RegressionResult(type: $type, coeffs: $coefficients, R^2: $rSquared, r: $correlation)';
}
