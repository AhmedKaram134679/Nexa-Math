import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Immutable domain model representing a symbolic mathematical expression in NexaMath.
///
/// Encapsulates the underlying [ExpressionNode] AST and provides structural
/// properties, variable extraction, and formatting utilities.
final class SymbolicExpression extends MathValue {
  /// The underlying immutable AST node representing the mathematical structure.
  final ExpressionNode node;

  /// Creates an immutable [SymbolicExpression] wrapping [node].
  const SymbolicExpression(this.node);

  /// Factory constructor for a scalar number literal.
  factory SymbolicExpression.number(ScalarValue value) => SymbolicExpression(
    NumberLiteralNode(position: SourcePosition.start, value: value),
  );

  /// Factory constructor for an integer literal.
  factory SymbolicExpression.integer(int value) =>
      SymbolicExpression.number(IntegerValue.fromInt(value));

  /// Factory constructor for a named variable (e.g. `x`, `y`, `theta`).
  factory SymbolicExpression.variable(String name) => SymbolicExpression(
    VariableNode(position: SourcePosition.start, name: name),
  );

  /// Factory constructor for a named constant (e.g. `pi`, `e`).
  factory SymbolicExpression.constant(String name) => SymbolicExpression(
    ConstantNode(position: SourcePosition.start, name: name),
  );

  /// Factory constructor for a function call (e.g. `sin(x)`, `ln(x)`).
  factory SymbolicExpression.function(
    String name,
    List<SymbolicExpression> args,
  ) => SymbolicExpression(
    FunctionCallNode(
      position: SourcePosition.start,
      name: name,
      arguments: List.unmodifiable(args.map((a) => a.node)),
    ),
  );

  /// Whether this expression is an atomic numeric literal.
  bool get isNumber => node is NumberLiteralNode;

  /// Whether this expression is a named variable.
  bool get isVariable => node is VariableNode;

  /// Whether this expression is a named constant.
  bool get isConstant => node is ConstantNode;

  /// Whether this expression is an integer or rational zero.
  bool get isZero {
    if (node is! NumberLiteralNode) return false;
    final val = (node as NumberLiteralNode).value;
    if (val is IntegerValue) return val.isZero;
    if (val is FractionValue) return val.isZero;
    return false;
  }

  /// Whether this expression is an integer or rational one.
  bool get isOne {
    if (node is! NumberLiteralNode) return false;
    final val = (node as NumberLiteralNode).value;
    if (val is IntegerValue) return val.value == BigInt.one;
    if (val is FractionValue) return val == FractionValue.one;
    return false;
  }

  /// Extracts the set of distinct variable names present in this expression.
  Set<String> get variables {
    final vars = <String>{};
    _collectVariables(node, vars);
    return Set.unmodifiable(vars);
  }

  static void _collectVariables(ExpressionNode n, Set<String> vars) {
    if (n is VariableNode) {
      vars.add(n.name);
    } else if (n is GroupNode) {
      _collectVariables(n.inner, vars);
    } else if (n is UnaryOpNode) {
      _collectVariables(n.operand, vars);
    } else if (n is BinaryOpNode) {
      _collectVariables(n.left, vars);
      _collectVariables(n.right, vars);
    } else if (n is FunctionCallNode) {
      for (final arg in n.arguments) {
        _collectVariables(arg, vars);
      }
    }
  }

  /// Operator overloading for convenient symbolic expression building.
  SymbolicExpression operator +(SymbolicExpression other) => SymbolicExpression(
    BinaryOpNode(
      position: SourcePosition.start,
      operator: BinaryOperator.add,
      left: node,
      right: other.node,
    ),
  );

  SymbolicExpression operator -(SymbolicExpression other) => SymbolicExpression(
    BinaryOpNode(
      position: SourcePosition.start,
      operator: BinaryOperator.subtract,
      left: node,
      right: other.node,
    ),
  );

  SymbolicExpression operator *(SymbolicExpression other) => SymbolicExpression(
    BinaryOpNode(
      position: SourcePosition.start,
      operator: BinaryOperator.multiply,
      left: node,
      right: other.node,
      isImplicit: true,
    ),
  );

  SymbolicExpression operator /(SymbolicExpression other) => SymbolicExpression(
    BinaryOpNode(
      position: SourcePosition.start,
      operator: BinaryOperator.divide,
      left: node,
      right: other.node,
    ),
  );

  SymbolicExpression operator -() => SymbolicExpression(
    UnaryOpNode(
      position: SourcePosition.start,
      operator: UnaryOperator.negate,
      operand: node,
      isPrefix: true,
    ),
  );

