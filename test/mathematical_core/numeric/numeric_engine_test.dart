import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('NumericEngine Operations & Coordination Unit Tests', () {
    final engine = NumericEngine();

    test('Exact Integer addition & subtraction', () {
      final a = IntegerValue.fromInt(15);
      final b = IntegerValue.fromInt(27);

      final addRes = engine.add(a, b);
      expect(addRes.isSuccess, isTrue);
      expect(addRes.valueOrNull, equals(IntegerValue.fromInt(42)));
      expect(addRes.metadata.isExact, isTrue);

      final subRes = engine.subtract(a, b);
      expect(subRes.isSuccess, isTrue);
      expect(subRes.valueOrNull, equals(IntegerValue.fromInt(-12)));
      expect(subRes.metadata.isExact, isTrue);
    });

    test('Exact Fraction addition & multiplication', () {
      final f1 = FractionValue.fromInts(1, 2);
      final f2 = FractionValue.fromInts(1, 3);

      final addRes = engine.add(f1, f2);
      expect(addRes.isSuccess, isTrue);
      expect(addRes.valueOrNull, equals(FractionValue.fromInts(5, 6)));
      expect(addRes.metadata.isExact, isTrue);

      final mulRes = engine.multiply(f1, f2);
      expect(mulRes.isSuccess, isTrue);
      expect(mulRes.valueOrNull, equals(FractionValue.fromInts(1, 6)));
    });

    test('Exact Mixed-type operations (Integer + Fraction)', () {
      final i = IntegerValue.fromInt(2);
      final f = FractionValue.fromInts(3, 4);

      final addRes = engine.add(i, f);
      expect(addRes.isSuccess, isTrue);
      expect(addRes.valueOrNull, equals(FractionValue.fromInts(11, 4)));
      expect(addRes.metadata.isExact, isTrue);
    });

    test('Integer division producing exact Fraction', () {
      final a = IntegerValue.fromInt(7);
      final b = IntegerValue.fromInt(2);

      final divRes = engine.divide(a, b);
      expect(divRes.isSuccess, isTrue);
      expect(divRes.valueOrNull, equals(FractionValue.fromInts(7, 2)));
      expect(divRes.metadata.isExact, isTrue);

      // Whole division simplifies to IntegerValue
      final wholeRes = engine.divide(
        IntegerValue.fromInt(8),
        IntegerValue.fromInt(2),
      );
      expect(wholeRes.isSuccess, isTrue);
      expect(wholeRes.valueOrNull, equals(IntegerValue.fromInt(4)));
    });

    test('Division by zero produces DivisionByZeroError', () {
      final a = IntegerValue.fromInt(10);
      final z = IntegerValue.zero;

      final divRes = engine.divide(a, z);
      expect(divRes.isFailure, isTrue);
      expect(divRes.errorOrNull, isA<DivisionByZeroError>());
    });

    test('Decimal high-precision division with metadata', () {
      final d1 = DecimalValue.parse('1');
      final d2 = DecimalValue.parse('3');

      final divRes = engine.divide(d1, d2);
      expect(divRes.isSuccess, isTrue);
      expect(divRes.metadata.isExact, isFalse);
      expect(divRes.metadata.approximation, isNotNull);
      expect(divRes.metadata.approximation!.method, equals('decimalDivision'));
      expect(
        divRes.valueOrNull!.toString().startsWith('0.3333333333333333'),
        isTrue,
      );
    });

    test('Complex arithmetic (add, multiply)', () {
      final z1 = ComplexNumber.fromInts(1, 2);
      final z2 = ComplexNumber.fromInts(3, 4);

      // (1 + 2i) + (3 + 4i) = 4 + 6i
      final addRes = engine.add(z1, z2);
      expect(addRes.isSuccess, isTrue);
      expect(addRes.valueOrNull, equals(ComplexNumber.fromInts(4, 6)));

      // (1 + 2i) * (3 + 4i) = (3 - 8) + (4 + 6)i = -5 + 10i
      final mulRes = engine.multiply(z1, z2);
      expect(mulRes.isSuccess, isTrue);
      expect(mulRes.valueOrNull, equals(ComplexNumber.fromInts(-5, 10)));
    });

    test('Power operations (exact vs approximation)', () {
      // 2^10 = 1024 exact
      final pow1 = engine.power(
        IntegerValue.fromInt(2),
        IntegerValue.fromInt(10),
      );
      expect(pow1.isSuccess, isTrue);
      expect(pow1.valueOrNull, equals(IntegerValue.fromInt(1024)));
      expect(pow1.metadata.isExact, isTrue);

      // 2^(-3) = 1/8 exact
      final pow2 = engine.power(
        IntegerValue.fromInt(2),
        IntegerValue.fromInt(-3),
      );
      expect(pow2.isSuccess, isTrue);
      expect(pow2.valueOrNull, equals(FractionValue.fromInts(1, 8)));
    });

    test('Type conversion via engine.convert()', () {
      final f = FractionValue.fromInts(3, 4);
      final decRes = engine.convert(f, NumericKind.decimal);
      expect(decRes.isSuccess, isTrue);
      expect(decRes.valueOrNull, equals(DecimalValue.parse('0.75')));

      final zRes = engine.convert(f, NumericKind.complex);
      expect(zRes.isSuccess, isTrue);
      expect(
        zRes.valueOrNull,
        equals(
          ComplexNumber(
            real: DecimalValue.parse('0.75'),
            imaginary: DecimalValue.zero,
          ),
        ),
      );
    });
  });
}
