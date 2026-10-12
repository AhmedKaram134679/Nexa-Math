import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';

void main() {
  group('ComplexNumber Unit Tests', () {
    test('Constructors and factories', () {
      final z = ComplexNumber(
        real: DecimalValue.parse('3'),
        imaginary: DecimalValue.parse('4'),
      );
      expect(z.real, equals(DecimalValue.parse('3')));
      expect(z.imaginary, equals(DecimalValue.parse('4')));
      expect(z.toString(), equals('3 + 4i'));

      final zInt = ComplexNumber.fromInts(3, 4);
      expect(z, equals(zInt));
    });

    test('Special instances and pure checks', () {
      expect(ComplexNumber.zero.isZero, isTrue);
      expect(ComplexNumber.one.isReal, isTrue);
      expect(ComplexNumber.i.isPurelyImaginary, isTrue);
      expect(ComplexNumber.i.toString(), equals('i'));

      final minusI = -ComplexNumber.i;
      expect(minusI.toString(), equals('-i'));
    });

    test('Conjugate and negation', () {
      final z = ComplexNumber.fromInts(3, -4);
      expect(z.toString(), equals('3 - 4i'));

      final conj = z.conjugate();
      expect(conj, equals(ComplexNumber.fromInts(3, 4)));

      final neg = -z;
      expect(neg, equals(ComplexNumber.fromInts(-3, 4)));
    });

    test('Equality and hashCode', () {
      final z1 = ComplexNumber.fromInts(2, 5);
      final z2 = ComplexNumber(
        real: DecimalValue.parse('2.00'),
        imaginary: DecimalValue.parse('5.0'),
      );

      expect(z1, equals(z2));
      expect(z1.hashCode, equals(z2.hashCode));
    });
  });
}
