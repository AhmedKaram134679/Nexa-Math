import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Immutable model aggregating complete univariate descriptive statistical metrics for a [Dataset].
final class DescriptiveStatistics {
  /// Number of observations $N$.
  final IntegerValue count;

  /// Sum of all observations $\sum x_i$.
  final ScalarValue sum;

  /// Arithmetic mean $\bar{x} = \frac{1}{N}\sum x_i$.
  final ScalarValue mean;

  /// Sample median splitting ordered observations.
  final ScalarValue median;

  /// Deterministic mode values according to the NexaMath Mode Convention.
  final List<ScalarValue> modes;

  /// Minimum observed value $\min(x_i)$.
  final ScalarValue min;

  /// Maximum observed value $\max(x_i)$.
  final ScalarValue max;

  /// Statistical range: $\max(x_i) - \min(x_i)$.
  final ScalarValue range;

  /// Population variance: $\sigma^2 = \frac{1}{N}\sum (x_i - \bar{x})^2$.
  final ScalarValue populationVariance;

  /// Sample variance: $s^2 = \frac{1}{N-1}\sum (x_i - \bar{x})^2$ ($N \ge 2$). Null if $N < 2$.
  final ScalarValue? sampleVariance;

  /// Population standard deviation: $\sigma = \sqrt{\sigma^2}$.
  final ScalarValue populationStandardDeviation;

  /// Sample standard deviation: $s = \sqrt{s^2}$ ($N \ge 2$). Null if $N < 2$.
  final ScalarValue? sampleStandardDeviation;

  /// Calculation metadata describing exactness and numerical approximation methods.
  final CalculationMetadata metadata;

  const DescriptiveStatistics({
    required this.count,
    required this.sum,
    required this.mean,
    required this.median,
    required this.modes,
    required this.min,
    required this.max,
    required this.range,
    required this.populationVariance,
    this.sampleVariance,
    required this.populationStandardDeviation,
    this.sampleStandardDeviation,
    required this.metadata,
  });

  @override
  String toString() =>
      'DescriptiveStatistics(count: $count, mean: $mean, median: $median, modes: $modes, '
      'popVar: $populationVariance, sampleVar: $sampleVariance)';
}
