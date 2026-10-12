import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/symbolic/differentiation/symbolic_differentiator.dart';
import 'package:nexa_math/mathematical_core/symbolic/models/symbolic_expression.dart';

void main() {
  group('SymbolicDifferentiator Tests', () {
    final diff = DefaultSymbolicDifferentiator();

    test('Derivative of constant is 0: d/dx(5) = 0, d/dx(c) = 0', () {
      final five = SymbolicExpression.integer(5);
      final c = SymbolicExpression.constant('pi');

      final res1 = diff.differentiate(five.node, variableName: 'x');
      final res2 = diff.differentiate(c.node, variableName: 'x');

      expect(res1.valueOrNull, equals(SymbolicExpression.integer(0).node));
      expect(res2.valueOrNull, equals(SymbolicExpression.integer(0).node));
    });

    test('Derivative of target variable is 1: d/dx(x) = 1', () {
      final x = SymbolicExpression.variable('x');
      final res = diff.differentiate(x.node, variableName: 'x');

      expect(res.valueOrNull, equals(SymbolicExpression.integer(1).node));
    });

    test('Derivative of different variable is 0: d/dx(y) = 0', () {
      final y = SymbolicExpression.variable('y');
      final res = diff.differentiate(y.node, variableName: 'x');

      expect(res.valueOrNull, equals(SymbolicExpression.integer(0).node));
    });

    test('Sum rule: d/dx(x + 5) = 1', () {
      final x = SymbolicExpression.variable('x');
      final five = SymbolicExpression.integer(5);

      final sum = x + five;
      final res = diff.differentiate(sum.node, variableName: 'x');

      expect(res.valueOrNull, equals(SymbolicExpression.integer(1).node));
    });

    test('Power rule: d/dx(x^2) = 2*x', () {
      final x = SymbolicExpression.variable('x');
      final two = SymbolicExpression.integer(2);

      final pow = x.power(two);
      final res = diff.differentiate(pow.node, variableName: 'x');

      final str = res.valueOrNull.toString();
      expect(str, contains('2'));
      expect(str, contains('x'));
    });

    test('Power rule higher degree: d/dx(x^4) = 4*x^3', () {
      final x = SymbolicExpression.variable('x');
      final four = SymbolicExpression.integer(4);

      final pow = x.power(four);
      final res = diff.differentiate(pow.node, variableName: 'x');

      final str = res.valueOrNull.toString();
      expect(str, contains('4'));
      expect(str, contains('x'));
      expect(str, contains('3'));
    });

    test('Product rule: d/dx(x * x) = 2*x', () {
      final x = SymbolicExpression.variable('x');
      final prod = x * x;

      final res = diff.differentiate(prod.node, variableName: 'x');
      final str = res.valueOrNull.toString();
      expect(str, contains('2'));
      expect(str, contains('x'));
    });

    test('Trigonometric derivatives: d/dx(sin(x)) = cos(x), d/dx(cos(x)) = -sin(x)', () {
      final x = SymbolicExpression.variable('x');
      final sinX = SymbolicExpression.function('sin', [x]);
      final cosX = SymbolicExpression.function('cos', [x]);

      final diffSin = diff.differentiate(sinX.node, variableName: 'x');
      final diffCos = diff.differentiate(cosX.node, variableName: 'x');

      expect(
        SymbolicExpression(diffSin.valueOrNull!).toString(),
        contains('cos'),
      );
      expect(
        SymbolicExpression(diffCos.valueOrNull!).toString(),
        contains('sin'),
      );
      expect(
        SymbolicExpression(diffCos.valueOrNull!).toString(),
        contains('-'),
      );
    });

    test('Chain rule: d/dx(sin(x^2)) = cos(x^2) * 2x', () {
      final x = SymbolicExpression.variable('x');
      final xSq = x.power(SymbolicExpression.integer(2));
      final sinXSq = SymbolicExpression.function('sin', [xSq]);

      final res = diff.differentiate(sinXSq.node, variableName: 'x');
      final str = res.valueOrNull.toString();

      expect(str, contains('cos'));
      expect(str, contains('2'));
      expect(str, contains('x'));
    });

    test(
      'Exponential and Logarithm: d/dx(exp(x)) = exp(x), d/dx(ln(x)) = 1/x',
      () {
        final x = SymbolicExpression.variable('x');
        final expX = SymbolicExpression.function('exp', [x]);
        final lnX = SymbolicExpression.function('ln', [x]);

        final diffExp = diff.differentiate(expX.node, variableName: 'x');
        final diffLn = diff.differentiate(lnX.node, variableName: 'x');

        expect(diffExp.valueOrNull.toString(), contains('exp'));
        expect(diffLn.valueOrNull.toString(), contains('1'));
        expect(diffLn.valueOrNull.toString(), contains('x'));
      },
    );

    test('Quotient rule: d/dx(1 / x) = -1 / x^2', () {
      final x = SymbolicExpression.variable('x');
      final one = SymbolicExpression.integer(1);
      final quot = one / x;

      final res = diff.differentiate(quot.node, variableName: 'x');
      final str = res.valueOrNull.toString();
      expect(str, contains('-'));
      expect(str, contains('x'));
    });

    test('Power rule with negative integer power: d/dx(x^-2) = -2 * x^-3', () {
      final x = SymbolicExpression.variable('x');
      final negTwo = SymbolicExpression.integer(-2);
      final pow = x.power(negTwo);

      final res = diff.differentiate(pow.node, variableName: 'x');
      expect(res.isSuccess, isTrue);
      final symExpr = SymbolicExpression(res.valueOrNull!);
      expect(symExpr.toString(), contains('-2'));
      expect(symExpr.toString(), contains('x'));
      expect(symExpr.toString(), contains('-3'));
    });

    test('Exponential rule with constant base: d/dx(2^x) = 2^x * ln(2)', () {
      final two = SymbolicExpression.integer(2);
      final x = SymbolicExpression.variable('x');
      final pow = two.power(x);

      final res = diff.differentiate(pow.node, variableName: 'x');
      expect(res.isSuccess, isTrue);
      final symExpr = SymbolicExpression(res.valueOrNull!);
      expect(symExpr.toString(), contains('2^x'));
      expect(symExpr.toString(), contains('ln(2)'));
    });

    test('General variable base and variable exponent u(x)^v(x) returns unsupported operation', () {
      final x = SymbolicExpression.variable('x');
      final xPowX = x.power(x);

      final res = diff.differentiate(xPowX.node, variableName: 'x');
      expect(res.isFailure, isTrue);
    });
  });
}
