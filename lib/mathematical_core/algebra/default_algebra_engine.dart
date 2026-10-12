import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/algebra_engine.dart';
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
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Canonical production implementation of [AlgebraEngine].
final class DefaultAlgebraEngine implements AlgebraEngine {
  final ExpressionEngine _expressionEngine;
  @override
  final PolynomialOperations polynomialOperations;
  @override
  final AlgebraicSimplifier simplifier;
  @override
  final ExpressionExpander expander;
  @override
  final PolynomialFactorizer factorizer;
  @override
  final ExpressionSubstitutor substitutor;

  DefaultAlgebraEngine({
    ExpressionEngine? expressionEngine,
    NumericEngine? numericEngine,
    PolynomialOperations? polynomialOperations,
    AlgebraicSimplifier? simplifier,
    ExpressionExpander? expander,
    PolynomialFactorizer? factorizer,
    ExpressionSubstitutor? substitutor,
  }) : _expressionEngine = expressionEngine ?? ExpressionEngine(),
       polynomialOperations =
           polynomialOperations ??
           DefaultPolynomialOperations(numericEngine: numericEngine),
       simplifier =
           simplifier ??
           DefaultAlgebraicSimplifier(numericEngine: numericEngine),
       expander = expander ?? DefaultExpressionExpander(simplifier: simplifier),
       factorizer =
           factorizer ??
           DefaultPolynomialFactorizer(numericEngine: numericEngine),
       substitutor = substitutor ?? const DefaultExpressionSubstitutor();

  @override
  MathResult<ExpressionNode> simplifyString(String expression) {
    final parseRes = _expressionEngine.parse(expression);
    if (parseRes.isFailure) return MathFailure(parseRes.errorOrNull!);
    return simplify(parseRes.valueOrNull!);
  }

  @override
  MathResult<ExpressionNode> simplify(ExpressionNode expression) {
    return simplifier.simplify(expression);
  }

  @override
  MathResult<ExpressionNode> expandString(String expression) {
    final parseRes = _expressionEngine.parse(expression);
    if (parseRes.isFailure) return MathFailure(parseRes.errorOrNull!);
    return expand(parseRes.valueOrNull!);
  }

  @override
  MathResult<ExpressionNode> expand(ExpressionNode expression) {
    return expander.expand(expression);
  }

  @override
  MathResult<ExpressionNode> factor(Polynomial polynomial) {
    return factorizer.factor(polynomial);
  }

  @override
  MathResult<ExpressionNode> substitute(
    ExpressionNode expression,
    String variableName,
    ExpressionNode replacement,
  ) {
    return substitutor.substitute(expression, variableName, replacement);
  }

  @override
  MathResult<ExpressionNode> substituteValues(
    ExpressionNode expression,
    Map<String, ScalarValue> values,
  ) {
    return substitutor.substituteValues(expression, values);
  }

  @override
  MathResult<Polynomial> toPolynomial(
    ExpressionNode expression, {
    String variable = 'x',
  }) {
    // First expand and simplify expression
    final expanded = expand(expression).valueOrNull!;
    return _buildPolynomial(expanded, variable);
  }

  @override
  MathResult<Equation> parseEquation(String equation) {
    final sides = equation.split('=');
    if (sides.length != 2) {
      return const MathFailure(
        SyntaxError(
          message: 'Equation must contain exactly one "=" sign.',
          position: 0,
        ),
      );
    }
    final leftRes = _expressionEngine.parse(sides[0].trim());
    if (leftRes.isFailure) return MathFailure(leftRes.errorOrNull!);
    final rightRes = _expressionEngine.parse(sides[1].trim());
    if (rightRes.isFailure) return MathFailure(rightRes.errorOrNull!);

    return MathSuccess(
      Equation(left: leftRes.valueOrNull!, right: rightRes.valueOrNull!),
    );
  }

  MathResult<Polynomial> _buildPolynomial(
    ExpressionNode node,
    String variable,
  ) {
    if (node is NumberLiteralNode) {
      return MathSuccess(Polynomial.constant(node.value, variable: variable));
    }
    if (node is VariableNode) {
      if (node.name == variable) {
        return MathSuccess(
          Polynomial.monomial(IntegerValue.one, 1, variable: variable),
        );
      } else {
        return MathFailure(
          DomainError(
            message:
                'Expression contains unexpected variable "${node.name}" when expecting "$variable".',
            functionName: 'toPolynomial',
          ),
        );
      }
    }
    if (node is UnaryOpNode) {
      if (node.operator == UnaryOperator.negate) {
        final inner = _buildPolynomial(node.operand, variable);
        if (inner.isFailure) return inner;
        return polynomialOperations.negate(inner.valueOrNull!);
      } else if (node.operator == UnaryOperator.plus) {
        return _buildPolynomial(node.operand, variable);
      }
    }
    if (node is BinaryOpNode) {
      final leftPoly = _buildPolynomial(node.left, variable);
      if (leftPoly.isFailure) return leftPoly;
      final rightPoly = _buildPolynomial(node.right, variable);
      if (rightPoly.isFailure) return rightPoly;

      switch (node.operator) {
        case BinaryOperator.add:
          return polynomialOperations.add(
            leftPoly.valueOrNull!,
            rightPoly.valueOrNull!,
          );
        case BinaryOperator.subtract:
          return polynomialOperations.subtract(
            leftPoly.valueOrNull!,
            rightPoly.valueOrNull!,
          );
        case BinaryOperator.multiply:
          return polynomialOperations.multiply(
            leftPoly.valueOrNull!,
            rightPoly.valueOrNull!,
          );
        case BinaryOperator.power:
          if (node.right is NumberLiteralNode &&
              (node.right as NumberLiteralNode).value is IntegerValue) {
            final exp =
                ((node.right as NumberLiteralNode).value as IntegerValue).value;
            if (exp >= BigInt.zero && exp <= BigInt.from(50)) {
              return polynomialOperations.power(
                leftPoly.valueOrNull!,
                exp.toInt(),
              );
            }
          }
          return const MathFailure(
            DomainError(
              message:
                  'Polynomial exponent must be a small non-negative integer.',
              functionName: 'toPolynomial',
            ),
          );
        default:
          return MathFailure(
            DomainError(
              message:
                  'Unsupported operator ${node.operator} in polynomial conversion.',
              functionName: 'toPolynomial',
            ),
          );
      }
    }

    if (node is GroupNode) {
      return _buildPolynomial(node.inner, variable);
    }

    return MathFailure(
      DomainError(
        message: 'Cannot convert expression ${node.runtimeType} to polynomial.',
        functionName: 'toPolynomial',
      ),
    );
  }
}
