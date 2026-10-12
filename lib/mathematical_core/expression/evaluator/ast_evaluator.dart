import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/evaluator/expression_evaluator.dart';
import 'package:nexa_math/mathematical_core/expression/registry/constant_registry.dart';
import 'package:nexa_math/mathematical_core/expression/registry/function_registry.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Production AST Evaluator traversing [ExpressionNode] syntax trees and delegating
/// arithmetic operations directly to [NumericEngine].
final class AstEvaluator
    implements
        ExpressionEvaluator,
        ExpressionVisitor<MathResult<ScalarValue>, EvaluationContext> {
  final NumericEngine numericEngine;
  final FunctionRegistry functionRegistry;
  final ConstantRegistry constantRegistry;

  AstEvaluator({
    NumericEngine? numericEngine,
    FunctionRegistry? functionRegistry,
    ConstantRegistry? constantRegistry,
  }) : numericEngine = numericEngine ?? NumericEngine(),
       functionRegistry = functionRegistry ?? DefaultFunctionRegistry(),
       constantRegistry = constantRegistry ?? const DefaultConstantRegistry();

  @override
  MathResult<ScalarValue> evaluate(
    ExpressionNode expression,
    EvaluationContext context,
  ) {
    return expression.accept(this, context);
  }

  @override
  MathResult<ScalarValue> visitNumberLiteral(
    NumberLiteralNode node,
    EvaluationContext context,
  ) {
    return MathSuccess(node.value);
  }

  @override
  MathResult<ScalarValue> visitVariable(
    VariableNode node,
    EvaluationContext context,
  ) {
    // 1. Check in context.variables
    if (context.variables.containsKey(node.name)) {
      final val = context.variables[node.name]!;
      if (val is ScalarValue) {
        return MathSuccess(val);
      }
      return MathFailure(
        InvalidArgumentError(
          argumentName: node.name,
          reason: 'Variable is not a scalar number.',
        ),
      );
    }

    // 2. Check in constants
    final constant = constantRegistry.resolve(node.name);
    if (constant != null) {
      return MathSuccess(constant);
    }

    return MathFailure(UnknownIdentifierError(identifier: node.name));
  }

  @override
  MathResult<ScalarValue> visitConstant(
    ConstantNode node,
    EvaluationContext context,
  ) {
    final constant = constantRegistry.resolve(node.name);
    if (constant != null) {
      return MathSuccess(constant);
    }
    // Also check context constants
    if (context.constants.containsKey(node.name)) {
      final val = context.constants[node.name]!;
      if (val is ScalarValue) return MathSuccess(val);
    }
    return MathFailure(UnknownIdentifierError(identifier: node.name));
  }

  @override
  MathResult<ScalarValue> visitUnaryOp(
    UnaryOpNode node,
    EvaluationContext context,
  ) {
    final operandRes = node.operand.accept(this, context);
    if (operandRes.isFailure) return operandRes;
    final operand = operandRes.valueOrNull!;

    switch (node.operator) {
      case UnaryOperator.plus:
        return MathSuccess(operand);
      case UnaryOperator.negate:
        return numericEngine.negate(operand);
      case UnaryOperator.factorial:
        return numericEngine.factorial(operand);
    }
  }

  @override
  MathResult<ScalarValue> visitBinaryOp(
    BinaryOpNode node,
    EvaluationContext context,
  ) {
    final leftRes = node.left.accept(this, context);
    if (leftRes.isFailure) return leftRes;
    final left = leftRes.valueOrNull!;

    final rightRes = node.right.accept(this, context);
    if (rightRes.isFailure) return rightRes;
    final right = rightRes.valueOrNull!;

    switch (node.operator) {
      case BinaryOperator.add:
        return numericEngine.add(left, right);
      case BinaryOperator.subtract:
        return numericEngine.subtract(left, right);
      case BinaryOperator.multiply:
        return numericEngine.multiply(left, right);
      case BinaryOperator.divide:
        return numericEngine.divide(left, right);
      case BinaryOperator.power:
        return numericEngine.power(left, right);
      case BinaryOperator.modulo:
        // Modulo is handled via integer quotient remainder or integer operations
        if (left is IntegerValue && right is IntegerValue) {
          if (right.isZero) {
            return const MathFailure(DivisionByZeroError());
          }
          final rem = left.value % right.value;
          return MathSuccess(IntegerValue(rem));
        }
        return const MathFailure(
          DomainError(
            message: 'Modulo operator % requires integer operands.',
            functionName: '%',
          ),
        );
    }
  }

  @override
  MathResult<ScalarValue> visitFunctionCall(
    FunctionCallNode node,
    EvaluationContext context,
  ) {
    final fn = functionRegistry.resolve(node.name);
    if (fn == null) {
      return MathFailure(UnknownFunctionError(functionName: node.name));
    }

    // Check argument bounds
    if (fn.minimumArguments != null &&
        node.arguments.length < fn.minimumArguments!) {
      return MathFailure(
        InvalidArgumentError(
          argumentName: node.name,
          reason:
              'Function "${node.name}" requires at least ${fn.minimumArguments} arguments.',
        ),
      );
    }
    if (fn.maximumArguments != null &&
        node.arguments.length > fn.maximumArguments!) {
      return MathFailure(
        InvalidArgumentError(
          argumentName: node.name,
          reason:
              'Function "${node.name}" accepts at most ${fn.maximumArguments} arguments.',
        ),
      );
    }

    // Evaluate argument subexpressions
    final evalArgs = <ScalarValue>[];
    for (final argNode in node.arguments) {
      final argRes = argNode.accept(this, context);
      if (argRes.isFailure) return argRes;
      evalArgs.add(argRes.valueOrNull!);
    }

    return fn.invoke(evalArgs, context, numericEngine);
  }

  @override
  MathResult<ScalarValue> visitGroup(
    GroupNode node,
    EvaluationContext context,
  ) {
    return node.inner.accept(this, context);
  }
}
