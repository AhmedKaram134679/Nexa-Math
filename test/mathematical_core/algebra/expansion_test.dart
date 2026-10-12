import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/algebra/expansion/expression_expander.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('ExpressionExpander Unit Tests', () {
    final parser = ExpressionEngine();
    final expander = DefaultExpressionExpander();

    ExpressionNode expandStr(String expr) {
      final node = parser.parse(expr).valueOrNull!;
      return expander.expand(node).valueOrNull!;
    }

    test('Binomial product expansion: (x + 2)*(x + 3)', () {
      final expanded = expandStr('(x + 2)*(x + 3)');
      expect(expanded, isA<BinaryOpNode>());

      // Evaluates algebraically to x^2 + 5x + 6
      final evalEngine = ExpressionEngine();
      for (final x in [0, 1, 2, -3, 10]) {
        final ctx = EvaluationContext(
          variables: {'x': IntegerValue.fromInt(x)},
        );
        final origVal = evalEngine
            .evaluate('(x + 2)*(x + 3)', context: ctx)
            .valueOrNull!;
        final expVal = evalEngine
            .evaluateAst(expanded, context: ctx)
            .valueOrNull!;
        expect(expVal, equals(origVal));
      }
    });

    test('Square of binomial expansion: (x + 2)^2', () {
      final expanded = expandStr('(x + 2)^2');
      expect(expanded, isA<BinaryOpNode>());

      final evalEngine = ExpressionEngine();
      for (final x in [-2, 0, 3, 5]) {
        final ctx = EvaluationContext(
          variables: {'x': IntegerValue.fromInt(x)},
        );
        final origVal = evalEngine
            .evaluate('(x + 2)^2', context: ctx)
            .valueOrNull!;
        final expVal = evalEngine
            .evaluateAst(expanded, context: ctx)
            .valueOrNull!;
        expect(expVal, equals(origVal));
      }
    });

    test('Difference of squares product: (x - 3)*(x + 3)', () {
      final expanded = expandStr('(x - 3)*(x + 3)');
      expect(expanded, isA<BinaryOpNode>());

      final evalEngine = ExpressionEngine();
      for (final x in [-3, 0, 3, 7]) {
        final ctx = EvaluationContext(
          variables: {'x': IntegerValue.fromInt(x)},
        );
        final origVal = evalEngine
            .evaluate('(x - 3)*(x + 3)', context: ctx)
            .valueOrNull!;
        final expVal = evalEngine
            .evaluateAst(expanded, context: ctx)
            .valueOrNull!;
        expect(expVal, equals(origVal));
      }
    });

    test('Cubic power expansion invariant: (x + 1)^3', () {
      final expanded = expandStr('(x + 1)^3');
      final evalEngine = ExpressionEngine();
      for (final x in [-2, -1, 0, 1, 2]) {
        final ctx = EvaluationContext(
          variables: {'x': IntegerValue.fromInt(x)},
        );
        final origVal = evalEngine
            .evaluate('(x + 1)^3', context: ctx)
            .valueOrNull!;
        final expVal = evalEngine
            .evaluateAst(expanded, context: ctx)
            .valueOrNull!;
        expect(expVal, equals(origVal));
      }
    });

    test('Multi-variable expansion invariant: (a + b)*(c + d)', () {
      final expanded = expandStr('(a + b)*(c + d)');
      final evalEngine = ExpressionEngine();
      final testCases = [
        {'a': 1, 'b': 2, 'c': 3, 'd': 4},
        {'a': -1, 'b': 5, 'c': -2, 'd': 0},
        {'a': 0, 'b': 0, 'c': 10, 'd': -3},
      ];
      for (final tc in testCases) {
        final ctx = EvaluationContext(
          variables: tc.map((k, v) => MapEntry(k, IntegerValue.fromInt(v))),
        );
        final origVal = evalEngine
            .evaluate('(a + b)*(c + d)', context: ctx)
            .valueOrNull!;
        final expVal = evalEngine
            .evaluateAst(expanded, context: ctx)
            .valueOrNull!;
        expect(expVal, equals(origVal));
      }
    });
  });
}
