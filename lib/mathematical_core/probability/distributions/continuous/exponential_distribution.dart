import 'dart:math' as math;

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
import 'package:nexa_math/mathematical_core/probability/sampling/standard_random_source.dart';

/// Implementation of the continuous Exponential distribution $\text{Exp}(\lambda)$.
///
/// Parameters:
/// - $\lambda > 0$: Rate parameter. $\lambda \le 0$ is rejected.
///
/// Support:
/// - $x \in [0, \infty)$. For $x < 0$, PDF and CDF return exact structural 0.
final class ExponentialDistribution extends ContinuousDistribution {
  /// Rate parameter $\lambda > 0$.
  final ScalarValue rateParameter;

  final double _lambda;

  ExponentialDistribution._({
    required this.rateParameter,
    required this._lambda,
  });

  /// Factory constructor validating rate parameter $\lambda > 0$.
  static MathResult<ExponentialDistribution> create({
    required ScalarValue rate,
  }) {
    final lamRes = ProbabilityNumericHelper.toDouble(
      rate,
      functionName: 'ExponentialDistribution',
      argumentName: 'rate',
    );
    if (lamRes is MathFailure<double>) return MathFailure(lamRes.error);
    final lamVal = (lamRes as MathSuccess<double>).value;

    if (lamVal.isNaN || lamVal <= 0.0 || lamVal.isInfinite) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'rate',
          reason:
              'Rate parameter lambda must be strictly positive (lambda > 0).',
        ),
      );
    }

    return MathSuccess(
      ExponentialDistribution._(rateParameter: rate, lambda: lamVal),
    );
  }

  @override
  String get name => 'ExponentialDistribution';

  @override
  MathResult<ScalarValue> get mean {
    if (rateParameter is IntegerValue) {
      final v = (rateParameter as IntegerValue).value;
      return MathSuccess(FractionValue(BigInt.one, v));
    }
    if (rateParameter is FractionValue) {
      final f = rateParameter as FractionValue;
      return MathSuccess(f.reciprocal());
    }
    final m = 1.0 / _lambda;
    return MathSuccess(
      DecimalValue.parse(m.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get variance {
    if (rateParameter is IntegerValue) {
      final v = (rateParameter as IntegerValue).value;
      return MathSuccess(FractionValue(BigInt.one, v * v));
    }
    if (rateParameter is FractionValue) {
      final f = rateParameter as FractionValue;
      final inv = f.reciprocal();
      return FractionOperations.multiply(inv, inv);
    }
    final v = 1.0 / (_lambda * _lambda);
    return MathSuccess(
      DecimalValue.parse(v.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get standardDeviation => mean;

  @override
  MathResult<ScalarValue> pdf(ScalarValue x) {
    final xRes = ProbabilityNumericHelper.toDouble(
      x,
      functionName: 'ExponentialDistribution.pdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    if (xVal < 0.0) {
      return MathSuccess(IntegerValue.zero);
    }

    final exponent = -_lambda * xVal;
    if (exponent < -744.0) {
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    final density = _lambda * math.exp(exponent);
    if (density == 0.0) {
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    return MathSuccess(
      DecimalValue.parse(density.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> cdf(ScalarValue x) {
    final xRes = ProbabilityNumericHelper.toDouble(
      x,
      functionName: 'ExponentialDistribution.cdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    if (xVal <= 0.0) {
      return MathSuccess(IntegerValue.zero);
    }

    // Numerically stable evaluation:
    // F(x) = 1 - exp(-lambda * x) = -expm1(-lambda * x)
    final z = -_lambda * xVal;
    final prob = (z < -744.0) ? 1.0 : -_expm1(z);

    return ProbabilityNumericHelper.clampProbability(prob);
  }

  /// Evaluates survival function $S(x) = P(X > x) = e^{-\lambda x}$.
  MathResult<ScalarValue> survivalFunction(ScalarValue x) {
    final xRes = ProbabilityNumericHelper.toDouble(
      x,
      functionName: 'ExponentialDistribution.survivalFunction',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    if (xVal <= 0.0) {
      return MathSuccess(IntegerValue.one);
    }

    final exponent = -_lambda * xVal;
    if (exponent < -744.0) {
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    final s = math.exp(exponent);
    if (s == 0.0) {
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    return ProbabilityNumericHelper.clampProbability(s);
  }

  @override
  MathResult<ScalarValue> inverseCdf(ScalarValue probability) {
    final pRes = ProbabilityNumericHelper.toDouble(
      probability,
      functionName: 'ExponentialDistribution.inverseCdf',
      argumentName: 'probability',
    );
    if (pRes is MathFailure<double>) return MathFailure(pRes.error);
    final p = (pRes as MathSuccess<double>).value;

    if (p < 0.0 || p > 1.0 || p.isNaN) {
      return MathFailure(InvalidProbabilityError(value: p));
    }

    // Endpoint behavior: Q(0) = 0, Q(1) = +infinity
    if (p == 0.0) return MathSuccess(IntegerValue.zero);
    if (p == 1.0) {
      return const MathFailure(
        DomainError(
          functionName: 'ExponentialDistribution.inverseCdf',
          argument: 'probability',
          message: 'Inverse CDF is unbounded at p = 1 (+infinity).',
        ),
      );
    }

    // Q(p) = -ln(1 - p) / lambda = -log1p(-p) / lambda
    final quant = -_log1p(-p) / _lambda;

    return MathSuccess(
      DecimalValue.parse(quant.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> sampleOne(RandomSource source) {
    // Inverse transform: X = -ln(U) / lambda with U in (0, 1)
    final uRes = OpenIntervalSamplingHelper.nextOpenDouble(source);
    if (uRes is MathFailure<double>) return MathFailure(uRes.error);
    final u = (uRes as MathSuccess<double>).value;

    final x = -math.log(u) / _lambda;
    return MathSuccess(
      DecimalValue.parse(x.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
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
