import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/default_expression_engine.dart';
import 'package:nexa_math/mathematical_core/expression/registry/constant_registry.dart';
import 'package:nexa_math/mathematical_core/expression/registry/function_registry.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';

/// Primary public façade interface for the NexaMath Expression Engine.
///
/// Encapsulates parsing, syntax validation, AST construction, and mathematical
/// evaluation, coordinating:
/// - [Lexer]
/// - [ExpressionParser]
/// - [ExpressionEvaluator]
/// - [FunctionRegistry]
/// - [ConstantRegistry]
abstract interface class ExpressionEngine {
  /// Default factory constructor creating the canonical production [DefaultExpressionEngine].
  factory ExpressionEngine({
    NumericEngine? numericEngine,
    FunctionRegistry? functionRegistry,
    ConstantRegistry? constantRegistry,
  }) = DefaultExpressionEngine;

  /// Parses raw mathematical expression [source] into an immutable [ExpressionNode] syntax tree.
  MathResult<ExpressionNode> parse(String source);

  /// Directly parses and evaluates raw mathematical expression [source] under [context].
  MathResult<ScalarValue> evaluate(
    String source, {
    EvaluationContext context = EvaluationContext.standard,
  });

  /// Evaluates an already-parsed [expression] syntax tree under [context].
  MathResult<ScalarValue> evaluateAst(
    ExpressionNode expression, {
    EvaluationContext context = EvaluationContext.standard,
  });
}
