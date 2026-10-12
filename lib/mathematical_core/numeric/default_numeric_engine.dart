import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/complex_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/decimal_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/fraction_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/integer_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/primitives/combinatorics.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Canonical production implementation of [NumericEngine].
final class DefaultNumericEngine implements NumericEngine {
  @override
  final PrecisionContext context;

  final NumericPromoter _promoter;

  /// Creates a [DefaultNumericEngine] instance with the specified [context].
  DefaultNumericEngine({this.context = PrecisionContext.standard})
    : _promoter = const NumericPromoter();

  @override
  MathResult<ScalarValue> add(ScalarValue left, ScalarValue right) {
    final (pLeft, pRight) = _promoter.promote(left, right);

    return switch ((pLeft, pRight)) {
      (final IntegerValue a, final IntegerValue b) => IntegerOperations.add(
        a,
        b,
      ),
      (final FractionValue a, final FractionValue b) => FractionOperations.add(
        a,
        b,
      ),
      (final DecimalValue a, final DecimalValue b) => DecimalOperations.add(
        a,
        b,
      ),
      (final ComplexNumber a, final ComplexNumber b) => ComplexOperations.add(
        a,
        b,
      ),
      _ => MathFailure(
        UnsupportedOperationError(
          message:
              'Addition between ${pLeft.runtimeType} and ${pRight.runtimeType} is unsupported.',
          operation: 'add',
        ),
      ),
    };
  }

  @override
  MathResult<ScalarValue> subtract(ScalarValue left, ScalarValue right) {
    final (pLeft, pRight) = _promoter.promote(left, right);

    return switch ((pLeft, pRight)) {
      (final IntegerValue a, final IntegerValue b) =>
        IntegerOperations.subtract(a, b),
      (final FractionValue a, final FractionValue b) =>
        FractionOperations.subtract(a, b),
      (final DecimalValue a, final DecimalValue b) =>
        DecimalOperations.subtract(a, b),
      (final ComplexNumber a, final ComplexNumber b) =>
        ComplexOperations.subtract(a, b),
      _ => MathFailure(
        UnsupportedOperationError(
          message:
              'Subtraction between ${pLeft.runtimeType} and ${pRight.runtimeType} is unsupported.',
          operation: 'subtract',
        ),
      ),
    };
  }

  @override
  MathResult<ScalarValue> multiply(ScalarValue left, ScalarValue right) {
    final (pLeft, pRight) = _promoter.promote(left, right);

    return switch ((pLeft, pRight)) {
      (final IntegerValue a, final IntegerValue b) =>
        IntegerOperations.multiply(a, b),
      (final FractionValue a, final FractionValue b) =>
        FractionOperations.multiply(a, b),
      (final DecimalValue a, final DecimalValue b) =>
        DecimalOperations.multiply(a, b),
      (final ComplexNumber a, final ComplexNumber b) =>
        ComplexOperations.multiply(a, b),
      _ => MathFailure(
        UnsupportedOperationError(
          message:
              'Multiplication between ${pLeft.runtimeType} and ${pRight.runtimeType} is unsupported.',
          operation: 'multiply',
        ),
      ),
    };
  }

  @override
  MathResult<ScalarValue> divide(ScalarValue left, ScalarValue right) {
    // Special exact case: Integer / Integer -> FractionValue
    if (left is IntegerValue && right is IntegerValue) {
      if (right.isZero) {
        return const MathFailure(DivisionByZeroError());
      }
      final frac = FractionValue(left.value, right.value);
      if (frac.isInteger) {
        return MathSuccess(
          IntegerValue(frac.numerator),
          metadata: CalculationMetadata.exact,
        );
      }
      return MathSuccess(frac, metadata: CalculationMetadata.exact);
    }

    final (pLeft, pRight) = _promoter.promote(left, right);

    return switch ((pLeft, pRight)) {
      (final FractionValue a, final FractionValue b) =>
        FractionOperations.divide(a, b),
      (final DecimalValue a, final DecimalValue b) => DecimalOperations.divide(
        a,
        b,
        context: context,
      ),
      (final ComplexNumber a, final ComplexNumber b) =>
        ComplexOperations.divide(a, b, context: context),
      _ => MathFailure(
        UnsupportedOperationError(
          message:
              'Division between ${pLeft.runtimeType} and ${pRight.runtimeType} is unsupported.',
          operation: 'divide',
        ),
      ),
    };
  }

