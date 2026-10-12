import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/fraction_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/discrete_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_numeric_helper.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/standard_random_source.dart';

/// Implementation of the discrete Geometric distribution $\text{Geom}(p)$.
///
/// Mathematical Convention (Revision 6):
/// - Number of trials until the first success.
/// - Support: $k \in \{1, 2, 3, \dots\}$. For $k \le 0$, PMF and CDF return exact structural 0.
/// - Parameter: $p \in (0, 1]$. $p \le 0$ or $p > 1$ is rejected.
/// - PMF: $P(X = k) = (1 - p)^{k - 1} p$.
/// - CDF: $P(X \le k) = 1 - (1 - p)^k$.
/// - Inverse CDF: $Q(p) = \inf\{k \ge 1 : F(k) \ge p\} = \lceil \frac{\ln(1 - p)}{\ln(1 - p)} \rceil$.
///
/// Exactness:
/// - When $p$ is exact rational and bit lengths $\le 1024$, PMF and CDF maintain exact rational values.
final class GeometricDistribution extends DiscreteDistribution {
  /// Success probability parameter $p \in (0, 1]$.
  final ScalarValue probabilityParameter;

  final double _p;

  GeometricDistribution._({
    required this.probabilityParameter,
    required this._p,
  });

  /// Factory constructor validating parameter $p \in (0, 1]$.
  static MathResult<GeometricDistribution> create({
    required ScalarValue probability,
  }) {
    final pRes = ProbabilityNumericHelper.toDouble(
      probability,
      functionName: 'GeometricDistribution',
      argumentName: 'probability',
    );
    if (pRes is MathFailure<double>) return MathFailure(pRes.error);
    final pVal = (pRes as MathSuccess<double>).value;

    if (pVal.isNaN || pVal <= 0.0 || pVal > 1.0) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'probability',
          reason: 'Probability parameter p must be in (0, 1] for trials-until-first-success Geometric.',
        ),
      );
    }

    return MathSuccess(
      GeometricDistribution._(probabilityParameter: probability, p: pVal),
    );
  }

  @override
  String get name => 'GeometricDistribution';

  bool get _isExactRational =>
      probabilityParameter is IntegerValue ||
      probabilityParameter is FractionValue;

  FractionValue _toFraction(ScalarValue val) {
    if (val is IntegerValue) return FractionValue.fromInteger(val);
    if (val is FractionValue) return val;
    throw StateError('Expected rational value');
  }

  @override
  MathResult<ScalarValue> get mean {
    if (_isExactRational) {
      final fp = _toFraction(probabilityParameter);
      final m = fp.reciprocal();
      if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
        m.numerator,
        m.denominator,
      )) {
        return MathSuccess(m);
      }
    }
    final mVal = 1.0 / _p;
    return MathSuccess(
      DecimalValue.parse(mVal.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get variance {
    if (_isExactRational) {
      final fp = _toFraction(probabilityParameter);
      final fqRes = FractionOperations.subtract(FractionValue.one, fp);
      final pSqRes = FractionOperations.multiply(fp, fp);
      if (fqRes is MathSuccess<FractionValue> &&
          pSqRes is MathSuccess<FractionValue>) {
        final vRes = FractionOperations.divide(fqRes.value, pSqRes.value);
        if (vRes is MathSuccess<FractionValue>) {
          final v = vRes.value;
          if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
            v.numerator,
            v.denominator,
          )) {
            return MathSuccess(v);
          }
        }
      }
    }
    final vVal = (1.0 - _p) / (_p * _p);
    return MathSuccess(
      DecimalValue.parse(vVal.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get standardDeviation {
    final vVal = (1.0 - _p) / (_p * _p);
    final sdVal = math.sqrt(vVal);
    return MathSuccess(
      DecimalValue.parse(sdVal.toString(), isExact: false),
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
    final kVal = k.value;

    // Support is k >= 1
    if (kVal < BigInt.one) {
      return MathSuccess(IntegerValue.zero);
    }

    // Exact degenerate case p = 1
    if (_p == 1.0) {
      return (kVal == BigInt.one)
          ? MathSuccess(IntegerValue.one)
          : MathSuccess(IntegerValue.zero);
    }

    final kInt = kVal.toInt();

    // Exact rational computation with 1,024-bit predictive check
    if (_isExactRational) {
      final fp = _toFraction(probabilityParameter);
      final fqRes = FractionOperations.subtract(FractionValue.one, fp);
      if (fqRes is MathSuccess<FractionValue>) {
        final fq = fqRes.value;
        final denBits = kInt * fp.denominator.bitLength;
        if (denBits <= ProbabilityNumericHelper.maxRationalBitLength) {
          final qPowRes = FractionOperations.power(fq, kInt - 1);
          if (qPowRes is MathSuccess<FractionValue>) {
            final resRes = FractionOperations.multiply(qPowRes.value, fp);
            if (resRes is MathSuccess<FractionValue>) {
              final resFrac = resRes.value;
              if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
                resFrac.numerator,
                resFrac.denominator,
              )) {
                return MathSuccess(resFrac);
              }
            }
          }
        }
      }
    }

    // Log-domain numerical evaluation:
    // log P(X = k) = (k - 1) * ln(1 - p) + ln(p)
    final logP = (kInt - 1) * math.log(1.0 - _p) + math.log(_p);

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
      functionName: 'GeometricDistribution.cdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    final k = xVal.floor();
    if (k < 1) {
      return MathSuccess(IntegerValue.zero);
    }

    if (_p == 1.0) {
      return MathSuccess(IntegerValue.one);
    }

    // Exact rational computation: 1 - (1 - p)^k
    if (_isExactRational) {
      final fp = _toFraction(probabilityParameter);
      final fqRes = FractionOperations.subtract(FractionValue.one, fp);
      if (fqRes is MathSuccess<FractionValue>) {
        final fq = fqRes.value;
        final denBits = k * fp.denominator.bitLength;
        if (denBits <= ProbabilityNumericHelper.maxRationalBitLength) {
          final qPowRes = FractionOperations.power(fq, k);
          if (qPowRes is MathSuccess<FractionValue>) {
            final resRes = FractionOperations.subtract(
              FractionValue.one,
              qPowRes.value,
            );
            if (resRes is MathSuccess<FractionValue>) {
              final resFrac = resRes.value;
              if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
                resFrac.numerator,
                resFrac.denominator,
              )) {
                return MathSuccess(resFrac);
              }
            }
          }
        }
      }
    }

    // F(k) = 1 - (1 - p)^k = -expm1(k * ln(1 - p))
    final z = k * math.log(1.0 - _p);
    final prob = (z < -744.0) ? 1.0 : -_expm1(z);

    return ProbabilityNumericHelper.clampProbability(prob);
  }

  @override
  MathResult<ScalarValue> inverseCdf(ScalarValue probability) {
    final pRes = ProbabilityNumericHelper.toDouble(
      probability,
      functionName: 'GeometricDistribution.inverseCdf',
      argumentName: 'probability',
    );
    if (pRes is MathFailure<double>) return MathFailure(pRes.error);
    final p = (pRes as MathSuccess<double>).value;

    if (p < 0.0 || p > 1.0 || p.isNaN) {
      return MathFailure(InvalidProbabilityError(value: p));
    }

    // Endpoint Q(0) = inf{k >= 1 : F(k) >= 0} = 1
    if (p == 0.0) return MathSuccess(IntegerValue.one);
    if (p == 1.0) {
      return const MathFailure(
        DomainError(
          functionName: 'GeometricDistribution.inverseCdf',
          argument: 'probability',
          message: 'Inverse CDF is unbounded at p = 1 for unbounded Geometric support.',
        ),
      );
    }

    if (_p == 1.0) return MathSuccess(IntegerValue.one);

    // Q(p) = ceil(ln(1 - p) / ln(1 - p_param))
    // Note: ln(1 - p) = log1p(-p)
    final num = _log1p(-p);
    final den = _log1p(-_p);
    final k = (num / den).ceil();

    return MathSuccess(IntegerValue.fromInt(math.max(1, k)));
  }

  @override
  MathResult<ScalarValue> sampleOne(RandomSource source) {
    if (_p == 1.0) return MathSuccess(IntegerValue.one);

    // Inverse transform: k = ceil(ln(U) / ln(1 - p)) with U in (0, 1)
    final uRes = OpenIntervalSamplingHelper.nextOpenDouble(source);
    if (uRes is MathFailure<double>) return MathFailure(uRes.error);
    final u = (uRes as MathSuccess<double>).value;

    final den = _log1p(-_p);
    final k = (math.log(u) / den).ceil();
    return MathSuccess(IntegerValue.fromInt(math.max(1, k)));
  }

  static double _expm1(double x) {
    if (x.abs() < 1e-5) {
      return x * (1.0 + x * (0.5 + x / 6.0));
    }
    return math.exp(x) - 1.0;
  }

  static double _log1p(double x) {
    if (x.abs() < 1e-4) {
      return x * (1.0 - x * (0.5 - x / 3.0));
    }
    return math.log(1.0 + x);
  }
}
