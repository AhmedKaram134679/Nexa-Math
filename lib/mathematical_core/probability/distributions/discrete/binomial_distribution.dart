import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/fraction_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/primitives/combinatorics.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/discrete_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_numeric_helper.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/standard_random_source.dart';
import 'package:nexa_math/mathematical_core/probability/special_functions/beta_functions.dart';
import 'package:nexa_math/mathematical_core/probability/special_functions/gamma_functions.dart';

/// Implementation of the discrete Binomial distribution $\text{Bin}(n, p)$.
///
/// Parameters:
/// - $n \in \mathbb{N}_0$: Number of trials. Must be an integer $n \ge 0$.
/// - $p \in [0, 1]$: Probability of success per trial.
///
/// Support:
/// - $k \in \{0, 1, \dots, n\}$. Outside this support, PMF is structural 0.
///
/// Exactness:
/// - When $p$ is exact rational (Integer or Fraction) and bit lengths $\le 1024$,
///   computations are performed with exact rational arithmetic.
/// - Degenerate cases $n = 0$, $p = 0$, $p = 1$ are evaluated exactly.
final class BinomialDistribution extends DiscreteDistribution {
  /// Number of trials $n \ge 0$.
  final IntegerValue trialsParameter;

  /// Success probability parameter $p \in [0, 1]$.
  final ScalarValue probabilityParameter;

  final int _n;
  final double _p;

  BinomialDistribution._({
    required this.trialsParameter,
    required this.probabilityParameter,
    required this._n,
    required this._p,
  });

