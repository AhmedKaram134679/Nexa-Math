import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Enum representing the fundamental numerical scalar kinds in NexaMath.
enum NumericKind { integer, fraction, decimal, complex }

/// Canonical contract alias matching Section 15 of NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md.
typedef NumericType = NumericKind;

/// Centralized promoter defining deterministic promotion and coercion across scalar types.
///
/// Promotion follows the canonical lattice:
/// `Integer` -> `Fraction` -> `Decimal` -> `Complex`
///
/// Exactness is preserved whenever possible:
/// - `Integer + Integer` -> `Integer`
/// - `Integer + Fraction` -> `Fraction`
/// - `Fraction + Fraction` -> `Fraction`
/// - `Integer + Decimal` -> `Decimal`
/// - `Fraction + Decimal` -> `Decimal`
/// - Any scalar with `Complex` -> `Complex`
final class NumericPromoter {
  const NumericPromoter();

  /// Identifies the [NumericKind] of a [ScalarValue].
  static NumericKind kindOf(ScalarValue value) {
    return switch (value) {
      IntegerValue() => NumericKind.integer,
      FractionValue() => NumericKind.fraction,
      DecimalValue() => NumericKind.decimal,
      ComplexNumber() => NumericKind.complex,
      _ => throw UnsupportedError(
        'Unknown ScalarValue subtype: ${value.runtimeType}',
      ),
    };
  }

  /// Promotes a pair of [ScalarValue]s to their lowest common compatible [ScalarValue] representation.
  (ScalarValue, ScalarValue) promote(ScalarValue a, ScalarValue b) {
    if (a.runtimeType == b.runtimeType) {
      return (a, b);
    }

    final kindA = kindOf(a);
    final kindB = kindOf(b);

    // If either is Complex, promote both to ComplexNumber
    if (kindA == NumericKind.complex || kindB == NumericKind.complex) {
      return (toComplex(a), toComplex(b));
    }

    // If either is Decimal, promote both to DecimalValue
    if (kindA == NumericKind.decimal || kindB == NumericKind.decimal) {
      return (toDecimal(a), toDecimal(b));
    }

    // If either is Fraction, promote both to FractionValue
    if (kindA == NumericKind.fraction || kindB == NumericKind.fraction) {
      return (toFraction(a), toFraction(b));
    }

    // Both must be IntegerValue
    return (a, b);
  }

  /// Converts any real scalar to a [FractionValue].
  static FractionValue toFraction(ScalarValue value) {
    return switch (value) {
      FractionValue() => value,
      IntegerValue(:final value) => FractionValue(value, BigInt.one),
      DecimalValue() => value.toFraction(),
      ComplexNumber() => throw UnsupportedError(
        'Cannot convert ComplexNumber to FractionValue.',
      ),
      _ => throw UnsupportedError(
        'Unsupported conversion to FractionValue from ${value.runtimeType}',
      ),
    };
  }

  /// Converts any real scalar to a [DecimalValue].
  static DecimalValue toDecimal(ScalarValue value) {
    return switch (value) {
      DecimalValue() => value,
      IntegerValue(:final value) => DecimalValue(value, 0, isExact: true),
      FractionValue() =>
        value.isInteger
            ? DecimalValue(value.numerator, 0, isExact: true)
            : value.toIntegerValueOrNull() != null
            ? DecimalValue(
                value.toIntegerValueOrNull()!.value,
                0,
                isExact: true,
              )
            : _fractionToDecimal(value),
      ComplexNumber() => throw UnsupportedError(
        'Cannot convert ComplexNumber to DecimalValue.',
      ),
      _ => throw UnsupportedError(
        'Unsupported conversion to DecimalValue from ${value.runtimeType}',
      ),
    };
  }

  /// Converts any scalar to a [ComplexNumber].
  static ComplexNumber toComplex(ScalarValue value) {
    return switch (value) {
      ComplexNumber() => value,
      _ => ComplexNumber.realOnly(toDecimal(value)),
    };
  }

  static DecimalValue _fractionToDecimal(FractionValue fraction) {
    // When converting fraction to decimal for promotion, convert with exact decimal division if denominator is power of 2 & 5,
    // or standard high precision.
    final den = fraction.denominator;
    final num = fraction.numerator;

    // Check if denominator is 2^a * 5^b (terminating decimal)
    var d = den;
    var count2 = 0;
    var count5 = 0;
    while (d % BigInt.two == BigInt.zero) {
      d ~/= BigInt.two;
      count2++;
    }
    final five = BigInt.from(5);
    while (d % five == BigInt.zero) {
      d ~/= five;
      count5++;
    }

    if (d == BigInt.one) {
      // Terminating exact decimal!
      final maxPower = count2 > count5 ? count2 : count5;
      final scale = maxPower;
      final factor = BigInt.from(10).pow(scale);
      final unscaled = (num * factor) ~/ den;
      return DecimalValue(unscaled, scale, isExact: true);
    } else {
      // Non-terminating decimal, approximate with 34 digits precision
      const precisionDigits = 34;
      final factor = BigInt.from(10).pow(precisionDigits);
      final unscaled = (num * factor) ~/ den;
      return DecimalValue(unscaled, precisionDigits, isExact: false);
    }
  }
}