  SymbolicExpression power(SymbolicExpression exponent) => SymbolicExpression(
    BinaryOpNode(
      position: SourcePosition.start,
      operator: BinaryOperator.power,
      left: node,
      right: exponent.node,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymbolicExpression &&
          runtimeType == other.runtimeType &&
          node == other.node;

  @override
  int get hashCode => node.hashCode;

  @override
  String toString() => _nodeToString(node);

  /// Converts this symbolic expression to standard LaTeX format.
  String toLaTeX() => _nodeToLaTeX(node);

  static String _nodeToString(ExpressionNode n) {
    if (n is NumberLiteralNode) return n.value.toString();
    if (n is VariableNode) return n.name;
    if (n is ConstantNode) return n.name;
    if (n is GroupNode) return '(${_nodeToString(n.inner)})';
    if (n is UnaryOpNode) {
      if (n.operator == UnaryOperator.negate) {
        final innerStr = _nodeToString(n.operand);
        if (n.operand is BinaryOpNode) return '-($innerStr)';
        return '-$innerStr';
      }
      if (n.operator == UnaryOperator.factorial) {
        return '${_nodeToString(n.operand)}!';
      }
      return '+${_nodeToString(n.operand)}';
    }
    if (n is BinaryOpNode) {
      final leftStr = _nodeToString(n.left);
      final rightStr = _nodeToString(n.right);
      switch (n.operator) {
        case BinaryOperator.add:
          return '$leftStr + $rightStr';
        case BinaryOperator.subtract:
          return '$leftStr - ${_wrapIfLower(n.right, BinaryOperator.subtract)}';
        case BinaryOperator.multiply:
          return '$leftStr * $rightStr';
        case BinaryOperator.divide:
          return '$leftStr / ${_wrapIfComposite(n.right)}';
        case BinaryOperator.power:
          return '${_wrapIfComposite(n.left)}^${_wrapIfComposite(n.right)}';
        case BinaryOperator.modulo:
          return '$leftStr % $rightStr';
      }
    }
    if (n is FunctionCallNode) {
      final argsStr = n.arguments.map(_nodeToString).join(', ');
      return '${n.name}($argsStr)';
    }
    return n.toString();
  }

  static String _wrapIfComposite(ExpressionNode n) {
    if (n is BinaryOpNode || n is UnaryOpNode) {
      return '(${_nodeToString(n)})';
    }
    return _nodeToString(n);
  }

  static String _wrapIfLower(ExpressionNode n, BinaryOperator parentOp) {
    if (n is BinaryOpNode &&
        (n.operator == BinaryOperator.add ||
            n.operator == BinaryOperator.subtract)) {
      return '(${_nodeToString(n)})';
    }
    return _nodeToString(n);
  }

  static String _nodeToLaTeX(ExpressionNode n) {
    if (n is NumberLiteralNode) return n.value.toString();
    if (n is VariableNode) return n.name;
    if (n is ConstantNode) {
      if (n.name.toLowerCase() == 'pi' || n.name == 'π') return r'\pi';
      if (n.name.toLowerCase() == 'phi' || n.name == 'ϕ' || n.name == 'φ') {
        return r'\phi';
      }
      return n.name;
    }
    if (n is GroupNode) return '(${_nodeToLaTeX(n.inner)})';
    if (n is UnaryOpNode) {
      if (n.operator == UnaryOperator.negate) {
        return '-${_nodeToLaTeX(n.operand)}';
      }
      if (n.operator == UnaryOperator.factorial) {
        return '{${_nodeToLaTeX(n.operand)}}!';
      }
      return '+${_nodeToLaTeX(n.operand)}';
    }
    if (n is BinaryOpNode) {
      switch (n.operator) {
        case BinaryOperator.add:
          return '${_nodeToLaTeX(n.left)} + ${_nodeToLaTeX(n.right)}';
        case BinaryOperator.subtract:
          return '${_nodeToLaTeX(n.left)} - ${_nodeToLaTeX(n.right)}';
        case BinaryOperator.multiply:
          return '${_nodeToLaTeX(n.left)} \\cdot ${_nodeToLaTeX(n.right)}';
        case BinaryOperator.divide:
          return '\\frac{${_nodeToLaTeX(n.left)}}{${_nodeToLaTeX(n.right)}}';
        case BinaryOperator.power:
          return '{${_nodeToLaTeX(n.left)}}^{${_nodeToLaTeX(n.right)}}';
        case BinaryOperator.modulo:
          return '${_nodeToLaTeX(n.left)} \\bmod ${_nodeToLaTeX(n.right)}';
      }
    }
    if (n is FunctionCallNode) {
      final argsStr = n.arguments.map(_nodeToLaTeX).join(', ');
      return '\\${n.name}\\left($argsStr\\right)';
    }
    return n.toString();
  }
}
