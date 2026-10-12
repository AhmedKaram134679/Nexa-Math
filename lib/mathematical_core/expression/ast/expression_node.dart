import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';

/// Visitor interface for traversing immutable [ExpressionNode] syntax trees.
abstract interface class ExpressionVisitor<R, C> {
  R visitNumberLiteral(NumberLiteralNode node, C context);
  R visitVariable(VariableNode node, C context);
  R visitConstant(ConstantNode node, C context);
  R visitUnaryOp(UnaryOpNode node, C context);
  R visitBinaryOp(BinaryOpNode node, C context);
  R visitFunctionCall(FunctionCallNode node, C context);
  R visitGroup(GroupNode node, C context);
}

/// Abstract base class for all nodes in the immutable NexaMath Expression Abstract Syntax Tree.
sealed class ExpressionNode {
  /// The source position in the original text where this node starts.
  final SourcePosition position;

  const ExpressionNode({required this.position});

  /// Accepts an [ExpressionVisitor] according to the visitor pattern.
  R accept<R, C>(ExpressionVisitor<R, C> visitor, C context);
}

/// Represents a literal scalar number in the AST.
final class NumberLiteralNode extends ExpressionNode {
  /// The exact mathematical scalar value ([IntegerValue] or [DecimalValue]).
  final ScalarValue value;

  const NumberLiteralNode({required super.position, required this.value});

  @override
  R accept<R, C>(ExpressionVisitor<R, C> visitor, C context) =>
      visitor.visitNumberLiteral(this, context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumberLiteralNode &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Number($value)';
}

/// Represents a named variable identifier (e.g. `x`, `y`, `theta`).
final class VariableNode extends ExpressionNode {
  /// The variable name.
  final String name;

  const VariableNode({required super.position, required this.name});

  @override
  R accept<R, C>(ExpressionVisitor<R, C> visitor, C context) =>
      visitor.visitVariable(this, context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariableNode &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Var($name)';
}

/// Represents a named mathematical constant (e.g. `pi`, `e`, `phi`).
final class ConstantNode extends ExpressionNode {
  /// The constant identifier.
  final String name;

  const ConstantNode({required super.position, required this.name});

  @override
  R accept<R, C>(ExpressionVisitor<R, C> visitor, C context) =>
      visitor.visitConstant(this, context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstantNode &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Const($name)';
}

/// Unary operator types.
enum UnaryOperator {
  /// Unary plus (`+x`).
  plus,

  /// Unary negation (`-x`).
  negate,

  /// Postfix factorial (`x!`).
  factorial,
}

/// Represents a unary operator expression (`+x`, `-x`, or `x!`).
final class UnaryOpNode extends ExpressionNode {
  final UnaryOperator operator;
  final ExpressionNode operand;
  final bool isPrefix;

  const UnaryOpNode({
    required super.position,
    required this.operator,
    required this.operand,
    this.isPrefix = true,
  });

  @override
  R accept<R, C>(ExpressionVisitor<R, C> visitor, C context) =>
      visitor.visitUnaryOp(this, context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnaryOpNode &&
          runtimeType == other.runtimeType &&
          operator == other.operator &&
          operand == other.operand &&
          isPrefix == other.isPrefix;

  @override
  int get hashCode => Object.hash(operator, operand, isPrefix);

  @override
  String toString() =>
      isPrefix ? 'Unary($operator, $operand)' : 'Postfix($operand, $operator)';
}

/// Binary operator types.
enum BinaryOperator { add, subtract, multiply, divide, modulo, power }

/// Represents a binary operator expression (`left + right`, `left * right`, etc.).
final class BinaryOpNode extends ExpressionNode {
  final BinaryOperator operator;
  final ExpressionNode left;
  final ExpressionNode right;
  final bool isImplicit;

  const BinaryOpNode({
    required super.position,
    required this.operator,
    required this.left,
    required this.right,
    this.isImplicit = false,
  });

  @override
  R accept<R, C>(ExpressionVisitor<R, C> visitor, C context) =>
      visitor.visitBinaryOp(this, context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BinaryOpNode &&
          runtimeType == other.runtimeType &&
          operator == other.operator &&
          left == other.left &&
          right == other.right &&
          isImplicit == other.isImplicit;

  @override
  int get hashCode => Object.hash(operator, left, right, isImplicit);

  @override
  String toString() =>
      'Binary($left ${isImplicit ? "[impl]*" : operator.name} $right)';
}

/// Represents a function call expression (e.g. `sin(x)`, `gcd(a, b)`).
final class FunctionCallNode extends ExpressionNode {
  /// The canonical name of the function being invoked.
  final String name;

  /// The argument expressions passed to the function.
  final List<ExpressionNode> arguments;

  const FunctionCallNode({
    required super.position,
    required this.name,
    required this.arguments,
  });

  @override
  R accept<R, C>(ExpressionVisitor<R, C> visitor, C context) =>
      visitor.visitFunctionCall(this, context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionCallNode &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _listEquals(arguments, other.arguments);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(arguments));

  @override
  String toString() => 'Call($name, ${arguments.join(", ")})';

  static bool _listEquals(List<ExpressionNode> a, List<ExpressionNode> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Represents a parenthesized grouped subexpression `(expr)`.
final class GroupNode extends ExpressionNode {
  final ExpressionNode inner;

  const GroupNode({required super.position, required this.inner});

  @override
  R accept<R, C>(ExpressionVisitor<R, C> visitor, C context) =>
      visitor.visitGroup(this, context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupNode &&
          runtimeType == other.runtimeType &&
          inner == other.inner;

  @override
  int get hashCode => inner.hashCode;

  @override
  String toString() => 'Group($inner)';
}