  @override
  MathResult<ScalarValue> power(ScalarValue base, ScalarValue exponent) {
    // Integer base with integer exponent
    if (base is IntegerValue && exponent is IntegerValue) {
      return IntegerOperations.power(base, exponent).map((frac) {
        if (frac.isInteger) {
          return IntegerValue(frac.numerator);
        }
        return frac;
      });
    }

    // Fraction base with integer exponent
    if (base is FractionValue && exponent is IntegerValue) {
      if (exponent.value > BigInt.from(100000) ||
          exponent.value < -BigInt.from(100000)) {
        return const MathFailure(
          OverflowError(
            message: 'Exponent magnitude is too large for fraction power.',
          ),
        );
      }
      return FractionOperations.power(base, exponent.value.toInt());
    }

    // Decimal or promoted power
    final decBase = NumericPromoter.toDecimal(base);
    final decExp = NumericPromoter.toDecimal(exponent);
    return DecimalOperations.power(decBase, decExp, context: context);
  }

  @override
  MathResult<ScalarValue> negate(ScalarValue value) {
    return switch (value) {
      final IntegerValue a => IntegerOperations.negate(a),
      final FractionValue a => FractionOperations.negate(a),
      final DecimalValue a => DecimalOperations.negate(a),
      final ComplexNumber a => ComplexOperations.negate(a),
      _ => MathFailure(
        UnsupportedOperationError(
          message: 'Negation on ${value.runtimeType} is unsupported.',
          operation: 'negate',
        ),
      ),
    };
  }

  @override
  MathResult<ScalarValue> absolute(ScalarValue value) {
    return switch (value) {
      final IntegerValue a => IntegerOperations.absolute(a),
      final FractionValue a => FractionOperations.absolute(a),
      final DecimalValue a => DecimalOperations.absolute(a),
      final ComplexNumber a => _complexMagnitude(a),
      _ => MathFailure(
        UnsupportedOperationError(
          message: 'Absolute value on ${value.runtimeType} is unsupported.',
          operation: 'absolute',
        ),
      ),
    };
  }

  MathResult<DecimalValue> _complexMagnitude(ComplexNumber z) {
    // |z| = sqrt(real^2 + imag^2)
    final r2 = DecimalOperations.multiply(z.real, z.real).valueOrNull!;
    final i2 = DecimalOperations.multiply(
      z.imaginary,
      z.imaginary,
    ).valueOrNull!;
    final sum = DecimalOperations.add(r2, i2).valueOrNull!;
    return DecimalOperations.sqrt(sum, context: context);
  }

  @override
  MathResult<ScalarValue> factorial(ScalarValue value) {
    if (value is! IntegerValue) {
      return const MathFailure(
        DomainError(
          message: 'Factorial is currently only supported for exact non-negative integers.',
          functionName: 'factorial',
        ),
      );
    }
    return Combinatorics.factorial(value);
  }

  @override
  MathResult<ScalarValue> convert(ScalarValue value, NumericType targetType) {
    try {
      final res = switch (targetType) {
        NumericKind.integer => switch (value) {
          final IntegerValue a => a,
          final FractionValue a =>
            a.isInteger
                ? IntegerValue(a.numerator)
                : throw const DomainError(
                    message:
                        'Fraction cannot be losslessly converted to integer.',
                    code: 'DOMAIN_ERROR',
                  ),
          final DecimalValue a =>
            a.scale == 0
                ? IntegerValue(a.unscaledValue)
                : throw const DomainError(
                    message: 'Non-integer decimal cannot be losslessly converted to integer.',
                    code: 'DOMAIN_ERROR',
                  ),
          final ComplexNumber a =>
            a.isReal
                ? convert(a.real, NumericKind.integer).valueOrNull!
                : throw const DomainError(
                    message: 'Non-real complex number cannot be converted to integer.',
                    code: 'DOMAIN_ERROR',
                  ),
          _ => throw const DomainError(
            message: 'Unsupported scalar conversion to integer.',
            code: 'DOMAIN_ERROR',
          ),
        },
        NumericKind.fraction => NumericPromoter.toFraction(value),
        NumericKind.decimal => NumericPromoter.toDecimal(value),
        NumericKind.complex => NumericPromoter.toComplex(value),
      };
      return MathSuccess(res, metadata: CalculationMetadata.exact);
    } on MathError catch (e) {
      return MathFailure(e);
    } catch (e) {
      return MathFailure(
        UnsupportedOperationError(
          message: 'Conversion to $targetType failed: $e',
          operation: 'convert',
        ),
      );
    }
  }
}
