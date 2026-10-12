import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/algebra_engine.dart';
import 'package:nexa_math/mathematical_core/algebra/expansion/expression_expander.dart';
import 'package:nexa_math/mathematical_core/algebra/factorization/polynomial_factorizer.dart';
import 'package:nexa_math/mathematical_core/algebra/substitution/expression_substitutor.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/symbolic/canonicalization/symbolic_canonicalizer.dart';
import 'package:nexa_math/mathematical_core/symbolic/differentiation/symbolic_differentiator.dart';
import 'package:nexa_math/mathematical_core/symbolic/models/symbolic_expression.dart';
import 'package:nexa_math/mathematical_core/symbolic/simplification/symbolic_simplifier.dart';
import 'package:nexa_math/mathematical_core/symbolic/symbolic_engine.dart';

/// Canonical production implementation of [SymbolicEngine].
///
/// Coordinates:
/// - Parsing through [ExpressionEngine]
/// - AST wrapping in [SymbolicExpression]
/// - Deterministic domain-safe simplification through [SymbolicSimplifier]
/// - Canonicalization through [SymbolicCanonicalizer]
/// - Substitution through [ExpressionSubstitutor]
/// - Expansion through [ExpressionExpander]
/// - Factorization through [PolynomialFactorizer] and [AlgebraEngine]
/// - Exact analytical differentiation through [SymbolicDifferentiator]
final class DefaultSymbolicEngine implements SymbolicEngine {
  final ExpressionEngine _expressionEngine;
  final AlgebraEngine _algebraEngine;
  final SymbolicSimplifier _simplifier;
  final SymbolicCanonicalizer _canonicalizer;
  final ExpressionSubstitutor _substitutor;
  final ExpressionExpander _expander;
  final PolynomialFactorizer _factorizer;
  final SymbolicDifferentiator _differentiator;

  DefaultSymbolicEngine({
    ExpressionEngine? expressionEngine,
    AlgebraEngine? algebraEngine,
    NumericEngine? numericEngine,
    SymbolicSimplifier? simplifier,
    SymbolicCanonicalizer? canonicalizer,
    ExpressionSubstitutor? substitutor,
    ExpressionExpander? expander,
    PolynomialFactorizer? factorizer,
    SymbolicDifferentiator? differentiator,
  }) : _expressionEngine = expressionEngine ?? ExpressionEngine(),
       _algebraEngine = algebraEngine ?? AlgebraEngine(),
       _simplifier =
           simplifier ??
           DefaultSymbolicSimplifier(numericEngine: numericEngine),
       _canonicalizer =
           canonicalizer ??
           DefaultSymbolicCanonicalizer(numericEngine: numericEngine),
       _substitutor = substitutor ?? const DefaultExpressionSubstitutor(),
       _expander = expander ?? DefaultExpressionExpander(),
       _factorizer =
           factorizer ??
           DefaultPolynomialFactorizer(numericEngine: numericEngine),
       _differentiator =
           differentiator ??
           DefaultSymbolicDifferentiator(numericEngine: numericEngine);

  @override
  MathResult<SymbolicExpression> parse(String expression) {
    final parseRes = _expressionEngine.parse(expression);
    if (parseRes.isFailure) return MathFailure(parseRes.errorOrNull!);
    return MathSuccess(SymbolicExpression(parseRes.valueOrNull!));
  }

  @override
  SymbolicExpression fromNode(ExpressionNode node) => SymbolicExpression(node);

  @override
  MathResult<SymbolicExpression> simplify(SymbolicExpression expression) {
    final simpRes = _simplifier.simplify(expression.node);
    if (simpRes.isFailure) return MathFailure(simpRes.errorOrNull!);
    return MathSuccess(SymbolicExpression(simpRes.valueOrNull!));
  }

  @override
  MathResult<SymbolicExpression> simplifyString(String expression) {
    final parseRes = parse(expression);
    if (parseRes.isFailure) return parseRes;
    return simplify(parseRes.valueOrNull!);
  }

  @override
  MathResult<SymbolicExpression> canonicalize(SymbolicExpression expression) {
    final canonRes = _canonicalizer.canonicalize(expression.node);
    if (canonRes.isFailure) return MathFailure(canonRes.errorOrNull!);
    return MathSuccess(SymbolicExpression(canonRes.valueOrNull!));
  }

