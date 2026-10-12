import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/decimal_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/fraction_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/statistics/descriptive/descriptive_calculator.dart';
import 'package:nexa_math/mathematical_core/statistics/models/correlation_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/paired_dataset.dart';

/// Bivariate statistics calculator.
///
/// Implements population and sample covariance, Pearson correlation with bounded clamping
/// ($\epsilon_{\text{clamp}} = 10^{-15}$), and catastrophic round-off error rejection.
final class BivariateCalculator {
  final PrecisionContext context;
  final DescriptiveCalculator descriptiveCalculator;

  const BivariateCalculator({this.context = PrecisionContext.standard})
    : descriptiveCalculator = const DescriptiveCalculator();

  /// Computes population covariance:
  /// $\operatorname{Cov}_{\text{pop}}(X, Y) = \frac{1}{N}\sum_{i=1}^N (x_i - \bar{x})(y_i - \bar{y})$.
  ///
  /// Contract:
  /// - $N = 0$: MathFailure(InvalidArgumentError)
  /// - $N = 1$: Population covariance for singleton paired dataset is well-defined and equals 0.
  MathResult<ScalarValue> populationCovariance(PairedDataset dataset) {
    final validation = dataset.validateMinPairs<ScalarValue>(
      1,
      operation: 'populationCovariance',
    );
    if (validation != null) return validation;

    final n = dataset.length;
    if (n == 1) {
      return MathSuccess(
        IntegerValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    return _computeCovariance(dataset, divisor: n);
  }

  /// Computes sample covariance:
  /// $\operatorname{Cov}_{\text{sample}}(X, Y) = \frac{1}{N - 1}\sum_{i=1}^N (x_i - \bar{x})(y_i - \bar{y})$.
  ///
  /// Requires $N \ge 2$. Returns InvalidArgumentError for $N < 2$.
  MathResult<ScalarValue> sampleCovariance(PairedDataset dataset) {
    final validation = dataset.validateMinPairs<ScalarValue>(
      2,
      operation: 'sampleCovariance',
    );
    if (validation != null) return validation;

    final n = dataset.length;
    return _computeCovariance(dataset, divisor: n - 1);
  }

  /// Computes Pearson correlation coefficient $r$:
  /// $r = \frac{\sum (x_i - \bar{x})(y_i - \bar{y})}{\sqrt{\sum (x_i - \bar{x})^2}\sqrt{\sum (y_i - \bar{y})^2}}$.
  ///
  /// Contract:
  /// - Requires $N \ge 2$.
  /// - If variance of $X$ or $Y$ is zero, returns `MathFailure(DomainError)`.
  /// - Bounded clamping: If $1.0 < r \le 1.0 + 10^{-15}$, clamps to $1.0$.
  ///   If $-1.0 - 10^{-15} \le r < -1.0$, clamps to $-1.0$.
  /// - If $|r| > 1.0 + 10^{-15}$, returns `MathFailure(PrecisionLossError)`.
  MathResult<DecimalValue> pearsonCorrelation(PairedDataset dataset) {
    final validation = dataset.validateMinPairs<DecimalValue>(
      2,
      operation: 'pearsonCorrelation',
    );
    if (validation != null) return validation;

    final meanXRes = descriptiveCalculator.mean(dataset.x);
    final meanYRes = descriptiveCalculator.mean(dataset.y);
    if (meanXRes.isFailure) return MathFailure(meanXRes.errorOrNull!);
    if (meanYRes.isFailure) return MathFailure(meanYRes.errorOrNull!);

    final meanX = _scalarToDouble(meanXRes.valueOrNull!);
    final meanY = _scalarToDouble(meanYRes.valueOrNull!);

    double sumSqX = 0.0;
    double sumSqY = 0.0;
    double sumXY = 0.0;

    for (var i = 0; i < dataset.length; i++) {
      final xi = _scalarToDouble(dataset.x[i]) - meanX;
      final yi = _scalarToDouble(dataset.y[i]) - meanY;
      sumSqX += xi * xi;
      sumSqY += yi * yi;
      sumXY += xi * yi;
    }

    final zeroTol = context.zeroTolerance;
    if (sumSqX <= zeroTol || sumSqY <= zeroTol) {
      return const MathFailure(
        DomainError(
          functionName: 'pearsonCorrelation',
          message: 'Pearson correlation is undefined when variance of X or Y is zero.',
        ),
      );
    }

    final denom = math.sqrt(sumSqX * sumSqY);
    if (denom <= zeroTol) {
      return const MathFailure(
        DomainError(
          functionName: 'pearsonCorrelation',
          message: 'Pearson correlation denominator is zero.',
        ),
      );
    }

    var r = sumXY / denom;

    if (r.isNaN || r.isInfinite) {
      return const MathFailure(
        PrecisionLossError(
          message: 'Correlation coefficient could not be computed due to numerical overflow or indeterminate intermediate value.',
        ),
      );
    }

    // Check bounded clamping rule with zero tolerance
    final clampTol = context.zeroTolerance; // 1e-15
    if (r > 1.0) {
      if (r <= 1.0 + clampTol) {
        r = 1.0;
      } else {
        return const MathFailure(
          PrecisionLossError(
            message: 'Correlation coefficient exceeded valid mathematical bounds due to severe numerical error.',
          ),
        );
      }
    } else if (r < -1.0) {
      if (r >= -1.0 - clampTol) {
        r = -1.0;
      } else {
        return const MathFailure(
          PrecisionLossError(
            message: 'Correlation coefficient exceeded valid mathematical bounds due to severe numerical error.',
          ),
        );
      }
    }

    return MathSuccess(
      DecimalValue.parse(r.toString(), isExact: false),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'pearsonCorrelation',
          precision: context.precisionDigits,
          converged: true,
        ),
      ),
    );
  }

