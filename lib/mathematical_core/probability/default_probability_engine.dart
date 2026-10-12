import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/fraction_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/continuous_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/discrete_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_engine.dart';
import 'package:nexa_math/mathematical_core/probability/probability_numeric_helper.dart';
import 'package:nexa_math/mathematical_core/probability/queries/probability_query.dart';
import 'package:nexa_math/mathematical_core/probability/queries/probability_result.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/distribution_sampler.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';
import 'package:nexa_math/mathematical_core/statistics/models/dataset.dart';

/// Default production implementation of [ProbabilityEngine].
final class DefaultProbabilityEngine implements ProbabilityEngine {
  const DefaultProbabilityEngine();

  @override
  MathResult<ProbabilityResult> probability(
    ProbabilityDistribution distribution,
    ProbabilityQuery query,
  ) {
    return switch (query) {
      final PointProbabilityQuery q => _evaluatePoint(distribution, q),
      final IntervalProbabilityQuery q => _evaluateInterval(distribution, q),
      final LowerTailQuery q => _evaluateLowerTail(distribution, q),
      final UpperTailQuery q => _evaluateUpperTail(distribution, q),
    };
  }

  @override
  MathResult<ScalarValue> pdf(
    ProbabilityDistribution distribution,
    ScalarValue x,
  ) {
    return distribution.pdf(x);
  }

  @override
  MathResult<ScalarValue> cdf(
    ProbabilityDistribution distribution,
    ScalarValue x,
  ) {
    return distribution.cdf(x);
  }

  @override
  MathResult<ScalarValue> inverseCdf(
    ProbabilityDistribution distribution,
    ScalarValue probability,
  ) {
    return distribution.inverseCdf(probability);
  }

  @override
  MathResult<Dataset> sample(
    ProbabilityDistribution distribution,
    int count,
    RandomSource randomSource,
  ) {
    return DistributionSampler.sample(distribution, count, randomSource);
  }

  MathResult<ProbabilityResult> _evaluatePoint(
    ProbabilityDistribution distribution,
    PointProbabilityQuery query,
  ) {
    if (distribution is ContinuousDistribution) {
      // In any continuous distribution, the probability of any exact point is 0
      return MathSuccess(
        ProbabilityResult(value: IntegerValue.zero, query: query),
      );
    }

    if (distribution is DiscreteDistribution) {
      final pmfRes = distribution.pdf(query.point);
      if (pmfRes is MathFailure<ScalarValue>) {
        return MathFailure(pmfRes.error);
      }
      return MathSuccess(
        ProbabilityResult(
          value: (pmfRes as MathSuccess<ScalarValue>).value,
          query: query,
        ),
      );
    }

    return distribution
        .pdf(query.point)
        .map((val) => ProbabilityResult(value: val, query: query));
  }

  MathResult<ProbabilityResult> _evaluateLowerTail(
    ProbabilityDistribution distribution,
    LowerTailQuery query,
  ) {
    if (distribution is ContinuousDistribution) {
      // For continuous distributions, P(X <= x) == P(X < x) = F(x)
      final cdfRes = distribution.cdf(query.value);
      if (cdfRes is MathFailure<ScalarValue>) return MathFailure(cdfRes.error);
      return MathSuccess(
        ProbabilityResult(
          value: (cdfRes as MathSuccess<ScalarValue>).value,
          query: query,
        ),
      );
    }

    if (distribution is DiscreteDistribution) {
      final valRes = ProbabilityNumericHelper.toDouble(
        query.value,
        functionName: 'ProbabilityEngine.probability',
        argumentName: 'value',
      );
      if (valRes is MathFailure<double>) return MathFailure(valRes.error);
      final d = (valRes as MathSuccess<double>).value;

      final k = query.inclusive ? d.floor() : (d - 1e-15).floor();
      final cdfRes = distribution.cdf(IntegerValue.fromInt(k));
      if (cdfRes is MathFailure<ScalarValue>) return MathFailure(cdfRes.error);
      return MathSuccess(
        ProbabilityResult(
          value: (cdfRes as MathSuccess<ScalarValue>).value,
          query: query,
        ),
      );
    }

    return distribution
        .cdf(query.value)
        .map((val) => ProbabilityResult(value: val, query: query));
  }

  MathResult<ProbabilityResult> _evaluateUpperTail(
    ProbabilityDistribution distribution,
    UpperTailQuery query,
  ) {
    if (distribution is ContinuousDistribution) {
      // P(X >= x) == P(X > x) = 1 - F(x)
      final cdfRes = distribution.cdf(query.value);
      if (cdfRes is MathFailure<ScalarValue>) return MathFailure(cdfRes.error);
      final cdfVal = (cdfRes as MathSuccess<ScalarValue>).value;

      return _subtractFromOne(cdfVal)
          .map((val) => ProbabilityResult(value: val, query: query));
    }

    if (distribution is DiscreteDistribution) {
      final valRes = ProbabilityNumericHelper.toDouble(
        query.value,
        functionName: 'ProbabilityEngine.probability',
        argumentName: 'value',
      );
      if (valRes is MathFailure<double>) return MathFailure(valRes.error);
      final d = (valRes as MathSuccess<double>).value;

      // P(X >= k) = 1 - P(X <= k - 1)
      // P(X > k) = 1 - P(X <= k)
      final cutoff = query.inclusive ? (d - 1e-15).floor() : d.floor();
      final cdfRes = distribution.cdf(IntegerValue.fromInt(cutoff));
      if (cdfRes is MathFailure<ScalarValue>) return MathFailure(cdfRes.error);
      final cdfVal = (cdfRes as MathSuccess<ScalarValue>).value;

      return _subtractFromOne(cdfVal)
          .map((val) => ProbabilityResult(value: val, query: query));
    }

    return const MathFailure(
      DomainError(message: 'Unsupported distribution classification.'),
    );
  }

