import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';

/// Pure, exact rational arithmetic operations for NexaMath.
///
/// Ensures exact fractional values are maintained without floating-point error,
/// auto-reducing to irreducible canonical forms.
final class FractionOperations {
  const FractionOperations();

  /// Adds two fractions: `a/b + c/d = (a*d + b*c) / (b*d)`.
  static MathResult<FractionValue> add(FractionValue a, FractionValue b) {
    final num = a.numerator * b.denominator + b.numerator * a.denominator;
    final den = a.denominator * b.denominator;
    return MathSuccess(
      FractionValue(num, den),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Subtracts two fractions: `a/b - c/d = (a*d - b*c) / (b*d)`.
  static MathResult<FractionValue> subtract(FractionValue a, FractionValue b) {
    final num = a.numerator * b.denominator - b.numerator * a.denominator;
    final den = a.denominator * b.denominator;
    return MathSuccess(
      FractionValue(num, den),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Multiplies two fractions: `(a/b) * (c/d) = (a*c) / (b*d)`.
  static MathResult<FractionValue> multiply(FractionValue a, FractionValue b) {
    final num = a.numerator * b.numerator;
    final den = a.denominator * b.denominator;
    return MathSuccess(
      FractionValue(num, den),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Divides two fractions: `(a/b) / (c/d) = (a*d) / (b*c)`.
  static MathResult<FractionValue> divide(FractionValue a, FractionValue b) {
    if (b.isZero) {
      return const MathFailure(DivisionByZeroError());
    }
    final num = a.numerator * b.denominator;
    final den = a.denominator * b.numerator;
    return MathSuccess(
      FractionValue(num, den),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Power of a fraction with an integral exponent: `(a/b)^exp`.
  static MathResult<FractionValue> power(FractionValue base, int exponent) {
    if (base.isZero && exponent == 0) {
      return const MathFailure(
        DomainError(
          message: '0^0 is an indeterminate form.',
          functionName: 'power',
        ),
      );
    }

    if (base.isZero && exponent == 0) {
      return const MathFailure(
        DomainError(
          message: '0^0 is an indeterminate form.',
          functionName: 'power',
        ),
      );
    }

    if (base.isZero) {
      if (exponent < 0) {
        return const MathFailure(DivisionByZeroError());
      }
      return MathSuccess(
        FractionValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    if (exponent == 0) {
      return MathSuccess(
        FractionValue.one,
        metadata: CalculationMetadata.exact,
      );
    }

    if (exponent > 0) {
      if (exponent > 100000) {
        return const MathFailure(
          OverflowError(
            message: 'Exponent is too large for fraction power computation.',
          ),
        );
      }
      final num = base.numerator.pow(exponent);
      final den = base.denominator.pow(exponent);
      return MathSuccess(
        FractionValue(num, den),
        metadata: CalculationMetadata.exact,
      );
    } else {
      final absExp = -exponent;
      if (absExp > 100000) {
        return const MathFailure(
          OverflowError(
            message: 'Exponent magnitude is too large for fraction power computation.',
          ),
        );
      }
      final num = base.denominator.pow(absExp);
      final den = base.numerator.pow(absExp);
      return MathSuccess(
        FractionValue(num, den),
        metadata: CalculationMetadata.exact,
      );
    }
  }

  /// Negates a fraction: `-(a/b)`.
  static MathResult<FractionValue> negate(FractionValue a) {
    return MathSuccess(-a, metadata: CalculationMetadata.exact);
  }

  /// Absolute value of a fraction: `|a/b|`.
  static MathResult<FractionValue> absolute(FractionValue a) {
    return MathSuccess(a.abs(), metadata: CalculationMetadata.exact);
  }
}
