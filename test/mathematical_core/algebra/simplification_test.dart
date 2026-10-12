import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/algebra/simplification/algebraic_simplifier.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('AlgebraicSimplifier Unit Tests', () {
    final parser = ExpressionEngine();
    final simplifier = DefaultAlgebraicSimplifier();
    const pos = SourcePosition.start;

    ExpressionNode simplifyStr(String expr) {
      final node = parser.parse(expr).valueOrNull!;
      return simplifier.simplify(node).valueOrNull!;
    }

    test('Zero identity rewrites: x + 0, 0 + x, x - 0, x * 0, 0 * x', () {
      expect(
        simplifyStr('x + 0'),
        equals(const VariableNode(position: pos, name: 'x')),
      );
      expect(
        simplifyStr('0 + x'),
        equals(const VariableNode(position: pos, name: 'x')),
      );
      expect(
        simplifyStr('x - 0'),
        equals(const VariableNode(position: pos, name: 'x')),
      );
      expect(
        simplifyStr('x * 0'),
        equals(NumberLiteralNode(position: pos, value: IntegerValue.zero)),
      );
      expect(
        simplifyStr('0 * x'),
        equals(NumberLiteralNode(position: pos, value: IntegerValue.zero)),
      );
    });

    test('One identity rewrites: x * 1, 1 * x, x / 1, x ^ 1', () {
      expect(
        simplifyStr('x * 1'),
        equals(const VariableNode(position: pos, name: 'x')),
      );
      expect(
        simplifyStr('1 * x'),
        equals(const VariableNode(position: pos, name: 'x')),
      );
      expect(
        simplifyStr('x / 1'),
        equals(const VariableNode(position: pos, name: 'x')),
      );
      expect(
        simplifyStr('x ^ 1'),
        equals(const VariableNode(position: pos, name: 'x')),
      );
    });

    test(
      'Self cancellations: x - x -> 0, non-zero constant division c / c -> 1',
      () {
        expect(
          simplifyStr('x - x'),
          equals(NumberLiteralNode(position: pos, value: IntegerValue.zero)),
        );
        expect(
          simplifyStr('5 / 5'),
          equals(NumberLiteralNode(position: pos, value: IntegerValue.one)),
        );
      },
    );

    test('Domain safety: x / x and 0 / x are not unconditionally rewritten to 1 or 0', () {
      // x / x must NOT be blindly rewritten to 1 without establishing x != 0
      final xDivX = simplifyStr('x / x');
      expect(xDivX, isA<BinaryOpNode>());
      final bX = xDivX as BinaryOpNode;
      expect(bX.operator, equals(BinaryOperator.divide));
      expect(bX.left, equals(const VariableNode(position: pos, name: 'x')));
      expect(bX.right, equals(const VariableNode(position: pos, name: 'x')));

      // 0 / x must NOT be blindly rewritten to 0 without establishing x != 0
      final zeroDivX = simplifyStr('0 / x');
      expect(zeroDivX, isA<BinaryOpNode>());
      final bZeroX = zeroDivX as BinaryOpNode;
      expect(bZeroX.operator, equals(BinaryOperator.divide));

      // 0 / 5 -> 0 (for non-zero literal denominator)
      expect(
        simplifyStr('0 / 5'),
        equals(NumberLiteralNode(position: pos, value: IntegerValue.zero)),
      );

      // 0 / 0 is indeterminate; must not rewrite
      final zeroDivZero = simplifyStr('0 / 0');
      expect(zeroDivZero, isA<BinaryOpNode>());
      expect(
        (zeroDivZero as BinaryOpNode).operator,
        equals(BinaryOperator.divide),
      );
    });

    test('Domain safety: powers 0^0, x^0, 0^x, 5^0, 0^3', () {
      // 0^0 is indeterminate form; must not rewrite to 1 or 0
      final zeroPowZero = simplifyStr('0 ^ 0');
      expect(zeroPowZero, isA<BinaryOpNode>());
      expect(
        (zeroPowZero as BinaryOpNode).operator,
        equals(BinaryOperator.power),
      );

      // x ^ 0 must not be unconditionally rewritten to 1 without establishing x != 0
      final xPowZero = simplifyStr('x ^ 0');
      expect(xPowZero, isA<BinaryOpNode>());
      expect((xPowZero as BinaryOpNode).operator, equals(BinaryOperator.power));

      // 5 ^ 0 -> 1 (non-zero literal base)
      expect(
        simplifyStr('5 ^ 0'),
        equals(NumberLiteralNode(position: pos, value: IntegerValue.one)),
      );

      // 0 ^ 3 -> 0 (strictly positive literal exponent)
      expect(
        simplifyStr('0 ^ 3'),
        equals(NumberLiteralNode(position: pos, value: IntegerValue.zero)),
      );

      // 0 ^ x must not be blindly rewritten to 0 (since x could be <= 0 or 0)
      final zeroPowX = simplifyStr('0 ^ x');
      expect(zeroPowX, isA<BinaryOpNode>());
      expect((zeroPowX as BinaryOpNode).operator, equals(BinaryOperator.power));
    });

    test('Like term collection: x + x -> 2x, 3x + 2x -> 5x, 4x - x -> 3x', () {
      final res1 = simplifyStr('x + x');
      expect(res1, isA<BinaryOpNode>());
      final b1 = res1 as BinaryOpNode;
      expect(b1.operator, equals(BinaryOperator.multiply));
      expect(
        b1.left,
        equals(
          NumberLiteralNode(position: pos, value: IntegerValue.fromInt(2)),
        ),
      );
      expect(b1.right, equals(const VariableNode(position: pos, name: 'x')));

      final res2 = simplifyStr('3x + 2x');
      expect(res2, isA<BinaryOpNode>());
      final b2 = res2 as BinaryOpNode;
      expect(b2.operator, equals(BinaryOperator.multiply));
      expect(
        b2.left,
        equals(
          NumberLiteralNode(position: pos, value: IntegerValue.fromInt(5)),
        ),
      );
      expect(b2.right, equals(const VariableNode(position: pos, name: 'x')));

      final res3 = simplifyStr('4x - x');
      expect(res3, isA<BinaryOpNode>());
      final b3 = res3 as BinaryOpNode;
      expect(b3.operator, equals(BinaryOperator.multiply));
      expect(
        b3.left,
        equals(
          NumberLiteralNode(position: pos, value: IntegerValue.fromInt(3)),
        ),
      );
      expect(b3.right, equals(const VariableNode(position: pos, name: 'x')));
    });

    test('Constant folding in subtrees', () {
      // (2 + 3) * x -> 5 * x
      final res = simplifyStr('(2 + 3) * x');
      expect(res, isA<BinaryOpNode>());
      final b = res as BinaryOpNode;
      expect(
        b.left,
        equals(
          NumberLiteralNode(position: pos, value: IntegerValue.fromInt(5)),
        ),
      );
      expect(b.right, equals(const VariableNode(position: pos, name: 'x')));
    });
  });
}
