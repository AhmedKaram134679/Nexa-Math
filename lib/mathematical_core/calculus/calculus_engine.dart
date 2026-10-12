/// Public contract for the NexaMath Calculus Engine.
library;

import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/calculus/default_calculus_engine.dart';
import 'package:nexa_math/mathematical_core/calculus/differentiation/numerical_differentiator.dart';
import 'package:nexa_math/mathematical_core/calculus/integration/quadrature_rules.dart';
import 'package:nexa_math/mathematical_core/calculus/models/calculus_options.dart';
import 'package:nexa_math/mathematical_core/calculus/models/numeric_derivative.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/evaluator/ast_evaluator.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/symbolic/differentiation/symbolic_differentiator.dart';

/// Primary interface for analytical and numerical calculus capabilities in NexaMath.
///
/// Provides symbolic differentiation via Phase 6 integration, numerical differentiation
/// with error estimation and Richardson extrapolation, and high-order numerical integration
/// with domain safety and singularity protection.
abstract interface class CalculusEngine {
  /// Default factory constructor returning the canonical production implementation.
  factory CalculusEngine({
    SymbolicDifferentiator? symbolicDifferentiator,
    NumericalDifferentiator? numericalDifferentiator,
    QuadratureRules? quadratureRules,
    AstEvaluator? astEvaluator,
  }) = DefaultCalculusEngine;

  /// Computes the symbolic derivative d/d[variable] of [expression].
  ///
  /// Optionally passes [order] (defaults to 1st derivative) and [context] for constants.
  MathResult<ExpressionNode> differentiate(
    ExpressionNode expression, {
    String variable = 'x',
    int order = 1,
    EvaluationContext context = const EvaluationContext(),
  });

  /// Evaluates the numerical derivative of a mathematical function [f] at [point].
  ///
  /// [method] selects between forward, backward, central difference, Richardson extrapolation,
  /// or adaptive step size determination.
  MathResult<NumericDerivative> numericalDerivative(
    RealFunction f,
    double point, {
    DifferentiationMethod method =
        DifferentiationMethod.richardsonExtrapolation,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
    bool enableTrace = false,
  });

  /// Evaluates the numerical derivative of an [expression] with respect to [variable] at [point].
  MathResult<NumericDerivative> numericalDerivativeOfExpression(
    ExpressionNode expression,
    double point, {
    String variable = 'x',
    DifferentiationMethod method =
        DifferentiationMethod.richardsonExtrapolation,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
    EvaluationContext baseContext = const EvaluationContext(),
    bool enableTrace = false,
  });

  /// Evaluates the definite integral ∫[a, b] f(x) dx using the specified quadrature [method].
  ///
  /// Strictly respects boundary properties (a == b -> 0, a > b -> -∫[b, a]),
  /// validates against non-finite evaluations and singularities, and reports typed failures.
  MathResult<DecimalValue> definiteIntegral(
    RealFunction f,
    double a,
    double b, {
    IntegrationMethod method = IntegrationMethod.adaptiveSimpson,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
  });

  /// Evaluates the definite integral ∫[a, b] expression dx with respect to [variable].
  MathResult<DecimalValue> definiteIntegralOfExpression(
    ExpressionNode expression,
    double a,
    double b, {
    String variable = 'x',
    IntegrationMethod method = IntegrationMethod.adaptiveSimpson,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
    EvaluationContext baseContext = const EvaluationContext(),
  });
}
