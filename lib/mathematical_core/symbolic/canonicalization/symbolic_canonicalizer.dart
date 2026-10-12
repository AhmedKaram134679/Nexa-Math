import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/simplification/algebraic_simplifier.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Contract for deterministic symbolic canonicalization.
abstract interface class SymbolicCanonicalizer {
  /// Normalizes an [ExpressionNode] into canonical associative, commutative, and structural form.
  MathResult<ExpressionNode> canonicalize(ExpressionNode expression);
}

/// Production implementation of [SymbolicCanonicalizer].
///
/// Implements:
/// 1. Flattening of associative operators (`+` and `*`).
/// 2. Deterministic total ordering of terms (numbers -> constants -> variables -> composite terms).
/// 3. Collection of identical terms and like-terms during canonical sorting.
/// 4. Elimination of trivial grouping structures.
final class DefaultSymbolicCanonicalizer
    implements SymbolicCanonicalizer, ExpressionVisitor<ExpressionNode, void> {
  final NumericEngine numericEngine;
  final AlgebraicSimplifier simplifier;

  DefaultSymbolicCanonicalizer({
    NumericEngine? numericEngine,
    AlgebraicSimplifier? simplifier,
  }) : numericEngine = numericEngine ?? NumericEngine(),
       simplifier =
           simplifier ??
           DefaultAlgebraicSimplifier(numericEngine: numericEngine);

  @override
  MathResult<ExpressionNode> canonicalize(ExpressionNode expression) {
    // First apply algebraic simplification
    final simpRes = simplifier.simplify(expression);
    final simplified = simpRes.valueOrNull ?? expression;

    // Next canonicalize recursively
    final canonical = simplified.accept(this, null);
    return MathSuccess(canonical);
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
    final op = node.operand.accept(this, context);
    return UnaryOpNode(
      position: node.position,
      operator: node.operator,
      operand: op,
      isPrefix: node.isPrefix,
    );
  }

  @override
  ExpressionNode visitBinaryOp(BinaryOpNode node, void context) {
    final left = node.left.accept(this, context);
    final right = node.right.accept(this, context);

    if (node.operator == BinaryOperator.add) {
      return _canonicalizeSum(left, right, node.position);
    }

    if (node.operator == BinaryOperator.multiply) {
      return _canonicalizeProduct(left, right, node.position);
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
    final args = node.arguments.map((a) => a.accept(this, context)).toList();
    return FunctionCallNode(
      position: node.position,
      name: node.name,
      arguments: List.unmodifiable(args),
    );
  }

  ExpressionNode _canonicalizeSum(
    ExpressionNode left,
    ExpressionNode right,
    SourcePosition pos,
  ) {
    final terms = <ExpressionNode>[];
    _flattenSum(left, terms);
    _flattenSum(right, terms);

    // Group numbers vs non-numbers
    ScalarValue numericSum = IntegerValue.zero;
    final nonNumericTerms = <ExpressionNode>[];

    for (final term in terms) {
      if (term is NumberLiteralNode) {
        numericSum =
            numericEngine.add(numericSum, term.value).valueOrNull ?? numericSum;
      } else {
        nonNumericTerms.add(term);
      }
    }

    // Combine like non-numeric terms (e.g. 2*x and 3*x -> 5*x)
    final combinedLikeTerms = _combineLikeTermsList(nonNumericTerms, pos);

    // Sort non-numeric terms by deterministic canonical order
    combinedLikeTerms.sort(_compareNodes);

    // Reassemble sum: non-numeric terms first, constant at the end (standard polynomial order)
    final combined = <ExpressionNode>[...combinedLikeTerms];
    if (!_isScalarZero(numericSum) || combined.isEmpty) {
      combined.add(NumberLiteralNode(position: pos, value: numericSum));
    }

    if (combined.isEmpty) {
      return NumberLiteralNode(position: pos, value: IntegerValue.zero);
    }
    if (combined.length == 1) {
      return combined.first;
    }

    ExpressionNode result = combined.first;
    for (var i = 1; i < combined.length; i++) {
      result = BinaryOpNode(
        position: pos,
        operator: BinaryOperator.add,
        left: result,
        right: combined[i],
      );
    }
    return result;
  }

  List<ExpressionNode> _combineLikeTermsList(
    List<ExpressionNode> terms,
    SourcePosition pos,
  ) {
    if (terms.isEmpty) return terms;
    final map = <String, (ScalarValue coeff, ExpressionNode varPart)>{};

    for (final term in terms) {
      final (coeff, varPart) = _extractCoeffAndVarPart(term);
      final key = _nodeKey(varPart);
      if (map.containsKey(key)) {
        final existing = map[key]!;
        final newCoeff =
            numericEngine.add(existing.$1, coeff).valueOrNull ?? existing.$1;
        map[key] = (newCoeff, existing.$2);
      } else {
        map[key] = (coeff, varPart);
      }
    }

    final result = <ExpressionNode>[];
    for (final entry in map.values) {
      final coeff = entry.$1;
      final varPart = entry.$2;
      if (_isScalarZero(coeff)) continue;
      if (_isScalarOne(coeff)) {
        result.add(varPart);
      } else {
        result.add(
          BinaryOpNode(
            position: pos,
            operator: BinaryOperator.multiply,
            left: NumberLiteralNode(position: pos, value: coeff),
            right: varPart,
          ),
        );
      }
    }
    return result;
  }

  (ScalarValue, ExpressionNode) _extractCoeffAndVarPart(ExpressionNode node) {
    if (node is BinaryOpNode && node.operator == BinaryOperator.multiply) {
      if (node.left is NumberLiteralNode) {
        return ((node.left as NumberLiteralNode).value, node.right);
      }
      if (node.right is NumberLiteralNode) {
        return ((node.right as NumberLiteralNode).value, node.left);
      }
    }
    return (IntegerValue.one, node);
  }

  String _nodeKey(ExpressionNode node) {
    // Generate a deterministic structural key for like-term matching
    if (node is VariableNode) return 'v:${node.name}';
    if (node is BinaryOpNode && node.operator == BinaryOperator.power) {
      return 'pow:${_nodeKey(node.left)}^${node.right}';
    }
    return node.toString();
  }

  ExpressionNode _canonicalizeProduct(
    ExpressionNode left,
    ExpressionNode right,
    SourcePosition pos,
  ) {
    final factors = <ExpressionNode>[];
    _flattenProduct(left, factors);
    _flattenProduct(right, factors);

    ScalarValue numericProduct = IntegerValue.one;
    final nonNumericFactors = <ExpressionNode>[];

    for (final factor in factors) {
      if (factor is NumberLiteralNode) {
        numericProduct =
            numericEngine.multiply(numericProduct, factor.value).valueOrNull ??
            numericProduct;
      } else if (factor is BinaryOpNode &&
          factor.operator == BinaryOperator.multiply &&
          (factor.left is NumberLiteralNode ||
              factor.right is NumberLiteralNode)) {
        // Unpack nested constant multiplication e.g. 4 * (2 * x)
        final subFactors = <ExpressionNode>[];
        _flattenProduct(factor, subFactors);
        for (final sub in subFactors) {
          if (sub is NumberLiteralNode) {
            numericProduct =
                numericEngine.multiply(numericProduct, sub.value).valueOrNull ??
                numericProduct;
          } else {
            nonNumericFactors.add(sub);
          }
        }
      } else {
        nonNumericFactors.add(factor);
      }
    }

    // If numeric factor is zero, whole product is zero
    if (_isScalarZero(numericProduct)) {
      return NumberLiteralNode(position: pos, value: IntegerValue.zero);
    }

    // Sort non-numeric factors canonically
    nonNumericFactors.sort(_compareNodes);

    final combined = <ExpressionNode>[];
    // Leading coefficient comes first
    if (!_isScalarOne(numericProduct) || nonNumericFactors.isEmpty) {
      combined.add(NumberLiteralNode(position: pos, value: numericProduct));
    }
    combined.addAll(nonNumericFactors);

    if (combined.isEmpty) {
      return NumberLiteralNode(position: pos, value: IntegerValue.one);
    }
    if (combined.length == 1) {
      return combined.first;
    }

    ExpressionNode result = combined.first;
    for (var i = 1; i < combined.length; i++) {
      result = BinaryOpNode(
        position: pos,
        operator: BinaryOperator.multiply,
        left: result,
        right: combined[i],
      );
    }
    return result;
  }

  void _flattenSum(ExpressionNode node, List<ExpressionNode> terms) {
    if (node is BinaryOpNode && node.operator == BinaryOperator.add) {
      _flattenSum(node.left, terms);
      _flattenSum(node.right, terms);
    } else {
      terms.add(node);
    }
  }

  void _flattenProduct(ExpressionNode node, List<ExpressionNode> factors) {
    if (node is BinaryOpNode && node.operator == BinaryOperator.multiply) {
      _flattenProduct(node.left, factors);
      _flattenProduct(node.right, factors);
    } else {
      factors.add(node);
    }
  }

  static int _compareNodes(ExpressionNode a, ExpressionNode b) {
    // 1. Order by structural type priority: Variable < Function < Binary < Constant < Number
    final pA = _typePriority(a);
    final pB = _typePriority(b);
    if (pA != pB) return pA.compareTo(pB);

    // 2. Variables compared lexicographically
    if (a is VariableNode && b is VariableNode) {
      return a.name.compareTo(b.name);
    }

    // 3. Constants compared lexicographically
    if (a is ConstantNode && b is ConstantNode) {
      return a.name.compareTo(b.name);
    }

    // 4. Function calls compared by name then arguments
    if (a is FunctionCallNode && b is FunctionCallNode) {
      final nameComp = a.name.compareTo(b.name);
      if (nameComp != 0) return nameComp;
      if (a.arguments.length != b.arguments.length) {
        return a.arguments.length.compareTo(b.arguments.length);
      }
      for (var i = 0; i < a.arguments.length; i++) {
        final c = _compareNodes(a.arguments[i], b.arguments[i]);
        if (c != 0) return c;
      }
      return 0;
    }

    // 5. Binary operators
    if (a is BinaryOpNode && b is BinaryOpNode) {
      final opComp = a.operator.index.compareTo(b.operator.index);
      if (opComp != 0) return opComp;
      final leftComp = _compareNodes(a.left, b.left);
      if (leftComp != 0) return leftComp;
      return _compareNodes(a.right, b.right);
    }

    // Fallback string representation comparison
    return a.toString().compareTo(b.toString());
  }

  static int _typePriority(ExpressionNode n) {
    if (n is VariableNode) return 1;
    if (n is FunctionCallNode) return 2;
    if (n is BinaryOpNode) return 3;
    if (n is UnaryOpNode) return 4;
    if (n is ConstantNode) return 5;
    if (n is NumberLiteralNode) return 6;
    return 7;
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
}
