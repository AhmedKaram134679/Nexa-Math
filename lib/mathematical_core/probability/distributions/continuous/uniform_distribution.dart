import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/fraction_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/continuous_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_numeric_helper.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/random_source.dart';

/// Implementation of the continuous Uniform distribution $\mathcal{U}(a, b)$.
///
/// Parameters:
/// - $a < b$: Real endpoints defining support $[a, b]$. $a \ge b$ is rejected.
///
/// Exactness:
/// - Exact rational computation is preserved when $a, b, x \in \mathbb{Q}$ and bit lengths $\le 1024$.
/// - Outside support $[a, b]$, PDF and tails return exact structural zeroes/ones where appropriate.
final class UniformDistribution extends ContinuousDistribution {
  /// Lower bound parameter $a$.
  final ScalarValue aParameter;

  /// Upper bound parameter $b$.
  final ScalarValue bParameter;

  final double _a;
  final double _b;

  UniformDistribution._({
    required this.aParameter,
    required this.bParameter,
    required this._a,
    required this._b,
  });

  /// Factory constructor validating parameters $a < b$.
  static MathResult<UniformDistribution> create({
    required ScalarValue a,
    required ScalarValue b,
  }) {
    final aRes = ProbabilityNumericHelper.toDouble(
      a,
      functionName: 'UniformDistribution',
      argumentName: 'a',
    );
    if (aRes is MathFailure<double>) return MathFailure(aRes.error);
    final aVal = (aRes as MathSuccess<double>).value;

    final bRes = ProbabilityNumericHelper.toDouble(
      b,
      functionName: 'UniformDistribution',
      argumentName: 'b',
    );
    if (bRes is MathFailure<double>) return MathFailure(bRes.error);
    final bVal = (bRes as MathSuccess<double>).value;

    if (aVal.isNaN || aVal.isInfinite) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'a',
          reason: 'Lower bound a must be finite.',
        ),
      );
    }
    if (bVal.isNaN || bVal.isInfinite) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'b',
          reason: 'Upper bound b must be finite.',
        ),
      );
    }

    if (aVal >= bVal) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'a, b',
          reason:
              'Lower bound a must be strictly less than upper bound b (a < b).',
        ),
      );
    }

    return MathSuccess(
      UniformDistribution._(aParameter: a, bParameter: b, a: aVal, b: bVal),
    );
  }

  /// Convenience standard uniform distribution $\mathcal{U}(0, 1)$.
  static UniformDistribution standard() => UniformDistribution._(
    aParameter: IntegerValue.zero,
    bParameter: IntegerValue.one,
    a: 0.0,
    b: 1.0,
  );

  @override
  String get name => 'UniformDistribution';

  bool get _isExactRational =>
      (aParameter is IntegerValue || aParameter is FractionValue) &&
      (bParameter is IntegerValue || bParameter is FractionValue);

  FractionValue _toFraction(ScalarValue val) {
    if (val is IntegerValue) return FractionValue.fromInteger(val);
    if (val is FractionValue) return val;
    throw StateError('Expected rational value');
  }

  @override
  MathResult<ScalarValue> get mean {
    if (_isExactRational) {
      final fa = _toFraction(aParameter);
      final fb = _toFraction(bParameter);
      final sumRes = FractionOperations.add(fa, fb);
      if (sumRes is MathSuccess<FractionValue>) {
        final two = FractionValue.fromInts(2, 1);
        final divRes = FractionOperations.divide(sumRes.value, two);
        if (divRes is MathSuccess<FractionValue>) {
          final m = divRes.value;
          if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
            m.numerator,
            m.denominator,
          )) {
            return MathSuccess(m);
          }
        }
      }
    }
    final mVal = (_a + _b) / 2.0;
    return MathSuccess(
      DecimalValue.parse(mVal.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get variance {
    if (_isExactRational) {
      final fa = _toFraction(aParameter);
      final fb = _toFraction(bParameter);
      final diffRes = FractionOperations.subtract(fb, fa);
      if (diffRes is MathSuccess<FractionValue>) {
        final sqRes = FractionOperations.multiply(diffRes.value, diffRes.value);
        if (sqRes is MathSuccess<FractionValue>) {
          final twelve = FractionValue.fromInts(12, 1);
          final divRes = FractionOperations.divide(sqRes.value, twelve);
          if (divRes is MathSuccess<FractionValue>) {
            final v = divRes.value;
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
    final diff = _b - _a;
    final vVal = (diff * diff) / 12.0;
    return MathSuccess(
      DecimalValue.parse(vVal.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get standardDeviation {
    final diff = _b - _a;
    final sdVal = diff / 3.4641016151377545870548926830117; // sqrt(12)
    return MathSuccess(
      DecimalValue.parse(sdVal.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> pdf(ScalarValue x) {
    final xRes = ProbabilityNumericHelper.toDouble(
      x,
      functionName: 'UniformDistribution.pdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    // Support is [a, b]. Outside support, density is structural 0.
    if (xVal < _a || xVal > _b) {
      return MathSuccess(IntegerValue.zero);
    }

    if (_isExactRational) {
      final fa = _toFraction(aParameter);
      final fb = _toFraction(bParameter);
      final diffRes = FractionOperations.subtract(fb, fa);
      if (diffRes is MathSuccess<FractionValue>) {
        final divRes = FractionOperations.divide(
          FractionValue.one,
          diffRes.value,
        );
        if (divRes is MathSuccess<FractionValue>) {
          final density = divRes.value;
          if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
            density.numerator,
            density.denominator,
          )) {
            return MathSuccess(density);
          }
        }
      }
    }

    final d = 1.0 / (_b - _a);
    return MathSuccess(
      DecimalValue.parse(d.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> cdf(ScalarValue x) {
    final xRes = ProbabilityNumericHelper.toDouble(
      x,
      functionName: 'UniformDistribution.cdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    if (xVal <= _a) {
      return MathSuccess(IntegerValue.zero);
    }
    if (xVal >= _b) {
      return MathSuccess(IntegerValue.one);
    }

    if (_isExactRational && (x is IntegerValue || x is FractionValue)) {
      final fa = _toFraction(aParameter);
      final fb = _toFraction(bParameter);
      final fx = _toFraction(x);
      final numRes = FractionOperations.subtract(fx, fa);
      final denRes = FractionOperations.subtract(fb, fa);
      if (numRes is MathSuccess<FractionValue> &&
          denRes is MathSuccess<FractionValue>) {
        final probRes = FractionOperations.divide(numRes.value, denRes.value);
        if (probRes is MathSuccess<FractionValue>) {
          final prob = probRes.value;
          if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
            prob.numerator,
            prob.denominator,
          )) {
            return MathSuccess(prob);
          }
        }
      }
    }

    final prob = (xVal - _a) / (_b - _a);
    return ProbabilityNumericHelper.clampProbability(prob);
  }

  @override
  MathResult<ScalarValue> inverseCdf(ScalarValue probability) {
    final pRes = ProbabilityNumericHelper.toDouble(
      probability,
      functionName: 'UniformDistribution.inverseCdf',
      argumentName: 'probability',
    );
    if (pRes is MathFailure<double>) return MathFailure(pRes.error);
    final p = (pRes as MathSuccess<double>).value;

    if (p < 0.0 || p > 1.0 || p.isNaN) {
      return MathFailure(InvalidProbabilityError(value: p));
    }

    // Endpoint behavior: Q(0) = a, Q(1) = b
    if (p == 0.0) return MathSuccess(aParameter);
    if (p == 1.0) return MathSuccess(bParameter);

    if (_isExactRational &&
        (probability is IntegerValue || probability is FractionValue)) {
      final fa = _toFraction(aParameter);
      final fb = _toFraction(bParameter);
      final fp = _toFraction(probability);
      final diffRes = FractionOperations.subtract(fb, fa);
      if (diffRes is MathSuccess<FractionValue>) {
        final prodRes = FractionOperations.multiply(fp, diffRes.value);
        if (prodRes is MathSuccess<FractionValue>) {
          final quantRes = FractionOperations.add(fa, prodRes.value);
          if (quantRes is MathSuccess<FractionValue>) {
            final quant = quantRes.value;
            if (!ProbabilityNumericHelper.exceedsRationalResourceLimit(
              quant.numerator,
              quant.denominator,
            )) {
              return MathSuccess(quant);
            }
          }
        }
      }
    }

    final quant = _a + p * (_b - _a);
    return MathSuccess(
      DecimalValue.parse(quant.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> sampleOne(RandomSource source) {
    final u = source.nextDouble();
    final x = _a + u * (_b - _a);
    return MathSuccess(
      DecimalValue.parse(x.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }
}
