import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('IntegerValue Unit Tests', () {
    test('Constructors and factory methods', () {
      final a = IntegerValue(BigInt.from(42));
      final b = IntegerValue.fromInt(42);
      final c = IntegerValue.parse('42');
      final d = IntegerValue.tryParse('42');

      expect(a, equals(b));
      expect(b, equals(c));
      expect(c, equals(d));
      expect(a.value, equals(BigInt.from(42)));
    });

    test('Zero, positive, negative, signum', () {
      expect(IntegerValue.zero.isZero, isTrue);
      expect(IntegerValue.one.isPositive, isTrue);
      expect(IntegerValue.minusOne.isNegative, isTrue);
      expect(IntegerValue.one.signum, equals(1));
      expect(IntegerValue.minusOne.signum, equals(-1));
      expect(IntegerValue.zero.signum, equals(0));
    });

    test('Parity checks', () {
      expect(IntegerValue.fromInt(4).isEven, isTrue);
      expect(IntegerValue.fromInt(4).isOdd, isFalse);
      expect(IntegerValue.fromInt(5).isEven, isFalse);
      expect(IntegerValue.fromInt(5).isOdd, isTrue);
    });

    test('Negation and absolute value', () {
      final pos = IntegerValue.fromInt(10);
      final neg = IntegerValue.fromInt(-10);

      expect(-pos, equals(neg));
      expect(-neg, equals(pos));
      expect(neg.abs(), equals(pos));
      expect(pos.abs(), equals(pos));
    });

    test('Arbitrary precision without 64-bit overflow', () {
      const hugeStr = '1234567890123456789012345678901234567890';
      final huge = IntegerValue.parse(hugeStr);

      expect(huge.value.toString(), equals(hugeStr));
      expect(huge.toString(), equals(hugeStr));
    });

    test('Comparison and ordering', () {
      final a = IntegerValue.fromInt(10);
      final b = IntegerValue.fromInt(20);
      final c = IntegerValue.fromInt(10);

      expect(a.compareTo(b), isNegative);
      expect(b.compareTo(a), isPositive);
      expect(a.compareTo(c), equals(0));
    });
  });
}
