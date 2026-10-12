import 'package:nexa_math/mathematical_core/algebra/simplification/algebraic_simplifier.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Represents an immutable algebraic equation: $LHS = RHS$.
final class Equation extends MathValue {
  /// The left-hand side expression.
  final ExpressionNode left;

  /// The right-hand side expression.
  final ExpressionNode right;

  const Equation({required this.left, required this.right});

  /// Normalizes the equation to standard zero-form: $LHS - RHS = 0$.
  Equation normalizeToZero() {
    final normalizedLhs = BinaryOpNode(
      position: left.position,
      operator: BinaryOperator.subtract,
      left: left,
      right: right,
    );
    final zeroRhs = NumberLiteralNode(
      position: right.position,
      value: IntegerValue.zero,
    );
    return Equation(left: normalizedLhs, right: zeroRhs);
  }

  /// Simplifies both sides of the equation using [simplifier].
  Equation simplify({AlgebraicSimplifier? simplifier}) {
    final s = simplifier ?? DefaultAlgebraicSimplifier();
    final simplifiedLeft = s.simplify(left).valueOrNull ?? left;
    final simplifiedRight = s.simplify(right).valueOrNull ?? right;
    return Equation(left: simplifiedLeft, right: simplifiedRight);
  }

  /// Moves all terms to the left side and simplifies: $\text{simplify}(LHS - RHS) = 0$.
  Equation toCanonicalForm({AlgebraicSimplifier? simplifier}) {
    return normalizeToZero().simplify(simplifier: simplifier);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Equation &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(left, right);

  @override
  String toString() => '$left = $right';
}
