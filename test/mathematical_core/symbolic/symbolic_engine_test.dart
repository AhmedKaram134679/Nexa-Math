import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/symbolic/symbolic.dart';

void main() {
  group('SymbolicEngine Facade & Integration Tests', () {
    final engine = SymbolicEngine();

    test('parse, simplify, and format expression string', () {
      final res = engine.simplifyString('x + 0 + 2 * x');
      expect(res.isSuccess, isTrue);
      final expr = res.valueOrNull!;
      expect(expr.toString(), contains('3 * x'));
    });

    test('Variable substitution: substitute x with 5 in x^2 + 2x + 1', () {
      final parsed = engine.parse('x^2 + 2*x + 1').valueOrNull!;
      final subbed = engine
          .substitute(parsed, 'x', SymbolicExpression.integer(5))
          .valueOrNull!;

      expect(subbed.toString(), contains('36'));
    });

    test('Multi-variable substitution: substitute x with 2 and y with 3 in x*y + x', () {
      final parsed = engine.parse('x*y + x').valueOrNull!;
      final subbed = engine.substituteAll(parsed, {
        'x': SymbolicExpression.integer(2),
        'y': SymbolicExpression.integer(3),
      }).valueOrNull!;

      expect(subbed.toString(), contains('8'));
    });

    test('Symbolic expansion: expand (x + 2)(x + 3)', () {
      final expRes = engine.expandString('(x + 2) * (x + 3)');
      expect(expRes.isSuccess, isTrue);
      final expanded = expRes.valueOrNull!;

      expect(expanded.toString(), contains('x^2'));
      expect(expanded.toString(), contains('5 * x'));
      expect(expanded.toString(), contains('6'));
    });

    test('Polynomial factorization integration: factor x^2 + 5x + 6', () {
      final parsed = engine.parse('x^2 + 5*x + 6').valueOrNull!;
      final factored = engine.factor(parsed).valueOrNull!;

      final str = factored.toString();
      expect(str, contains('x + 2'));
      expect(str, contains('x + 3'));
    });

    test('Symbolic differentiation through facade: d/dx(x^3 + 4x^2 + 5)', () {
      final diffRes = engine.differentiateString('x^3 + 4*x^2 + 5');
      expect(diffRes.isSuccess, isTrue);
      final deriv = diffRes.valueOrNull!;

      final str = deriv.toString();
      expect(str, contains('3 * x^2'));
      expect(str, contains('8 * x'));
    });

    test('Bounded symbolic equivalence: areEquivalent(x + y, y + x)', () {
      final a = engine.parse('x + y').valueOrNull!;
      final b = engine.parse('y + x').valueOrNull!;

      final eqRes = engine.areEquivalent(a, b);
      expect(eqRes.isSuccess, isTrue);
      expect(eqRes.valueOrNull, isTrue);
    });

    test('Bounded symbolic equivalence with expansion: areEquivalent((x+1)^2, x^2 + 2x + 1)', () {
      final a = engine.parse('(x + 1)^2').valueOrNull!;
      final b = engine.parse('x^2 + 2*x + 1').valueOrNull!;

      final eqRes = engine.areEquivalent(a, b);
      expect(eqRes.isSuccess, isTrue);
      expect(eqRes.valueOrNull, isTrue);
    });
  });
}
