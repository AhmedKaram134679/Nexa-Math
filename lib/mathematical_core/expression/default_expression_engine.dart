import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/evaluator/ast_evaluator.dart';
import 'package:nexa_math/mathematical_core/expression/evaluator/expression_evaluator.dart';
import 'package:nexa_math/mathematical_core/expression/expression_engine.dart';
import 'package:nexa_math/mathematical_core/expression/lexer/expression_lexer.dart';
import 'package:nexa_math/mathematical_core/expression/lexer/lexer.dart';
import 'package:nexa_math/mathematical_core/expression/parser/expression_parser.dart';
import 'package:nexa_math/mathematical_core/expression/parser/pratt_parser.dart';
import 'package:nexa_math/mathematical_core/expression/registry/constant_registry.dart';
import 'package:nexa_math/mathematical_core/expression/registry/function_registry.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';

/// Canonical production implementation of [ExpressionEngine].
///
/// Coordinates the complete deterministic pipeline:
/// `String` -> `Lexer` -> `Tokens` -> `Parser` -> `AST` -> `Evaluator` -> `MathResult<ScalarValue>`.
final class DefaultExpressionEngine implements ExpressionEngine {
  final Lexer _lexer;
  final ExpressionParser _parser;
  final ExpressionEvaluator _evaluator;

  DefaultExpressionEngine({
    NumericEngine? numericEngine,
    FunctionRegistry? functionRegistry,
    ConstantRegistry? constantRegistry,
    Lexer? lexer,
    ExpressionParser? parser,
    ExpressionEvaluator? evaluator,
  }) : _lexer = lexer ?? const ExpressionLexer(),
       _parser = parser ?? const PrattParser(),
       _evaluator =
           evaluator ??
           AstEvaluator(
             numericEngine: numericEngine,
             functionRegistry: functionRegistry,
             constantRegistry: constantRegistry,
           );

  @override
  MathResult<ExpressionNode> parse(String source) {
    final tokenResult = _lexer.tokenize(source);
    if (tokenResult.isFailure) return MathFailure(tokenResult.errorOrNull!);
    return _parser.parse(tokenResult.valueOrNull!);
  }

  @override
  MathResult<ScalarValue> evaluate(
    String source, {
    EvaluationContext context = EvaluationContext.standard,
  }) {
    final parseResult = parse(source);
    if (parseResult.isFailure) return MathFailure(parseResult.errorOrNull!);
    return evaluateAst(parseResult.valueOrNull!, context: context);
  }

  @override
  MathResult<ScalarValue> evaluateAst(
    ExpressionNode expression, {
    EvaluationContext context = EvaluationContext.standard,
  }) {
    return _evaluator.evaluate(expression, context);
  }
}
