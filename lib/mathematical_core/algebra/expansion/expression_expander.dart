import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/simplification/algebraic_simplifier.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Contract for algebraic expansion (distributive law, binomial powers).
abstract interface class ExpressionExpander {
  /// Expands products and integer powers across the syntax tree: e.g. `(a + b)(c + d) -> ac + ad + bc + bd`.
  MathResult<ExpressionNode> expand(ExpressionNode expression);
}

/// Production implementation of [ExpressionExpander].
final class DefaultExpressionExpander
    implements ExpressionExpander, ExpressionVisitor<ExpressionNode, void> {
  final AlgebraicSimplifier simplifier;

  DefaultExpressionExpander({AlgebraicSimplifier? simplifier})
    : simplifier = simplifier ?? DefaultAlgebraicSimplifier();

  @override
  MathResult<ExpressionNode> expand(ExpressionNode expression) {
    final expanded = expression.accept(this, null);
    return simplifier.simplify(expanded);
  }

  @override
  ExpressionNode visitNumberLiteral(NumberLiteralNode node, void context) =>
      node;

  @override
  ExpressionNode visitVariable(VariableNode node, void context) => node;

  @override
  ExpressionNode visitConstant(ConstantNode node, void context) => node;

  @override
  ExpressionNode visitGroup(GroupNode node, void context) {
    final inner = node.inner.accept(this, context);
    return GroupNode(position: node.position, inner: inner);
  }

  @override
  ExpressionNode visitUnaryOp(UnaryOpNode node, void context) {
    final operand = node.operand.accept(this, context);
    if (node.operator == UnaryOperator.negate && operand is BinaryOpNode) {
      if (operand.operator == BinaryOperator.add) {
        // -(a + b) -> -a - b
        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.subtract,
          left: UnaryOpNode(
            position: node.position,
            operator: UnaryOperator.negate,
            operand: operand.left,
            isPrefix: true,
          ),
          right: operand.right,
        );
      } else if (operand.operator == BinaryOperator.subtract) {
        // -(a - b) -> b - a
        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.subtract,
          left: operand.right,
          right: operand.left,
        );
      }
    }
    return UnaryOpNode(
      position: node.position,
      operator: node.operator,
      operand: operand,
      isPrefix: node.isPrefix,
    );
  }

  @override
  ExpressionNode visitBinaryOp(BinaryOpNode node, void context) {
    final left = node.left.accept(this, context);
    final right = node.right.accept(this, context);

    if (node.operator == BinaryOperator.multiply) {
      return _expandProduct(left, right, node.position);
    }

    if (node.operator == BinaryOperator.power) {
      // (a + b)^2 -> (a + b)(a + b)
      if (right is NumberLiteralNode && right.value is IntegerValue) {
        final exp = (right.value as IntegerValue).value;
        if (exp == BigInt.two) {
          return _expandProduct(left, left, node.position);
        } else if (exp == BigInt.from(3)) {
          final squared = _expandProduct(left, left, node.position);
          return _expandProduct(squared, left, node.position);
        }
      }
    }

    return BinaryOpNode(
      position: node.position,
      operator: node.operator,
      left: left,
      right: right,
      isImplicit: node.isImplicit,
    );
  }

  @override
  ExpressionNode visitFunctionCall(FunctionCallNode node, void context) {
    final expandedArgs = node.arguments
        .map((a) => a.accept(this, context))
        .toList();
    return FunctionCallNode(
      position: node.position,
      name: node.name,
      arguments: List.unmodifiable(expandedArgs),
    );
  }

  ExpressionNode _expandProduct(
    ExpressionNode left,
    ExpressionNode right,
    SourcePosition pos,
  ) {
    final leftUnwrapped = _unwrap(left);
    final rightUnwrapped = _unwrap(right);

    // Case 1: (a + b) * c -> ac + bc
    if (leftUnwrapped is BinaryOpNode &&
        leftUnwrapped.operator == BinaryOperator.add) {
      final ac = _expandProduct(leftUnwrapped.left, right, pos);
      final bc = _expandProduct(leftUnwrapped.right, right, pos);
      return BinaryOpNode(
        position: pos,
        operator: BinaryOperator.add,
        left: ac,
        right: bc,
      );
    }

    // Case 2: (a - b) * c -> ac - bc
    if (leftUnwrapped is BinaryOpNode &&
        leftUnwrapped.operator == BinaryOperator.subtract) {
      final ac = _expandProduct(leftUnwrapped.left, right, pos);
      final bc = _expandProduct(leftUnwrapped.right, right, pos);
      return BinaryOpNode(
        position: pos,
        operator: BinaryOperator.subtract,
        left: ac,
        right: bc,
      );
    }

    // Case 3: a * (b + c) -> ab + ac
    if (rightUnwrapped is BinaryOpNode &&
        rightUnwrapped.operator == BinaryOperator.add) {
      final ab = _expandProduct(left, rightUnwrapped.left, pos);
      final ac = _expandProduct(left, rightUnwrapped.right, pos);
      return BinaryOpNode(
        position: pos,
        operator: BinaryOperator.add,
        left: ab,
        right: ac,
      );
    }

    // Case 4: a * (b - c) -> ab - ac
    if (rightUnwrapped is BinaryOpNode &&
        rightUnwrapped.operator == BinaryOperator.subtract) {
      final ab = _expandProduct(left, rightUnwrapped.left, pos);
      final ac = _expandProduct(left, rightUnwrapped.right, pos);
      return BinaryOpNode(
        position: pos,
        operator: BinaryOperator.subtract,
        left: ab,
        right: ac,
      );
    }

    // Default base multiplication
    return BinaryOpNode(
      position: pos,
      operator: BinaryOperator.multiply,
      left: left,
      right: right,
    );
  }

  ExpressionNode _unwrap(ExpressionNode node) {
    if (node is GroupNode) return _unwrap(node.inner);
    return node;
  }
}
