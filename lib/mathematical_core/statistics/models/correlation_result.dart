import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';

/// Immutable model representing the result of bivariate correlation analysis.
final class CorrelationResult {
  /// Pearson correlation coefficient $r \in [-1, 1]$.
  final ScalarValue coefficient;

  /// Population covariance $\operatorname{Cov}_{\text{pop}}(X, Y)$.
  final ScalarValue populationCovariance;

  /// Sample covariance $\operatorname{Cov}_{\text{sample}}(X, Y)$ ($N \ge 2$). Null if $N < 2$.
  final ScalarValue? sampleCovariance;

  /// Calculation metadata and warnings.
  final CalculationMetadata metadata;

  const CorrelationResult({
    required this.coefficient,
    required this.populationCovariance,
    this.sampleCovariance,
    required this.metadata,
  });

  @override
  String toString() =>
      'CorrelationResult(r: $coefficient, popCov: $populationCovariance, sampleCov: $sampleCovariance)';
}
