import 'package:nexa_math/mathematical_core/probability/probability_distribution.dart';

/// Base abstract class for univariate continuous probability distributions.
///
/// Continuous distributions are defined over subsets of $\mathbb{R}$ with support
/// intervals. Point probabilities $P(X = x)$ are always identically zero.
abstract class ContinuousDistribution implements ProbabilityDistribution {
  const ContinuousDistribution();

  @override
  DistributionType get type => DistributionType.continuous;

  @override
  bool get isContinuous => true;

  @override
  bool get isDiscrete => false;
}
