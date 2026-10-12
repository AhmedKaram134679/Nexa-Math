import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Represents a single algebraic term $c \cdot x_1^{k_1} x_2^{k_2} \dots$ for multi-variable manipulation.
final class Monomial {
  /// The scalar coefficient of this monomial.
  final ScalarValue coefficient;

  /// Map from variable name to integer exponent (e.g. {'x': 2, 'y': 1} for $x^2 y$).
  final Map<String, int> powers;

  Monomial(this.coefficient, Map<String, int> powers)
    : powers = _normalizePowers(powers);

  /// Constant monomial $c$.
  factory Monomial.constant(ScalarValue c) => Monomial(c, const {});

  /// Single variable monomial $c \cdot x^k$.
  factory Monomial.variable(
    String variable, {
    ScalarValue? coefficient,
    int power = 1,
  }) {
    final c = coefficient ?? IntegerValue.one;
    if (power == 0) return Monomial.constant(c);
    return Monomial(c, {variable: power});
  }

  static Map<String, int> _normalizePowers(Map<String, int> raw) {
    final map = <String, int>{};
    for (final entry in raw.entries) {
      if (entry.value > 0) {
        map[entry.key] = entry.value;
      }
    }
    // Return sorted keys for canonical comparison
    final sortedKeys = map.keys.toList()..sort();
    final sorted = <String, int>{};
    for (final k in sortedKeys) {
      sorted[k] = map[k]!;
    }
    return Map.unmodifiable(sorted);
  }

  /// Whether this is a constant term (all variable powers are 0).
  bool get isConstant => powers.isEmpty;

  /// Whether the coefficient is 0.
  bool get isZero => _isScalarZero(coefficient);

  /// Total degree of this monomial (sum of exponents).
  int get totalDegree =>
      powers.values.fold(0, (prev, element) => prev + element);

  /// Checks if another monomial has the exact same variable powers (is a "like term").
  bool isLikeTerm(Monomial other) {
    if (powers.length != other.powers.length) return false;
    for (final entry in powers.entries) {
      if (other.powers[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Adds another like term to this monomial.
  Monomial addLikeTerm(Monomial other, NumericEngine engine) {
    if (!isLikeTerm(other)) {
      throw ArgumentError('Cannot combine unlike terms: $this and $other');
    }
    final sum = engine.add(coefficient, other.coefficient).valueOrNull!;
    return Monomial(sum, powers);
  }

  /// Multiplies this monomial with another monomial.
  Monomial multiply(Monomial other, NumericEngine engine) {
    final prodCoeff = engine
        .multiply(coefficient, other.coefficient)
        .valueOrNull!;
    final combinedPowers = Map<String, int>.from(powers);
    for (final entry in other.powers.entries) {
      combinedPowers[entry.key] =
          (combinedPowers[entry.key] ?? 0) + entry.value;
    }
    return Monomial(prodCoeff, combinedPowers);
  }

  /// Converts this monomial into an [ExpressionNode] syntax tree.
  ExpressionNode toExpressionNode({
    SourcePosition position = SourcePosition.start,
  }) {
    if (powers.isEmpty) {
      return NumberLiteralNode(position: position, value: coefficient);
    }

    ExpressionNode? current;

    // Build variable product
    for (final entry in powers.entries) {
      ExpressionNode varNode = VariableNode(
        position: position,
        name: entry.key,
      );
      if (entry.value > 1) {
        varNode = BinaryOpNode(
          position: position,
          operator: BinaryOperator.power,
          left: varNode,
          right: NumberLiteralNode(
            position: position,
            value: IntegerValue.fromInt(entry.value),
          ),
        );
      }

      if (current == null) {
        current = varNode;
      } else {
        current = BinaryOpNode(
          position: position,
          operator: BinaryOperator.multiply,
          left: current,
          right: varNode,
          isImplicit: true,
        );
      }
    }

    final isOne = _isScalarOne(coefficient);
    final isNegOne = _isScalarNegativeOne(coefficient);

    if (isOne) {
      return current!;
    } else if (isNegOne) {
      return UnaryOpNode(
        position: position,
        operator: UnaryOperator.negate,
        operand: current!,
        isPrefix: true,
      );
    } else {
      return BinaryOpNode(
        position: position,
        operator: BinaryOperator.multiply,
        left: NumberLiteralNode(position: position, value: coefficient),
        right: current!,
        isImplicit: true,
      );
    }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Monomial &&
          runtimeType == other.runtimeType &&
          coefficient == other.coefficient &&
          isLikeTerm(other);

  @override
  int get hashCode => Object.hash(coefficient, powers.toString());

  @override
  String toString() {
    if (powers.isEmpty) return coefficient.toString();
    final sb = StringBuffer();
    if (!_isScalarOne(coefficient)) {
      if (_isScalarNegativeOne(coefficient)) {
        sb.write('-');
      } else {
        sb.write('$coefficient*');
      }
    }
    var first = true;
    for (final entry in powers.entries) {
      if (!first) sb.write('*');
      first = false;
      sb.write(entry.key);
      if (entry.value > 1) sb.write('^${entry.value}');
    }
    return sb.toString();
  }
}