  /// Calculates complete correlation analysis including covariances and Pearson $r$.
  MathResult<CorrelationResult> calculateCorrelation(PairedDataset dataset) {
    final validation = dataset.validateMinPairs<CorrelationResult>(
      2,
      operation: 'calculateCorrelation',
    );
    if (validation != null) return validation;

    final rRes = pearsonCorrelation(dataset);
    if (rRes.isFailure) return MathFailure(rRes.errorOrNull!);

    final popCovRes = populationCovariance(dataset);
    final smpCovRes = sampleCovariance(dataset);

    if (popCovRes.isFailure) return MathFailure(popCovRes.errorOrNull!);
    if (smpCovRes.isFailure) return MathFailure(smpCovRes.errorOrNull!);

    return MathSuccess(
      CorrelationResult(
        coefficient: rRes.valueOrNull!,
        populationCovariance: popCovRes.valueOrNull!,
        sampleCovariance: smpCovRes.valueOrNull,
        metadata: rRes.metadata,
      ),
    );
  }

  // --- Internal Covariance Implementation ---

  MathResult<ScalarValue> _computeCovariance(
    PairedDataset dataset, {
    required int divisor,
  }) {
    final meanXRes = descriptiveCalculator.mean(dataset.x);
    final meanYRes = descriptiveCalculator.mean(dataset.y);
    if (meanXRes.isFailure) return meanXRes;
    if (meanYRes.isFailure) return meanYRes;

    final n = dataset.length;

    if (dataset.isExact) {
      final meanX = _toExactFraction(meanXRes.valueOrNull!);
      final meanY = _toExactFraction(meanYRes.valueOrNull!);

      FractionValue sumProd = FractionValue.zero;
      for (var i = 0; i < n; i++) {
        final xi = _toExactFraction(dataset.x[i]);
        final yi = _toExactFraction(dataset.y[i]);

        final dx = FractionOperations.subtract(xi, meanX).valueOrNull!;
        final dy = FractionOperations.subtract(yi, meanY).valueOrNull!;
        final prod = FractionOperations.multiply(dx, dy).valueOrNull!;
        sumProd = FractionOperations.add(sumProd, prod).valueOrNull!;
      }

      final covFrac = FractionValue(
        sumProd.numerator,
        sumProd.denominator * BigInt.from(divisor),
      );
      return MathSuccess(
        _canonicalizeScalar(covFrac),
        metadata: CalculationMetadata.exact,
      );
    } else {
      final meanX = _toDecimal(meanXRes.valueOrNull!);
      final meanY = _toDecimal(meanYRes.valueOrNull!);

      DecimalValue sumProd = DecimalValue.zero;
      for (var i = 0; i < n; i++) {
        final xi = _toDecimal(dataset.x[i]);
        final yi = _toDecimal(dataset.y[i]);

        final dx = DecimalOperations.subtract(xi, meanX).valueOrNull!;
        final dy = DecimalOperations.subtract(yi, meanY).valueOrNull!;
        final prod = DecimalOperations.multiply(dx, dy).valueOrNull!;
        sumProd = DecimalOperations.add(sumProd, prod).valueOrNull!;
      }

      final divRes = DecimalOperations.divide(
        sumProd,
        DecimalValue.fromInt(divisor),
        context: context,
      );
      if (divRes.isFailure) return divRes;

      return MathSuccess(
        divRes.valueOrNull!,
        metadata: CalculationMetadata(
          isExact: false,
          approximation: ApproximationMetadata(
            method: 'decimalCovariance',
            precision: context.precisionDigits,
            converged: true,
          ),
        ),
      );
    }
  }

  // --- Helpers ---

  static double _scalarToDouble(ScalarValue v) {
    if (v is IntegerValue) {
      return v.value.toDouble();
    }
    if (v is FractionValue) {
      return v.numerator.toDouble() / v.denominator.toDouble();
    }
    if (v is DecimalValue) {
      return v.toDouble();
    }
    throw UnsupportedError('Unsupported ScalarValue type: ${v.runtimeType}');
  }

  static FractionValue _toExactFraction(ScalarValue v) {
    if (v is IntegerValue) {
      return FractionValue.fromInteger(v);
    }
    if (v is FractionValue) {
      return v;
    }
    if (v is DecimalValue) {
      return v.toFraction();
    }
    throw UnsupportedError('Unsupported ScalarValue type: ${v.runtimeType}');
  }

  static DecimalValue _toDecimal(ScalarValue v) {
    if (v is DecimalValue) {
      return v;
    }
    if (v is IntegerValue) {
      return DecimalValue.fromInteger(v);
    }
    if (v is FractionValue) {
      final div = DecimalOperations.divide(
        DecimalValue.fromInteger(IntegerValue(v.numerator)),
        DecimalValue.fromInteger(IntegerValue(v.denominator)),
      );
      return div.valueOrNull ??
          DecimalValue.parse(
            (v.numerator.toDouble() / v.denominator.toDouble()).toString(),
            isExact: false,
          );
    }
    throw UnsupportedError('Unsupported ScalarValue type: ${v.runtimeType}');
  }

  static ScalarValue _canonicalizeScalar(FractionValue f) {
    if (f.isInteger) return IntegerValue(f.numerator);
    return f;
  }
}
