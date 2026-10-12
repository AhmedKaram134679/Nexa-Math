import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/probability/probability_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';
import 'package:nexa_math/mathematical_core/statistics/models/dataset.dart';

/// Production sampling utility for generating variates from probability distributions.
final class DistributionSampler {
  DistributionSampler._();

  /// Maximum allowed sample count in single call (prevents out-of-memory denial of service).
  static const int maxSampleCount = 1000000;

  /// Generates a [Dataset] containing [count] independent observations from [distribution]
  /// using the provided [randomSource].
  static MathResult<Dataset> sample(
    ProbabilityDistribution distribution,
    int count,
    RandomSource randomSource,
  ) {
    if (count <= 0) {
      return const MathFailure(
        InvalidArgumentError(
          message: 'Sample count must be strictly positive (count > 0).',
          argumentName: 'count',
        ),
      );
    }

    if (count > maxSampleCount) {
      return const MathFailure(
        InvalidArgumentError(
          message: 'Sample count exceeds maximum permitted limit (1000000).',
          argumentName: 'count',
        ),
      );
    }

    final samples = <ScalarValue>[];
    for (var i = 0; i < count; i++) {
      final sampleRes = distribution.sampleOne(randomSource);
      if (sampleRes is MathFailure<ScalarValue>) {
        return MathFailure(sampleRes.error);
      }
      samples.add((sampleRes as MathSuccess<ScalarValue>).value);
    }

    return MathSuccess(Dataset(samples));
  }
}
