import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';

/// Abstract interface for evaluating an immutable [ExpressionNode] syntax tree.
abstract interface class ExpressionEvaluator {
  /// Evaluates the given [expression] syntax tree under the provided [context].
  ///
  /// Returns a [MathResult] with the evaluated [ScalarValue], or [MathFailure] with [MathError].
  MathResult<ScalarValue> evaluate(
    ExpressionNode expression,
    EvaluationContext context,
  );
}
