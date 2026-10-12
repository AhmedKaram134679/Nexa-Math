import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('Equation Unit Tests', () {
    final parser = ExpressionEngine();

    test('Equation model and normalization to zero: 2x + 3 = 7 -> (2x + 3) - 7 = 0', () {
      final lhs = parser.parse('2x + 3').valueOrNull!;
      final rhs = parser.parse('7').valueOrNull!;
      final eq = Equation(left: lhs, right: rhs);

      expect(eq.left, equals(lhs));
      expect(eq.right, equals(rhs));

      final norm = eq.normalizeToZero();
      expect(norm.right, isA<NumberLiteralNode>());
      expect(
        (norm.right as NumberLiteralNode).value,
        equals(IntegerValue.zero),
      );
      expect(norm.left, isA<BinaryOpNode>());
      expect(
        (norm.left as BinaryOpNode).operator,
        equals(BinaryOperator.subtract),
      );
    });

    test('Equation canonical simplification: x + 5 = 2x + 1', () {
      final lhs = parser.parse('x + 5').valueOrNull!;
      final rhs = parser.parse('2x + 1').valueOrNull!;
      final eq = Equation(left: lhs, right: rhs);

      final canonical = eq.toCanonicalForm();
      expect(canonical.right, isA<NumberLiteralNode>());
      expect(
        (canonical.right as NumberLiteralNode).value,
        equals(IntegerValue.zero),
      );
    });
  });
}
