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
import 'package:nexa_math/mathematical_core/statistics/models/dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/percentile_result.dart';

/// Quantile, quartile, and percentile calculator implementing Hyndman-Fan Type 7 linear interpolation.
///
/// Mathematical Formulation:
/// Given sorted sample $x_{(1)} \le x_{(2)} \le \dots \le x_{(N)}$:
/// Normalized quantile fraction: $q = \frac{p}{100}$ for $p \in [0, 100]$.
/// Rank index: $h = (N - 1) q + 1$.
/// Let $k = \lfloor h \rfloor$, $f = h - k \in [0, 1)$.
/// If $k = N$ (i.e. $p = 100$): $P_{100} = x_{(N)}$.
/// Otherwise: $P_p = (1 - f) x_{(k)} + f x_{(k+1)}$.
///
/// Exactness Contract:
/// Exact rational path is used if and only if both the dataset and the percentile parameter $p$
/// are exact representations.
final class QuantileCalculator {
  final PrecisionContext context;

  const QuantileCalculator({this.context = PrecisionContext.standard});

  /// Computes the percentile $P_p$ for $p \in [0, 100]$ using Hyndman-Fan Type 7 linear interpolation.
  MathResult<PercentileResult> percentile(
    Dataset dataset,
    ScalarValue percentile,
  ) {
    final validation = dataset.validateMinElements<PercentileResult>(
      1,
      operation: 'percentile',
    );
    if (validation != null) return validation;

    // Validate domain: 0 <= p <= 100
    final pDbl = _scalarToDouble(percentile);
    if (pDbl < 0.0 || pDbl > 100.0) {
      return const MathFailure(
        DomainError(
          functionName: 'percentile',
          argument: 'p',
          message: 'Percentile must be between 0 and 100 inclusive.',
        ),
      );
    }

    final n = dataset.length;
    final sorted = _sortObservations(dataset.values);

    if (n == 1) {
      final meta = CalculationMetadata(
        isExact: dataset.isExact && _isExactScalar(percentile),
      );
      return MathSuccess(
        PercentileResult(
          percentile: percentile,
          value: sorted.first,
          rank: IntegerValue.one,
          metadata: meta,
        ),
        metadata: meta,
      );
    }

    final isExactCalc = dataset.isExact && _isExactScalar(percentile);

    if (isExactCalc) {
      return _calculateExactType7(sorted, percentile, n);
    } else {
      return _calculateApproxType7(sorted, percentile, n);
    }
  }

  /// Convenience overload taking platform double or num percentile.
  MathResult<PercentileResult> percentileNum(Dataset dataset, num p) {
    ScalarValue pScalar;
    if (p is int) {
      pScalar = IntegerValue.fromInt(p);
    } else {
      pScalar = DecimalValue.parse(p.toString(), isExact: false);
    }
    return percentile(dataset, pScalar);
  }

  /// Computes five-number summary quartiles ($Q_0, Q_1, Q_2, Q_3, Q_4$) and $\text{IQR} = Q_3 - Q_1$.
  MathResult<QuartileResult> quartiles(Dataset dataset) {
    final validation = dataset.validateMinElements<QuartileResult>(
      1,
      operation: 'quartiles',
    );
    if (validation != null) return validation;

    final q0Res = percentile(dataset, IntegerValue.zero);
    final q1Res = percentile(dataset, IntegerValue(BigInt.from(25)));
    final q2Res = percentile(dataset, IntegerValue(BigInt.from(50)));
    final q3Res = percentile(dataset, IntegerValue(BigInt.from(75)));
    final q4Res = percentile(dataset, IntegerValue(BigInt.from(100)));

    if (q0Res.isFailure) return MathFailure(q0Res.errorOrNull!);
    if (q1Res.isFailure) return MathFailure(q1Res.errorOrNull!);
    if (q2Res.isFailure) return MathFailure(q2Res.errorOrNull!);
    if (q3Res.isFailure) return MathFailure(q3Res.errorOrNull!);
    if (q4Res.isFailure) return MathFailure(q4Res.errorOrNull!);

    final v0 = q0Res.valueOrNull!.value;
    final v1 = q1Res.valueOrNull!.value;
    final v2 = q2Res.valueOrNull!.value;
    final v3 = q3Res.valueOrNull!.value;
    final v4 = q4Res.valueOrNull!.value;

    ScalarValue iqrVal;
    if (dataset.isExact) {
      final f1 = _toExactFraction(v1);
      final f3 = _toExactFraction(v3);
      final diff = FractionOperations.subtract(f3, f1).valueOrNull!;
      iqrVal = _canonicalizeScalar(diff);
    } else {
      final d1 = _toDecimal(v1);
      final d3 = _toDecimal(v3);
      iqrVal = DecimalOperations.subtract(d3, d1).valueOrNull!;
    }

    return MathSuccess(
      QuartileResult(
        q0: v0,
        q1: v1,
        q2: v2,
        q3: v3,
        q4: v4,
        iqr: iqrVal,
        metadata: CalculationMetadata(isExact: dataset.isExact),
      ),
    );
  }

