import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('FractionValue Unit Tests', () {
    test('Canonical irreducible normalization', () {
      final f1 = FractionValue(BigInt.from(6), BigInt.from(8));
      expect(f1.numerator, equals(BigInt.from(3)));
      expect(f1.denominator, equals(BigInt.from(4)));
      expect(f1.toString(), equals('3/4'));

      final f2 = FractionValue(BigInt.from(-10), BigInt.from(20));
      expect(f2.numerator, equals(BigInt.from(-1)));
      expect(f2.denominator, equals(BigInt.from(2)));
      expect(f2.toString(), equals('-1/2'));

      // Sign normalization with negative denominator
      final f3 = FractionValue(BigInt.from(5), BigInt.from(-15));
      expect(f3.numerator, equals(BigInt.from(-1)));
      expect(f3.denominator, equals(BigInt.from(3)));
    });

    test('Zero fraction normalization', () {
      final z = FractionValue(BigInt.zero, BigInt.from(999));
      expect(z.numerator, equals(BigInt.zero));
      expect(z.denominator, equals(BigInt.one));
      expect(z.isZero, isTrue);
      expect(z.toString(), equals('0'));
    });

    test('Zero denominator throws ArgumentError', () {
      expect(
        () => FractionValue(BigInt.one, BigInt.zero),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Proper and integer checks', () {
      final proper = FractionValue.fromInts(3, 4);
      final improper = FractionValue.fromInts(7, 4);
      final whole = FractionValue.fromInts(8, 4);

      expect(proper.isProper, isTrue);
      expect(improper.isProper, isFalse);
      expect(whole.isInteger, isTrue);
      expect(whole.toIntegerValueOrNull(), equals(IntegerValue.fromInt(2)));
    });

    test('Reciprocal, negation, absolute value', () {
      final f = FractionValue.fromInts(2, 5);

      expect(f.reciprocal(), equals(FractionValue.fromInts(5, 2)));
      expect(-f, equals(FractionValue.fromInts(-2, 5)));
      expect((-f).abs(), equals(f));
    });

    test('Comparison and equality', () {
      final f1 = FractionValue.fromInts(1, 2);
      final f2 = FractionValue.fromInts(2, 4);
      final f3 = FractionValue.fromInts(3, 4);

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1.compareTo(f3), isNegative);
      expect(f3.compareTo(f1), isPositive);
    });

    test('Parsing valid and invalid strings', () {
      expect(FractionValue.parse('3/4'), equals(FractionValue.fromInts(3, 4)));
      expect(FractionValue.parse('5'), equals(FractionValue.fromInts(5, 1)));
      expect(FractionValue.tryParse('invalid'), isNull);
    });
  });
}
