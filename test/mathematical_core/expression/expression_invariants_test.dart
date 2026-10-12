import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('ExpressionEngine Mathematical Invariant & Property Tests', () {
    final engine = ExpressionEngine();

    test(
      'Associativity and precedence consistency: a - b - c == (a - b) - c',
      () {
        final leftAssociative = engine.evaluate('10 - 5 - 2').valueOrNull!;
        final explicitGroup = engine.evaluate('(10 - 5) - 2').valueOrNull!;
        final rightGroup = engine.evaluate('10 - (5 - 2)').valueOrNull!;

        expect(leftAssociative, equals(IntegerValue.fromInt(3)));
        expect(leftAssociative, equals(explicitGroup));
        expect(leftAssociative, isNot(equals(rightGroup))); // 3 != 7
      },
    );

    test('Power right-associativity: a ^ b ^ c == a ^ (b ^ c)', () {
      final rightAssoc = engine.evaluate('2 ^ 3 ^ 2').valueOrNull!;
      final explicitRight = engine.evaluate('2 ^ (3 ^ 2)').valueOrNull!;
      final explicitLeft = engine.evaluate('(2 ^ 3) ^ 2').valueOrNull!;

      // 2 ^ (9) = 512
      expect(rightAssoc, equals(IntegerValue.fromInt(512)));
      expect(rightAssoc, equals(explicitRight));
      // (8) ^ 2 = 64
      expect(rightAssoc, isNot(equals(explicitLeft)));
    });

    test('Deterministic evaluation across repeated runs', () {
      const expr = '3 * sin(0) + cos(0) * 5! / 10 + 2^4';
      final run1 = engine.evaluate(expr).valueOrNull!;
      final run2 = engine.evaluate(expr).valueOrNull!;
      final run3 = engine.evaluate(expr).valueOrNull!;

      expect(run1, equals(run2));
      expect(run2, equals(run3));
    });

    test(
      'Exactness preservation: rational arithmetic does not become double',
      () {
        // 1/3 + 1/6 = 3/6 = 1/2
        final res = engine.evaluate('1/3 + 1/6');
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull, equals(FractionValue.fromInts(1, 2)));

        // 1/4 * 2/5 = 2/20 = 1/10
        final multRes = engine.evaluate('(1/4) * (2/5)');
        expect(multRes.isSuccess, isTrue);
        expect(multRes.valueOrNull, equals(FractionValue.fromInts(1, 10)));
      },
    );

    test('High precision context override in evaluation', () {
      const ctx = EvaluationContext(precision: PrecisionContext.highPrecision);
      final piEval = engine.evaluate('pi + 0', context: ctx);
      expect(piEval.isSuccess, isTrue);
      expect(piEval.valueOrNull, isA<DecimalValue>());
      expect(piEval.valueOrNull.toString().length, greaterThan(30));
    });
  });
}
