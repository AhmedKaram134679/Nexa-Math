import 'package:nexa_math/mathematical_core/common/math_value.dart';

/// Represents an arbitrary-precision integer mathematical value in NexaMath.
///
/// Integers in NexaMath are exact mathematical entities backed by [BigInt],
/// never suffering from 64-bit integer overflow.
final class IntegerValue extends ScalarValue
    implements Comparable<IntegerValue> {
  /// The underlying arbitrary-precision integer value.
  final BigInt value;

  /// Creates a constant [IntegerValue] with the given [value].
  const IntegerValue(this.value);

  /// Creates an [IntegerValue] from a 64-bit platform integer.
  factory IntegerValue.fromInt(int val) => IntegerValue(BigInt.from(val));

  /// Parses a string representation of an integer into an [IntegerValue],
  /// or throws a [FormatException] if the string is not a valid integer.
  factory IntegerValue.parse(String source) =>
      IntegerValue(BigInt.parse(source.trim()));

  /// Tries to parse a string representation of an integer into an [IntegerValue],
  /// returning null if parsing fails.
  static IntegerValue? tryParse(String source) {
    final parsed = BigInt.tryParse(source.trim());
    return parsed != null ? IntegerValue(parsed) : null;
  }

  /// The integer 0.
  static final IntegerValue zero = IntegerValue(BigInt.zero);

  /// The integer 1.
  static final IntegerValue one = IntegerValue(BigInt.one);

  /// The integer 2.
  static final IntegerValue two = IntegerValue(BigInt.two);

  /// The integer -1.
  static final IntegerValue minusOne = IntegerValue(-BigInt.one);

  /// The integer 10.
  static final IntegerValue ten = IntegerValue(BigInt.from(10));

  /// Returns true if this integer is zero.
  bool get isZero => value == BigInt.zero;

  /// Returns true if this integer is strictly positive (> 0).
  bool get isPositive => value > BigInt.zero;

  /// Returns true if this integer is strictly negative (< 0).
  bool get isNegative => value < BigInt.zero;

  /// Returns true if this integer is even.
  bool get isEven => value.isEven;

  /// Returns true if this integer is odd.
  bool get isOdd => value.isOdd;

  /// Returns the signum of this integer: -1 if negative, 0 if zero, 1 if positive.
  int get signum => value == BigInt.zero ? 0 : (value < BigInt.zero ? -1 : 1);

  /// Returns the absolute value of this integer.
  IntegerValue abs() => IntegerValue(value.abs());

  /// Returns the negation of this integer.
  IntegerValue operator -() => IntegerValue(-value);

  @override
  int compareTo(IntegerValue other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntegerValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
