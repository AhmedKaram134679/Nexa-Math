import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('NumericPromoter Unit Tests', () {
    const promoter = NumericPromoter();

    test('Integer + Integer -> Integer', () {
      final a = IntegerValue.fromInt(10);
      final b = IntegerValue.fromInt(20);
      final (pA, pB) = promoter.promote(a, b);

      expect(pA, isA<IntegerValue>());
      expect(pB, isA<IntegerValue>());
    });

    test('Integer + Fraction -> Fraction', () {
      final a = IntegerValue.fromInt(2);
      final b = FractionValue.fromInts(1, 3);
      final (pA, pB) = promoter.promote(a, b);

      expect(pA, isA<FractionValue>());
      expect(pB, isA<FractionValue>());
      expect(pA, equals(FractionValue.fromInts(2, 1)));
      expect(pB, equals(FractionValue.fromInts(1, 3)));
    });

    test('Integer + Decimal -> Decimal', () {
      final a = IntegerValue.fromInt(5);
      final b = DecimalValue.parse('2.5');
      final (pA, pB) = promoter.promote(a, b);

      expect(pA, isA<DecimalValue>());
      expect(pB, isA<DecimalValue>());
      expect(pA, equals(DecimalValue.parse('5')));
    });

    test('Fraction + Decimal -> Decimal', () {
      final a = FractionValue.fromInts(1, 4); // 0.25 exact
      final b = DecimalValue.parse('1.5');
      final (pA, pB) = promoter.promote(a, b);

      expect(pA, isA<DecimalValue>());
      expect(pB, isA<DecimalValue>());
      expect(pA, equals(DecimalValue.parse('0.25')));
    });

    test('Scalar + Complex -> Complex', () {
      final a = IntegerValue.fromInt(3);
      final z = ComplexNumber.fromInts(1, 2);
      final (pA, pB) = promoter.promote(a, z);

      expect(pA, isA<ComplexNumber>());
      expect(pB, isA<ComplexNumber>());
      expect(pA, equals(ComplexNumber.fromInts(3, 0)));
      expect(pB, equals(z));
    });

    test('Exact vs non-terminating fraction promotion exactness metadata', () {
      // 1/2 -> exact terminating decimal 0.5
      final halfDec = NumericPromoter.toDecimal(FractionValue.fromInts(1, 2));
      expect(halfDec.isExact, isTrue);
      expect(halfDec, equals(DecimalValue.parse('0.5')));

      // 1/4 -> exact terminating decimal 0.25
      final quarterDec = NumericPromoter.toDecimal(
        FractionValue.fromInts(1, 4),
      );
      expect(quarterDec.isExact, isTrue);
      expect(quarterDec, equals(DecimalValue.parse('0.25')));

      // 1/8 -> exact terminating decimal 0.125
      final eighthDec = NumericPromoter.toDecimal(FractionValue.fromInts(1, 8));
      expect(eighthDec.isExact, isTrue);
      expect(eighthDec, equals(DecimalValue.parse('0.125')));

      // 1/3 -> non-terminating approximate decimal (isExact: false)
      final thirdDec = NumericPromoter.toDecimal(FractionValue.fromInts(1, 3));
      expect(thirdDec.isExact, isFalse);
      expect(thirdDec.scale, equals(34));
      expect(thirdDec.toString().startsWith('0.33333333333333333333'), isTrue);

      // Complex with non-terminating fraction
      final complexThird = NumericPromoter.toComplex(
        FractionValue.fromInts(1, 3),
      );
      expect(complexThird.real.isExact, isFalse);
      expect(complexThird.imaginary.isZero, isTrue);
    });
  });
}
