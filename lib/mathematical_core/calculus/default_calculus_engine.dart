/// Canonical implementation of [CalculusEngine].
library;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/calculus/calculus_engine.dart';
import 'package:nexa_math/mathematical_core/calculus/differentiation/numerical_differentiator.dart';
import 'package:nexa_math/mathematical_core/calculus/integration/quadrature_rules.dart';
import 'package:nexa_math/mathematical_core/calculus/models/calculus_options.dart';
import 'package:nexa_math/mathematical_core/calculus/models/numeric_derivative.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/evaluator/ast_evaluator.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/symbolic/differentiation/symbolic_differentiator.dart';

/// Production implementation of [CalculusEngine] orchestrating Phase 6 symbolic differentiation,
/// finite difference differentiation, and quadrature integration.
final class DefaultCalculusEngine implements CalculusEngine {
  final SymbolicDifferentiator _symbolicDifferentiator;
  final NumericalDifferentiator _numericalDifferentiator;
  final QuadratureRules _quadratureRules;
  final AstEvaluator _astEvaluator;

  /// Creates a [DefaultCalculusEngine].
  DefaultCalculusEngine({
    SymbolicDifferentiator? symbolicDifferentiator,
    NumericalDifferentiator? numericalDifferentiator,
    QuadratureRules? quadratureRules,
    AstEvaluator? astEvaluator,
  }) : _symbolicDifferentiator =
           symbolicDifferentiator ?? DefaultSymbolicDifferentiator(),
       _numericalDifferentiator =
           numericalDifferentiator ?? NumericalDifferentiator(),
       _quadratureRules = quadratureRules ?? QuadratureRules(),
       _astEvaluator = astEvaluator ?? AstEvaluator();

  @override
  MathResult<ExpressionNode> differentiate(
    ExpressionNode expression, {
    String variable = 'x',
    int order = 1,
    EvaluationContext context = const EvaluationContext(),
  }) {
    if (order < 1) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'order',
          reason: 'Differentiation order must be a positive integer (>= 1).',
        ),
      );
    }

    ExpressionNode current = expression;
    for (int i = 0; i < order; i++) {
      final res = _symbolicDifferentiator.differentiate(
        current,
        variableName: variable,
      );
      if (res.isFailure) return res;
      current = res.valueOrNull!;
    }

    return MathSuccess(current);
  }

  @override
  MathResult<NumericDerivative> numericalDerivative(
    RealFunction f,
    double point, {
    DifferentiationMethod method =
        DifferentiationMethod.richardsonExtrapolation,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
    bool enableTrace = false,
  }) {
    return _numericalDifferentiator.differentiate(
      f: f,
      x: point,
      options: options,
      method: method,
      enableTrace: enableTrace,
    );
  }

  @override
  MathResult<NumericDerivative> numericalDerivativeOfExpression(
    ExpressionNode expression,
    double point, {
    String variable = 'x',
    DifferentiationMethod method =
        DifferentiationMethod.richardsonExtrapolation,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
    EvaluationContext baseContext = const EvaluationContext(),
    bool enableTrace = false,
  }) {
    MathResult<double> f(double xVal) {
      final updatedVars = Map<String, MathValue>.from(baseContext.variables)
        ..[variable] = DecimalValue.parse(xVal.toString(), isExact: false);
      final evalCtx = baseContext.copyWith(variables: updatedVars);
      final res = _astEvaluator.evaluate(expression, evalCtx);
      if (res.isFailure) return MathFailure(res.errorOrNull!);
      final scalar = res.valueOrNull!;
      if (scalar is DecimalValue) {
        return MathSuccess(scalar.toDouble());
      }
      final dec = NumericPromoter.toDecimal(scalar);
      return MathSuccess(dec.toDouble());
    }

    return numericalDerivative(
      f,
      point,
      method: method,
      options: options,
      enableTrace: enableTrace,
    );
  }

  @override
  MathResult<DecimalValue> definiteIntegral(
    RealFunction f,
    double a,
    double b, {
    IntegrationMethod method = IntegrationMethod.adaptiveSimpson,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
  }) {
    return _quadratureRules.integrate(
      f: f,
      a: a,
      b: b,
      method: method,
      options: options,
    );
  }

  @override
  MathResult<DecimalValue> definiteIntegralOfExpression(
    ExpressionNode expression,
    double a,
    double b, {
    String variable = 'x',
    IntegrationMethod method = IntegrationMethod.adaptiveSimpson,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
    EvaluationContext baseContext = const EvaluationContext(),
  }) {
    MathResult<double> f(double xVal) {
      final updatedVars = Map<String, MathValue>.from(baseContext.variables)
        ..[variable] = DecimalValue.parse(xVal.toString(), isExact: false);
      final evalCtx = baseContext.copyWith(variables: updatedVars);
      final res = _astEvaluator.evaluate(expression, evalCtx);
      if (res.isFailure) return MathFailure(res.errorOrNull!);
      final scalar = res.valueOrNull!;
      if (scalar is DecimalValue) {
        return MathSuccess(scalar.toDouble());
      }
      final dec = NumericPromoter.toDecimal(scalar);
      return MathSuccess(dec.toDouble());
    }

    return definiteIntegral(f, a, b, method: method, options: options);
  }
}
