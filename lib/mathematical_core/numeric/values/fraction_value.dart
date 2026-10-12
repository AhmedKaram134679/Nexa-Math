import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Represents an exact canonical rational number (fraction) in NexaMath.
///
/// Invariants:
/// 1. [denominator] is strictly positive (`denominator > 0`).
/// 2. The fraction is in irreducible form: `gcd(|numerator|, denominator) == 1`.
/// 3. Zero is uniquely represented as `0/1`.
final class FractionValue extends ScalarValue
    implements Comparable<FractionValue> {
  /// The numerator of the fraction.
  final BigInt numerator;

  /// The strictly positive denominator of the irreducible fraction.
  final BigInt denominator;

  /// Private constructor enforcing reduced canonical representation.
  const FractionValue._(this.numerator, this.denominator);

  /// Canonical factory creating a normalized, irreducible [FractionValue].
  ///
  /// Throws [ArgumentError] if [denominator] is zero.
  factory FractionValue(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw ArgumentError.value(
        denominator,
        'denominator',
        'Denominator of a fraction cannot be zero.',
      );
    }

    if (numerator == BigInt.zero) {
      return FractionValue._(BigInt.zero, BigInt.one);
    }

    // Normalize sign so denominator is always strictly positive
    var num = numerator;
    var den = denominator;
    if (den < BigInt.zero) {
      num = -num;
      den = -den;
    }

    // Reduce to lowest terms by dividing by gcd
    final commonDivisor = num.abs().gcd(den);
    if (commonDivisor > BigInt.one) {
      num = num ~/ commonDivisor;
      den = den ~/ commonDivisor;
    }

    return FractionValue._(num, den);
  }

  /// Creates a fraction from standard 64-bit platform integers.
  factory FractionValue.fromInts(int num, int den) =>
      FractionValue(BigInt.from(num), BigInt.from(den));

  /// Creates a fraction representing an integer [n] as `n / 1`.
  factory FractionValue.fromInteger(IntegerValue integer) =>
      FractionValue._(integer.value, BigInt.one);

  /// Parses a string representation such as `"3/4"` or `"-5/2"` into a [FractionValue].
  factory FractionValue.parse(String source) {
    final parts = source.trim().split('/');
    if (parts.length == 1) {
      final num = BigInt.parse(parts[0].trim());
      return FractionValue._(num, BigInt.one);
    } else if (parts.length == 2) {
      final num = BigInt.parse(parts[0].trim());
      final den = BigInt.parse(parts[1].trim());
      return FractionValue(num, den);
    } else {
      throw FormatException('Invalid fraction format: "$source"');
    }
  }

  /// Tries to parse a string representation of a fraction, returning null if invalid.
  static FractionValue? tryParse(String source) {
    try {
      return FractionValue.parse(source);
    } catch (_) {
      return null;
    }
  }

  /// The fraction 0/1.
  static final FractionValue zero = FractionValue._(BigInt.zero, BigInt.one);

  /// The fraction 1/1.
  static final FractionValue one = FractionValue._(BigInt.one, BigInt.one);

  /// The fraction 1/2.
  static final FractionValue half = FractionValue._(BigInt.one, BigInt.two);

  /// Returns true if this fraction equals zero (0/1).
  bool get isZero => numerator == BigInt.zero;

  /// Returns true if this fraction is strictly positive (> 0).
  bool get isPositive => numerator > BigInt.zero;

  /// Returns true if this fraction is strictly negative (< 0).
  bool get isNegative => numerator < BigInt.zero;

  /// Returns true if the fraction is proper, i.e., `|numerator| < denominator`.
  bool get isProper => numerator.abs() < denominator;

  /// Returns true if this fraction has denominator 1 and can be simplified to an integer.
  bool get isInteger => denominator == BigInt.one;

  /// Returns this fraction as an [IntegerValue] if [isInteger] is true, or null otherwise.
  IntegerValue? toIntegerValueOrNull() =>
      isInteger ? IntegerValue(numerator) : null;

  /// Returns the reciprocal (multiplicative inverse) of this fraction.
  /// Throws [StateError] if this fraction is zero.
  FractionValue reciprocal() {
    if (numerator == BigInt.zero) {
      throw StateError('Cannot compute reciprocal of zero fraction.');
    }
    return FractionValue(denominator, numerator);
  }

  /// Returns the absolute value of this fraction.
  FractionValue abs() => FractionValue._(numerator.abs(), denominator);

  /// Returns the negation of this fraction.
  FractionValue operator -() => FractionValue._(-numerator, denominator);

  @override
  int compareTo(FractionValue other) {
    // Cross-multiplication since denominators are strictly positive
    return (numerator * other.denominator).compareTo(
      other.numerator * denominator,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FractionValue &&
          runtimeType == other.runtimeType &&
          numerator == other.numerator &&
          denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() {
    if (denominator == BigInt.one) {
      return numerator.toString();
    }
    return '$numerator/$denominator';
  }
}
