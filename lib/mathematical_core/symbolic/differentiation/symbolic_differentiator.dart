import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/symbolic/simplification/symbolic_simplifier.dart';

/// Contract for exact symbolic differentiation.
abstract interface class SymbolicDifferentiator {
  /// Computes the exact symbolic derivative of [expression] with respect to [variableName].
  MathResult<ExpressionNode> differentiate(
    ExpressionNode expression, {
    String variableName = 'x',
  });
}

/// Production implementation of [SymbolicDifferentiator].
///
/// Implements analytical calculus rules:
/// 1. Linearity: $\frac{d}{dx}(c) = 0$, $\frac{d}{dx}(x) = 1$, $\frac{d}{dx}(y) = 0$.
/// 2. Sum/Difference: $\frac{d}{dx}(u \pm v) = u' \pm v'$.
/// 3. Product rule: $\frac{d}{dx}(u \cdot v) = u' v + u v'$.
/// 4. Quotient rule: $\frac{d}{dx}(u / v) = \frac{u' v - u v'}{v^2}$.
/// 5. General Power rule: $\frac{d}{dx}(u^n) = n u^{n-1} u'$ for constant $n$.
/// 6. Standard Trigonometric: $\sin(u) \to \cos(u) u'$, $\cos(u) \to -\sin(u) u'$, $\tan(u) \to \sec^2(u) u'$.
/// 7. Exponential & Logarithm: $\exp(u) \to \exp(u) u'$, $\ln(u) \to \frac{u'}{u}$.
final class DefaultSymbolicDifferentiator
    implements
        SymbolicDifferentiator,
        ExpressionVisitor<MathResult<ExpressionNode>, String> {
  final NumericEngine numericEngine;
  final SymbolicSimplifier simplifier;

  DefaultSymbolicDifferentiator({
    NumericEngine? numericEngine,
    SymbolicSimplifier? simplifier,
  }) : numericEngine = numericEngine ?? NumericEngine(),
       simplifier =
           simplifier ??
           DefaultSymbolicSimplifier(numericEngine: numericEngine);

  @override
  MathResult<ExpressionNode> differentiate(
    ExpressionNode expression, {
    String variableName = 'x',
  }) {
    final diffRes = expression.accept(this, variableName);
    if (diffRes.isFailure) return diffRes;
    return simplifier.simplify(diffRes.valueOrNull!);
  }

  @override
  MathResult<ExpressionNode> visitNumberLiteral(
    NumberLiteralNode node,
    String varName,
  ) {
    return MathSuccess(
      NumberLiteralNode(position: node.position, value: IntegerValue.zero),
    );
  }

  @override
  MathResult<ExpressionNode> visitConstant(ConstantNode node, String varName) {
    return MathSuccess(
      NumberLiteralNode(position: node.position, value: IntegerValue.zero),
    );
  }

  @override
  MathResult<ExpressionNode> visitVariable(VariableNode node, String varName) {
    if (node.name == varName) {
      return MathSuccess(
        NumberLiteralNode(position: node.position, value: IntegerValue.one),
      );
    }
    return MathSuccess(
      NumberLiteralNode(position: node.position, value: IntegerValue.zero),
    );
  }

  @override
  MathResult<ExpressionNode> visitGroup(GroupNode node, String varName) {
    final innerDiff = node.inner.accept(this, varName);
    if (innerDiff.isFailure) return innerDiff;
    return MathSuccess(
      GroupNode(position: node.position, inner: innerDiff.valueOrNull!),
    );
  }

  @override
  MathResult<ExpressionNode> visitUnaryOp(UnaryOpNode node, String varName) {
    final opDiff = node.operand.accept(this, varName);
    if (opDiff.isFailure) return opDiff;

    switch (node.operator) {
      case UnaryOperator.plus:
        return opDiff;
      case UnaryOperator.negate:
        return MathSuccess(
          UnaryOpNode(
            position: node.position,
            operator: UnaryOperator.negate,
            operand: opDiff.valueOrNull!,
            isPrefix: true,
          ),
        );
      case UnaryOperator.factorial:
        return const MathFailure(
          UnsupportedOperationError(
            operation:
                'Derivative of factorial function is not supported in Phase 6.',
          ),
        );
    }
  }

  @override
  MathResult<ExpressionNode> visitBinaryOp(BinaryOpNode node, String varName) {
    final u = node.left;
    final v = node.right;

    switch (node.operator) {
      case BinaryOperator.add:
      case BinaryOperator.subtract:
        final duRes = u.accept(this, varName);
        if (duRes.isFailure) return duRes;
        final dvRes = v.accept(this, varName);
        if (dvRes.isFailure) return dvRes;

        return MathSuccess(
          BinaryOpNode(
            position: node.position,
            operator: node.operator,
            left: duRes.valueOrNull!,
            right: dvRes.valueOrNull!,
          ),
        );

      case BinaryOperator.multiply:
        // Product rule: d/dx(u * v) = u' * v + u * v'
        final duRes = u.accept(this, varName);
        if (duRes.isFailure) return duRes;
        final dvRes = v.accept(this, varName);
        if (dvRes.isFailure) return dvRes;

        final du = duRes.valueOrNull!;
        final dv = dvRes.valueOrNull!;

        final leftTerm = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.multiply,
          left: du,
          right: v,
          isImplicit: true,
        );
        final rightTerm = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.multiply,
          left: u,
          right: dv,
          isImplicit: true,
        );

        return MathSuccess(
          BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.add,
            left: leftTerm,
            right: rightTerm,
          ),
        );

      case BinaryOperator.divide:
        // Quotient rule: d/dx(u / v) = (u' * v - u * v') / (v^2)
        final duRes = u.accept(this, varName);
        if (duRes.isFailure) return duRes;
        final dvRes = v.accept(this, varName);
        if (dvRes.isFailure) return dvRes;

        final du = duRes.valueOrNull!;
        final dv = dvRes.valueOrNull!;

        final numeratorLeft = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.multiply,
          left: du,
          right: v,
          isImplicit: true,
        );
        final numeratorRight = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.multiply,
          left: u,
          right: dv,
          isImplicit: true,
        );
        final numerator = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.subtract,
          left: numeratorLeft,
          right: numeratorRight,
        );
        final denominator = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.power,
          left: v,
          right: NumberLiteralNode(
            position: node.position,
            value: IntegerValue.fromInt(2),
          ),
        );

        return MathSuccess(
          BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.divide,
            left: GroupNode(position: node.position, inner: numerator),
            right: GroupNode(position: node.position, inner: denominator),
          ),
        );

      case BinaryOperator.power:
        // Power rule:
        // Case 1: u(x)^n where n is constant -> n * u(x)^(n-1) * u'(x)
        final vDependsOnVar = _dependsOnVariable(v, varName);
        final uDependsOnVar = _dependsOnVariable(u, varName);

        if (!vDependsOnVar && !uDependsOnVar) {
          return MathSuccess(
            NumberLiteralNode(
              position: node.position,
              value: IntegerValue.zero,
            ),
          );
        }

        if (!vDependsOnVar) {
          // n * u^(n-1) * u'
          final duRes = u.accept(this, varName);
          if (duRes.isFailure) return duRes;
          final du = duRes.valueOrNull!;

          // n - 1
          ExpressionNode expMinusOne;
          if (v is NumberLiteralNode && v.value is IntegerValue) {
            final intVal = (v.value as IntegerValue).value;
            expMinusOne = NumberLiteralNode(
              position: node.position,
              value: IntegerValue(intVal - BigInt.one),
            );
          } else {
            expMinusOne = BinaryOpNode(
              position: node.position,
              operator: BinaryOperator.subtract,
              left: v,
              right: NumberLiteralNode(
                position: node.position,
                value: IntegerValue.one,
              ),
            );
          }

          final powerTerm = BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.power,
            left: u,
            right: expMinusOne,
          );

          final coeffTimesPower = BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.multiply,
            left: v,
            right: powerTerm,
            isImplicit: true,
          );

          return MathSuccess(
            BinaryOpNode(
              position: node.position,
              operator: BinaryOperator.multiply,
              left: coeffTimesPower,
              right: du,
              isImplicit: true,
            ),
          );
        }

        // Case 2: a^v(x) where a is constant -> a^v(x) * ln(a) * v'(x)
        if (!uDependsOnVar) {
          final dvRes = v.accept(this, varName);
          if (dvRes.isFailure) return dvRes;
          final dv = dvRes.valueOrNull!;

          final lnA = FunctionCallNode(
            position: node.position,
            name: 'ln',
            arguments: [u],
          );

          final originalPower = BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.power,
            left: u,
            right: v,
          );

          final prod1 = BinaryOpNode(
            position: node.position,
            operator: BinaryOperator.multiply,
            left: originalPower,
            right: lnA,
            isImplicit: true,
          );

          return MathSuccess(
            BinaryOpNode(
              position: node.position,
              operator: BinaryOperator.multiply,
              left: prod1,
              right: dv,
              isImplicit: true,
            ),
          );
        }

        return const MathFailure(
          UnsupportedOperationError(
            operation: 'Derivative of general variable base to variable power u(x)^v(x) is not supported in Phase 6.',
          ),
        );

      case BinaryOperator.modulo:
        return const MathFailure(
          UnsupportedOperationError(
            operation: 'Derivative of modulo operator is undefined.',
          ),
        );
    }
  }

  @override
  MathResult<ExpressionNode> visitFunctionCall(
    FunctionCallNode node,
    String varName,
  ) {
    if (node.arguments.length != 1) {
      return MathFailure(
        UnsupportedOperationError(
          operation:
              'Multi-argument function differentiation (${node.name}) is not supported in Phase 6.',
        ),
      );
    }

    final u = node.arguments.first;
    final duRes = u.accept(this, varName);
    if (duRes.isFailure) return duRes;
    final du = duRes.valueOrNull!;

    ExpressionNode derivativeOfFn;
    final name = node.name.toLowerCase();

    switch (name) {
      case 'sin':
        // d/dx(sin(u)) = cos(u) * u'
        derivativeOfFn = FunctionCallNode(
          position: node.position,
          name: 'cos',
          arguments: [u],
        );
        break;

      case 'cos':
        // d/dx(cos(u)) = -sin(u) * u'
        derivativeOfFn = UnaryOpNode(
          position: node.position,
          operator: UnaryOperator.negate,
          operand: FunctionCallNode(
            position: node.position,
            name: 'sin',
            arguments: [u],
          ),
          isPrefix: true,
        );
        break;

      case 'tan':
        // d/dx(tan(u)) = 1 / cos(u)^2 * u'
        final cosU = FunctionCallNode(
          position: node.position,
          name: 'cos',
          arguments: [u],
        );
        final cosUSq = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.power,
          left: cosU,
          right: NumberLiteralNode(
            position: node.position,
            value: IntegerValue.fromInt(2),
          ),
        );
        derivativeOfFn = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.divide,
          left: NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          ),
          right: cosUSq,
        );
        break;

      case 'exp':
        // d/dx(exp(u)) = exp(u) * u'
        derivativeOfFn = FunctionCallNode(
          position: node.position,
          name: 'exp',
          arguments: [u],
        );
        break;

      case 'ln':
        // d/dx(ln(u)) = 1 / u * u'
        derivativeOfFn = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.divide,
          left: NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          ),
          right: u,
        );
        break;

      case 'sqrt':
        // d/dx(sqrt(u)) = 1 / (2 * sqrt(u)) * u'
        final sqrtU = FunctionCallNode(
          position: node.position,
          name: 'sqrt',
          arguments: [u],
        );
        final denom = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.multiply,
          left: NumberLiteralNode(
            position: node.position,
            value: IntegerValue.fromInt(2),
          ),
          right: sqrtU,
          isImplicit: true,
        );
        derivativeOfFn = BinaryOpNode(
          position: node.position,
          operator: BinaryOperator.divide,
          left: NumberLiteralNode(
            position: node.position,
            value: IntegerValue.one,
          ),
          right: denom,
        );
        break;

      default:
        return MathFailure(
          UnsupportedOperationError(
            operation:
                'Derivative of function "$name" is not supported in Phase 6.',
          ),
        );
    }

    // Multiply by chain rule derivative u'
    return MathSuccess(
      BinaryOpNode(
        position: node.position,
        operator: BinaryOperator.multiply,
        left: derivativeOfFn,
        right: du,
        isImplicit: true,
      ),
    );
  }

  bool _dependsOnVariable(ExpressionNode n, String varName) {
    if (n is VariableNode) return n.name == varName;
    if (n is GroupNode) return _dependsOnVariable(n.inner, varName);
    if (n is UnaryOpNode) return _dependsOnVariable(n.operand, varName);
    if (n is BinaryOpNode) {
      return _dependsOnVariable(n.left, varName) ||
          _dependsOnVariable(n.right, varName);
    }
    if (n is FunctionCallNode) {
      for (final a in n.arguments) {
        if (_dependsOnVariable(a, varName)) return true;
      }
    }
    return false;
  }
}
