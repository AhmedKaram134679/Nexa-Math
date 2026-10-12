import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/expression/evaluator/ast_evaluator.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/symbolic/canonicalization/symbolic_canonicalizer.dart';
import 'package:nexa_math/mathematical_core/symbolic/models/symbolic_expression.dart';
import 'package:nexa_math/mathematical_core/symbolic/simplification/symbolic_simplifier.dart';

void main() {
  group('SymbolicSimplifier & SymbolicCanonicalizer Tests', () {
    final simplifier = DefaultSymbolicSimplifier();
    final canonicalizer = DefaultSymbolicCanonicalizer();

    test('Identity elimination: x + 0 -> x, 0 + x -> x', () {
      final x = SymbolicExpression.variable('x');
      final zero = SymbolicExpression.integer(0);

      final res1 = simplifier.simplify((x + zero).node);
      final res2 = simplifier.simplify((zero + x).node);

      expect(res1.valueOrNull, equals(x.node));
      expect(res2.valueOrNull, equals(x.node));
    });

    test('Multiplicative identity: x * 1 -> x, 1 * x -> x', () {
      final x = SymbolicExpression.variable('x');
      final one = SymbolicExpression.integer(1);

      final res1 = simplifier.simplify((x * one).node);
      final res2 = simplifier.simplify((one * x).node);

      expect(res1.valueOrNull, equals(x.node));
      expect(res2.valueOrNull, equals(x.node));
    });

    test('Zero multiplication: x * 0 -> 0, 0 * x -> 0', () {
      final x = SymbolicExpression.variable('x');
      final zero = SymbolicExpression.integer(0);

      final res1 = simplifier.simplify((x * zero).node);
      final res2 = simplifier.simplify((zero * x).node);

      expect(res1.valueOrNull, equals(zero.node));
      expect(res2.valueOrNull, equals(zero.node));
    });

    test('Like term collection: x + x -> 2*x', () {
      final x = SymbolicExpression.variable('x');
      final res = simplifier.simplify((x + x).node);

      expect(res.valueOrNull.toString(), contains('2'));
      expect(res.valueOrNull.toString(), contains('x'));
    });

    test('Power rules: x^1 -> x, 1^x -> 1', () {
      final x = SymbolicExpression.variable('x');
      final one = SymbolicExpression.integer(1);

      final res1 = simplifier.simplify(x.power(one).node);
      final res2 = simplifier.simplify(one.power(x).node);

      expect(res1.valueOrNull, equals(x.node));
      expect(res2.valueOrNull, equals(one.node));
    });

    test('Power product collection: x^2 * x^3 -> x^5', () {
      final x = SymbolicExpression.variable('x');
      final two = SymbolicExpression.integer(2);
      final three = SymbolicExpression.integer(3);

      final prod = x.power(two) * x.power(three);
      final res = simplifier.simplify(prod.node);

      expect(res.valueOrNull.toString(), contains('x'));
      expect(res.valueOrNull.toString(), contains('5'));
    });

    test(
      'Power product collection with implicit exponent 1: x * x^4 -> x^5',
      () {
        final x = SymbolicExpression.variable('x');
        final four = SymbolicExpression.integer(4);

        final prod = x * x.power(four);
        final res = simplifier.simplify(prod.node);

        expect(res.valueOrNull.toString(), contains('x'));
        expect(res.valueOrNull.toString(), contains('5'));
      },
    );

    test('Power of power: (x^2)^3 -> x^6', () {
      final x = SymbolicExpression.variable('x');
      final two = SymbolicExpression.integer(2);
      final three = SymbolicExpression.integer(3);

      final pow = x.power(two).power(three);
      final res = simplifier.simplify(pow.node);

      expect(res.valueOrNull.toString(), contains('x'));
      expect(res.valueOrNull.toString(), contains('6'));
    });

    test('Domain safety: preserves 0^0 without rewrite', () {
      final zero = SymbolicExpression.integer(0);
      final pow00 = zero.power(zero);
      final res = simplifier.simplify(pow00.node);

      // Must remain 0^0, NOT reduced to 1 or 0
      expect(res.valueOrNull, equals(pow00.node));
    });

    test('Domain safety: preserves variable division x / x without blind reduction to 1', () {
      final x = SymbolicExpression.variable('x');
      final quot = x / x;
      final res = simplifier.simplify(quot.node);

      // Must NOT blindly rewrite x/x -> 1 since x could be 0
      expect(res.valueOrNull, equals(quot.node));
    });

    test('Canonicalizer normalizes commutative sum: 3 + x -> x + 3', () {
      final x = SymbolicExpression.variable('x');
      final three = SymbolicExpression.integer(3);

      final sum1 = x + three;
      final sum2 = three + x;

      final canon1 = canonicalizer.canonicalize(sum1.node);
      final canon2 = canonicalizer.canonicalize(sum2.node);

      expect(canon1.valueOrNull, equals(canon2.valueOrNull));
    });

    test('Canonicalizer normalizes commutative product: 4 * x -> 4 * x', () {
      final x = SymbolicExpression.variable('x');
      final four = SymbolicExpression.integer(4);

      final prod1 = x * four;
      final prod2 = four * x;

      final canon1 = canonicalizer.canonicalize(prod1.node);
      final canon2 = canonicalizer.canonicalize(prod2.node);

      expect(canon1.valueOrNull, equals(canon2.valueOrNull));
    });

    test('Canonicalizer idempotence: canonicalize(canonicalize(e)) == canonicalize(e)', () {
      final x = SymbolicExpression.variable('x');
      final y = SymbolicExpression.variable('y');
      final z = SymbolicExpression.variable('z');
      final three = SymbolicExpression.integer(3);

      final expr = ((three + y) + (x + z)) * (y + x);
      final c1 = canonicalizer.canonicalize(expr.node).valueOrNull!;
      final c2 = canonicalizer.canonicalize(c1).valueOrNull!;

      expect(c1, equals(c2));
    });

    test('Associative normalization: (x + y) + z == x + (y + z)', () {
      final x = SymbolicExpression.variable('x');
      final y = SymbolicExpression.variable('y');
      final z = SymbolicExpression.variable('z');

      final a1 = (x + y) + z;
      final a2 = x + (y + z);

      final c1 = canonicalizer.canonicalize(a1.node).valueOrNull!;
      final c2 = canonicalizer.canonicalize(a2.node).valueOrNull!;

      expect(c1, equals(c2));
    });

    test('Associative product normalization: (x * y) * z == x * (y * z)', () {
      final x = SymbolicExpression.variable('x');
      final y = SymbolicExpression.variable('y');
      final z = SymbolicExpression.variable('z');

      final m1 = (x * y) * z;
      final m2 = x * (y * z);

      final c1 = canonicalizer.canonicalize(m1.node).valueOrNull!;
      final c2 = canonicalizer.canonicalize(m2.node).valueOrNull!;

      expect(c1, equals(c2));
    });

    test('Domain safety: sqrt(x^2) is NOT reduced to x', () {
      final x = SymbolicExpression.variable('x');
      final xSq = x.power(SymbolicExpression.integer(2));
      final sqrtExpr = SymbolicExpression.function('sqrt', [xSq]);

      final res = simplifier.simplify(sqrtExpr.node);
      // Must preserve sqrt(x^2) without unconditionally transforming to x
      expect(res.valueOrNull, equals(sqrtExpr.node));
    });

    test('Domain safety: unrestricted symbolic exponents on variable base are preserved: x^a * x^b', () {
      final x = SymbolicExpression.variable('x');
      final a = SymbolicExpression.variable('a');
      final b = SymbolicExpression.variable('b');

      final prod = x.power(a) * x.power(b);
      final res = simplifier.simplify(prod.node);

      // Must be preserved because a and b could evaluate to negative values (e.g. a = -1, b = 2)
      expect(res.valueOrNull, equals(prod.node));
    });

    test('Domain safety: mixed symbolic and numeric exponent on variable base is preserved: x^a * x^2', () {
      final x = SymbolicExpression.variable('x');
      final a = SymbolicExpression.variable('a');
      final two = SymbolicExpression.integer(2);

      final prod = x.power(a) * x.power(two);
      final res = simplifier.simplify(prod.node);

      // Must be preserved because a could evaluate to a negative value
      expect(res.valueOrNull, equals(prod.node));
    });

    test('Domain safety: symbolic inverse on variable base is preserved: x^a * x^-a', () {
      final x = SymbolicExpression.variable('x');
      final a = SymbolicExpression.variable('a');
      final negA = -a;

      final prod = x.power(a) * x.power(negA);
      final res = simplifier.simplify(prod.node);

      // Must be preserved because x = 0 is undefined if a != 0
      expect(res.valueOrNull, equals(prod.node));
    });

    test('Proven non-zero base allows symbolic exponent combination: 2^a * 2^b -> 2^(a+b)', () {
      final two = SymbolicExpression.integer(2);
      final a = SymbolicExpression.variable('a');
      final b = SymbolicExpression.variable('b');

      final prod = two.power(a) * two.power(b);
      final res = simplifier.simplify(prod.node);

      final symExpr = SymbolicExpression(res.valueOrNull!);
      expect(symExpr.toString(), contains('2'));
      expect(symExpr.toString(), contains('a + b'));
    });

    test('Domain safety: negative exponent power product on variable base is preserved to protect x=0', () {
      final x = SymbolicExpression.variable('x');
      final four = SymbolicExpression.integer(4);
      final two = SymbolicExpression.integer(2);
      final negTwo = SymbolicExpression.integer(-2);

      final prod1 = x.power(four) * x.power(negTwo);
      final res1 = simplifier.simplify(prod1.node);
      // Must NOT reduce to x^2 because 0^-2 is undefined while 0^2 is defined
      expect(res1.valueOrNull, equals(prod1.node));

      final prod2 = x.power(two) * x.power(negTwo);
      final res2 = simplifier.simplify(prod2.node);
      // Must NOT reduce to x^0 or 1 because 0^-2 is undefined
      expect(res2.valueOrNull, equals(prod2.node));
    });

    test('Domain safety: variable product with inverse x * x^-1 is preserved to protect x=0', () {
      final x = SymbolicExpression.variable('x');
      final negOne = SymbolicExpression.integer(-1);

      final prod = x * x.power(negOne);
      final res = simplifier.simplify(prod.node);

      // Must NOT reduce to x^0 or 1 because x=0 is not in domain of x^-1
      expect(res.valueOrNull, equals(prod.node));
    });

    test('Known non-zero base allows negative exponent power combination: 2^4 * 2^-2 -> 4', () {
      final two = SymbolicExpression.integer(2);
      final four = SymbolicExpression.integer(4);
      final negTwo = SymbolicExpression.integer(-2);

      final prod = two.power(four) * two.power(negTwo);
      final res = simplifier.simplify(prod.node);

      final symExpr = SymbolicExpression(res.valueOrNull!);
      // Evaluates to 2^2 and constant-folds to 4
      expect(symExpr.toString(), equals('4'));
    });

    test('Power product of zero base: 0 * 0^2 -> 0 (via zero absorption)', () {
      final zero = SymbolicExpression.integer(0);
      final two = SymbolicExpression.integer(2);

      final prod = zero * zero.power(two);
      final res = simplifier.simplify(prod.node);

      final symExpr = SymbolicExpression(res.valueOrNull!);
      expect(symExpr.toString(), equals('0'));
    });

    test('Domain safety: fractional exponents on variable base are preserved: x^(1/2) * x^(1/2)', () {
      final x = SymbolicExpression.variable('x');
      final half = SymbolicExpression.number(
        FractionValue(BigInt.one, BigInt.two),
      );

      final prod = x.power(half) * x.power(half);
      final res = simplifier.simplify(prod.node);

      // Must NOT combine into x^1 or x because x^(1/2) is undefined for x < 0 in real arithmetic,
      // whereas x^1 is defined on all of R. Preserving ensures domain is not enlarged.
      expect(res.valueOrNull, equals(prod.node));
    });

    test('Domain safety: odd-root fractional exponents on variable base are preserved: x^(1/3) * x^(1/3)', () {
      final x = SymbolicExpression.variable('x');
      final oneThird = SymbolicExpression.number(
        FractionValue(BigInt.one, BigInt.from(3)),
      );

      final prod = x.power(oneThird) * x.power(oneThird);
      final res = simplifier.simplify(prod.node);

      // Must be preserved without assumptions
      expect(res.valueOrNull, equals(prod.node));
    });

    test('Domain safety: rational exponents summing to 1 on variable base are preserved: x^(2/3) * x^(1/3)', () {
      final x = SymbolicExpression.variable('x');
      final twoThirds = SymbolicExpression.number(
        FractionValue(BigInt.two, BigInt.from(3)),
      );
      final oneThird = SymbolicExpression.number(
        FractionValue(BigInt.one, BigInt.from(3)),
      );

      final prod = x.power(twoThirds) * x.power(oneThird);
      final res = simplifier.simplify(prod.node);

      // Must NOT combine to x^1 or x because in NexaMath real power semantics (-8)^(1/3) / (-8)^(2/3)
      // fail with DomainError (fractional powers of negative bases require positive base).
      expect(res.valueOrNull, equals(prod.node));
    });

    test('Domain safety: mixed fractional and integer exponent on variable base is preserved: x^(1/2) * x^2', () {
      final x = SymbolicExpression.variable('x');
      final half = SymbolicExpression.number(
        FractionValue(BigInt.one, BigInt.two),
      );
      final two = SymbolicExpression.integer(2);

      final prod = x.power(half) * x.power(two);
      final res = simplifier.simplify(prod.node);

      expect(res.valueOrNull, equals(prod.node));
    });

    test('Domain safety: 3/2 and 1/2 fractional exponents on variable base are preserved: x^(3/2) * x^(1/2)', () {
      final x = SymbolicExpression.variable('x');
      final threeHalves = SymbolicExpression.number(
        FractionValue(BigInt.from(3), BigInt.two),
      );
      final half = SymbolicExpression.number(
        FractionValue(BigInt.one, BigInt.two),
      );

      final prod = x.power(threeHalves) * x.power(half);
      final res = simplifier.simplify(prod.node);

      // Must NOT combine to x^2 because at x = -1, x^(3/2) is undefined in real semantics
      expect(res.valueOrNull, equals(prod.node));
    });

    test('Proven non-zero positive numeric base allows fractional exponent combination: 4^(1/2) * 4^(1/2) -> 4', () {
      final four = SymbolicExpression.integer(4);
      final half = SymbolicExpression.number(
        FractionValue(BigInt.one, BigInt.two),
      );

      final prod = four.power(half) * four.power(half);
      final res = simplifier.simplify(prod.node);

      final symExpr = SymbolicExpression(res.valueOrNull!);
      // Combines to 4^(1/2 + 1/2) = 4^1 = 4
      expect(symExpr.toString(), equals('4'));
    });

    test('Domain safety: power products with zero exponent on variable base are preserved: x^0 * x^3, x^3 * x^0, x^0 * x^0', () {
      final x = SymbolicExpression.variable('x');
      final zero = SymbolicExpression.integer(0);
      final three = SymbolicExpression.integer(3);

      final prod1 = x.power(zero) * x.power(three);
      final res1 = simplifier.simplify(prod1.node);
      // Must NOT simplify to x^3 because 0^0 is undefined in NexaMath semantics
      expect(res1.valueOrNull, equals(prod1.node));

      final prod2 = x.power(three) * x.power(zero);
      final res2 = simplifier.simplify(prod2.node);
      expect(res2.valueOrNull, equals(prod2.node));

      final prod00 = x.power(zero) * x.power(zero);
      final res00 = simplifier.simplify(prod00.node);
      expect(res00.valueOrNull, equals(prod00.node));

      final prodX0 = x * x.power(zero);
      final resX0 = simplifier.simplify(prodX0.node);
      expect(resX0.valueOrNull, equals(prodX0.node));

      final prod0X = x.power(zero) * x;
      final res0X = simplifier.simplify(prod0X.node);
      expect(res0X.valueOrNull, equals(prod0X.node));

      final pow02 = x.power(zero).power(SymbolicExpression.integer(2));
      final res02 = simplifier.simplify(pow02.node);
      // Exponent 0 * 2 = 0: must remain a zero power of x, NOT simplified to 1
      expect(res02.valueOrNull.toString(), contains('x'));
      expect(res02.valueOrNull.toString(), contains('0'));

      final pow03 = x.power(zero).power(SymbolicExpression.integer(3));
      final res03 = simplifier.simplify(pow03.node);
      expect(res03.valueOrNull.toString(), contains('x'));
      expect(res03.valueOrNull.toString(), contains('0'));
    });

    test('Proven non-zero base allows zero exponent power combinations: 2^0 * 2^3 and 4^0 * 4^5', () {
      final two = SymbolicExpression.integer(2);
      final zero = SymbolicExpression.integer(0);
      final three = SymbolicExpression.integer(3);
      final four = SymbolicExpression.integer(4);
      final five = SymbolicExpression.integer(5);

      final prod1 = two.power(zero) * two.power(three);
      final res1 = simplifier.simplify(prod1.node);
      final symExpr1 = SymbolicExpression(res1.valueOrNull!);
      // 2^0 = 1, 1 * 2^3 = 2^3 -> 8
      expect(symExpr1.toString(), equals('8'));

      final prod2 = four.power(zero) * four.power(five);
      final res2 = simplifier.simplify(prod2.node);
      final symExpr2 = SymbolicExpression(res2.valueOrNull!);
      // 4^0 = 1, 1 * 4^5 -> 1024
      expect(symExpr2.toString(), equals('1024'));
    });

    test('Semantic verification: x^0 * x^3 at x = 0 retains DomainError in AstEvaluator', () {
      final evaluator = AstEvaluator();
      final x = SymbolicExpression.variable('x');
      final zero = SymbolicExpression.integer(0);
      final three = SymbolicExpression.integer(3);
      final prod = x.power(zero) * x.power(three);

      // Verify that at x = 0, prod evaluates with DomainError because 0^0 is indeterminate
      final zeroContext = EvaluationContext(
        variables: {'x': IntegerValue.zero},
      );
      final zeroEval = evaluator.evaluate(prod.node, zeroContext);
      expect(zeroEval.isFailure, isTrue);
      expect(zeroEval.errorOrNull, isA<DomainError>());

      // Also verify that valid positive integer case x^2 * x^3 evaluates identically to x^5 at x = 0
      final prodPos = x.power(SymbolicExpression.integer(2)) * x.power(three);
      final simplifiedPos = simplifier.simplify(prodPos.node).valueOrNull!;
      final evalOriginal = evaluator.evaluate(prodPos.node, zeroContext);
      final evalSimplified = evaluator.evaluate(simplifiedPos, zeroContext);
      expect(evalOriginal.isSuccess, isTrue);
      expect(evalSimplified.isSuccess, isTrue);
      expect(evalOriginal.valueOrNull, equals(evalSimplified.valueOrNull));
    });

    test('Semantic verification: x^(1/2) * x^(1/2) at x = -1 vs x = 4 in AstEvaluator', () {
      final evaluator = AstEvaluator();
      final x = SymbolicExpression.variable('x');
      final half = SymbolicExpression.number(
        FractionValue(BigInt.one, BigInt.two),
      );
      final prod = x.power(half) * x.power(half);

      // Verify that prod evaluates with error at x = -1
      final negContext = EvaluationContext(
        variables: {'x': IntegerValue.minusOne},
      );
      final negEval = evaluator.evaluate(prod.node, negContext);
      expect(negEval.isFailure, isTrue);
      // DomainError: Negative base with fractional exponent results in a complex number.

      // Verify that at x = 4, prod evaluates to 2 * 2 = 4
      final posContext = EvaluationContext(
        variables: {'x': IntegerValue(BigInt.from(4))},
      );
      final posEval = evaluator.evaluate(prod.node, posContext);
      expect(posEval.isSuccess, isTrue);
    });
  });
}
