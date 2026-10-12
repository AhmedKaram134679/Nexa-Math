import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/discrete_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_numeric_helper.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/standard_random_source.dart';
import 'package:nexa_math/mathematical_core/probability/special_functions/gamma_functions.dart';

/// Implementation of the discrete Poisson distribution $\text{Pois}(\lambda)$.
///
/// Parameters:
/// - $\lambda > 0$: Rate/mean parameter. $\lambda \le 0$ is rejected.
///
/// Support:
/// - $k \in \{0, 1, 2, \dots\}$. For $k < 0$, PMF and CDF return exact structural 0.
final class PoissonDistribution extends DiscreteDistribution {
  /// Rate parameter $\lambda > 0$.
  final ScalarValue lambdaParameter;

  final double _lambda;

  PoissonDistribution._({required this.lambdaParameter, required this._lambda});

  /// Factory constructor validating rate parameter $\lambda > 0$.
  static MathResult<PoissonDistribution> create({required ScalarValue lambda}) {
    final lamRes = ProbabilityNumericHelper.toDouble(
      lambda,
      functionName: 'PoissonDistribution',
      argumentName: 'lambda',
    );
    if (lamRes is MathFailure<double>) return MathFailure(lamRes.error);
    final lamVal = (lamRes as MathSuccess<double>).value;

    if (lamVal.isNaN || lamVal <= 0.0 || lamVal.isInfinite) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'lambda',
          reason:
              'Rate parameter lambda must be strictly positive (lambda > 0).',
        ),
      );
    }

    return MathSuccess(
      PoissonDistribution._(lambdaParameter: lambda, lambda: lamVal),
    );
  }

  @override
  String get name => 'PoissonDistribution';

  @override
  MathResult<ScalarValue> get mean => MathSuccess(lambdaParameter);

  @override
  MathResult<ScalarValue> get variance => MathSuccess(lambdaParameter);

  @override
  MathResult<ScalarValue> get standardDeviation {
    final sd = math.sqrt(_lambda);
    return MathSuccess(
      DecimalValue.parse(sd.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> pdf(ScalarValue x) {
    if (x is! IntegerValue) {
      final xRes = ProbabilityNumericHelper.toDouble(x);
      if (xRes is MathFailure<double>) return MathFailure(xRes.error);
      final d = (xRes as MathSuccess<double>).value;
      if (d != d.roundToDouble()) {
        return MathSuccess(IntegerValue.zero);
      }
      return pmf(IntegerValue.fromInt(d.toInt()));
    }
    return pmf(x);
  }

  @override
  MathResult<ScalarValue> pmf(IntegerValue k) {
    if (k.isNegative) {
      return MathSuccess(IntegerValue.zero);
    }

    final kVal = k.value.toDouble();

    // Log-domain evaluation to prevent intermediate factorial overflow:
    // log P(X = k) = k * ln(lambda) - lambda - ln(k!)
    // ln(k!) = logGamma(k + 1)
    final logFact = GammaFunctions.logGamma(kVal + 1.0);
    final logP = kVal * math.log(_lambda) - _lambda - logFact;

    if (logP < -744.0) {
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    final prob = math.exp(logP);
    if (prob == 0.0) {
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    return ProbabilityNumericHelper.clampProbability(prob);
  }

  @override
  MathResult<ScalarValue> cdf(ScalarValue x) {
    final xRes = ProbabilityNumericHelper.toDouble(
      x,
      functionName: 'PoissonDistribution.cdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    final k = xVal.floor();
    if (k < 0) {
      return MathSuccess(IntegerValue.zero);
    }

    // Cumulative Poisson distribution has exact identity with upper regularized gamma:
    // P(X <= k) = Q(k + 1, lambda) = Gamma(k + 1, lambda) / Gamma(k + 1)
    final prob = GammaFunctions.regularizedGammaQ(k + 1.0, _lambda);

    return ProbabilityNumericHelper.clampProbability(prob);
  }

  @override
  MathResult<ScalarValue> inverseCdf(ScalarValue probability) {
    final pRes = ProbabilityNumericHelper.toDouble(
      probability,
      functionName: 'PoissonDistribution.inverseCdf',
      argumentName: 'probability',
    );
    if (pRes is MathFailure<double>) return MathFailure(pRes.error);
    final p = (pRes as MathSuccess<double>).value;

    if (p < 0.0 || p > 1.0 || p.isNaN) {
      return MathFailure(InvalidProbabilityError(value: p));
    }

    // Generalized inverse: Q(p) = inf{k : F(k) >= p}
    // Endpoint Q(0) = 0
    if (p == 0.0) return MathSuccess(IntegerValue.zero);
    if (p == 1.0) {
      return const MathFailure(
        DomainError(
          functionName: 'PoissonDistribution.inverseCdf',
          argument: 'probability',
          message: 'Inverse CDF is unbounded at p = 1 for unbounded Poisson support.',
        ),
      );
    }

    // Find initial upper bound for binary search
    var low = 0;
    var high = math.max(10, (_lambda + 10.0 * math.sqrt(_lambda)).toInt());

    // Expand high if necessary with deterministic safety ceiling (ISS-10-02)
    const maxDoublings = 50;
    var doublings = 0;
    var highCdfRes = cdf(IntegerValue.fromInt(high));
    while (highCdfRes is MathSuccess<ScalarValue>) {
      final valRes = ProbabilityNumericHelper.toDouble(highCdfRes.value);
      if (valRes is MathSuccess<double> && valRes.value >= p) {
        break;
      }
      doublings++;
      if (doublings > maxDoublings) {
        return const MathFailure(
          ConvergenceFailureError(
            message: 'Poisson inverse CDF failed to bracket quantile within bounded search ceiling.',
            iterations: maxDoublings,
            method: 'PoissonDistribution.inverseCdf',
          ),
        );
      }
      high *= 2;
      highCdfRes = cdf(IntegerValue.fromInt(high));
    }
    if (highCdfRes is MathFailure<ScalarValue>) return highCdfRes;

    var ans = high;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final cdfRes = cdf(IntegerValue.fromInt(mid));
      if (cdfRes is MathFailure<ScalarValue>) return cdfRes;
      final cdfValRes = ProbabilityNumericHelper.toDouble(
        (cdfRes as MathSuccess<ScalarValue>).value,
      );
      if (cdfValRes is MathFailure<double>) return MathFailure(cdfValRes.error);
      final cdfVal = (cdfValRes as MathSuccess<double>).value;

      if (cdfVal >= p) {
        ans = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    return MathSuccess(IntegerValue.fromInt(ans));
  }

  @override
  MathResult<ScalarValue> sampleOne(RandomSource source) {
    // For small lambda < 30, use Knuth's direct multiplication algorithm
    if (_lambda < 30.0) {
      final l = math.exp(-_lambda);
      var k = 0;
      var p = 1.0;
      do {
        k++;
        p *= source.nextDouble();
      } while (p > l);
      return MathSuccess(IntegerValue.fromInt(k - 1));
    }

    // For larger lambda, use inverse transform
    final uRes = OpenIntervalSamplingHelper.nextOpenDouble(source);
    if (uRes is MathFailure<double>) return MathFailure(uRes.error);
    final u = (uRes as MathSuccess<double>).value;

    return inverseCdf(DecimalValue.parse(u.toString(), isExact: false));
  }
}