  MathResult<ProbabilityResult> _evaluateInterval(
    ProbabilityDistribution distribution,
    IntervalProbabilityQuery query,
  ) {
    final lowerRes = ProbabilityNumericHelper.toDouble(
      query.lower,
      functionName: 'ProbabilityEngine.probability',
      argumentName: 'lower',
    );
    if (lowerRes is MathFailure<double>) return MathFailure(lowerRes.error);
    final a = (lowerRes as MathSuccess<double>).value;

    final upperRes = ProbabilityNumericHelper.toDouble(
      query.upper,
      functionName: 'ProbabilityEngine.probability',
      argumentName: 'upper',
    );
    if (upperRes is MathFailure<double>) return MathFailure(upperRes.error);
    final b = (upperRes as MathSuccess<double>).value;

    if (a > b) {
      return const MathFailure(
        InvalidArgumentError(
          message: 'Interval lower bound must not exceed upper bound (lower <= upper).',
          argumentName: 'lower, upper',
        ),
      );
    }

    if (a == b) {
      if (!query.includeLower || !query.includeUpper) {
        return MathSuccess(
          ProbabilityResult(value: IntegerValue.zero, query: query),
        );
      }
      return _evaluatePoint(distribution, PointProbabilityQuery(query.lower));
    }

    if (distribution is ContinuousDistribution) {
      // P(a <= X <= b) = F(b) - F(a) regardless of endpoint inclusivity
      final fbRes = distribution.cdf(query.upper);
      if (fbRes is MathFailure<ScalarValue>) return MathFailure(fbRes.error);
      final faRes = distribution.cdf(query.lower);
      if (faRes is MathFailure<ScalarValue>) return MathFailure(faRes.error);

      final fb = (fbRes as MathSuccess<ScalarValue>).value;
      final fa = (faRes as MathSuccess<ScalarValue>).value;

      return _subtractProbabilities(
        fb,
        fa,
      ).map((val) => ProbabilityResult(value: val, query: query));
    }

    if (distribution is DiscreteDistribution) {
      // Discrete interval:
      // k_min: smallest integer in interval
      // k_max: largest integer in interval
      final kMin = query.includeLower ? a.ceil() : (a + 1e-15).floor() + 1;
      final kMax = query.includeUpper ? b.floor() : (b - 1e-15).ceil() - 1;

      if (kMin > kMax) {
        return MathSuccess(
          ProbabilityResult(value: IntegerValue.zero, query: query),
        );
      }

      // P(k_min <= X <= k_max) = F(k_max) - F(k_min - 1)
      final fbRes = distribution.cdf(IntegerValue.fromInt(kMax));
      if (fbRes is MathFailure<ScalarValue>) return MathFailure(fbRes.error);
      final faRes = distribution.cdf(IntegerValue.fromInt(kMin - 1));
      if (faRes is MathFailure<ScalarValue>) return MathFailure(faRes.error);

      final fb = (fbRes as MathSuccess<ScalarValue>).value;
      final fa = (faRes as MathSuccess<ScalarValue>).value;

      return _subtractProbabilities(
        fb,
        fa,
      ).map((val) => ProbabilityResult(value: val, query: query));
    }

    return const MathFailure(
      DomainError(message: 'Unsupported distribution classification.'),
    );
  }

  MathResult<ScalarValue> _subtractFromOne(ScalarValue p) {
    if (p is IntegerValue) {
      return MathSuccess(IntegerValue(BigInt.one - p.value));
    }
    if (p is FractionValue) {
      return FractionOperations.subtract(FractionValue.one, p);
    }
    final dRes = ProbabilityNumericHelper.toDouble(p);
    if (dRes is MathFailure<double>) return MathFailure(dRes.error);
    final d = (dRes as MathSuccess<double>).value;

    final diff = 1.0 - d;
    return ProbabilityNumericHelper.clampProbability(diff);
  }

  MathResult<ScalarValue> _subtractProbabilities(
    ScalarValue high,
    ScalarValue low,
  ) {
    if (high is IntegerValue && low is IntegerValue) {
      return MathSuccess(IntegerValue(high.value - low.value));
    }
    if (high is FractionValue && low is FractionValue) {
      final diffRes = FractionOperations.subtract(high, low);
      if (diffRes is MathSuccess<FractionValue>) {
        final diff = diffRes.value;
        if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
          diff.numerator,
          diff.denominator,
        )) {
          return MathSuccess(diff);
        }
      }
    }
    final highRes = ProbabilityNumericHelper.toDouble(high);
    if (highRes is MathFailure<double>) return MathFailure(highRes.error);
    final lowRes = ProbabilityNumericHelper.toDouble(low);
    if (lowRes is MathFailure<double>) return MathFailure(lowRes.error);

    final diff =
        (highRes as MathSuccess<double>).value -
        (lowRes as MathSuccess<double>).value;

    return ProbabilityNumericHelper.clampProbability(diff);
  }
}
