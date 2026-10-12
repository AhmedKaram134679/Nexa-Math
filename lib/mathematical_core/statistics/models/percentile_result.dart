import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';

/// Immutable model representing the result of a quantile or percentile calculation.
final class PercentileResult {
  /// The percentile parameter $p \in [0, 100]$.
  final ScalarValue percentile;

  /// The interpolated quantile value $P_p$.
  final ScalarValue value;

  /// The computed rank index $h = (N - 1)(p / 100) + 1$.
  final ScalarValue rank;

  /// Calculation metadata describing whether the quantile was evaluated exactly or approximately.
  final CalculationMetadata metadata;

  const PercentileResult({
    required this.percentile,
    required this.value,
    required this.rank,
    required this.metadata,
  });

  @override
  String toString() =>
      'PercentileResult(p: $percentile, value: $value, rank: $rank)';
}

/// Immutable model aggregating five-number summary quartiles and interquartile range (IQR).
final class QuartileResult {
  /// Minimum observed value $Q_0 \equiv P_0$.
  final ScalarValue q0;

  /// First quartile $Q_1 \equiv P_{25}$.
  final ScalarValue q1;

  /// Second quartile / median $Q_2 \equiv P_{50}$.
  final ScalarValue q2;

  /// Third quartile $Q_3 \equiv P_{75}$.
  final ScalarValue q3;

  /// Maximum observed value $Q_4 \equiv P_{100}$.
  final ScalarValue q4;

  /// Interquartile range $\text{IQR} = Q_3 - Q_1$.
  final ScalarValue iqr;

  /// Calculation metadata.
  final CalculationMetadata metadata;

  const QuartileResult({
    required this.q0,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    required this.iqr,
    required this.metadata,
  });

  @override
  String toString() => 'QuartileResult(Q1: $q1, Q2: $q2, Q3: $q3, IQR: $iqr)';
}
