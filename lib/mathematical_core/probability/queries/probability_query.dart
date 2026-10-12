import 'package:nexa_math/mathematical_core/common/math_value.dart';

/// Sealed hierarchy of structured probability queries.
///
/// Pure Dart contract matching `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §38.
sealed class ProbabilityQuery {
  const ProbabilityQuery();
}

/// Query for point probability:
/// - Discrete PMF: $P(X = x)$
/// - Continuous: $P(X = x) = 0$
final class PointProbabilityQuery extends ProbabilityQuery {
  final ScalarValue point;

  const PointProbabilityQuery(this.point);

  @override
  String toString() => 'PointProbabilityQuery($point)';
}

/// Query for interval probability $P(a \le X \le b)$ with inclusive or exclusive endpoints.
final class IntervalProbabilityQuery extends ProbabilityQuery {
  final ScalarValue lower;
  final ScalarValue upper;
  final bool includeLower;
  final bool includeUpper;

  const IntervalProbabilityQuery({
    required this.lower,
    required this.upper,
    this.includeLower = true,
    this.includeUpper = true,
  });

  @override
  String toString() =>
      'IntervalProbabilityQuery(lower: $lower, upper: $upper, '
      'includeLower: $includeLower, includeUpper: $includeUpper)';
}

/// Query for lower tail probability $P(X \le x)$ or $P(X < x)$.
final class LowerTailQuery extends ProbabilityQuery {
  final ScalarValue value;
  final bool inclusive;

  const LowerTailQuery(this.value, {this.inclusive = true});

  @override
  String toString() => 'LowerTailQuery($value, inclusive: $inclusive)';
}

/// Query for upper tail probability $P(X \ge x)$ or $P(X > x)$.
final class UpperTailQuery extends ProbabilityQuery {
  final ScalarValue value;
  final bool inclusive;

  const UpperTailQuery(this.value, {this.inclusive = true});

  @override
  String toString() => 'UpperTailQuery($value, inclusive: $inclusive)';
}