  /// Factory constructor validating parameters $n \in \mathbb{N}_0$ and $p \in [0, 1]$.
  static MathResult<BinomialDistribution> create({
    required ScalarValue trials,
    required ScalarValue probability,
  }) {
    if (trials is! IntegerValue) {
      if (trials is DecimalValue) {
        final dVal = trials.toDouble();
        if (dVal == dVal.roundToDouble() && dVal >= 0) {
          // Can be safely coerced to integer
          return create(
            trials: IntegerValue.fromInt(dVal.toInt()),
            probability: probability,
          );
        }
      }
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'trials',
          reason: 'Trials parameter n must be an integer.',
        ),
      );
    }

    if (trials.value < BigInt.zero) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'trials',
          reason: 'Trials parameter n must be non-negative (n >= 0).',
        ),
      );
    }

    final pRes = ProbabilityNumericHelper.toDouble(
      probability,
      functionName: 'BinomialDistribution',
      argumentName: 'probability',
    );
    if (pRes is MathFailure<double>) return MathFailure(pRes.error);
    final pVal = (pRes as MathSuccess<double>).value;

    if (pVal < 0.0 || pVal > 1.0 || pVal.isNaN) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'probability',
          reason: 'Probability parameter p must be in [0, 1].',
        ),
      );
    }

    final nInt = trials.value.toInt();

    return MathSuccess(
      BinomialDistribution._(
        trialsParameter: trials,
        probabilityParameter: probability,
        n: nInt,
        p: pVal,
      ),
    );
  }

  @override
  String get name => 'BinomialDistribution';

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
      final fn = FractionValue.fromInts(_n, 1);
      final mRes = FractionOperations.multiply(fn, fp);
      if (mRes is MathSuccess<FractionValue>) {
        final m = mRes.value;
        if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
          m.numerator,
          m.denominator,
        )) {
          return MathSuccess(m);
        }
      }
    }
    final mVal = _n * _p;
    return MathSuccess(
      DecimalValue.parse(mVal.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get variance {
    if (_isExactRational) {
      final fp = _toFraction(probabilityParameter);
      final fn = FractionValue.fromInts(_n, 1);
      final fqRes = FractionOperations.subtract(FractionValue.one, fp);
      if (fqRes is MathSuccess<FractionValue>) {
        final npRes = FractionOperations.multiply(fn, fp);
        if (npRes is MathSuccess<FractionValue>) {
          final vRes = FractionOperations.multiply(npRes.value, fqRes.value);
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
    }
    final vVal = _n * _p * (1.0 - _p);
    return MathSuccess(
      DecimalValue.parse(vVal.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get standardDeviation {
    final vVal = _n * _p * (1.0 - _p);
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
    final nBig = trialsParameter.value;

    // Support is 0 <= k <= n
    if (kVal < BigInt.zero || kVal > nBig) {
      return MathSuccess(IntegerValue.zero);
    }

    // Degenerate case n = 0
    if (_n == 0) {
      return (kVal == BigInt.zero)
          ? MathSuccess(IntegerValue.one)
          : MathSuccess(IntegerValue.zero);
    }

    // Degenerate case p = 0
    if (_p == 0.0) {
      return (kVal == BigInt.zero)
          ? MathSuccess(IntegerValue.one)
          : MathSuccess(IntegerValue.zero);
    }

    // Degenerate case p = 1
    if (_p == 1.0) {
      return (kVal == nBig)
          ? MathSuccess(IntegerValue.one)
          : MathSuccess(IntegerValue.zero);
    }

    // Exact rational computation with 1,024-bit predictive check
    if (_isExactRational) {
      final fp = _toFraction(probabilityParameter);
      final pNum = fp.numerator.abs();
      final pDen = fp.denominator.abs();
      final qNum = (pDen - pNum).abs();

      final kInt = kVal.toInt();
      final nMinusK = _n - kInt;

      final denBits = (nBig * BigInt.from(pDen.bitLength)).toInt();
      if (denBits <= ProbabilityNumericHelper.maxRationalBitLength) {
        final combRes = Combinatorics.combinations(trialsParameter, k);
        if (combRes is MathSuccess<IntegerValue>) {
          final c = combRes.value.value;
          final num = c * (pNum.pow(kInt)) * (qNum.pow(nMinusK));
          final den = pDen.pow(_n);
          final resFrac = FractionValue(num, den);
          if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
            resFrac.numerator,
            resFrac.denominator,
          )) {
            return MathSuccess(resFrac);
          }
        }
      }
    }

    // Numerical evaluation via log-gamma
    final kInt = kVal.toInt();
    final logC =
        GammaFunctions.logGamma(_n + 1.0) -
        GammaFunctions.logGamma(kInt + 1.0) -
        GammaFunctions.logGamma(_n - kInt + 1.0);

    final logP = logC + kInt * math.log(_p) + (_n - kInt) * math.log(1.0 - _p);

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
      functionName: 'BinomialDistribution.cdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    final k = xVal.floor();

    if (k < 0) {
      return MathSuccess(IntegerValue.zero);
    }
    if (k >= _n) {
      return MathSuccess(IntegerValue.one);
    }

    if (_p == 0.0) {
      return (k >= 0)
          ? MathSuccess(IntegerValue.one)
          : MathSuccess(IntegerValue.zero);
    }
    if (_p == 1.0) {
      return (k >= _n)
          ? MathSuccess(IntegerValue.one)
          : MathSuccess(IntegerValue.zero);
    }

    // If small n and exact rational, sum exact PMF
    if (_isExactRational && _n <= 100) {
      var sum = FractionValue.zero;
      var exceeded = false;
      for (var i = 0; i <= k; i++) {
        final pmfRes = pmf(IntegerValue.fromInt(i));
        if (pmfRes is MathSuccess<ScalarValue> &&
            pmfRes.value is FractionValue) {
          final addRes = FractionOperations.add(
            sum,
            pmfRes.value as FractionValue,
          );
          if (addRes is MathSuccess<FractionValue>) {
            sum = addRes.value;
            if (ProbabilityNumericHelper.exceedsRationalResourceLimit(
              sum.numerator,
              sum.denominator,
            )) {
              exceeded = true;
              break;
            }
          } else {
            exceeded = true;
            break;
          }
        } else {
          exceeded = true;
          break;
        }
      }
      if (!exceeded) {
        return MathSuccess(sum);
      }
    }

    final prob = BetaFunctions.regularizedBeta(
      _n - k.toDouble(),
      k + 1.0,
      1.0 - _p,
    );

    return ProbabilityNumericHelper.clampProbability(prob);
  }

  @override
  MathResult<ScalarValue> inverseCdf(ScalarValue probability) {
    final pRes = ProbabilityNumericHelper.toDouble(
      probability,
      functionName: 'BinomialDistribution.inverseCdf',
      argumentName: 'probability',
    );
    if (pRes is MathFailure<double>) return MathFailure(pRes.error);
    final p = (pRes as MathSuccess<double>).value;

    if (p < 0.0 || p > 1.0 || p.isNaN) {
      return MathFailure(InvalidProbabilityError(value: p));
    }

    if (p == 0.0) return MathSuccess(IntegerValue.zero);
    if (_n == 0) return MathSuccess(IntegerValue.zero);
    if (_p == 0.0) return MathSuccess(IntegerValue.zero);
    if (_p == 1.0) return MathSuccess(trialsParameter);

    var low = 0;
    var high = _n;
    var ans = _n;

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
    if (_n == 0) return MathSuccess(IntegerValue.zero);
    if (_p == 0.0) return MathSuccess(IntegerValue.zero);
    if (_p == 1.0) return MathSuccess(trialsParameter);

    if (_n <= 100) {
      var successes = 0;
      for (var i = 0; i < _n; i++) {
        if (source.nextDouble() < _p) {
          successes++;
        }
      }
      return MathSuccess(IntegerValue.fromInt(successes));
    }

    final uRes = OpenIntervalSamplingHelper.nextOpenDouble(source);
    if (uRes is MathFailure<double>) return MathFailure(uRes.error);
    final u = (uRes as MathSuccess<double>).value;

    return inverseCdf(DecimalValue.parse(u.toString(), isExact: false));
  }
}
