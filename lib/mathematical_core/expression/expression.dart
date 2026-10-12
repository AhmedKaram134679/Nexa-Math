/// NexaMath Expression Engine Module.
///
/// Contains pure Dart expression parsing, token models, Pratt parser,
/// immutable AST nodes, function/constant registries, and evaluation logic.
library;

export 'ast/expression_node.dart';
export 'default_expression_engine.dart';
export 'evaluator/ast_evaluator.dart';
export 'evaluator/expression_evaluator.dart';
export 'expression_engine.dart';
export 'lexer/expression_lexer.dart';
export 'lexer/lexer.dart';
export 'parser/expression_parser.dart';
export 'parser/operator_precedence.dart';
export 'parser/pratt_parser.dart';
export 'registry/constant_registry.dart';
export 'registry/function_registry.dart';
export 'registry/math_function.dart';
export 'tokens/source_position.dart';
export 'tokens/token.dart';
export 'tokens/token_type.dart';
