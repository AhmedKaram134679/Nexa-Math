import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/decimal_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/fraction_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/statistics/models/dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/descriptive_statistics.dart';

/// Univariate descriptive statistics calculator.
///
/// Implements exact rational arithmetic when inputs are exact, stable two-pass variance for
/// approximate values, deterministic mode semantics (NexaMath Mode Convention), and exact
/// rational square-root standard deviations.
final class DescriptiveCalculator {
  final PrecisionContext context;

  const DescriptiveCalculator({this.context = PrecisionContext.standard});

  /// Computes the observation count $N = |\mathcal{D}|$.
  ///
  /// Always returns exact [IntegerValue]. Valid for $N \ge 0$.
  IntegerValue count(Dataset dataset) => IntegerValue.fromInt(dataset.length);

  /// Computes the sum of all observations: $S = \sum_{i=1}^N x_i$.
  ///
  /// For $N = 0$, returns exact 0. Exact if all elements are exact.
  MathResult<ScalarValue> sum(Dataset dataset) {
    if (dataset.isEmpty) {
      return MathSuccess(
        IntegerValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    if (dataset.isExact) {
      FractionValue total = FractionValue.zero;
      for (final v in dataset.values) {
        final f = _toExactFraction(v);
        total = FractionOperations.add(total, f).valueOrNull!;
      }
      return MathSuccess(
        _canonicalizeScalar(total),
        metadata: CalculationMetadata.exact,
      );
    } else {
      DecimalValue total = DecimalValue.zero;
      for (final v in dataset.values) {
        final d = _toDecimal(v);
        total = DecimalOperations.add(total, d).valueOrNull!;
      }
      return MathSuccess(
        total,
        metadata: CalculationMetadata(
          isExact: false,
          approximation: ApproximationMetadata(
            method: 'decimalSum',
            precision: context.precisionDigits,
            converged: true,
          ),
        ),
      );
    }
  }

  /// Computes the arithmetic mean: $\bar{x} = \frac{1}{N}\sum_{i=1}^N x_i$.
  ///
  /// Requires $N \ge 1$. Exact rational if all inputs exact; approximate DecimalValue otherwise.
  MathResult<ScalarValue> mean(Dataset dataset) {
    final validation = dataset.validateMinElements<ScalarValue>(
      1,
      operation: 'mean',
    );
    if (validation != null) return validation;

    final sumRes = sum(dataset);
    if (sumRes.isFailure) return sumRes;

    final n = dataset.length;
    final total = sumRes.valueOrNull!;

    if (dataset.isExact) {
      final f = _toExactFraction(total);
      final meanFrac = FractionValue(
        f.numerator,
        f.denominator * BigInt.from(n),
      );
      return MathSuccess(
        _canonicalizeScalar(meanFrac),
        metadata: CalculationMetadata.exact,
      );
    } else {
      final d = _toDecimal(total);
      final divRes = DecimalOperations.divide(
        d,
        DecimalValue.fromInt(n),
        context: context,
      );
      return divRes;
    }
  }

  /// Computes the sample median.
  ///
  /// Requires $N \ge 1$. Sorts a defensive local copy.
  MathResult<ScalarValue> median(Dataset dataset) {
    final validation = dataset.validateMinElements<ScalarValue>(
      1,
      operation: 'median',
    );
    if (validation != null) return validation;

    final sorted = _sortObservations(dataset.values);
    final n = sorted.length;

    if (n % 2 == 1) {
      // Odd: middle element
      return MathSuccess(
        sorted[n ~/ 2],
        metadata: CalculationMetadata(isExact: dataset.isExact),
      );
    } else {
      // Even: mean of two middle elements
      final mid1 = sorted[(n ~/ 2) - 1];
      final mid2 = sorted[n ~/ 2];
      if (dataset.isExact) {
        final f1 = _toExactFraction(mid1);
        final f2 = _toExactFraction(mid2);
        final sumF = FractionOperations.add(f1, f2).valueOrNull!;
        final medF = FractionValue(
          sumF.numerator,
          sumF.denominator * BigInt.two,
        );
        return MathSuccess(
          _canonicalizeScalar(medF),
          metadata: CalculationMetadata.exact,
        );
      } else {
        final d1 = _toDecimal(mid1);
        final d2 = _toDecimal(mid2);
        final sumD = DecimalOperations.add(d1, d2).valueOrNull!;
        final medD = DecimalOperations.divide(
          sumD,
          DecimalValue.two,
          context: context,
        ).valueOrNull!;
        return MathSuccess(
          medD,
          metadata: CalculationMetadata(
            isExact: false,
            approximation: ApproximationMetadata(
              method: 'medianInterpolation',
              precision: context.precisionDigits,
              converged: true,
            ),
          ),
        );
      }
    }
  }

  /// Computes the statistical mode according to the NexaMath Mode Convention.
  ///
  /// Contract:
  /// - $N = 0$: MathFailure(InvalidArgumentError)
  /// - $N = 1$: `[x_1]`
  /// - $N > 1$ and $f_{max} = 1$: `[]` (no mode)
  /// - $N > 1$ and all identical ($f_{max} = N$): `[x]`
  /// - $N > 1$ and all distinct values share identical frequency $f > 1$: `[]`
  /// - Unimodal ($f_{max} > 1$): `[mode]`
  /// - Multimodal ($f_{max} > 1$): `[mode1, mode2, ...]` sorted in ascending numerical order.
  MathResult<List<ScalarValue>> mode(Dataset dataset) {
    final validation = dataset.validateMinElements<List<ScalarValue>>(
      1,
      operation: 'mode',
    );
    if (validation != null) return validation;

    final n = dataset.length;
    if (n == 1) {
      return MathSuccess([
        dataset.values.first,
      ], metadata: CalculationMetadata.exact);
    }

    // Build frequency table by grouping numerically equal scalars
    final groups = <_ScalarGroup>[];
    for (final v in dataset.values) {
      var found = false;
      for (final g in groups) {
        if (_areScalarsEqual(g.representative, v)) {
          g.count++;
          found = true;
          break;
        }
      }
      if (!found) {
        groups.add(_ScalarGroup(v, 1));
      }
    }

    var maxFreq = 0;
    for (final g in groups) {
      if (g.count > maxFreq) maxFreq = g.count;
    }

    // If max frequency is 1, all values are unique -> no mode
    if (maxFreq == 1) {
      return const MathSuccess([], metadata: CalculationMetadata.exact);
    }

    // If all distinct groups share the identical frequency maxFreq
    final allShareMaxFreq = groups.every((g) => g.count == maxFreq);
    if (allShareMaxFreq) {
      if (groups.length == 1) {
        // All observations identical e.g. [5, 5, 5, 5] -> unique mode
        return MathSuccess([
          groups.first.representative,
        ], metadata: CalculationMetadata.exact);
      } else {
        // Multiple groups tie across entire dataset e.g. [1, 1, 2, 2, 3, 3] -> no mode
        return const MathSuccess([], metadata: CalculationMetadata.exact);
      }
    }

    // Extract all groups with frequency == maxFreq
    final modeGroups = groups.where((g) => g.count == maxFreq).toList();
    final modeScalars = modeGroups.map((g) => g.representative).toList();

    // Sort modes in ascending order
    final sortedModes = _sortObservations(modeScalars);
    return MathSuccess(sortedModes, metadata: CalculationMetadata.exact);
  }

  /// Computes the minimum observed value: $\min(x_i)$.
  MathResult<ScalarValue> min(Dataset dataset) {
    final validation = dataset.validateMinElements<ScalarValue>(
      1,
      operation: 'min',
    );
    if (validation != null) return validation;

    ScalarValue minVal = dataset.values.first;
    for (var i = 1; i < dataset.length; i++) {
      if (_compareScalars(dataset.values[i], minVal) < 0) {
        minVal = dataset.values[i];
      }
    }
    return MathSuccess(
      minVal,
      metadata: CalculationMetadata(isExact: dataset.isExact),
    );
  }

  /// Computes the maximum observed value: $\max(x_i)$.
  MathResult<ScalarValue> max(Dataset dataset) {
    final validation = dataset.validateMinElements<ScalarValue>(
      1,
      operation: 'max',
    );
    if (validation != null) return validation;

    ScalarValue maxVal = dataset.values.first;
    for (var i = 1; i < dataset.length; i++) {
      if (_compareScalars(dataset.values[i], maxVal) > 0) {
        maxVal = dataset.values[i];
      }
    }
    return MathSuccess(
      maxVal,
      metadata: CalculationMetadata(isExact: dataset.isExact),
    );
  }

  /// Computes the statistical range: $\max(x_i) - \min(x_i)$.
  MathResult<ScalarValue> range(Dataset dataset) {
    final validation = dataset.validateMinElements<ScalarValue>(
      1,
      operation: 'range',
    );
    if (validation != null) return validation;

    final minRes = min(dataset);
    final maxRes = max(dataset);
    if (minRes.isFailure) return minRes;
    if (maxRes.isFailure) return maxRes;

    final minVal = minRes.valueOrNull!;
    final maxVal = maxRes.valueOrNull!;

    if (dataset.isExact) {
      final fMin = _toExactFraction(minVal);
      final fMax = _toExactFraction(maxVal);
      final diff = FractionOperations.subtract(fMax, fMin).valueOrNull!;
      return MathSuccess(
        _canonicalizeScalar(diff),
        metadata: CalculationMetadata.exact,
      );
    } else {
      final dMin = _toDecimal(minVal);
      final dMax = _toDecimal(maxVal);
      final diff = DecimalOperations.subtract(dMax, dMin).valueOrNull!;
      return MathSuccess(
        diff,
        metadata: const CalculationMetadata(isExact: false),
      );
    }
  }

  /// Computes population variance: $\sigma^2 = \frac{1}{N}\sum (x_i - \bar{x})^2$.
  ///
  /// Requires $N \ge 1$. For $N = 1$, returns 0.
  MathResult<ScalarValue> populationVariance(Dataset dataset) {
    final validation = dataset.validateMinElements<ScalarValue>(
      1,
      operation: 'populationVariance',
    );
    if (validation != null) return validation;

    final n = dataset.length;
    if (n == 1) {
      return MathSuccess(
        IntegerValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    return _computeVariance(dataset, divisor: n, isSample: false);
  }

  /// Computes sample variance: $s^2 = \frac{1}{N-1}\sum (x_i - \bar{x})^2$.
  ///
  /// Requires $N \ge 2$. Returns InvalidArgumentError for $N < 2$.
  MathResult<ScalarValue> sampleVariance(Dataset dataset) {
    final validation = dataset.validateMinElements<ScalarValue>(
      2,
      operation: 'sampleVariance',
    );
    if (validation != null) return validation;

    final n = dataset.length;
    return _computeVariance(dataset, divisor: n - 1, isSample: true);
  }

  /// Computes population standard deviation: $\sigma = \sqrt{\sigma^2}$.
  ///
  /// Returns exact rational if variance is a perfect rational square, else approximate DecimalValue.
  MathResult<ScalarValue> populationStandardDeviation(Dataset dataset) {
    final varRes = populationVariance(dataset);
    if (varRes.isFailure) return varRes;
    return _computeStandardDeviation(varRes.valueOrNull!);
  }

  /// Computes sample standard deviation: $s = \sqrt{s^2}$.
  MathResult<ScalarValue> sampleStandardDeviation(Dataset dataset) {
    final varRes = sampleVariance(dataset);
    if (varRes.isFailure) return varRes;
    return _computeStandardDeviation(varRes.valueOrNull!);
  }

  /// Aggregates all descriptive metrics into an immutable [DescriptiveStatistics] container.
  MathResult<DescriptiveStatistics> calculateAll(Dataset dataset) {
    final validation = dataset.validateMinElements<DescriptiveStatistics>(
      1,
      operation: 'calculateAll',
    );
    if (validation != null) return validation;

    final cnt = count(dataset);
    final sumVal = sum(dataset).valueOrNull!;
    final meanVal = mean(dataset).valueOrNull!;
    final medianVal = median(dataset).valueOrNull!;
    final modesVal = mode(dataset).valueOrNull!;
    final minVal = min(dataset).valueOrNull!;
    final maxVal = max(dataset).valueOrNull!;
    final rangeVal = range(dataset).valueOrNull!;
    final popVar = populationVariance(dataset).valueOrNull!;
    final popStd = populationStandardDeviation(dataset).valueOrNull!;

    ScalarValue? smpVar;
    ScalarValue? smpStd;
    if (dataset.length >= 2) {
      smpVar = sampleVariance(dataset).valueOrNull;
      smpStd = sampleStandardDeviation(dataset).valueOrNull;
    }

    return MathSuccess(
      DescriptiveStatistics(
        count: cnt,
        sum: sumVal,
        mean: meanVal,
        median: medianVal,
        modes: modesVal,
        min: minVal,
        max: maxVal,
        range: rangeVal,
        populationVariance: popVar,
        sampleVariance: smpVar,
        populationStandardDeviation: popStd,
        sampleStandardDeviation: smpStd,
        metadata: CalculationMetadata(isExact: dataset.isExact),
      ),
    );
  }

  // --- Internal Numerical Helpers ---

  MathResult<ScalarValue> _computeVariance(
    Dataset dataset, {
    required int divisor,
    required bool isSample,
  }) {
    final meanRes = mean(dataset);
    if (meanRes.isFailure) return meanRes;
    final meanVal = meanRes.valueOrNull!;

    if (dataset.isExact) {
      final meanFrac = _toExactFraction(meanVal);
      FractionValue sumSqDev = FractionValue.zero;
      for (final v in dataset.values) {
        final vf = _toExactFraction(v);
        final dev = FractionOperations.subtract(vf, meanFrac).valueOrNull!;
        final devSq = FractionOperations.multiply(dev, dev).valueOrNull!;
        sumSqDev = FractionOperations.add(sumSqDev, devSq).valueOrNull!;
      }
      final varFrac = FractionValue(
        sumSqDev.numerator,
        sumSqDev.denominator * BigInt.from(divisor),
      );
      return MathSuccess(
        _canonicalizeScalar(varFrac),
        metadata: CalculationMetadata.exact,
      );
    } else {
      // Stable two-pass variance
      final meanDec = _toDecimal(meanVal);
      DecimalValue sumSqDev = DecimalValue.zero;
      for (final v in dataset.values) {
        final vd = _toDecimal(v);
        final dev = DecimalOperations.subtract(vd, meanDec).valueOrNull!;
        final devSq = DecimalOperations.multiply(dev, dev).valueOrNull!;
        sumSqDev = DecimalOperations.add(sumSqDev, devSq).valueOrNull!;
      }
      final divRes = DecimalOperations.divide(
        sumSqDev,
        DecimalValue.fromInt(divisor),
        context: context,
      );
      if (divRes.isFailure) return divRes;
      return MathSuccess(
        divRes.valueOrNull!,
        metadata: CalculationMetadata(
          isExact: false,
          approximation: ApproximationMetadata(
            method: 'twoPassVariance',
            precision: context.precisionDigits,
            converged: true,
          ),
        ),
      );
    }
  }

  MathResult<ScalarValue> _computeStandardDeviation(ScalarValue variance) {
    if (variance is IntegerValue) {
      if (variance.isZero) {
        return MathSuccess(
          IntegerValue.zero,
          metadata: CalculationMetadata.exact,
        );
      }
      final r = _integerSquareRoot(variance.value);
      if (r != null) {
        return MathSuccess(
          IntegerValue(r),
          metadata: CalculationMetadata.exact,
        );
      }
    } else if (variance is FractionValue) {
      if (variance.isZero) {
        return MathSuccess(
          IntegerValue.zero,
          metadata: CalculationMetadata.exact,
        );
      }
      final numR = _integerSquareRoot(variance.numerator);
      final denR = _integerSquareRoot(variance.denominator);
      if (numR != null && denR != null) {
        final frac = FractionValue(numR, denR);
        return MathSuccess(
          _canonicalizeScalar(frac),
          metadata: CalculationMetadata.exact,
        );
      }
    }

    // Fallback to DecimalOperations.sqrt
    final decVar = _toDecimal(variance);
    final sqrtRes = DecimalOperations.sqrt(decVar, context: context);
    if (sqrtRes.isFailure) return sqrtRes;

    return MathSuccess(
      sqrtRes.valueOrNull!,
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'newtonRaphsonSqrt',
          precision: context.precisionDigits,
          converged: true,
        ),
      ),
    );
  }

  static BigInt? _integerSquareRoot(BigInt n) {
    if (n < BigInt.zero) return null;
    if (n == BigInt.zero) return BigInt.zero;
    if (n == BigInt.one) return BigInt.one;

    var x0 = BigInt.one << ((n.bitLength + 1) >> 1);
    while (true) {
      final x1 = (x0 + n ~/ x0) >> 1;
      if (x1 >= x0) {
        if (x0 * x0 == n) return x0;
        return null;
      }
      x0 = x1;
    }
  }

  static FractionValue _toExactFraction(ScalarValue v) {
    if (v is IntegerValue) return FractionValue.fromInteger(v);
    if (v is FractionValue) return v;
    if (v is DecimalValue) return v.toFraction();
    throw UnsupportedError('Unsupported ScalarValue type: ${v.runtimeType}');
  }

  static DecimalValue _toDecimal(ScalarValue v) {
    if (v is DecimalValue) return v;
    if (v is IntegerValue) return DecimalValue.fromInteger(v);
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
    if (f.isInteger) {
      return IntegerValue(f.numerator);
    }
    return f;
  }

  static int _compareScalars(ScalarValue a, ScalarValue b) {
    if (a is IntegerValue && b is IntegerValue) {
      return a.compareTo(b);
    }
    final fa = _toExactFractionOrNull(a);
    final fb = _toExactFractionOrNull(b);
    if (fa != null && fb != null) {
      return fa.compareTo(fb);
    }
    final da = _toDecimal(a);
    final db = _toDecimal(b);
    return da.compareTo(db);
  }

  static bool _areScalarsEqual(ScalarValue a, ScalarValue b) {
    return _compareScalars(a, b) == 0;
  }

  static FractionValue? _toExactFractionOrNull(ScalarValue v) {
    if (v is IntegerValue) return FractionValue.fromInteger(v);
    if (v is FractionValue) return v;
    if (v is DecimalValue && v.isExact) return v.toFraction();
    return null;
  }

  static List<ScalarValue> _sortObservations(List<ScalarValue> list) {
    final copy = List<ScalarValue>.from(list);
    copy.sort(_compareScalars);
    return copy;
  }
}

class _ScalarGroup {
  final ScalarValue representative;
  int count;

  _ScalarGroup(this.representative, this.count);
}
