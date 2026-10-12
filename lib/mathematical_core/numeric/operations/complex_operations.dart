import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/decimal_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';

/// Elementary arithmetic operations on complex numbers `z = a + bi`.
final class ComplexOperations {
  const ComplexOperations();

  /// Adds two complex numbers: `(a + bi) + (c + di) = (a + c) + (b + d)i`.
  static MathResult<ComplexNumber> add(ComplexNumber a, ComplexNumber b) {
    final r = DecimalOperations.add(a.real, b.real).valueOrNull!;
    final i = DecimalOperations.add(a.imaginary, b.imaginary).valueOrNull!;
    return MathSuccess(
      ComplexNumber(real: r, imaginary: i),
      metadata: CalculationMetadata(isExact: a.isExact && b.isExact),
    );
  }

  /// Subtracts two complex numbers: `(a + bi) - (c + di) = (a - c) + (b - d)i`.
  static MathResult<ComplexNumber> subtract(ComplexNumber a, ComplexNumber b) {
    final r = DecimalOperations.subtract(a.real, b.real).valueOrNull!;
    final i = DecimalOperations.subtract(a.imaginary, b.imaginary).valueOrNull!;
    return MathSuccess(
      ComplexNumber(real: r, imaginary: i),
      metadata: CalculationMetadata(isExact: a.isExact && b.isExact),
    );
  }

  /// Multiplies two complex numbers:
  /// `(a + bi) * (c + di) = (ac - bd) + (ad + bc)i`.
  static MathResult<ComplexNumber> multiply(ComplexNumber a, ComplexNumber b) {
    final ac = DecimalOperations.multiply(a.real, b.real).valueOrNull!;
    final bd = DecimalOperations.multiply(
      a.imaginary,
      b.imaginary,
    ).valueOrNull!;
    final ad = DecimalOperations.multiply(a.real, b.imaginary).valueOrNull!;
    final bc = DecimalOperations.multiply(a.imaginary, b.real).valueOrNull!;

    final r = DecimalOperations.subtract(ac, bd).valueOrNull!;
    final i = DecimalOperations.add(ad, bc).valueOrNull!;

    return MathSuccess(
      ComplexNumber(real: r, imaginary: i),
      metadata: CalculationMetadata(isExact: a.isExact && b.isExact),
    );
  }

  /// Divides two complex numbers:
  /// `(a + bi) / (c + di) = [(ac + bd) + (bc - ad)i] / (c^2 + d^2)`.
  static MathResult<ComplexNumber> divide(
    ComplexNumber a,
    ComplexNumber b, {
    PrecisionContext context = PrecisionContext.standard,
  }) {
    if (b.isZero) {
      return const MathFailure(DivisionByZeroError());
    }

    final c2 = DecimalOperations.multiply(b.real, b.real).valueOrNull!;
    final d2 = DecimalOperations.multiply(
      b.imaginary,
      b.imaginary,
    ).valueOrNull!;
    final denom = DecimalOperations.add(c2, d2).valueOrNull!;

    final ac = DecimalOperations.multiply(a.real, b.real).valueOrNull!;
    final bd = DecimalOperations.multiply(
      a.imaginary,
      b.imaginary,
    ).valueOrNull!;
    final numR = DecimalOperations.add(ac, bd).valueOrNull!;

    final bc = DecimalOperations.multiply(a.imaginary, b.real).valueOrNull!;
    final ad = DecimalOperations.multiply(a.real, b.imaginary).valueOrNull!;
    final numI = DecimalOperations.subtract(bc, ad).valueOrNull!;

    final rRes = DecimalOperations.divide(numR, denom, context: context);
    final iRes = DecimalOperations.divide(numI, denom, context: context);

    if (rRes.isFailure) return MathFailure(rRes.errorOrNull!);
    if (iRes.isFailure) return MathFailure(iRes.errorOrNull!);

    final isExact = rRes.metadata.isExact && iRes.metadata.isExact;
    return MathSuccess(
      ComplexNumber(real: rRes.valueOrNull!, imaginary: iRes.valueOrNull!),
      metadata: CalculationMetadata(
        isExact: isExact,
        approximation: isExact ? null : rRes.metadata.approximation,
      ),
    );
  }

  /// Negates a complex number: `-a - bi`.
  static MathResult<ComplexNumber> negate(ComplexNumber a) {
    return MathSuccess(-a, metadata: CalculationMetadata(isExact: a.isExact));
  }

  /// Conjugate of a complex number: `a - bi`.
  static MathResult<ComplexNumber> conjugate(ComplexNumber a) {
    return MathSuccess(
      a.conjugate(),
      metadata: CalculationMetadata(isExact: a.isExact),
    );
  }
}
