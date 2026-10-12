import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';

/// Contract for structural variable substitution on expression ASTs.
abstract interface class ExpressionSubstitutor {
  /// Replaces occurrences of variable [variableName] with [replacement] node.
  MathResult<ExpressionNode> substitute(
    ExpressionNode expression,
    String variableName,
    ExpressionNode replacement,
  );

  /// Replaces occurrences of variables using a dictionary map.
  MathResult<ExpressionNode> substituteAll(
    ExpressionNode expression,
    Map<String, ExpressionNode> substitutions,
  );

  /// Substitutes scalar values for variables.
  MathResult<ExpressionNode> substituteValues(
    ExpressionNode expression,
    Map<String, ScalarValue> values,
  );
}

/// Production implementation of [ExpressionSubstitutor].
final class DefaultExpressionSubstitutor
    implements
        ExpressionSubstitutor,
        ExpressionVisitor<ExpressionNode, Map<String, ExpressionNode>> {
  const DefaultExpressionSubstitutor();

  @override
  MathResult<ExpressionNode> substitute(
    ExpressionNode expression,
    String variableName,
    ExpressionNode replacement,
  ) {
    return substituteAll(expression, {variableName: replacement});
  }

  @override
  MathResult<ExpressionNode> substituteAll(
    ExpressionNode expression,
    Map<String, ExpressionNode> substitutions,
  ) {
    final result = expression.accept(this, substitutions);
    return MathSuccess(result);
  }

  @override
  MathResult<ExpressionNode> substituteValues(
    ExpressionNode expression,
    Map<String, ScalarValue> values,
  ) {
    final nodeMap = values.map(
      (k, v) => MapEntry(
        k,
        NumberLiteralNode(position: expression.position, value: v),
      ),
    );
    return substituteAll(expression, nodeMap);
  }

  @override
  ExpressionNode visitNumberLiteral(
    NumberLiteralNode node,
    Map<String, ExpressionNode> context,
  ) {
    return node;
  }

  @override
  ExpressionNode visitVariable(
    VariableNode node,
    Map<String, ExpressionNode> context,
  ) {
    if (context.containsKey(node.name)) {
      final replacement = context[node.name]!;
      // Wrap complex expressions in GroupNode to preserve mathematical grouping
      if (replacement is BinaryOpNode) {
        return GroupNode(position: node.position, inner: replacement);
      }
      return replacement;
    }
    return node;
  }

  @override
  ExpressionNode visitConstant(
    ConstantNode node,
    Map<String, ExpressionNode> context,
  ) {
    return node;
  }

  @override
  ExpressionNode visitGroup(
    GroupNode node,
    Map<String, ExpressionNode> context,
  ) {
    final inner = node.inner.accept(this, context);
    return GroupNode(position: node.position, inner: inner);
  }

  @override
  ExpressionNode visitUnaryOp(
    UnaryOpNode node,
    Map<String, ExpressionNode> context,
  ) {
    final operand = node.operand.accept(this, context);
    return UnaryOpNode(
      position: node.position,
      operator: node.operator,
      operand: operand,
      isPrefix: node.isPrefix,
    );
  }

  @override
  ExpressionNode visitBinaryOp(
    BinaryOpNode node,
    Map<String, ExpressionNode> context,
  ) {
    final left = node.left.accept(this, context);
    final right = node.right.accept(this, context);
    return BinaryOpNode(
      position: node.position,
      operator: node.operator,
      left: left,
      right: right,
      isImplicit: node.isImplicit,
    );
  }

  @override
  ExpressionNode visitFunctionCall(
    FunctionCallNode node,
    Map<String, ExpressionNode> context,
  ) {
    final args = node.arguments.map((a) => a.accept(this, context)).toList();
    return FunctionCallNode(
      position: node.position,
      name: node.name,
      arguments: List.unmodifiable(args),
    );
  }
}
