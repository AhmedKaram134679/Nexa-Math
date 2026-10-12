import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/token.dart';

/// Abstract interface for parsing token sequences into immutable ASTs.
abstract interface class ExpressionParser {
  /// Parses an immutable list of [Token]s into an [ExpressionNode] syntax tree.
  ///
  /// Returns [MathSuccess] containing the root [ExpressionNode], or [MathFailure]
  /// with [SyntaxError] if syntax rules or grammar are violated.
  MathResult<ExpressionNode> parse(List<Token> tokens);
}
