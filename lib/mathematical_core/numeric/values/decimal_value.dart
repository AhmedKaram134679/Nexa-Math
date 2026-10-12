import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Represents an arbitrary-precision decimal mathematical value in NexaMath.
///
/// Backed by an arbitrary-precision integer [unscaledValue] and an integer [scale],
/// representing the mathematical number:
/// `value = unscaledValue * 10^(-scale)`.
///
/// Examples:
/// - 12.34 -> unscaledValue = 1234, scale = 2
/// - 0.005 -> unscaledValue = 5, scale = 3
/// - -700 with scale -2 -> -70000
///
/// Exactness is preserved during decimal additions, subtractions, and multiplications.
/// Division and transcendental functions apply [PrecisionContext] rules and report
/// whether the result remains exact or is an approximation.
final class DecimalValue extends ScalarValue
    implements Comparable<DecimalValue> {
  /// The unscaled arbitrary-precision integer component.
  final BigInt unscaledValue;

  /// The scale indicating the number of digits to the right of the decimal point.
  final int scale;

  /// Whether this decimal is mathematically exact or a precision-limited approximation.
  final bool isExact;

  /// Internal canonical constructor.
  const DecimalValue._(this.unscaledValue, this.scale, {this.isExact = true});

  /// Canonical factory creating a [DecimalValue] with the specified [unscaledValue] and [scale].
  factory DecimalValue(BigInt unscaledValue, int scale, {bool isExact = true}) {
    if (unscaledValue == BigInt.zero) {
      return DecimalValue._(BigInt.zero, 0, isExact: isExact);
    }
    return DecimalValue._(unscaledValue, scale, isExact: isExact);
  }

  /// Creates a [DecimalValue] from an [IntegerValue].
  factory DecimalValue.fromInteger(
    IntegerValue integer, {
    bool isExact = true,
  }) => DecimalValue._(integer.value, 0, isExact: isExact);

  /// Creates a [DecimalValue] from a platform 64-bit integer.
  factory DecimalValue.fromInt(int val, {bool isExact = true}) =>
      DecimalValue._(BigInt.from(val), 0, isExact: isExact);

  /// Parses a decimal string (e.g. `"123.456"`, `"-0.007"`, `"42"`, `"1.23e5"`, `"-4.5e-3"`).
  factory DecimalValue.parse(String source, {bool isExact = true}) {
    final str = source.trim().toLowerCase();
    if (str.isEmpty) {
      throw const FormatException('Cannot parse empty string as DecimalValue.');
    }

    // Check for scientific notation exponent 'e'
    final eIndex = str.indexOf('e');
    if (eIndex != -1) {
      final mantissaStr = str.substring(0, eIndex);
      final expStr = str.substring(eIndex + 1);
      final exp = int.parse(expStr);
      final baseDec = DecimalValue.parse(mantissaStr, isExact: isExact);
      // scale adjustment: value * 10^exp => scale becomes scale - exp
      return DecimalValue(
        baseDec.unscaledValue,
        baseDec.scale - exp,
        isExact: isExact,
      );
    }

    final isNegative = str.startsWith('-');
    final cleanStr = str.startsWith('+') || str.startsWith('-')
        ? str.substring(1)
        : str;

    final dotIndex = cleanStr.indexOf('.');
    if (dotIndex == -1) {
      // Plain integer
      final unscaled = BigInt.parse(cleanStr);
      return DecimalValue(
        isNegative ? -unscaled : unscaled,
        0,
        isExact: isExact,
      );
    }

    final intPart = cleanStr.substring(0, dotIndex);
    final fracPart = cleanStr.substring(dotIndex + 1);

    final combinedDigits = '$intPart$fracPart';
    if (combinedDigits.isEmpty) {
      throw FormatException('Invalid decimal string: "$source"');
    }

    final unscaled = BigInt.parse(combinedDigits);
    final scale = fracPart.length;

    return DecimalValue(
      isNegative ? -unscaled : unscaled,
      scale,
      isExact: isExact,
    );
  }

  /// Tries to parse a decimal string, returning null if invalid.
  static DecimalValue? tryParse(String source, {bool isExact = true}) {
    try {
      return DecimalValue.parse(source, isExact: isExact);
    } catch (_) {
      return null;
    }
  }

  /// Exact 0.
  static final DecimalValue zero = DecimalValue._(BigInt.zero, 0);

  /// Exact 1.
  static final DecimalValue one = DecimalValue._(BigInt.one, 0);

  /// Exact 2.
  static final DecimalValue two = DecimalValue._(BigInt.two, 0);

  /// Exact 10.
  static final DecimalValue ten = DecimalValue._(BigInt.from(10), 0);

  /// Exact 0.5.
  static final DecimalValue half = DecimalValue._(BigInt.from(5), 1);

  /// Returns true if this decimal equals zero.
  bool get isZero => unscaledValue == BigInt.zero;

  /// Returns true if this decimal is strictly positive (> 0).
  bool get isPositive => unscaledValue > BigInt.zero;

  /// Returns true if this decimal is strictly negative (< 0).
  bool get isNegative => unscaledValue < BigInt.zero;

  /// Returns the signum of this decimal: -1 if negative, 0 if zero, 1 if positive.
  int get signum =>
      unscaledValue == BigInt.zero ? 0 : (unscaledValue < BigInt.zero ? -1 : 1);

  /// Returns the absolute value of this decimal.
  DecimalValue abs() =>
      DecimalValue._(unscaledValue.abs(), scale, isExact: isExact);

  /// Returns the negation of this decimal.
  DecimalValue operator -() =>
      DecimalValue._(-unscaledValue, scale, isExact: isExact);

  /// Returns a normalized [DecimalValue] where trailing zeroes in the fractional part
  /// have been stripped (e.g. 1.500 -> 1.5).
  DecimalValue normalize() {
    if (unscaledValue == BigInt.zero) {
      return DecimalValue.zero;
    }

    var unscaled = unscaledValue;
    var currentScale = scale;
    final ten = BigInt.from(10);

    while (currentScale > 0 && unscaled % ten == BigInt.zero) {
      unscaled ~/= ten;
      currentScale--;
    }

    return DecimalValue._(unscaled, currentScale, isExact: isExact);
  }

  /// Rounds this [DecimalValue] to the specified precision or scale according to [context].
  DecimalValue roundToPrecision(PrecisionContext context) {
    if (isZero) return this;

    final norm = normalize();
    final digits = norm.unscaledValue.abs().toString();
    final totalDigits = digits.length;

    if (totalDigits <= context.precisionDigits) {
      return norm;
    }

    final excessDigits = totalDigits - context.precisionDigits;
    final divisor = BigInt.from(10).pow(excessDigits);
    final quotient = norm.unscaledValue ~/ divisor;
    final remainder = (norm.unscaledValue % divisor).abs();

    final halfDivisor = divisor ~/ BigInt.two;
    final isNegative = norm.unscaledValue < BigInt.zero;

    bool roundUp = false;
    switch (context.roundingMode) {
      case RoundingMode.halfUp:
        roundUp = remainder >= halfDivisor;
        break;
      case RoundingMode.halfEven:
        if (remainder > halfDivisor) {
          roundUp = true;
        } else if (remainder == halfDivisor) {
          // Banker's rounding: round towards even quotient
          roundUp = quotient.isOdd;
        } else {
          roundUp = false;
        }
        break;
      case RoundingMode.up:
        roundUp = remainder > BigInt.zero;
        break;
      case RoundingMode.down:
        roundUp = false;
        break;
      case RoundingMode.ceiling:
        roundUp = !isNegative && remainder > BigInt.zero;
        break;
      case RoundingMode.floor:
        roundUp = isNegative && remainder > BigInt.zero;
        break;
    }

    var roundedUnscaled = quotient;
    if (roundUp) {
      roundedUnscaled = isNegative
          ? roundedUnscaled - BigInt.one
          : roundedUnscaled + BigInt.one;
    }

    final newScale = norm.scale - excessDigits;
    return DecimalValue(roundedUnscaled, newScale, isExact: false).normalize();
  }

  /// Converts this [DecimalValue] to a [FractionValue] if possible.
  FractionValue toFraction() {
    if (scale == 0) {
      return FractionValue(unscaledValue, BigInt.one);
    }
    if (scale > 0) {
      final denominator = BigInt.from(10).pow(scale);
      return FractionValue(unscaledValue, denominator);
    } else {
      // Negative scale means integer multiplied by 10^(-scale)
      final multiplier = BigInt.from(10).pow(-scale);
      return FractionValue(unscaledValue * multiplier, BigInt.one);
    }
  }

  /// Converts this [DecimalValue] to double (may lose precision for very large values).
  double toDouble() => double.parse(toString());

  @override
  int compareTo(DecimalValue other) {
    if (scale == other.scale) {
      return unscaledValue.compareTo(other.unscaledValue);
    }
    // Align scales
    final maxScale = scale > other.scale ? scale : other.scale;
    final v1 = _rescale(unscaledValue, maxScale - scale);
    final v2 = _rescale(other.unscaledValue, maxScale - other.scale);
    return v1.compareTo(v2);
  }

  static BigInt _rescale(BigInt val, int diff) {
    if (diff == 0) return val;
    return val * BigInt.from(10).pow(diff);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DecimalValue) return false;
    // Mathematically equal values compare equal (e.g. 1.5 == 1.50)
    return compareTo(other) == 0;
  }

  @override
  int get hashCode {
    final norm = normalize();
    return Object.hash(norm.unscaledValue, norm.scale);
  }

  @override
  String toString() {
    if (scale == 0) {
      return unscaledValue.toString();
    }

    final isNeg = unscaledValue < BigInt.zero;
    final absStr = unscaledValue.abs().toString();

    if (scale > 0) {
      if (absStr.length <= scale) {
        final zeroesNeeded = scale - absStr.length;
        final frac = '0' * zeroesNeeded + absStr;
        return '${isNeg ? '-' : ''}0.$frac';
      } else {
        final intPart = absStr.substring(0, absStr.length - scale);
        final fracPart = absStr.substring(absStr.length - scale);
        return '${isNeg ? '-' : ''}$intPart.$fracPart';
      }
    } else {
      // scale < 0: trailing zeroes
      return '${isNeg ? '-' : ''}$absStr${'0' * (-scale)}';
    }
  }
}
