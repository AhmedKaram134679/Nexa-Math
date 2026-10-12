import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/symbolic/default_symbolic_engine.dart';
import 'package:nexa_math/mathematical_core/symbolic/models/symbolic_expression.dart';

/// Primary public façade interface for the NexaMath Symbolic Mathematics Engine.
///
/// Dispatches and coordinates:
/// - Parsing expressions into immutable [SymbolicExpression] domain representations.
/// - Deterministic, domain-safe symbolic simplification and canonical normalization.
/// - Exact single and multi-variable substitution.
/// - Symbolic polynomial expansion (distributive law, binomial powers).
/// - Polynomial factorization integration.
/// - Symbolic differentiation with analytical rules (sum, product, quotient, chain, power, trig, exp, ln).
/// - Safe structural and mathematical equivalence checking.
abstract interface class SymbolicEngine {
  /// Default factory constructor creating the canonical production [DefaultSymbolicEngine].
  factory SymbolicEngine() = DefaultSymbolicEngine;

  /// Parses a raw mathematical expression string into a [SymbolicExpression].
  MathResult<SymbolicExpression> parse(String expression);

  /// Converts an AST [ExpressionNode] into a [SymbolicExpression].
  SymbolicExpression fromNode(ExpressionNode node);

  /// Simplifies a [SymbolicExpression] using domain-safe, deterministic rewrite rules.
  MathResult<SymbolicExpression> simplify(SymbolicExpression expression);

  /// Simplifies a raw mathematical expression string.
  MathResult<SymbolicExpression> simplifyString(String expression);

  /// Normalizes a [SymbolicExpression] into canonical structural order.
  MathResult<SymbolicExpression> canonicalize(SymbolicExpression expression);

  /// Substitutes [variableName] with [replacement] inside [expression].
  MathResult<SymbolicExpression> substitute(
    SymbolicExpression expression,
    String variableName,
    SymbolicExpression replacement,
  );

  /// Substitutes multiple variables simultaneously using a map of replacements.
  MathResult<SymbolicExpression> substituteAll(
    SymbolicExpression expression,
    Map<String, SymbolicExpression> substitutions,
  );

  /// Substitutes scalar values for variables.
  MathResult<SymbolicExpression> substituteValues(
    SymbolicExpression expression,
    Map<String, ScalarValue> values,
  );

  /// Expands products and integer powers symbolically.
  MathResult<SymbolicExpression> expand(SymbolicExpression expression);

  /// Expands a raw mathematical expression string symbolically.
  MathResult<SymbolicExpression> expandString(String expression);

  /// Factors a [SymbolicExpression] into irreducible factors where supported.
  MathResult<SymbolicExpression> factor(SymbolicExpression expression);

  /// Computes the exact symbolic derivative with respect to [variableName].
  MathResult<SymbolicExpression> differentiate(
    SymbolicExpression expression, {
    String variableName = 'x',
  });

  /// Computes the exact symbolic derivative of an expression string with respect to [variableName].
  MathResult<SymbolicExpression> differentiateString(
    String expression, {
    String variableName = 'x',
  });

  /// Evaluates whether two symbolic expressions are mathematically equivalent within supported bounded forms.
  MathResult<bool> areEquivalent(SymbolicExpression a, SymbolicExpression b);
}
