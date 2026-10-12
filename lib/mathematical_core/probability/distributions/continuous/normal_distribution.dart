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
import 'package:nexa_math/mathematical_core/probability/special_functions/error_function.dart';

/// Implementation of the continuous Normal (Gaussian) distribution $\mathcal{N}(\mu, \sigma^2)$.
///
/// Parameters:
/// - $\mu \in \mathbb{R}$: Location parameter (mean).
/// - $\sigma > 0$: Scale parameter (standard deviation). $\sigma \le 0$ is rejected.
final class NormalDistribution extends ContinuousDistribution {
  /// Mean location parameter $\mu$.
  final ScalarValue meanParameter;

  /// Standard deviation scale parameter $\sigma > 0$.
  final ScalarValue standardDeviationParameter;

  final double _mu;
  final double _sigma;

  static const double _invSqrt2Pi =
      0.39894228040143267793994605993438; // 1 / sqrt(2*pi)
  static const double _sqrt2 = 1.4142135623730950488016887242097;

  NormalDistribution._({
    required this.meanParameter,
    required this.standardDeviationParameter,
    required this._mu,
    required this._sigma,
  });

  /// Factory constructor validating parameters according to Revision 6.
  static MathResult<NormalDistribution> create({
    ScalarValue? mean,
    ScalarValue? standardDeviation,
  }) {
    final effectiveMean = mean ?? IntegerValue.zero;
    final effectiveStdDev = standardDeviation ?? IntegerValue.one;

    final muRes = ProbabilityNumericHelper.toDouble(
      effectiveMean,
      functionName: 'NormalDistribution',
      argumentName: 'mean',
    );
    if (muRes is MathFailure<double>) return MathFailure(muRes.error);
    final mu = (muRes as MathSuccess<double>).value;

    final sigmaRes = ProbabilityNumericHelper.toDouble(
      effectiveStdDev,
      functionName: 'NormalDistribution',
      argumentName: 'standardDeviation',
    );
    if (sigmaRes is MathFailure<double>) return MathFailure(sigmaRes.error);
    final sigma = (sigmaRes as MathSuccess<double>).value;

    if (sigma.isNaN || sigma <= 0.0 || sigma.isInfinite) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'standardDeviation',
          reason:
              'Standard deviation sigma must be strictly positive (sigma > 0).',
        ),
      );
    }
    if (mu.isNaN || mu.isInfinite) {
      return const MathFailure(
        InvalidDistributionParameterError(
          parameterName: 'mean',
          reason: 'Mean mu must be finite.',
        ),
      );
    }

    return MathSuccess(
      NormalDistribution._(
        meanParameter: effectiveMean,
        standardDeviationParameter: effectiveStdDev,
        mu: mu,
        sigma: sigma,
      ),
    );
  }

  /// Convenience standard normal distribution $\mathcal{N}(0, 1)$.
  static NormalDistribution standard() => NormalDistribution._(
    meanParameter: IntegerValue.zero,
    standardDeviationParameter: IntegerValue.one,
    mu: 0.0,
    sigma: 1.0,
  );

  @override
  String get name => 'NormalDistribution';

  @override
  MathResult<ScalarValue> get mean => MathSuccess(meanParameter);

  @override
  MathResult<ScalarValue> get variance {
    if (standardDeviationParameter is IntegerValue) {
      final v = (standardDeviationParameter as IntegerValue).value;
      return MathSuccess(IntegerValue(v * v));
    }
    if (standardDeviationParameter is FractionValue) {
      final f = standardDeviationParameter as FractionValue;
      return FractionOperations.multiply(f, f);
    }
    return MathSuccess(
      DecimalValue.parse((_sigma * _sigma).toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> get standardDeviation =>
      MathSuccess(standardDeviationParameter);

  @override
  MathResult<ScalarValue> pdf(ScalarValue x) {
    final xRes = ProbabilityNumericHelper.toDouble(
      x,
      functionName: 'NormalDistribution.pdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    final z = (xVal - _mu) / _sigma;
    final exponent = -0.5 * z * z;

    // Numerical underflow in extreme Gaussian tails
    if (exponent < -744.0) {
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    final density = (_invSqrt2Pi / _sigma) * math.exp(exponent);
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
      functionName: 'NormalDistribution.cdf',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    final z = (xVal - _mu) / _sigma;

    // Use erfc directly to avoid cancellation:
    // Phi(z) = 0.5 * erfc(-z / sqrt(2))
    final prob = 0.5 * ErrorFunction.erfc(-z / _sqrt2);

    if (prob == 0.0 && z > -38.0) {
      // Underflow occurred in intermediate tail
      return ProbabilityNumericHelper.handleTailUnderflow();
    }
    if (prob == 0.0 && z <= -38.0) {
      // Far deep extreme tail underflow
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    return ProbabilityNumericHelper.clampProbability(prob);
  }

  /// Calculates complementary cumulative probability $P(X > x) = 1 - \Phi(z)$.
  MathResult<ScalarValue> survivalFunction(ScalarValue x) {
    final xRes = ProbabilityNumericHelper.toDouble(
      x,
      functionName: 'NormalDistribution.survivalFunction',
      argumentName: 'x',
    );
    if (xRes is MathFailure<double>) return MathFailure(xRes.error);
    final xVal = (xRes as MathSuccess<double>).value;

    final z = (xVal - _mu) / _sigma;
    // 1 - Phi(z) = 0.5 * erfc(z / sqrt(2))
    final prob = 0.5 * ErrorFunction.erfc(z / _sqrt2);

    if (prob == 0.0) {
      return ProbabilityNumericHelper.handleTailUnderflow();
    }

    return ProbabilityNumericHelper.clampProbability(prob);
  }

  @override
  MathResult<ScalarValue> inverseCdf(ScalarValue probability) {
    final pRes = ProbabilityNumericHelper.toDouble(
      probability,
      functionName: 'NormalDistribution.inverseCdf',
      argumentName: 'probability',
    );
    if (pRes is MathFailure<double>) return MathFailure(pRes.error);
    final p = (pRes as MathSuccess<double>).value;

    if (p < 0.0 || p > 1.0 || p.isNaN) {
      return MathFailure(InvalidProbabilityError(value: p));
    }

    // Endpoint behavior:
    // Q(0) = -infinity, Q(1) = +infinity
    if (p == 0.0) {
      return const MathFailure(
        DomainError(
          functionName: 'NormalDistribution.inverseCdf',
          argument: 'probability',
          message: 'Inverse CDF is unbounded at p = 0 (-infinity).',
        ),
      );
    }
    if (p == 1.0) {
      return const MathFailure(
        DomainError(
          functionName: 'NormalDistribution.inverseCdf',
          argument: 'probability',
          message: 'Inverse CDF is unbounded at p = 1 (+infinity).',
        ),
      );
    }

    // Q(p) = mu + sigma * sqrt(2) * erfinv(2p - 1)
    final w = ErrorFunction.erfinv(2.0 * p - 1.0);
    if (w.isNaN) {
      return const MathFailure(
        ConvergenceFailureError(message: 'Error computing normal quantile.'),
      );
    }

    final quant = _mu + _sigma * _sqrt2 * w;
    return MathSuccess(
      DecimalValue.parse(quant.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  @override
  MathResult<ScalarValue> sampleOne(RandomSource source) {
    // Generate standard normal variate using Box-Muller transform
    // Drawing u1 strictly in (0, 1)
    final u1Res = OpenIntervalSamplingHelper.nextOpenDouble(source);
    if (u1Res is MathFailure<double>) return MathFailure(u1Res.error);
    final u1 = (u1Res as MathSuccess<double>).value;

    final u2 = source.nextDouble(); // [0, 1) is safe for cosine
    final r = math.sqrt(-2.0 * math.log(u1));
    final theta = 2.0 * math.pi * u2;
    final z = r * math.cos(theta);

    final x = _mu + _sigma * z;
    return MathSuccess(
      DecimalValue.parse(x.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }
}
