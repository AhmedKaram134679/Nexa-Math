import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/algebra/substitution/expression_substitutor.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('ExpressionSubstitutor Unit Tests', () {
    final parser = ExpressionEngine();
    const substitutor = DefaultExpressionSubstitutor();

    test('Single variable scalar substitution: x^2 + 2x + 1 with x = 3', () {
      final expr = parser.parse('x^2 + 2x + 1').valueOrNull!;
      final substituted = substitutor.substituteValues(expr, {
        'x': IntegerValue.fromInt(3),
      }).valueOrNull!;

      // Evaluating substituted AST directly yields 3^2 + 2(3) + 1 = 16
      final evalRes = parser.evaluateAst(substituted);
      expect(evalRes.isSuccess, isTrue);
      expect(evalRes.valueOrNull, equals(IntegerValue.fromInt(16)));
    });

    test(
      'Expression-for-variable substitution: f(x) = x^2 with x = (y + 1)',
      () {
        final expr = parser.parse('x^2').valueOrNull!;
        final replacement = parser.parse('y + 1').valueOrNull!;

        final substituted = substitutor
            .substitute(expr, 'x', replacement)
            .valueOrNull!;
        expect(substituted, isA<BinaryOpNode>());
        final bin = substituted as BinaryOpNode;
        expect(bin.operator, equals(BinaryOperator.power));
        expect(bin.left, isA<GroupNode>());
        final grp = bin.left as GroupNode;
        expect(grp.inner, isA<BinaryOpNode>());
      },
    );

    test(
      'Multi-variable simultaneous substitution: x*y + z with x=2, y=3, z=4',
      () {
        final expr = parser.parse('x*y + z').valueOrNull!;
        final substituted = substitutor.substituteValues(expr, {
          'x': IntegerValue.fromInt(2),
          'y': IntegerValue.fromInt(3),
          'z': IntegerValue.fromInt(4),
        }).valueOrNull!;

        final evalRes = parser.evaluateAst(substituted);
        expect(evalRes.isSuccess, isTrue);
        expect(evalRes.valueOrNull, equals(IntegerValue.fromInt(10)));
      },
    );

    test('Structural non-prefix collision: x + x1 + xy with x -> 2', () {
      final expr = parser.parse('x + x1 + xy').valueOrNull!;
      final substituted = substitutor.substituteValues(expr, {
        'x': IntegerValue.fromInt(2),
      }).valueOrNull!;

      // Verify that x was replaced with NumberLiteralNode(2), but x1 and xy remain VariableNodes
      expect(substituted, isA<BinaryOpNode>());
      final topAdd = substituted as BinaryOpNode;
      expect(topAdd.right, isA<VariableNode>());
      expect((topAdd.right as VariableNode).name, equals('xy'));

      final leftAdd = topAdd.left as BinaryOpNode;
      expect(leftAdd.left, isA<NumberLiteralNode>());
      expect(
        (leftAdd.left as NumberLiteralNode).value,
        equals(IntegerValue.fromInt(2)),
      );
      expect(leftAdd.right, isA<VariableNode>());
      expect((leftAdd.right as VariableNode).name, equals('x1'));
    });
  });
}
