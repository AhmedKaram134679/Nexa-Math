import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';

/// Arbitrary-precision decimal arithmetic operations for NexaMath.
///
/// Implements exact additions, subtractions, multiplications, and precision-controlled
/// divisions, roots, and powers conforming to [PrecisionContext].
final class DecimalOperations {
  const DecimalOperations();

  /// Adds two [DecimalValue]s: `a + b`. Exact result.
  static MathResult<DecimalValue> add(DecimalValue a, DecimalValue b) {
    if (a.scale == b.scale) {
      final unscaled = a.unscaledValue + b.unscaledValue;
      return MathSuccess(
        DecimalValue(
          unscaled,
          a.scale,
          isExact: a.isExact && b.isExact,
        ).normalize(),
        metadata: CalculationMetadata(isExact: a.isExact && b.isExact),
      );
    }

    final maxScale = a.scale > b.scale ? a.scale : b.scale;
    final v1 = _rescale(a.unscaledValue, maxScale - a.scale);
    final v2 = _rescale(b.unscaledValue, maxScale - b.scale);
    final unscaled = v1 + v2;

    return MathSuccess(
      DecimalValue(
        unscaled,
        maxScale,
        isExact: a.isExact && b.isExact,
      ).normalize(),
      metadata: CalculationMetadata(isExact: a.isExact && b.isExact),
    );
  }

  /// Subtracts two [DecimalValue]s: `a - b`. Exact result.
  static MathResult<DecimalValue> subtract(DecimalValue a, DecimalValue b) {
    if (a.scale == b.scale) {
      final unscaled = a.unscaledValue - b.unscaledValue;
      return MathSuccess(
        DecimalValue(
          unscaled,
          a.scale,
          isExact: a.isExact && b.isExact,
        ).normalize(),
        metadata: CalculationMetadata(isExact: a.isExact && b.isExact),
      );
    }

    final maxScale = a.scale > b.scale ? a.scale : b.scale;
    final v1 = _rescale(a.unscaledValue, maxScale - a.scale);
    final v2 = _rescale(b.unscaledValue, maxScale - b.scale);
    final unscaled = v1 - v2;

    return MathSuccess(
      DecimalValue(
        unscaled,
        maxScale,
        isExact: a.isExact && b.isExact,
      ).normalize(),
      metadata: CalculationMetadata(isExact: a.isExact && b.isExact),
    );
  }

  /// Multiplies two [DecimalValue]s: `a * b`. Exact result.
  static MathResult<DecimalValue> multiply(DecimalValue a, DecimalValue b) {
    final unscaled = a.unscaledValue * b.unscaledValue;
    final scale = a.scale + b.scale;
    final isExact = a.isExact && b.isExact;

    return MathSuccess(
      DecimalValue(unscaled, scale, isExact: isExact).normalize(),
      metadata: CalculationMetadata(isExact: isExact),
    );
  }