  // --- Exact Rational Implementation ---

  MathResult<PercentileResult> _calculateExactType7(
    List<ScalarValue> sorted,
    ScalarValue pScalar,
    int n,
  ) {
    // q = p / 100 as exact FractionValue
    final pFrac = _toExactFraction(pScalar);
    final qFrac = FractionOperations.divide(
      pFrac,
      FractionValue.fromInteger(IntegerValue(BigInt.from(100))),
    ).valueOrNull!;

    // h = (N - 1) * q + 1
    final nMinus1 = FractionValue.fromInteger(IntegerValue(BigInt.from(n - 1)));
    final mult = FractionOperations.multiply(nMinus1, qFrac).valueOrNull!;
    final hFrac = FractionOperations.add(mult, FractionValue.one).valueOrNull!;

    // k = floor(h)
    final kBigInt = hFrac.numerator ~/ hFrac.denominator;
    final k = kBigInt.toInt(); // 1-based index: 1 <= k <= N

    // f = h - k
    final kFrac = FractionValue.fromInteger(IntegerValue(kBigInt));
    final fFrac = FractionOperations.subtract(hFrac, kFrac).valueOrNull!;

    ScalarValue pVal;
    if (k >= n) {
      // p = 100 -> P_100 = x_(N)
      pVal = sorted[n - 1];
    } else if (fFrac.isZero) {
      // Exactly at index k (1-based index k corresponds to zero-based k - 1)
      pVal = sorted[k - 1];
    } else {
      // P_p = (1 - f) * x_k + f * x_{k+1}
      final xK = _toExactFraction(sorted[k - 1]);
      final xKp1 = _toExactFraction(sorted[k]);

      final oneMinusF = FractionOperations.subtract(
        FractionValue.one,
        fFrac,
      ).valueOrNull!;
      final term1 = FractionOperations.multiply(oneMinusF, xK).valueOrNull!;
      final term2 = FractionOperations.multiply(fFrac, xKp1).valueOrNull!;
      final sumF = FractionOperations.add(term1, term2).valueOrNull!;
      pVal = _canonicalizeScalar(sumF);
    }

    return MathSuccess(
      PercentileResult(
        percentile: pScalar,
        value: pVal,
        rank: _canonicalizeScalar(hFrac),
        metadata: CalculationMetadata.exact,
      ),
      metadata: CalculationMetadata.exact,
    );
  }

  // --- Approximate Decimal Implementation ---

  MathResult<PercentileResult> _calculateApproxType7(
    List<ScalarValue> sorted,
    ScalarValue pScalar,
    int n,
  ) {
    final pDec = _toDecimal(pScalar);
    final hundredDec = DecimalValue.fromInt(100);
    final qDec = DecimalOperations.divide(
      pDec,
      hundredDec,
      context: context,
    ).valueOrNull!;

    // h = (N - 1) * q + 1
    final nMinus1Dec = DecimalValue.fromInt(n - 1);
    final mult = DecimalOperations.multiply(nMinus1Dec, qDec).valueOrNull!;
    final hDec = DecimalOperations.add(mult, DecimalValue.one).valueOrNull!;

    final hDbl = hDec.toDouble();
    final k = hDbl.floor(); // 1 <= k <= N
    final fDbl = hDbl - k;

    DecimalValue pVal;
    if (k >= n) {
      pVal = _toDecimal(sorted[n - 1]);
    } else if (fDbl.abs() < 1e-15) {
      pVal = _toDecimal(sorted[k - 1]);
    } else {
      final xK = _toDecimal(sorted[k - 1]);
      final xKp1 = _toDecimal(sorted[k]);
      final fDec = DecimalValue.parse(fDbl.toString(), isExact: false);
      final oneMinusF = DecimalOperations.subtract(
        DecimalValue.one,
        fDec,
      ).valueOrNull!;

      final term1 = DecimalOperations.multiply(oneMinusF, xK).valueOrNull!;
      final term2 = DecimalOperations.multiply(fDec, xKp1).valueOrNull!;
      pVal = DecimalOperations.add(term1, term2).valueOrNull!;
    }

    return MathSuccess(
      PercentileResult(
        percentile: pScalar,
        value: pVal,
        rank: hDec,
        metadata: CalculationMetadata(
          isExact: false,
          approximation: ApproximationMetadata(
            method: 'hyndmanFanType7Interpolation',
            precision: context.precisionDigits,
            converged: true,
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  static bool _isExactScalar(ScalarValue v) {
    if (v is IntegerValue) return true;
    if (v is FractionValue) return true;
    if (v is DecimalValue) return v.isExact;
    return false;
  }

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
    if (f.isInteger) return IntegerValue(f.numerator);
    return f;
  }

  static int _compareScalars(ScalarValue a, ScalarValue b) {
    if (a is IntegerValue && b is IntegerValue) return a.compareTo(b);
    final fa = _toExactFractionOrNull(a);
    final fb = _toExactFractionOrNull(b);
    if (fa != null && fb != null) return fa.compareTo(fb);
    return _toDecimal(a).compareTo(_toDecimal(b));
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
