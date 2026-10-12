import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';

/// Classification of univariate probability distributions.
enum DistributionType {
  /// Continuous distribution defined over real intervals.
  continuous,

  /// Discrete distribution defined over integer count supports.
  discrete,
}

/// Abstract contract for all univariate probability distributions in NexaMath Phase 10.
abstract interface class ProbabilityDistribution {
  /// Unique machine-readable name of the distribution.
  String get name;

  /// Classification of the distribution (continuous vs discrete).
  DistributionType get type;

  /// Whether this distribution is discrete (integer/count support).
  bool get isDiscrete;

  /// Whether this distribution is continuous (real interval support).
  bool get isContinuous;

  /// Theoretical expected value $E[X]$.
  ///
  /// Returns `MathFailure(DomainError)` if mean is undefined or diverges.
  MathResult<ScalarValue> get mean;

  /// Theoretical variance $\text{Var}(X)$.
  ///
  /// Returns `MathFailure(DomainError)` if variance is undefined or diverges.
  MathResult<ScalarValue> get variance;

  /// Theoretical standard deviation $\sigma = \sqrt{\text{Var}(X)}$.
  MathResult<ScalarValue> get standardDeviation;

  /// Evaluates Probability Density Function (continuous) or
  /// Probability Mass Function (discrete) at point [x].
  MathResult<ScalarValue> pdf(ScalarValue x);

  /// Evaluates Cumulative Distribution Function $F(x) = P(X \le x)$.
  MathResult<ScalarValue> cdf(ScalarValue x);

  /// Evaluates Quantile / Inverse CDF function $Q(p) = \inf\{x : F(x) \ge p\}$
  /// for probability $p \in [0, 1]$.
  MathResult<ScalarValue> inverseCdf(ScalarValue probability);

  /// Generates a single pseudo-random variate using [source].
  MathResult<ScalarValue> sampleOne(RandomSource source);
}
