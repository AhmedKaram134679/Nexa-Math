import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/common/angle_mode.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('AstEvaluator & ExpressionEngine Evaluation Tests', () {
    final engine = ExpressionEngine();

    test('Basic arithmetic evaluation', () {
      final res1 = engine.evaluate('2 + 3');
      expect(res1.isSuccess, isTrue);
      expect(res1.valueOrNull, equals(IntegerValue.fromInt(5)));

      final res2 = engine.evaluate('10 - 4');
      expect(res2.isSuccess, isTrue);
      expect(res2.valueOrNull, equals(IntegerValue.fromInt(6)));

      final res3 = engine.evaluate('6 * 7');
      expect(res3.isSuccess, isTrue);
      expect(res3.valueOrNull, equals(IntegerValue.fromInt(42)));

      // Exact integer division: 20 / 4 = 5 (canonical integer)
      final res4 = engine.evaluate('20 / 4');
      expect(res4.isSuccess, isTrue);
      expect(res4.valueOrNull, equals(IntegerValue.fromInt(5)));

      // Non-integer fraction division: 20 / 6 = 10/3
      final res4Frac = engine.evaluate('20 / 6');
      expect(res4Frac.isSuccess, isTrue);
      expect(res4Frac.valueOrNull, equals(FractionValue.fromInts(10, 3)));

      // Exact integer power: 2 ^ 10 = 1024
      final res5 = engine.evaluate('2 ^ 10');
      expect(res5.isSuccess, isTrue);
      expect(res5.valueOrNull, equals(IntegerValue.fromInt(1024)));

      // Negative exponent produces exact Fraction: 2 ^ -1 = 1/2
      final res6 = engine.evaluate('2 ^ -1');
      expect(res6.isSuccess, isTrue);
      expect(res6.valueOrNull, equals(FractionValue.fromInts(1, 2)));
    });

    test('Precedence and parenthesized grouping evaluation', () {
      // 2 + 3 * 4 = 14
      final res1 = engine.evaluate('2 + 3 * 4');
      expect(res1.isSuccess, isTrue);
      expect(res1.valueOrNull, equals(IntegerValue.fromInt(14)));

      // (2 + 3) * 4 = 20
      final res2 = engine.evaluate('(2 + 3) * 4');
      expect(res2.isSuccess, isTrue);
      expect(res2.valueOrNull, equals(IntegerValue.fromInt(20)));

      // 2 * (3 + 4)^2 = 2 * 49 = 98
      final res3 = engine.evaluate('2 * (3 + 4)^2');
      expect(res3.isSuccess, isTrue);
      expect(res3.valueOrNull, equals(IntegerValue.fromInt(98)));
    });

    test('Factorial evaluation', () {
      // 5! = 120
      final res = engine.evaluate('5!');
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(IntegerValue.fromInt(120)));

      // 3! + 4! = 6 + 24 = 30
      final res2 = engine.evaluate('3! + 4!');
      expect(res2.isSuccess, isTrue);
      expect(res2.valueOrNull, equals(IntegerValue.fromInt(30)));
    });

    test('Modulo operator evaluation', () {
      final res = engine.evaluate('17 % 5');
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(IntegerValue.fromInt(2)));
    });

    test('Constants: pi, e, phi', () {
      final piRes = engine.evaluate('pi');
      expect(piRes.isSuccess, isTrue);
      expect(piRes.valueOrNull, isA<DecimalValue>());
      expect(piRes.valueOrNull.toString().startsWith('3.14159265'), isTrue);

      final eRes = engine.evaluate('e');
      expect(eRes.isSuccess, isTrue);
      expect(eRes.valueOrNull.toString().startsWith('2.71828182'), isTrue);
    });

    test('Variables resolution from EvaluationContext', () {
      final ctx = EvaluationContext(
        variables: {
          'x': IntegerValue.fromInt(10),
          'y': DecimalValue.parse('2.5'),
        },
      );

      final res = engine.evaluate('x * y + 5', context: ctx);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(DecimalValue.parse('30')));
    });

    test('Trigonometric functions respecting AngleMode', () {
      // sin(90) in degrees = 1
      const degCtx = EvaluationContext(angleMode: AngleMode.degrees);
      final sin90 = engine.evaluate('sin(90)', context: degCtx);
      expect(sin90.isSuccess, isTrue);
      expect(sin90.valueOrNull, equals(DecimalValue.parse('1')));

      // cos(0) in radians = 1
      const radCtx = EvaluationContext(angleMode: AngleMode.radians);
      final cos0 = engine.evaluate('cos(0)', context: radCtx);
      expect(cos0.isSuccess, isTrue);
      expect(cos0.valueOrNull, equals(DecimalValue.parse('1')));
    });

    test('Built-in functions: sqrt, ln, gcd, nCr', () {
      final sqrtRes = engine.evaluate('sqrt(16)');
      expect(sqrtRes.isSuccess, isTrue);
      expect(sqrtRes.valueOrNull, equals(DecimalValue.parse('4')));

      final gcdRes = engine.evaluate('gcd(24, 36)');
      expect(gcdRes.isSuccess, isTrue);
      expect(gcdRes.valueOrNull, equals(IntegerValue.fromInt(12)));

      final ncrRes = engine.evaluate('nCr(5, 2)');
      expect(ncrRes.isSuccess, isTrue);
      expect(ncrRes.valueOrNull, equals(IntegerValue.fromInt(10)));
    });

    test('Mathematical error propagation: division by zero, domain error, unknown identifier', () {
      final divZero = engine.evaluate('10 / 0');
      expect(divZero.isFailure, isTrue);
      expect(divZero.errorOrNull, isA<DivisionByZeroError>());

      final sqrtNeg = engine.evaluate('sqrt(-9)');
      expect(sqrtNeg.isFailure, isTrue);
      expect(sqrtNeg.errorOrNull, isA<DomainError>());

      final unknownVar = engine.evaluate('foo + 1');
      expect(unknownVar.isFailure, isTrue);
      expect(unknownVar.errorOrNull, isA<UnknownIdentifierError>());

      final unknownFn = engine.evaluate('unknownFunc(10)');
      expect(unknownFn.isFailure, isTrue);
      expect(unknownFn.errorOrNull, isA<UnknownFunctionError>());
    });

    test(
      'Audit Area B Evaluation: Unary minus and exponentiation interactions',
      () {
        // -2^2 = -(2^2) = -4
        final res1 = engine.evaluate('-2^2');
        expect(res1.isSuccess, isTrue);
        expect(res1.valueOrNull, equals(IntegerValue.fromInt(-4)));

        // (-2)^2 = 4
        final res2 = engine.evaluate('(-2)^2');
        expect(res2.isSuccess, isTrue);
        expect(res2.valueOrNull, equals(IntegerValue.fromInt(4)));

        // -(2^2) = -4
        final res3 = engine.evaluate('-(2^2)');
        expect(res3.isSuccess, isTrue);
        expect(res3.valueOrNull, equals(IntegerValue.fromInt(-4)));

        // 2^-2 = 1/4 (exact Fraction)
        final res4 = engine.evaluate('2^-2');
        expect(res4.isSuccess, isTrue);
        expect(res4.valueOrNull, equals(FractionValue.fromInts(1, 4)));

        // 2^(-2) = 1/4 (exact Fraction)
        final res5 = engine.evaluate('2^(-2)');
        expect(res5.isSuccess, isTrue);
        expect(res5.valueOrNull, equals(FractionValue.fromInts(1, 4)));

        // -2^3 = -(2^3) = -8
        final res6 = engine.evaluate('-2^3');
        expect(res6.isSuccess, isTrue);
        expect(res6.valueOrNull, equals(IntegerValue.fromInt(-8)));

        // (-2)^3 = -8
        final res7 = engine.evaluate('(-2)^3');
        expect(res7.isSuccess, isTrue);
        expect(res7.valueOrNull, equals(IntegerValue.fromInt(-8)));

        // -(2^3) = -8
        final res8 = engine.evaluate('-(2^3)');
        expect(res8.isSuccess, isTrue);
        expect(res8.valueOrNull, equals(IntegerValue.fromInt(-8)));
      },
    );

    test(
      'Audit Area C Evaluation: Factorial interactions and domain bounds',
      () {
        // -3! = -(3!) = -6
        final res1 = engine.evaluate('-3!');
        expect(res1.isSuccess, isTrue);
        expect(res1.valueOrNull, equals(IntegerValue.fromInt(-6)));

        // (-3)! -> DomainError (factorial undefined for negative values)
        final res2 = engine.evaluate('(-3)!');
        expect(res2.isFailure, isTrue);
        expect(res2.errorOrNull, isA<DomainError>());

        // 3!! = (3!)! = 6! = 720
        final res3 = engine.evaluate('3!!');
        expect(res3.isSuccess, isTrue);
        expect(res3.valueOrNull, equals(IntegerValue.fromInt(720)));

        // 2 * 3! = 2 * 6 = 12
        final res4 = engine.evaluate('2 * 3!');
        expect(res4.isSuccess, isTrue);
        expect(res4.valueOrNull, equals(IntegerValue.fromInt(12)));

        // (2 + 3)! = 5! = 120
        final res5 = engine.evaluate('(2 + 3)!');
        expect(res5.isSuccess, isTrue);
        expect(res5.valueOrNull, equals(IntegerValue.fromInt(120)));
      },
    );

    test(
      'Audit Area D Evaluation: Implicit multiplication numerical results',
      () {
        final ctx = EvaluationContext(
          variables: {'x': IntegerValue.fromInt(3)},
        );

        // 2x = 2 * 3 = 6
        expect(
          engine.evaluate('2x', context: ctx).valueOrNull,
          equals(IntegerValue.fromInt(6)),
        );

        // 3(4) = 12
        expect(
          engine.evaluate('3(4)').valueOrNull,
          equals(IntegerValue.fromInt(12)),
        );

        // (2 + 3)(4 + 5) = 5 * 9 = 45
        expect(
          engine.evaluate('(2 + 3)(4 + 5)').valueOrNull,
          equals(IntegerValue.fromInt(45)),
        );

        // 2(x + 1)^2 = 2 * 4^2 = 32
        expect(
          engine.evaluate('2(x + 1)^2', context: ctx).valueOrNull,
          equals(IntegerValue.fromInt(32)),
        );

        // 2x^2 = 2 * 3^2 = 18
        expect(
          engine.evaluate('2x^2', context: ctx).valueOrNull,
          equals(IntegerValue.fromInt(18)),
        );

        // 2x/3 = (2 * 3) / 3 = 2
        expect(
          engine.evaluate('2x/3', context: ctx).valueOrNull,
          equals(IntegerValue.fromInt(2)),
        );

        // 2/3x with x=3: 2 / (3 * 3) = 2/9 (exact Fraction)
        expect(
          engine.evaluate('2/3x', context: ctx).valueOrNull,
          equals(FractionValue.fromInts(2, 9)),
        );

        // -2x = -6
        expect(
          engine.evaluate('-2x', context: ctx).valueOrNull,
          equals(IntegerValue.fromInt(-6)),
        );
      },
    );

    test(
      'Audit Area G Evaluation: Trigonometric angle modes and approximations',
      () {
        // sin(90) in degrees = 1
        const degCtx = EvaluationContext(angleMode: AngleMode.degrees);
        final sin90 = engine.evaluate('sin(90)', context: degCtx);
        expect(sin90.isSuccess, isTrue);
        expect(sin90.valueOrNull, equals(DecimalValue.parse('1')));
        expect(
          sin90.metadata.isExact,
          isFalse,
        ); // Trigonometric results are flagged approximate

        // asin(1) in degrees = 90
        final asin1 = engine.evaluate('asin(1)', context: degCtx);
        expect(asin1.isSuccess, isTrue);
        expect(asin1.valueOrNull, equals(DecimalValue.parse('90')));

        // sin(pi / 2) in radians with 64-digit pi approximation: evaluates to approximate 1
        const radCtx = EvaluationContext(angleMode: AngleMode.radians);
        final sinPiOver2 = engine.evaluate('sin(pi / 2)', context: radCtx);
        expect(sinPiOver2.isSuccess, isTrue);
        expect(sinPiOver2.valueOrNull, equals(DecimalValue.parse('1')));
        expect(sinPiOver2.metadata.isExact, isFalse);

        // sin(100) in gradians = 1
        const gradCtx = EvaluationContext(angleMode: AngleMode.gradians);
        final sin100 = engine.evaluate('sin(100)', context: gradCtx);
        expect(sin100.isSuccess, isTrue);
        expect(sin100.valueOrNull, equals(DecimalValue.parse('1')));
      },
    );

    test('Audit Area H & I: Function Registry arity, domain errors, and new aliases', () {
      // Arity checks
      expect(engine.evaluate('sin()').isFailure, isTrue);
      expect(engine.evaluate('sin()').errorOrNull, isA<InvalidArgumentError>());

      expect(engine.evaluate('nCr(5)').isFailure, isTrue);
      expect(
        engine.evaluate('nCr(5)').errorOrNull,
        isA<InvalidArgumentError>(),
      );

      expect(engine.evaluate('gcd(12)').isFailure, isTrue);
      expect(
        engine.evaluate('gcd(12)').errorOrNull,
        isA<InvalidArgumentError>(),
      );

      // Domain errors
      expect(engine.evaluate('ln(-1)').isFailure, isTrue);
      expect(engine.evaluate('ln(-1)').errorOrNull, isA<DomainError>());

      expect(engine.evaluate('log(-1)').isFailure, isTrue);
      expect(engine.evaluate('log(-1)').errorOrNull, isA<DomainError>());

      expect(engine.evaluate('log10(-1)').isFailure, isTrue);
      expect(engine.evaluate('log10(-1)').errorOrNull, isA<DomainError>());

      expect(engine.evaluate('log2(-1)').isFailure, isTrue);
      expect(engine.evaluate('log2(-1)').errorOrNull, isA<DomainError>());

      // Log10 and Log2 evaluations
      expect(
        engine.evaluate('log10(100)').valueOrNull,
        equals(DecimalValue.parse('2')),
      );
      expect(
        engine.evaluate('log2(8)').valueOrNull,
        equals(DecimalValue.parse('3')),
      );
    });

    test('Audit Area J: Modulo operator negative and zero semantics', () {
      // 17 % 5 = 2
      expect(
        engine.evaluate('17 % 5').valueOrNull,
        equals(IntegerValue.fromInt(2)),
      );

      // -17 % 5 in Dart BigInt remainder semantics: -17 % 5 = 3 (standard modulo) or -2?
      // In Dart: -17 % 5 is 3 (Euclidean/floored modulo: -17 = (-4)*5 + 3)
      expect(
        engine.evaluate('-17 % 5').valueOrNull,
        equals(IntegerValue.fromInt(3)),
      );

      // Modulo by zero produces DivisionByZeroError
      final modZero = engine.evaluate('10 % 0');
      expect(modZero.isFailure, isTrue);
      expect(modZero.errorOrNull, isA<DivisionByZeroError>());

      // Non-integer modulo produces DomainError
      final nonIntMod = engine.evaluate('10.5 % 2');
      expect(nonIntMod.isFailure, isTrue);
      expect(nonIntMod.errorOrNull, isA<DomainError>());
    });
  });
}
