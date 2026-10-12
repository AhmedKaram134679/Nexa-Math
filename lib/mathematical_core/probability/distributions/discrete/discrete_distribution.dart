import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/probability_distribution.dart';

/// Base abstract class for univariate discrete probability distributions.
///
/// Discrete distributions are defined over integer count supports (subsets of $\mathbb{Z}$).
abstract class DiscreteDistribution implements ProbabilityDistribution {
  const DiscreteDistribution();

  @override
  DistributionType get type => DistributionType.discrete;

  @override
  bool get isContinuous => false;

  @override
  bool get isDiscrete => true;

  /// Evaluates Probability Mass Function $P(X = k)$ at integer count [k].
  MathResult<ScalarValue> pmf(IntegerValue k);
}
