import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Pure, exact integer arithmetic operations for NexaMath.
///
/// All integer operations return exact [MathResult]s and guarantee
/// arbitrary-precision safety without 64-bit integer overflow.
final class IntegerOperations {
  const IntegerOperations();

  /// Adds two [IntegerValue]s: `a + b`.
  static MathResult<IntegerValue> add(IntegerValue a, IntegerValue b) {
    return MathSuccess(
      IntegerValue(a.value + b.value),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Subtracts two [IntegerValue]s: `a - b`.
  static MathResult<IntegerValue> subtract(IntegerValue a, IntegerValue b) {
    return MathSuccess(
      IntegerValue(a.value - b.value),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Multiplies two [IntegerValue]s: `a * b`.
  static MathResult<IntegerValue> multiply(IntegerValue a, IntegerValue b) {
    return MathSuccess(
      IntegerValue(a.value * b.value),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Exact division of two [IntegerValue]s yielding a [FractionValue] or [IntegerValue]: `a / b`.
  static MathResult<FractionValue> divide(IntegerValue a, IntegerValue b) {
    if (b.isZero) {
      return const MathFailure(DivisionByZeroError());
    }
    return MathSuccess(
      FractionValue(a.value, b.value),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Truncating integer quotient: `a ~/ b`.
  static MathResult<IntegerValue> quotient(IntegerValue a, IntegerValue b) {
    if (b.isZero) {
      return const MathFailure(DivisionByZeroError());
    }
    return MathSuccess(
      IntegerValue(a.value ~/ b.value),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Integer modulo remainder: `a % b`.
  static MathResult<IntegerValue> modulo(IntegerValue a, IntegerValue b) {
    if (b.isZero) {
      return const MathFailure(DivisionByZeroError());
    }
    return MathSuccess(
      IntegerValue(a.value % b.value),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Power operation: `base ^ exponent`.
  /// If exponent is negative, returns a [FractionValue].
  static MathResult<FractionValue> power(
    IntegerValue base,
    IntegerValue exponent,
  ) {
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
        FractionValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    if (exponent.isZero) {
      return MathSuccess(
        FractionValue.one,
        metadata: CalculationMetadata.exact,
      );
    }

    if (exponent.isPositive) {
      // Dart BigInt.pow requires an int exponent. Validate bound.
      if (exponent.value > BigInt.from(100000)) {
        return const MathFailure(
          OverflowError(
            message: 'Exponent is too large for integer power computation.',
          ),
        );
      }
      final powVal = base.value.pow(exponent.value.toInt());
      return MathSuccess(
        FractionValue(powVal, BigInt.one),
        metadata: CalculationMetadata.exact,
      );
    } else {
      // Exponent is negative: b^(-e) = 1 / (b^e)
      final absExp = (-exponent.value).toInt();
      if (absExp > 100000) {
        return const MathFailure(
          OverflowError(
            message: 'Exponent magnitude is too large for integer power computation.',
          ),
        );
      }
      final powVal = base.value.pow(absExp);
      return MathSuccess(
        FractionValue(BigInt.one, powVal),
        metadata: CalculationMetadata.exact,
      );
    }
  }

  /// Negates an [IntegerValue]: `-a`.
  static MathResult<IntegerValue> negate(IntegerValue a) {
    return MathSuccess(-a, metadata: CalculationMetadata.exact);
  }

  /// Absolute value of an [IntegerValue]: `|a|`.
  static MathResult<IntegerValue> absolute(IntegerValue a) {
    return MathSuccess(a.abs(), metadata: CalculationMetadata.exact);
  }
}
