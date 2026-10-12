import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';

void main() {
  group('DecimalValue Unit Tests', () {
    test('Constructors and string parsing', () {
      final d1 = DecimalValue(BigInt.from(1234), 2);
      expect(d1.toString(), equals('12.34'));

      final d2 = DecimalValue.parse('12.34');
      expect(d1, equals(d2));

      final d3 = DecimalValue.parse('-0.005');
      expect(d3.toString(), equals('-0.005'));
      expect(d3.scale, equals(3));
      expect(d3.unscaledValue, equals(BigInt.from(-5)));

      final d4 = DecimalValue.parse('42');
      expect(d4.toString(), equals('42'));
      expect(d4.scale, equals(0));
    });

    test('Scientific notation parsing', () {
      final sci1 = DecimalValue.parse('1.25e2');
      expect(sci1, equals(DecimalValue.parse('125')));

      final sci2 = DecimalValue.parse('5e-3');
      expect(sci2, equals(DecimalValue.parse('0.005')));
    });

    test('Normalization strips trailing fractional zeroes', () {
      final d = DecimalValue.parse('1.500');
      final norm = d.normalize();
      expect(norm.toString(), equals('1.5'));
      expect(norm.scale, equals(1));
      expect(d, equals(norm));
    });

    test('Mathematical equality regardless of scale representation', () {
      final a = DecimalValue.parse('2.5');
      final b = DecimalValue.parse('2.500');
      final c = DecimalValue.parse('2.50000');

      expect(a, equals(b));
      expect(b, equals(c));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.compareTo(b), equals(0));
    });

    test('Conversion to FractionValue', () {
      final d = DecimalValue.parse('0.75');
      final frac = d.toFraction();
      expect(frac, equals(FractionValue.fromInts(3, 4)));

      final whole = DecimalValue.parse('42');
      expect(whole.toFraction(), equals(FractionValue.fromInts(42, 1)));
    });

    test('Rounding to PrecisionContext', () {
      final d = DecimalValue.parse('1.234567');
      const ctx = PrecisionContext(
        precisionDigits: 4,
        roundingMode: RoundingMode.halfUp,
      );

      final rounded = d.roundToPrecision(ctx);
      // 1.234567 -> 4 significant digits -> 1.235
      expect(rounded.toString(), equals('1.235'));
    });

    test('Bankers rounding (halfEven)', () {
      const ctx = PrecisionContext(
        precisionDigits: 2,
        roundingMode: RoundingMode.halfEven,
      );

      // 1.25 -> 1.2 (even neighbor)
      final r1 = DecimalValue.parse('1.25').roundToPrecision(ctx);
      expect(r1.toString(), equals('1.2'));

      // 1.35 -> 1.4 (even neighbor)
      final r2 = DecimalValue.parse('1.35').roundToPrecision(ctx);
      expect(r2.toString(), equals('1.4'));

      // Negative values bankers rounding
      // -1.25 -> -1.2
      final rNeg1 = DecimalValue.parse('-1.25').roundToPrecision(ctx);
      expect(rNeg1.toString(), equals('-1.2'));

      // -1.35 -> -1.4
      final rNeg2 = DecimalValue.parse('-1.35').roundToPrecision(ctx);
      expect(rNeg2.toString(), equals('-1.4'));
    });

    test('All rounding modes on positive and negative values', () {
      const upCtx = PrecisionContext(
        precisionDigits: 2,
        roundingMode: RoundingMode.up,
      );
      const downCtx = PrecisionContext(
        precisionDigits: 2,
        roundingMode: RoundingMode.down,
      );
      const ceilCtx = PrecisionContext(
        precisionDigits: 2,
        roundingMode: RoundingMode.ceiling,
      );
      const floorCtx = PrecisionContext(
        precisionDigits: 2,
        roundingMode: RoundingMode.floor,
      );

      // Positive 1.21 -> 2 digits
      expect(
        DecimalValue.parse('1.21').roundToPrecision(upCtx).toString(),
        equals('1.3'),
      );
      expect(
        DecimalValue.parse('1.21').roundToPrecision(downCtx).toString(),
        equals('1.2'),
      );
      expect(
        DecimalValue.parse('1.21').roundToPrecision(ceilCtx).toString(),
        equals('1.3'),
      );
      expect(
        DecimalValue.parse('1.21').roundToPrecision(floorCtx).toString(),
        equals('1.2'),
      );

      // Negative -1.21 -> 2 digits
      expect(
        DecimalValue.parse('-1.21').roundToPrecision(upCtx).toString(),
        equals('-1.3'),
      );
      expect(
        DecimalValue.parse('-1.21').roundToPrecision(downCtx).toString(),
        equals('-1.2'),
      );
      expect(
        DecimalValue.parse('-1.21').roundToPrecision(ceilCtx).toString(),
        equals('-1.2'),
      );
      expect(
        DecimalValue.parse('-1.21').roundToPrecision(floorCtx).toString(),
        equals('-1.3'),
      );
    });
  });
}