  /// Divides two [DecimalValue]s according to [context]: `a / b`.
  static MathResult<DecimalValue> divide(
    DecimalValue a,
    DecimalValue b, {
    PrecisionContext context = PrecisionContext.standard,
  }) {
    if (b.isZero) {
      return const MathFailure(DivisionByZeroError());
    }

    if (a.isZero) {
      return MathSuccess(
        DecimalValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    // Align scales
    final maxScale = a.scale > b.scale ? a.scale : b.scale;
    var num = _rescale(a.unscaledValue, maxScale - a.scale);
    var den = _rescale(b.unscaledValue, maxScale - b.scale);

    if (den < BigInt.zero) {
      num = -num;
      den = -den;
    }

    // Attempt exact integer division
    if (num % den == BigInt.zero) {
      final quotient = num ~/ den;
      return MathSuccess(
        DecimalValue(quotient, 0, isExact: a.isExact && b.isExact),
        metadata: CalculationMetadata(isExact: a.isExact && b.isExact),
      );
    }

    // Calculate with target precision digits
    final targetPrecision = context.precisionDigits;
    // Scale numerator up by targetPrecision + 1 (for rounding lookahead)
    final scaleUp = targetPrecision + 4;
    final scaledNum = num * BigInt.from(10).pow(scaleUp);
    final rawQuotient = scaledNum ~/ den;
    final remainder = (scaledNum % den).abs();

    final isTerminating = remainder == BigInt.zero;
    final dec = DecimalValue(
      rawQuotient,
      scaleUp,
      isExact: isTerminating,
    ).roundToPrecision(context);

    return MathSuccess(
      dec,
      metadata: CalculationMetadata(
        isExact: isTerminating && a.isExact && b.isExact,
        approximation: isTerminating
            ? null
            : ApproximationMetadata(
                precision: context.precisionDigits,
                method: 'decimalDivision',
                converged: true,
              ),
      ),
    );
  }

  /// Power operation: `base ^ exponent`.
  static MathResult<DecimalValue> power(
    DecimalValue base,
    DecimalValue exponent, {
    PrecisionContext context = PrecisionContext.standard,
  }) {
    if (base.isZero && exponent.isZero) {
      return const MathFailure(
        DomainError(
          message: '0^0 is an indeterminate form.',
          functionName: 'power',
        ),
      );
    }

    if (base.isZero) {
      if (exponent.isNegative) {
        return const MathFailure(DivisionByZeroError());
      }
      return MathSuccess(
        DecimalValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    if (exponent.isZero) {
      return MathSuccess(DecimalValue.one, metadata: CalculationMetadata.exact);
    }

    // Integer exponent
    if (exponent.scale == 0 ||
        exponent.unscaledValue % BigInt.from(10).pow(exponent.scale) ==
            BigInt.zero) {
      final normExp = exponent.normalize();
      if (normExp.scale == 0) {
        final expVal = normExp.unscaledValue;
        if (expVal > BigInt.from(100000) || expVal < -BigInt.from(100000)) {
          return const MathFailure(
            OverflowError(
              message: 'Exponent magnitude is too large for power computation.',
            ),
          );
        }

        if (expVal > BigInt.zero) {
          final intExp = expVal.toInt();
          final unscaled = base.unscaledValue.pow(intExp);
          final scale = base.scale * intExp;
          return MathSuccess(
            DecimalValue(unscaled, scale, isExact: base.isExact).normalize(),
            metadata: CalculationMetadata(isExact: base.isExact),
          );
        } else {
          // Negative integer exponent: 1 / (base ^ |exp|)
          final absExp = (-expVal).toInt();
          final unscaled = base.unscaledValue.pow(absExp);
          final scale = base.scale * absExp;
          final positivePow = DecimalValue(
            unscaled,
            scale,
            isExact: base.isExact,
          ).normalize();
          return divide(DecimalValue.one, positivePow, context: context);
        }
      }
    }

    // Fractional / general power: base must be positive for real power
    if (base.isNegative) {
      return const MathFailure(
        DomainError(
          message: 'Negative base with fractional exponent results in a complex number.',
          functionName: 'power',
        ),
      );
    }

    // Approximation using e^(y * ln(x)) via floating point conversion with precision
    final baseDbl = base.toDouble();
    final expDbl = exponent.toDouble();
    final resDbl = math.pow(baseDbl, expDbl);

    if (resDbl.isInfinite) {
      return const MathFailure(
        OverflowError(
          message: 'Power operation result overflowed finite bound.',
        ),
      );
    }
    if (resDbl.isNaN) {
      return const MathFailure(
        DomainError(
          message: 'Power calculation evaluated to NaN.',
          functionName: 'power',
        ),
      );
    }

    final dec = DecimalValue.parse(resDbl.toString(), isExact: false);
    return MathSuccess(
      dec,
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'expLnApproximation',
          converged: true,
        ),
      ),
    );
  }

  /// Square root of [a]: `sqrt(a)`.
  static MathResult<DecimalValue> sqrt(
    DecimalValue a, {
    PrecisionContext context = PrecisionContext.standard,
  }) {
    if (a.isNegative) {
      return const MathFailure(
        DomainError(
          message:
              'Cannot compute square root of negative number in real domain.',
          functionName: 'sqrt',
        ),
      );
    }

    if (a.isZero) {
      return MathSuccess(
        DecimalValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    // Newton-Raphson iteration for high-precision decimal square root.
    // Standard initial seed from float representation:
    final dbl = a.toDouble();
    DecimalValue x;
    if (dbl.isFinite && dbl > 0.0) {
      final initDbl = math.sqrt(dbl);
      x = DecimalValue.parse(initDbl.toString(), isExact: false);
    } else {
      // For extreme magnitudes that underflow or overflow IEEE-754 double (e.g. > 10^308 or < 10^-308),
      // compute initial seed based on digit count / scale: sqrt(10^(2k)) = 10^k.
      final unscaledDigits = a.unscaledValue.abs().toString().length;
      final effectivePowerOfTen = unscaledDigits - a.scale;
      final halfPower = effectivePowerOfTen ~/ 2;
      if (halfPower >= 0) {
        x = DecimalValue(BigInt.from(10).pow(halfPower), 0, isExact: false);
      } else {
        x = DecimalValue(BigInt.one, -halfPower, isExact: false);
      }
    }

    // Allocate internal guard precision (+8 digits) during iteration to eliminate intermediate rounding error:
    final guardContext = PrecisionContext(
      precisionDigits: context.precisionDigits + 8,
      roundingMode: RoundingMode.halfEven,
    );

    final iterations = context.precisionDigits > 64 ? 12 : 8;
    for (int i = 0; i < iterations; i++) {
      // x_{n+1} = 0.5 * (x_n + a / x_n)
      final divRes = divide(a, x, context: guardContext);
      if (divRes.isFailure) return divRes;
      final addRes = add(x, divRes.valueOrNull!);
      if (addRes.isFailure) return addRes;
      x = multiply(DecimalValue.half, addRes.valueOrNull!).valueOrNull!;
    }

    final rounded = x.roundToPrecision(context);
    return MathSuccess(
      rounded,
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'newtonRaphsonSqrt',
          converged: true,
        ),
      ),
    );
  }

  /// Negates a [DecimalValue]: `-a`.
  static MathResult<DecimalValue> negate(DecimalValue a) {
    return MathSuccess(-a, metadata: CalculationMetadata(isExact: a.isExact));
  }

  /// Absolute value of a [DecimalValue]: `|a|`.
  static MathResult<DecimalValue> absolute(DecimalValue a) {
    return MathSuccess(
      a.abs(),
      metadata: CalculationMetadata(isExact: a.isExact),
    );
  }

  static BigInt _rescale(BigInt val, int diff) {
    if (diff <= 0) return val;
    return val * BigInt.from(10).pow(diff);
  }
}