  @override
  MathResult<SymbolicExpression> substitute(
    SymbolicExpression expression,
    String variableName,
    SymbolicExpression replacement,
  ) {
    final subRes = _substitutor.substitute(
      expression.node,
      variableName,
      replacement.node,
    );
    if (subRes.isFailure) return MathFailure(subRes.errorOrNull!);
    // Simplify after substitution
    return simplify(SymbolicExpression(subRes.valueOrNull!));
  }

  @override
  MathResult<SymbolicExpression> substituteAll(
    SymbolicExpression expression,
    Map<String, SymbolicExpression> substitutions,
  ) {
    final nodeMap = substitutions.map((k, v) => MapEntry(k, v.node));
    final subRes = _substitutor.substituteAll(expression.node, nodeMap);
    if (subRes.isFailure) return MathFailure(subRes.errorOrNull!);
    return simplify(SymbolicExpression(subRes.valueOrNull!));
  }

  @override
  MathResult<SymbolicExpression> substituteValues(
    SymbolicExpression expression,
    Map<String, ScalarValue> values,
  ) {
    final subRes = _substitutor.substituteValues(expression.node, values);
    if (subRes.isFailure) return MathFailure(subRes.errorOrNull!);
    return simplify(SymbolicExpression(subRes.valueOrNull!));
  }

  @override
  MathResult<SymbolicExpression> expand(SymbolicExpression expression) {
    final expRes = _expander.expand(expression.node);
    if (expRes.isFailure) return MathFailure(expRes.errorOrNull!);
    final canonRes = _canonicalizer.canonicalize(expRes.valueOrNull!);
    if (canonRes.isFailure) return MathFailure(canonRes.errorOrNull!);
    return MathSuccess(SymbolicExpression(canonRes.valueOrNull!));
  }

  @override
  MathResult<SymbolicExpression> expandString(String expression) {
    final parseRes = parse(expression);
    if (parseRes.isFailure) return parseRes;
    return expand(parseRes.valueOrNull!);
  }

  @override
  MathResult<SymbolicExpression> factor(SymbolicExpression expression) {
    // Attempt conversion to polynomial
    final polyRes = _algebraEngine.toPolynomial(expression.node);
    if (polyRes.isSuccess) {
      final factorRes = _factorizer.factor(polyRes.valueOrNull!);
      if (factorRes.isSuccess) {
        return MathSuccess(SymbolicExpression(factorRes.valueOrNull!));
      }
    }
    // Return original simplified expression if not a factorable polynomial
    return simplify(expression);
  }

  @override
  MathResult<SymbolicExpression> differentiate(
    SymbolicExpression expression, {
    String variableName = 'x',
  }) {
    final diffRes = _differentiator.differentiate(
      expression.node,
      variableName: variableName,
    );
    if (diffRes.isFailure) return MathFailure(diffRes.errorOrNull!);
    return MathSuccess(SymbolicExpression(diffRes.valueOrNull!));
  }

  @override
  MathResult<SymbolicExpression> differentiateString(
    String expression, {
    String variableName = 'x',
  }) {
    final parseRes = parse(expression);
    if (parseRes.isFailure) return parseRes;
    return differentiate(parseRes.valueOrNull!, variableName: variableName);
  }

  @override
  MathResult<bool> areEquivalent(SymbolicExpression a, SymbolicExpression b) {
    // Fast path: structural equality
    if (a == b) return const MathSuccess(true);

    // Canonicalization check: canonicalize(a) == canonicalize(b)
    final canonA = canonicalize(a);
    if (canonA.isFailure) return MathFailure(canonA.errorOrNull!);
    final canonB = canonicalize(b);
    if (canonB.isFailure) return MathFailure(canonB.errorOrNull!);

    if (canonA.valueOrNull == canonB.valueOrNull) {
      return const MathSuccess(true);
    }

    // Expansion check: expand(a) == expand(b)
    final expA = expand(a);
    if (expA.isFailure) return MathFailure(expA.errorOrNull!);
    final expB = expand(b);
    if (expB.isFailure) return MathFailure(expB.errorOrNull!);

    final canonExpA = canonicalize(expA.valueOrNull!);
    final canonExpB = canonicalize(expB.valueOrNull!);

    if (canonExpA.isSuccess &&
        canonExpB.isSuccess &&
        canonExpA.valueOrNull == canonExpB.valueOrNull) {
      return const MathSuccess(true);
    }

    // Difference check: expand(a - b) simplifies to 0
    final diff = a - b;
    final expDiff = expand(diff);
    if (expDiff.isSuccess && expDiff.valueOrNull!.isZero) {
      return const MathSuccess(true);
    }

    return const MathSuccess(false);
  }
}
