import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Contract for deterministic algebraic simplification.
abstract interface class AlgebraicSimplifier {
  /// Simplifies an AST expression node using mathematically guaranteed rewrite rules.
  MathResult<ExpressionNode> simplify(ExpressionNode expression);
}

/// Production implementation of [AlgebraicSimplifier].
final class DefaultAlgebraicSimplifier
    implements AlgebraicSimplifier, ExpressionVisitor<ExpressionNode, void> {
  final NumericEngine numericEngine;

  DefaultAlgebraicSimplifier({NumericEngine? numericEngine})
    : numericEngine = numericEngine ?? NumericEngine();

  @override
  MathResult<ExpressionNode> simplify(ExpressionNode expression) {
    var current = expression;
    // Iterate until fixpoint (no further changes) or max iterations to avoid cycles
    for (var i = 0; i < 10; i++) {
      final next = current.accept(this, null);
      if (next == current) break;
      current = next;
    }
    return MathSuccess(current);
  }

  @override
  ExpressionNode visitNumberLiteral(NumberLiteralNode node, void context) {
    return node;
  }

  @override
  ExpressionNode visitVariable(VariableNode node, void context) {
    return node;
  }

  @override
  ExpressionNode visitConstant(ConstantNode node, void context) {
    return node;
  }

  @override
  ExpressionNode visitGroup(GroupNode node, void context) {
    final simplifiedInner = node.inner.accept(this, context);
    // Remove group if inner is already an atomic literal, variable, constant, or group
    if (simplifiedInner is NumberLiteralNode ||
        simplifiedInner is VariableNode ||
        simplifiedInner is ConstantNode ||
        simplifiedInner is GroupNode) {
      return simplifiedInner;
    }
    return GroupNode(position: node.position, inner: simplifiedInner);
  }

  @override
  ExpressionNode visitUnaryOp(UnaryOpNode node, void context) {
    final simplifiedOperand = node.operand.accept(this, context);

    switch (node.operator) {
      case UnaryOperator.plus:
        return simplifiedOperand;

      case UnaryOperator.negate:
        // Double negation: -(-x) -> x
        if (simplifiedOperand is UnaryOpNode &&
            simplifiedOperand.operator == UnaryOperator.negate) {
          return simplifiedOperand.operand;
        }
        // Negate number literal directly: -(5) -> -5
        if (simplifiedOperand is NumberLiteralNode) {
          final val = simplifiedOperand.value;
          final negated = numericEngine.negate(val).valueOrNull!;
          return NumberLiteralNode(position: node.position, value: negated);
        }
        return UnaryOpNode(
          position: node.position,
          operator: UnaryOperator.negate,
          operand: simplifiedOperand,
          isPrefix: node.isPrefix,
        );

      case UnaryOperator.factorial:
        if (simplifiedOperand is NumberLiteralNode &&
            simplifiedOperand.value is IntegerValue) {
          final val = simplifiedOperand.value as IntegerValue;
          if (val.value >= BigInt.zero && val.value <= BigInt.from(20)) {
            final factRes = numericEngine.factorial(val);
            if (factRes.isSuccess) {
              return NumberLiteralNode(
                position: node.position,
                value: factRes.valueOrNull!,
              );
            }
          }
        }
        return UnaryOpNode(
          position: node.position,
          operator: UnaryOperator.factorial,
          operand: simplifiedOperand,
          isPrefix: false,
        );
    }
  }

  @override
  ExpressionNode visitBinaryOp(BinaryOpNode node, void context) {
    final left = node.left.accept(this, context);
    final right = node.right.accept(this, context);

    // Constant folding if both are numbers
    if (left is NumberLiteralNode && right is NumberLiteralNode) {
      final folded = _foldBinaryNumbers(node.operator, left.value, right.value);
      if (folded != null) {
        return NumberLiteralNode(position: node.position, value: folded);
      }
    }

    switch (node.operator) {
      case BinaryOperator.add:
        // x + 0 -> x
        if (_isZeroLiteral(right)) return left;
        // 0 + x -> x
        if (_isZeroLiteral(left)) return right;
        // x + x -> 2 * x
        if (left == right) {
          return BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.multiply,
            left: NumberLiteralNode(
              position: node.position,
              value: IntegerValue.fromInt(2),
            ),
            right: left,
            isImplicit: true,
          );
        }
        // Like-term addition: c1*x + c2*x -> (c1+c2)*x
        final combinedAdd = _combineLikeTermsAdd(left, right, node.position);
        if (combinedAdd != null) return combinedAdd;

        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.add,
          left: left,
          right: right,
        );

      case BinaryOperator.subtract:
        // x - 0 -> x
        if (_isZeroLiteral(right)) return left;
        // 0 - x -> -x
        if (_isZeroLiteral(left)) {
          return UnaryOpNode(
            position: node.position,
            operator: UnaryOperator.negate,
            operand: right,
            isPrefix: true,
          );
        }
        // x - x -> 0
        if (left == right) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.zero,
          );
        }
        // Like-term subtraction: c1*x - c2*x -> (c1-c2)*x
        final combinedSub = _combineLikeTermsSub(left, right, node.position);
        if (combinedSub != null) return combinedSub;

        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.subtract,
          left: left,
          right: right,
        );

      case BinaryOperator.multiply:
        // x * 0 -> 0 or 0 * x -> 0
        if (_isZeroLiteral(left) || _isZeroLiteral(right)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.zero,
          );
        }
        // x * 1 -> x
        if (_isOneLiteral(right)) return left;
        // 1 * x -> x
        if (_isOneLiteral(left)) return right;
        // x * -1 -> -x
        if (_isNegativeOneLiteral(right)) {
          return UnaryOpNode(
            position: node.position,
            operator: UnaryOperator.negate,
            operand: left,
            isPrefix: true,
          );
        }
        // -1 * x -> -x
        if (_isNegativeOneLiteral(left)) {
          return UnaryOpNode(
            position: node.position,
            operator: UnaryOperator.negate,
            operand: right,
            isPrefix: true,
          );
        }
        // x * x -> x^2 (only if left is not a fractional or zero power of an unproven base)
        if (left == right) {
          if (left is BinaryOpNode && left.operator == BinaryOperator.power) {
            final exp = left.right;
            if (exp is NumberLiteralNode) {
              final v = exp.value;
              if (v is FractionValue ||
                  (v is IntegerValue && v.value <= BigInt.zero)) {
                return BinaryOpNode(
                  position: node.position,
                  operator: BinaryOperator.multiply,
                  left: left,
                  right: right,
                  isImplicit: node.isImplicit,
                );
              }
            }
          }
          return BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.power,
            left: left,
            right: NumberLiteralNode(
              position: node.position,
              value: IntegerValue.fromInt(2),
            ),
          );
        }

        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.multiply,
          left: left,
          right: right,
          isImplicit: node.isImplicit,
        );

      case BinaryOperator.divide:
        // Division by literal 0 is undefined / indeterminate; do not rewrite.
        if (_isZeroLiteral(right)) {
          return BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.divide,
            left: left,
            right: right,
          );
        }
        // 0 / c -> 0 (for non-zero literal c)
        if (_isZeroLiteral(left) &&
            right is NumberLiteralNode &&
            !_isScalarZero(right.value)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.zero,
          );
        }
        // x / 1 -> x
        if (_isOneLiteral(right)) return left;
        // Non-zero literal division x / x -> 1 (guaranteed non-zero)
        if (left == right &&
            left is NumberLiteralNode &&
            !_isScalarZero(left.value)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          );
        }

        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.divide,
          left: left,
          right: right,
        );

      case BinaryOperator.power:
        // Base 0 with exponent 0 is indeterminate 0^0; do not rewrite to 1 or 0.
        if (_isZeroLiteral(left) && _isZeroLiteral(right)) {
          return BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.power,
            left: left,
            right: right,
          );
        }
        // Non-zero literal base to power 0: c^0 -> 1
        if (_isZeroLiteral(right) &&
            left is NumberLiteralNode &&
            !_isScalarZero(left.value)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          );
        }
        // x ^ 1 -> x
        if (_isOneLiteral(right)) return left;
        // 0 ^ c -> 0 (for strictly positive literal c > 0)
        if (_isZeroLiteral(left) &&
            right is NumberLiteralNode &&
            _isScalarPositive(right.value)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.zero,
          );
        }
        // 1 ^ x -> 1
        if (_isOneLiteral(left)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          );
        }

        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.power,
          left: left,
          right: right,
        );

      case BinaryOperator.modulo:
        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.modulo,
          left: left,
          right: right,
        );
    }
  }

  @override
  ExpressionNode visitFunctionCall(FunctionCallNode node, void context) {
    final simplifiedArgs = node.arguments
        .map((a) => a.accept(this, context))
        .toList();
    return FunctionCallNode(
      position: node.position,
      name: node.name,
      arguments: List.unmodifiable(simplifiedArgs),
    );
  }

  ScalarValue? _foldBinaryNumbers(
    BinaryOperator op,
    ScalarValue a,
    ScalarValue b,
  ) {
    switch (op) {
      case BinaryOperator.add:
        return numericEngine.add(a, b).valueOrNull;
      case BinaryOperator.subtract:
        return numericEngine.subtract(a, b).valueOrNull;
      case BinaryOperator.multiply:
        return numericEngine.multiply(a, b).valueOrNull;
      case BinaryOperator.divide:
        if (_isScalarZero(b)) return null;
        return numericEngine.divide(a, b).valueOrNull;
      case BinaryOperator.power:
        return numericEngine.power(a, b).valueOrNull;
      case BinaryOperator.modulo:
        if (a is IntegerValue && b is IntegerValue && !b.isZero) {
          return IntegerValue(a.value % b.value);
        }
        return null;
    }
  }

  bool _isZeroLiteral(ExpressionNode node) =>
      node is NumberLiteralNode && _isScalarZero(node.value);

  bool _isOneLiteral(ExpressionNode node) {
    if (node is! NumberLiteralNode) return false;
    return _isScalarOne(node.value);
  }

  bool _isNegativeOneLiteral(ExpressionNode node) {
    if (node is! NumberLiteralNode) return false;
    return _isScalarNegativeOne(node.value);
  }

  static bool _isScalarZero(ScalarValue s) {
    if (s is IntegerValue) return s.isZero;
    if (s is FractionValue) return s.isZero;
    return false;
  }

  static bool _isScalarOne(ScalarValue s) {
    if (s is IntegerValue) return s.value == BigInt.one;
    if (s is FractionValue) return s == FractionValue.one;
    return false;
  }

  static bool _isScalarNegativeOne(ScalarValue s) {
    if (s is IntegerValue) return s.value == -BigInt.one;
    if (s is FractionValue) {
      return s.numerator == -BigInt.one && s.denominator == BigInt.one;
    }
    return false;
  }

  static bool _isScalarPositive(ScalarValue s) {
    if (s is IntegerValue) return s.isPositive;
    if (s is FractionValue) return s.isPositive;
    return false;
  }

  ExpressionNode? _combineLikeTermsAdd(
    ExpressionNode left,
    ExpressionNode right,
    SourcePosition pos,
  ) {
    final termA = _extractTerm(left);
    final termB = _extractTerm(right);
    if (termA != null &&
        termB != null &&
        termA.variablePart == termB.variablePart) {
      final sumCoeff = numericEngine.add(termA.coeff, termB.coeff).valueOrNull!;
      if (_isScalarZero(sumCoeff)) {
        return NumberLiteralNode(position: pos, value: IntegerValue.zero);
      }
      return _buildTerm(sumCoeff, termA.variablePart, pos);
    }
    return null;
  }

  ExpressionNode? _combineLikeTermsSub(
    ExpressionNode left,
    ExpressionNode right,
    SourcePosition pos,
  ) {
    final termA = _extractTerm(left);
    final termB = _extractTerm(right);
    if (termA != null &&
        termB != null &&
        termA.variablePart == termB.variablePart) {
      final diffCoeff = numericEngine
          .subtract(termA.coeff, termB.coeff)
          .valueOrNull!;
      if (_isScalarZero(diffCoeff)) {
        return NumberLiteralNode(position: pos, value: IntegerValue.zero);
      }
      return _buildTerm(diffCoeff, termA.variablePart, pos);
    }
    return null;
  }

  _ParsedTerm? _extractTerm(ExpressionNode node) {
    if (node is VariableNode) {
      return _ParsedTerm(coeff: IntegerValue.one, variablePart: node);
    }
    if (node is BinaryOpNode) {
      if (node.operator == BinaryOperator.power && node.left is VariableNode) {
        return _ParsedTerm(coeff: IntegerValue.one, variablePart: node);
      }
      if (node.operator == BinaryOperator.multiply &&
          node.left is NumberLiteralNode) {
        return _ParsedTerm(
          coeff: (node.left as NumberLiteralNode).value,
          variablePart: node.right,
        );
      }
    }
    if (node is UnaryOpNode &&
        node.operator == UnaryOperator.negate &&
        node.operand is VariableNode) {
      return _ParsedTerm(
        coeff: IntegerValue.fromInt(-1),
        variablePart: node.operand,
      );
    }
    return null;
  }

  ExpressionNode _buildTerm(
    ScalarValue coeff,
    ExpressionNode varPart,
    SourcePosition pos,
  ) {
    if (coeff is IntegerValue && coeff.value == BigInt.one) return varPart;
    if (coeff is IntegerValue && coeff.value == -BigInt.one) {
      return UnaryOpNode(
        position: pos,
        operator: UnaryOperator.negate,
        operand: varPart,
        isPrefix: true,
      );
    }
    return BinaryOpNode(
      position: pos,
      operator: BinaryOperator.multiply,
      left: NumberLiteralNode(position: pos, value: coeff),
      right: varPart,
      isImplicit: true,
    );
  }
}

final class _ParsedTerm {
  final ScalarValue coeff;
  final ExpressionNode variablePart;

  const _ParsedTerm({required this.coeff, required this.variablePart});
}
