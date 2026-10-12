import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/mathematical_core.dart';

void main() {
  group('Mathematical Core Context Contracts Tests', () {
    test('AngleMode contains degrees, radians, and gradians', () {
      expect(
        AngleMode.values,
        containsAll([AngleMode.degrees, AngleMode.radians, AngleMode.gradians]),
      );
    });

    test('PrecisionContext defaults and equality', () {
      const precision = PrecisionContext.standard;
      expect(precision.precisionDigits, equals(34));
      expect(precision.roundingMode, equals(RoundingMode.halfEven));
      expect(precision.zeroTolerance, equals(1e-15));

      const highPrecision = PrecisionContext.highPrecision;
      expect(highPrecision.precisionDigits, equals(64));
    });

    test('NumericSettings defaults and display notation', () {
      const settings = NumericSettings.standard;
      expect(settings.precision, equals(34));
      expect(settings.notation, equals(DisplayNotation.standard));
      expect(settings.engineeringNotation, isFalse);
    });

    test('EvaluationContext and MathContext composition', () {
      const eval = EvaluationContext(
        angleMode: AngleMode.degrees,
        precision: PrecisionContext.standard,
      );
      expect(eval.angleMode, equals(AngleMode.degrees));

      final copy = eval.copyWith(angleMode: AngleMode.radians);
      expect(copy.angleMode, equals(AngleMode.radians));

      const mathCtx = MathContext(evaluation: eval);
      expect(mathCtx.evaluation.angleMode, equals(AngleMode.degrees));
    });
  });
}
