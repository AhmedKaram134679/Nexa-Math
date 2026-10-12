import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';

/// Represents a complex number `z = a + bi` where `a` and `b` are [DecimalValue]s.
///
/// Owned canonically by the Numeric layer under `mathematical_core/numeric/complex/`.
final class ComplexNumber extends ScalarValue {
  /// The real component `a`.
  final DecimalValue real;

  /// The imaginary component `b`.
  final DecimalValue imaginary;

  /// Creates a constant [ComplexNumber].
  const ComplexNumber({required this.real, required this.imaginary});

  /// Creates a complex number from real and imaginary integers.
  factory ComplexNumber.fromInts(int real, int imaginary) => ComplexNumber(
    real: DecimalValue.fromInt(real),
    imaginary: DecimalValue.fromInt(imaginary),
  );

  /// Creates a purely real complex number `a + 0i`.
  factory ComplexNumber.realOnly(DecimalValue real) =>
      ComplexNumber(real: real, imaginary: DecimalValue.zero);

  /// Creates a purely imaginary complex number `0 + bi`.
  factory ComplexNumber.imaginaryOnly(DecimalValue imaginary) =>
      ComplexNumber(real: DecimalValue.zero, imaginary: imaginary);

  /// The complex zero `0 + 0i`.
  static final ComplexNumber zero = ComplexNumber(
    real: DecimalValue.zero,
    imaginary: DecimalValue.zero,
  );

  /// The complex identity `1 + 0i`.
  static final ComplexNumber one = ComplexNumber(
    real: DecimalValue.one,
    imaginary: DecimalValue.zero,
  );

  /// The imaginary unit `i` (`0 + 1i`).
  static final ComplexNumber i = ComplexNumber(
    real: DecimalValue.zero,
    imaginary: DecimalValue.one,
  );

  /// Returns true if this complex number is zero (`0 + 0i`).
  bool get isZero => real.isZero && imaginary.isZero;

  /// Returns true if this complex number is purely real (`imaginary == 0`).
  bool get isReal => imaginary.isZero;

  /// Returns true if this complex number is purely imaginary (`real == 0` and `imaginary != 0`).
  bool get isPurelyImaginary => real.isZero && !imaginary.isZero;

  /// Returns true if both real and imaginary components are mathematically exact.
  bool get isExact => real.isExact && imaginary.isExact;

  /// Returns the complex conjugate `a - bi`.
  ComplexNumber conjugate() => ComplexNumber(real: real, imaginary: -imaginary);

  /// Negation of this complex number `-a - bi`.
  ComplexNumber operator -() =>
      ComplexNumber(real: -real, imaginary: -imaginary);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplexNumber &&
          runtimeType == other.runtimeType &&
          real == other.real &&
          imaginary == other.imaginary;

  @override
  int get hashCode => Object.hash(real, imaginary);

  @override
  String toString() {
    if (imaginary.isZero) {
      return real.toString();
    }
    if (real.isZero) {
      if (imaginary == DecimalValue.one) return 'i';
      if (imaginary == -DecimalValue.one) return '-i';
      return '${imaginary}i';
    }

    final sign = imaginary.isNegative ? '-' : '+';
    final absImag = imaginary.abs();
    final imagStr = absImag == DecimalValue.one ? 'i' : '${absImag}i';
    return '$real $sign $imagStr';
  }
}
