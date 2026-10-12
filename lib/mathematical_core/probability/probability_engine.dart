import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/probability/probability_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/queries/probability_query.dart';
import 'package:nexa_math/mathematical_core/probability/queries/probability_result.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';
import 'package:nexa_math/mathematical_core/statistics/models/dataset.dart';

/// Public engine façade contract for NexaMath probability and distributions.
///
/// Pure Dart contract matching `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §38.
abstract interface class ProbabilityEngine {
  /// Evaluates a structured probability query against a distribution.
  MathResult<ProbabilityResult> probability(
    ProbabilityDistribution distribution,
    ProbabilityQuery query,
  );

  /// Evaluates PDF (continuous) or PMF (discrete) at [x].
  MathResult<ScalarValue> pdf(
    ProbabilityDistribution distribution,
    ScalarValue x,
  );

  /// Evaluates Cumulative Distribution Function $F(x) = P(X \le x)$.
  MathResult<ScalarValue> cdf(
    ProbabilityDistribution distribution,
    ScalarValue x,
  );

  /// Evaluates Quantile / Inverse CDF $Q(p)$ for $p \in [0, 1]$.
  MathResult<ScalarValue> inverseCdf(
    ProbabilityDistribution distribution,
    ScalarValue probability,
  );

  /// Generates a dataset of [count] pseudo-random observations using [randomSource].
  MathResult<Dataset> sample(
    ProbabilityDistribution distribution,
    int count,
    RandomSource randomSource,
  );
}
