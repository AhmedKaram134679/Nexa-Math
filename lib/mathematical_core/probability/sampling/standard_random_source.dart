import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';

/// Concrete [RandomSource] backed by `dart:math.Random`.
///
/// Supports an optional fixed integer [seed] for deterministic testing
/// and repeatable simulation runs.
final class StandardRandomSource implements RandomSource {
  final math.Random _random;

  /// Creates a random source using system entropy or an optional deterministic [seed].
  StandardRandomSource([int? seed]) : _random = math.Random(seed);

  @override
  double nextDouble() => _random.nextDouble();

  @override
  int nextInt(int max) => _random.nextInt(max);
}

/// Internal utility ensuring that pseudo-random variates supplied to
/// inverse-transform sampling strictly satisfy the open unit interval $0 < U < 1$.
final class OpenIntervalSamplingHelper {
  OpenIntervalSamplingHelper._();

  /// Default finite retry limit before failing with a convergence error.
  static const int defaultMaxRetries = 100;

  /// Draws a uniform double strictly within $(0.0, 1.0)$ using [source].
  ///
  /// Rejection/resampling is applied if [source.nextDouble] produces $0.0$.
  /// To guard against pathological or defective random sources, at most
  /// [maxRetries] attempts are performed before aborting with [ConvergenceFailureError].
  static MathResult<double> nextOpenDouble(
    RandomSource source, {
    int maxRetries = defaultMaxRetries,
  }) {
    for (var i = 1; i <= maxRetries; i++) {
      final u = source.nextDouble();
      if (u > 0.0 && u < 1.0) {
        return MathSuccess(u);
      }
    }
    return MathFailure(
      ConvergenceFailureError(
        message:
            'RandomSource failed to generate an open-interval variate in (0, 1) '
            'within allowed retries.',
        iterations: maxRetries,
        method: 'RandomSource.sample',
      ),
    );
  }
}
