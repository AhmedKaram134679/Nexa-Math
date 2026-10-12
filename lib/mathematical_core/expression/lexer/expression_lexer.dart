import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/expression/lexer/lexer.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/token.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/token_type.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Production-grade deterministic lexer for NexaMath expressions.
///
/// Features:
/// - Exact number literal parsing: integer literals -> [IntegerValue], decimal/scientific -> [DecimalValue].
/// - Unicode operator support: `×`, `*`, `·` for multiplication; `÷`, `/` for division.
/// - Full 1-based source position tracking (line, column, offset).
/// - Returns structured [SyntaxError] for illegal characters or malformed numbers.
final class ExpressionLexer implements Lexer {
  const ExpressionLexer();

  @override
  MathResult<List<Token>> tokenize(String source) {
    final tokens = <Token>[];
    var offset = 0;
    var line = 1;
    var column = 1;

    bool isAtEnd() => offset >= source.length;
    String peek() => isAtEnd() ? '\x00' : source[offset];
    String peekNext() =>
        (offset + 1 >= source.length) ? '\x00' : source[offset + 1];

    String advance() {
      final c = source[offset];
      offset++;
      if (c == '\n') {
        line++;
        column = 1;
      } else {
        column++;
      }
      return c;
    }

    bool isDigit(String c) {
      if (c.isEmpty) return false;
      final code = c.codeUnitAt(0);
      return code >= 48 && code <= 57;
    }

    bool isAlpha(String c) {
      if (c.isEmpty) return false;
      final code = c.codeUnitAt(0);
      return (code >= 65 && code <= 90) || // A-Z
          (code >= 97 && code <= 122) || // a-z
          code == 95 || // _
          code == 960 || // π
          code == 952 || // θ
          code == 981 || // ϕ
          code == 934; // Φ
    }

    bool isAlphaNumeric(String c) => isAlpha(c) || isDigit(c);

    while (!isAtEnd()) {
      final startOffset = offset;
      final startLine = line;
      final startColumn = column;
      final startPos = SourcePosition(
        offset: startOffset,
        line: startLine,
        column: startColumn,
      );

      final c = advance();

      // Whitespace
      if (c == ' ' || c == '\r' || c == '\t' || c == '\n') {
        continue;
      }

      // Single-character and Unicode operators/delimiters
      switch (c) {
        case '+':
          tokens.add(
            Token(type: TokenType.plus, lexeme: '+', position: startPos),
          );
          continue;
        case '-':
        case '−': // Unicode minus
          tokens.add(
            Token(type: TokenType.minus, lexeme: '-', position: startPos),
          );
          continue;
        case '*':
        case '×':
        case '·':
          tokens.add(
            Token(type: TokenType.multiply, lexeme: c, position: startPos),
          );
          continue;
        case '/':
        case '÷':
          tokens.add(
            Token(type: TokenType.divide, lexeme: c, position: startPos),
          );
          continue;
        case '%':
          tokens.add(
            Token(type: TokenType.modulo, lexeme: '%', position: startPos),
          );
          continue;
        case '^':
          tokens.add(
            Token(type: TokenType.power, lexeme: '^', position: startPos),
          );
          continue;
        case '!':
          tokens.add(
            Token(type: TokenType.factorial, lexeme: '!', position: startPos),
          );
          continue;
        case '(':
          tokens.add(
            Token(type: TokenType.leftParen, lexeme: '(', position: startPos),
          );
          continue;
        case ')':
          tokens.add(
            Token(type: TokenType.rightParen, lexeme: ')', position: startPos),
          );
          continue;
        case ',':
          tokens.add(
            Token(type: TokenType.comma, lexeme: ',', position: startPos),
          );
          continue;
      }

      // Numbers: integer, decimal (including starting with `.`), or scientific notation
      if (isDigit(c) || (c == '.' && isDigit(peek()))) {
        var isDecimal = c == '.';
        var isScientific = false;

        while (isDigit(peek())) {
          advance();
        }

        // Fractional part
        if (peek() == '.' && !isDecimal) {
          isDecimal = true;
          advance(); // Consume '.'
          if (!isDigit(peek())) {
            // Trailing dot without digits (e.g. `123.`)
            // Still treated as decimal
          } else {
            while (isDigit(peek())) {
              advance();
            }
          }
        }

        // Scientific exponent part (e.g. 1.23e-4 or 5E10)
        if (peek() == 'e' || peek() == 'E') {
          final nextChar = peekNext();
          if (isDigit(nextChar) || nextChar == '+' || nextChar == '-') {
            isScientific = true;
            advance(); // Consume 'e' or 'E'
            if (peek() == '+' || peek() == '-') {
              advance();
            }
            if (!isDigit(peek())) {
              return MathFailure(
                SyntaxError(
                  message: 'Malformed scientific notation: exponent digits expected.',
                  position: offset,
                  token: source.substring(startOffset, offset),
                ),
              );
            }
            while (isDigit(peek())) {
              advance();
            }
          } else {
            // Dangling 'e' or 'E' following a number without a valid exponent (e.g. '1e')
            return MathFailure(
              SyntaxError(
                message:
                    'Malformed scientific notation: exponent digits expected after "${peek()}".',
                position: offset,
                token: source.substring(startOffset, offset + 1),
              ),
            );
          }
        }

        final numStr = source.substring(startOffset, offset);

        if (!isDecimal && !isScientific) {
          // Pure integer
          final intVal = IntegerValue.parse(numStr);
          tokens.add(
            Token(
              type: TokenType.integer,
              lexeme: numStr,
              position: startPos,
              literalValue: intVal,
            ),
          );
        } else {
          // Decimal or scientific notation
          final decVal = DecimalValue.parse(numStr, isExact: true);
          tokens.add(
            Token(
              type: isScientific
                  ? TokenType.scientificNumber
                  : TokenType.decimal,
              lexeme: numStr,
              position: startPos,
              literalValue: decVal,
            ),
          );
        }
        continue;
      }

      // Identifiers (variable names, constants, function names)
      if (isAlpha(c)) {
        while (isAlphaNumeric(peek())) {
          advance();
        }
        final identifierStr = source.substring(startOffset, offset);
        tokens.add(
          Token(
            type: TokenType.identifier,
            lexeme: identifierStr,
            position: startPos,
          ),
        );
        continue;
      }

      // Unrecognized character
      return MathFailure(
        SyntaxError(
          message: 'Unexpected character: "$c".',
          position: startOffset,
          token: c,
        ),
      );
    }

    final finalPos = SourcePosition(offset: offset, line: line, column: column);
    tokens.add(Token.eof(finalPos));

    return MathSuccess(List.unmodifiable(tokens));
  }
}
