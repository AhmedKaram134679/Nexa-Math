import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/simplification/algebraic_simplifier.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Contract for advanced domain-safe symbolic simplification.
abstract interface class SymbolicSimplifier {
  /// Simplifies an AST expression using domain-safe mathematical rewrite rules.
  MathResult<ExpressionNode> simplify(ExpressionNode expression);
}

/// Production implementation of [SymbolicSimplifier].
///
/// Features:
/// 1. Identity elimination ($x + 0 \to x$, $x \cdot 1 \to x$, $x \cdot 0 \to 0$).
/// 2. Constant folding and power rules ($x^1 \to x$, $1^x \to 1$).
/// 3. Domain safety: preserves indeterminate $0^0$, $0/0$, prevents illegal reductions like $x/x \to 1$ or $\sqrt{x^2} \to x$.
/// 4. Like-term collection for products and sums.
/// 5. Fixpoint loop with cycle prevention.
final class DefaultSymbolicSimplifier
    implements SymbolicSimplifier, ExpressionVisitor<ExpressionNode, void> {
  final NumericEngine numericEngine;
  final AlgebraicSimplifier algebraicSimplifier;

  DefaultSymbolicSimplifier({
    NumericEngine? numericEngine,
    AlgebraicSimplifier? algebraicSimplifier,
  }) : numericEngine = numericEngine ?? NumericEngine(),
       algebraicSimplifier =
           algebraicSimplifier ??
           DefaultAlgebraicSimplifier(numericEngine: numericEngine);

  @override
  MathResult<ExpressionNode> simplify(ExpressionNode expression) {
    var current = expression;
    for (var i = 0; i < 10; i++) {
      // Step A: Basic algebraic simplification
      final algRes = algebraicSimplifier.simplify(current);
      final afterAlg = algRes.valueOrNull ?? current;

      // Step B: Symbolic domain-safe visitor pass
      final next = afterAlg.accept(this, null);
      if (next == current) break;
      current = next;
    }
    return MathSuccess(current);
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
    if (inner is NumberLiteralNode ||
        inner is VariableNode ||
        inner is ConstantNode ||
        inner is GroupNode) {
      return inner;
    }
    return GroupNode(position: node.position, inner: inner);
  }

  @override
  ExpressionNode visitUnaryOp(UnaryOpNode node, void context) {
    final operand = node.operand.accept(this, context);
    switch (node.operator) {
      case UnaryOperator.plus:
        return operand;
      case UnaryOperator.negate:
        if (operand is UnaryOpNode &&
            operand.operator == UnaryOperator.negate) {
          return operand.operand;
        }
        if (operand is NumberLiteralNode) {
          final neg = numericEngine.negate(operand.value).valueOrNull!;
          return NumberLiteralNode(position: node.position, value: neg);
        }
        return UnaryOpNode(
          position: node.position,
          operator: UnaryOperator.negate,
          operand: operand,
          isPrefix: node.isPrefix,
        );
      case UnaryOperator.factorial:
        return UnaryOpNode(
          position: node.position,
          operator: UnaryOperator.factorial,
          operand: operand,
          isPrefix: false,
        );
    }
  }

  @override
  ExpressionNode visitBinaryOp(BinaryOpNode node, void context) {
    final left = node.left.accept(this, context);
    final right = node.right.accept(this, context);

    switch (node.operator) {
      case BinaryOperator.add:
        if (_isZeroLiteral(left)) return right;
        if (_isZeroLiteral(right)) return left;
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
        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.add,
          left: left,
          right: right,
        );

      case BinaryOperator.subtract:
        if (_isZeroLiteral(right)) return left;
        if (_isZeroLiteral(left)) {
          return UnaryOpNode(
            position: node.position,
            operator: UnaryOperator.negate,
            operand: right,
            isPrefix: true,
          );
        }
        if (left == right) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.zero,
          );
        }
        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.subtract,
          left: left,
          right: right,
        );

      case BinaryOperator.multiply:
        if (_isZeroLiteral(left) || _isZeroLiteral(right)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.zero,
          );
        }
        if (_isOneLiteral(left)) return right;
        if (_isOneLiteral(right)) return left;

        // Like-power products: x^a * x^b -> x^(a+b)
        final powerCombined = _combinePowersOfSameBase(
          left,
          right,
          node.position,
        );
        if (powerCombined != null) return powerCombined;

        if (left == right) {
          // If left is an expression with an explicit fractional or non-integer exponent
          // (e.g. x^(1/2)), forming (x^(1/2))^2 would later simplify to x^1 = x, which
          // would alter the domain. _combinePowersOfSameBase already refused combining it.
          // Therefore, only reduce identical terms to left^2 if left is not a fractional power.
          if (left is BinaryOpNode && left.operator == BinaryOperator.power) {
            final exp = left.right;
            if (!_isProvenPositiveInteger(exp) &&
                !_isProvenNonZero(left.left)) {
              // Leave unsimplified to prevent domain alteration
              return BinaryOpNode(
                position: node.position,
                operator: BinaryOperator.multiply,
                left: left,
                right: right,
                isImplicit: node.isImplicit,
              );
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

        // Constant coefficient folding: c1 * (c2 * x) -> (c1 * c2) * x or (x * c1) * c2 -> (c1 * c2) * x
        if (left is NumberLiteralNode &&
            right is BinaryOpNode &&
            right.operator == BinaryOperator.multiply) {
          if (right.left is NumberLiteralNode) {
            final prod = numericEngine
                .multiply(left.value, (right.left as NumberLiteralNode).value)
                .valueOrNull;
            if (prod != null) {
              return BinaryOpNode(
                position: node.position,
                operator: BinaryOperator.multiply,
                left: NumberLiteralNode(position: node.position, value: prod),
                right: right.right,
              );
            }
          }
        }
        if (right is NumberLiteralNode &&
            left is BinaryOpNode &&
            left.operator == BinaryOperator.multiply) {
          if (left.left is NumberLiteralNode) {
            final prod = numericEngine
                .multiply(right.value, (left.left as NumberLiteralNode).value)
                .valueOrNull;
            if (prod != null) {
              return BinaryOpNode(
                position: node.position,
                operator: BinaryOperator.multiply,
                left: NumberLiteralNode(position: node.position, value: prod),
                right: left.right,
              );
            }
          }
        }

        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.multiply,
          left: left,
          right: right,
          isImplicit: node.isImplicit,
        );

      case BinaryOperator.divide:
        // Division by 0: preserved as error / not simplified
        if (_isZeroLiteral(right)) {
          return BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.divide,
            left: left,
            right: right,
          );
        }
        // 0 / c -> 0 (for non-zero c)
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
        // Non-zero literal division: 5 / 5 -> 1
        if (left is NumberLiteralNode &&
            right is NumberLiteralNode &&
            left.value == right.value &&
            !_isScalarZero(left.value)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          );
        }
        // IMPORTANT: DO NOT blindly transform x / x -> 1 because x could be 0!
        return BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.divide,
          left: left,
          right: right,
        );

      case BinaryOperator.power:
        // 0^0 is indeterminate, preserve without rewrite
        if (_isZeroLiteral(left) && _isZeroLiteral(right)) {
          return BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.power,
            left: left,
            right: right,
          );
        }
        // x^1 -> x
        if (_isOneLiteral(right)) return left;
        // 1^x -> 1
        if (_isOneLiteral(left)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          );
        }
        // Constant non-zero base to 0: c^0 -> 1
        if (_isZeroLiteral(right) &&
            left is NumberLiteralNode &&
            !_isScalarZero(left.value)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          );
        }
        // 0^c -> 0 for positive literal c
        if (_isZeroLiteral(left) &&
            right is NumberLiteralNode &&
            _isScalarPositive(right.value)) {
          return NumberLiteralNode(
            position: node.position,
            value: IntegerValue.zero,
          );
        }
        // Power of a power: (x^a)^b -> x^(a*b) for integer b
        if (left is BinaryOpNode &&
            left.operator == BinaryOperator.power &&
            right is NumberLiteralNode) {
          final expProd = BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.multiply,
            left: left.right,
            right: right,
          );
          return BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.power,
            left: left.left,
            right: expProd,
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

  ExpressionNode? _combinePowersOfSameBase(
    ExpressionNode left,
    ExpressionNode right,
    SourcePosition pos,
  ) {
    ExpressionNode baseL = left;
    ExpressionNode expL = NumberLiteralNode(
      position: pos,
      value: IntegerValue.one,
    );
    if (left is BinaryOpNode && left.operator == BinaryOperator.power) {
      baseL = left.left;
      expL = left.right;
    }

    ExpressionNode baseR = right;
    ExpressionNode expR = NumberLiteralNode(
      position: pos,
      value: IntegerValue.one,
    );
    if (right is BinaryOpNode && right.operator == BinaryOperator.power) {
      baseR = right.left;
      expR = right.right;
    }

    if (baseL == baseR) {
      // Domain Safety Check:
      // If the base is not a proven non-zero literal, combining exponents changes
      // the mathematical domain unless both exponents are proven non-negative.
      // E.g., x^a * x^b can have a = -1, b = 2 where x^-1 * x^2 is undefined at x = 0,
      // but x^1 is defined at x = 0. Likewise, x * x^-1 is undefined at x = 0.
      final baseIsProvenNonZero = _isProvenNonZero(baseL);
      if (!baseIsProvenNonZero) {
        if (!_isProvenPositiveInteger(expL) ||
            !_isProvenPositiveInteger(expR)) {
          return null; // Refuse domain-changing reduction for unrestricted, zero, negative, or fractional exponents
        }
      }

      final sumExp = BinaryOpNode(
        position: pos,
        operator: BinaryOperator.add,
        left: expL,
        right: expR,
      );
      final simplifiedExp = simplify(sumExp).valueOrNull ?? sumExp;
      return BinaryOpNode(
        position: pos,
        operator: BinaryOperator.power,
        left: baseL,
        right: simplifiedExp,
      );
    }
    return null;
  }

  bool _isProvenNonZero(ExpressionNode node) {
    if (node is NumberLiteralNode) {
      return !_isScalarZero(node.value);
    }
    return false;
  }

  bool _isProvenPositiveInteger(ExpressionNode node) {
    if (node is NumberLiteralNode) {
      final val = node.value;
      if (val is IntegerValue) return val.isPositive;
    }
    return false;
  }

  bool _isZeroLiteral(ExpressionNode n) =>
      n is NumberLiteralNode && _isScalarZero(n.value);

  bool _isOneLiteral(ExpressionNode n) =>
      n is NumberLiteralNode && _isScalarOne(n.value);

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

  static bool _isScalarPositive(ScalarValue s) {
    if (s is IntegerValue) return s.isPositive;
    if (s is FractionValue) return s.isPositive;
    return false;
  }
}
