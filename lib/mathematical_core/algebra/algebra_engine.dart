import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/default_algebra_engine.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/algebra/expansion/expression_expander.dart';
import 'package:nexa_math/mathematical_core/algebra/factorization/polynomial_factorizer.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial_operations.dart';
import 'package:nexa_math/mathematical_core/algebra/simplification/algebraic_simplifier.dart';
import 'package:nexa_math/mathematical_core/algebra/substitution/expression_substitutor.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';

/// Primary public façade interface for the NexaMath Algebra Engine.
///
/// Encapsulates polynomial arithmetic, algebraic simplification, expression expansion,
/// factorization, variable substitution, and equation manipulation.
abstract interface class AlgebraEngine {
  /// Default factory constructor creating the canonical production [DefaultAlgebraEngine].
  factory AlgebraEngine({
    ExpressionEngine? expressionEngine,
    NumericEngine? numericEngine,
    PolynomialOperations? polynomialOperations,
    AlgebraicSimplifier? simplifier,
    ExpressionExpander? expander,
    PolynomialFactorizer? factorizer,
    ExpressionSubstitutor? substitutor,
  }) = DefaultAlgebraEngine;

  /// Access to polynomial operations subsystem.
  PolynomialOperations get polynomialOperations;

  /// Access to algebraic simplifier subsystem.
  AlgebraicSimplifier get simplifier;

  /// Access to expression expander subsystem.
  ExpressionExpander get expander;

  /// Access to polynomial factorizer subsystem.
  PolynomialFactorizer get factorizer;

  /// Access to expression substitutor subsystem.
  ExpressionSubstitutor get substitutor;

  /// Simplifies a mathematical expression string algebraically: e.g. `"x + x"` -> `"2*x"`.
  MathResult<ExpressionNode> simplifyString(String expression);

  /// Simplifies an AST expression node algebraically.
  MathResult<ExpressionNode> simplify(ExpressionNode expression);

  /// Expands products and binomial powers in an expression string: e.g. `"(x + 2)^2"`.
  MathResult<ExpressionNode> expandString(String expression);

  /// Expands an AST expression node.
  MathResult<ExpressionNode> expand(ExpressionNode expression);

  /// Factors a univariate polynomial into an expression AST.
  MathResult<ExpressionNode> factor(Polynomial polynomial);

  /// Substitutes a variable with another expression in [expression].
  MathResult<ExpressionNode> substitute(
    ExpressionNode expression,
    String variableName,
    ExpressionNode replacement,
  );

  /// Substitutes scalar values for variables in an expression string and evaluates or simplifies.
  MathResult<ExpressionNode> substituteValues(
    ExpressionNode expression,
    Map<String, ScalarValue> values,
  );

  /// Converts an AST expression representing a univariate polynomial in [variable] into a [Polynomial].
  MathResult<Polynomial> toPolynomial(
    ExpressionNode expression, {
    String variable = 'x',
  });

  /// Parses an equation string of form `"LHS = RHS"` into an [Equation] model.
  MathResult<Equation> parseEquation(String equation);
}
