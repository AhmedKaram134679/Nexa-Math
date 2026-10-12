import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/token.dart';

/// Abstract interface class for tokenizing raw mathematical expression strings.
abstract interface class Lexer {
  /// Scans the provided [source] text and produces an immutable list of [Token]s.
  ///
  /// Returns [MathSuccess] containing the tokens terminated with a [TokenType.endOfInput] token,
  /// or [MathFailure] with [SyntaxError] if illegal characters or malformed numbers are encountered.
  MathResult<List<Token>> tokenize(String source);
}
