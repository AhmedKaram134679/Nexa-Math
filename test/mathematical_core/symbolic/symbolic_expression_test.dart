import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/symbolic/models/symbolic_expression.dart';

void main() {
  group('SymbolicExpression Model Tests', () {
    test('Constructs number, variable, constant, and function expressions', () {
      final numExpr = SymbolicExpression.integer(42);
      final varExpr = SymbolicExpression.variable('x');
      final constExpr = SymbolicExpression.constant('pi');
      final fnExpr = SymbolicExpression.function('sin', [varExpr]);

      expect(numExpr.isNumber, isTrue);
      expect(varExpr.isVariable, isTrue);
      expect(constExpr.isConstant, isTrue);
      expect(numExpr.variables, isEmpty);
      expect(varExpr.variables, equals({'x'}));
      expect(fnExpr.variables, equals({'x'}));
    });

    test('Zero and One predicate tests', () {
      final zeroInt = SymbolicExpression.integer(0);
      final zeroFrac = SymbolicExpression.number(FractionValue.zero);
      final oneInt = SymbolicExpression.integer(1);
      final oneFrac = SymbolicExpression.number(FractionValue.one);
      final other = SymbolicExpression.integer(5);

      expect(zeroInt.isZero, isTrue);
      expect(zeroFrac.isZero, isTrue);
      expect(oneInt.isOne, isTrue);
      expect(oneFrac.isOne, isTrue);
      expect(other.isZero, isFalse);
      expect(other.isOne, isFalse);
    });

    test('Collects multi-variable set from composite expressions', () {
      final x = SymbolicExpression.variable('x');
      final y = SymbolicExpression.variable('y');
      final z = SymbolicExpression.variable('z');

      final composite = (x * y) + (z.power(SymbolicExpression.integer(2)));
      expect(composite.variables, equals({'x', 'y', 'z'}));
    });

    test('Operator overloading constructs valid AST trees', () {
      final a = SymbolicExpression.variable('a');
      final b = SymbolicExpression.variable('b');

      final sum = a + b;
      final diff = a - b;
      final prod = a * b;
      final quot = a / b;
      final neg = -a;

      expect(sum.node, isA<BinaryOpNode>());
      expect((sum.node as BinaryOpNode).operator, equals(BinaryOperator.add));
      expect(diff.node, isA<BinaryOpNode>());
      expect(
        (diff.node as BinaryOpNode).operator,
        equals(BinaryOperator.subtract),
      );
      expect(prod.node, isA<BinaryOpNode>());
      expect(
        (prod.node as BinaryOpNode).operator,
        equals(BinaryOperator.multiply),
      );
      expect(quot.node, isA<BinaryOpNode>());
      expect(
        (quot.node as BinaryOpNode).operator,
        equals(BinaryOperator.divide),
      );
      expect(neg.node, isA<UnaryOpNode>());
      expect((neg.node as UnaryOpNode).operator, equals(UnaryOperator.negate));
    });

    test('String formatting and LaTeX generation', () {
      final x = SymbolicExpression.variable('x');
      final two = SymbolicExpression.integer(2);
      final expr = (x.power(two)) + (two * x) + SymbolicExpression.integer(1);

      expect(expr.toString(), contains('x^2'));
      expect(expr.toString(), contains('2 * x'));
      expect(expr.toLaTeX(), contains('{x}^{2}'));
      expect(expr.toLaTeX(), contains(r'\cdot'));

      final fn = SymbolicExpression.function('sin', [x]);
      expect(fn.toLaTeX(), equals(r'\sin\left(x\right)'));
    });

    test('Equality and hash code contract', () {
      final a1 = SymbolicExpression.variable('x');
      final a2 = SymbolicExpression.variable('x');
      final b = SymbolicExpression.variable('y');

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(b)));

      final set = {a1};
      expect(set.contains(a2), isTrue);
      expect(set.contains(b), isFalse);
    });
  });
}
