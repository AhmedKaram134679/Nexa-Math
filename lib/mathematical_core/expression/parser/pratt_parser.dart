import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/parser/expression_parser.dart';
import 'package:nexa_math/mathematical_core/expression/parser/operator_precedence.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/token.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/token_type.dart';

/// Deterministic Pratt parser (precedence climbing) for mathematical expressions.
///
/// Handles:
/// - Binary operators with explicit precedence and associativity.
/// - Right-associative exponentiation: `2 ^ 3 ^ 2` parses as `2 ^ (3 ^ 2)`.
/// - Unary prefix operators (`+`, `-`).
/// - Postfix factorial operator (`!`).
/// - Implicit multiplication with tighter binding: `2x`, `3(4)`, `(a+b)(c+d)`.
/// - Function calls with multi-argument support: `f(x, y, z)`.
/// - Robust syntax validation and precise error position diagnostics.
final class PrattParser implements ExpressionParser {
  const PrattParser();

  @override
  MathResult<ExpressionNode> parse(List<Token> tokens) {
    if (tokens.isEmpty || tokens.first.type == TokenType.endOfInput) {
      return const MathFailure(
        SyntaxError(message: 'Expression is empty.', position: 0),
      );
    }

    final state = _ParserState(tokens);
    final exprResult = state.parseExpression(OperatorPrecedence.none);
    if (exprResult.isFailure) return exprResult;

    if (!state.isAtEnd()) {
      final current = state.peek();
      return MathFailure(
        SyntaxError(
          message: 'Unexpected token after expression: "${current.lexeme}".',
          position: current.position.offset,
          token: current.lexeme,
        ),
      );
    }

    return exprResult;
  }
}

final class _ParserState {
  final List<Token> tokens;
  int current = 0;

  _ParserState(this.tokens);

  bool isAtEnd() => peek().type == TokenType.endOfInput;
  Token peek() => tokens[current];
  Token previous() => tokens[current - 1];

  Token advance() {
    if (!isAtEnd()) current++;
    return previous();
  }

  bool check(TokenType type) {
    if (isAtEnd()) return false;
    return peek().type == type;
  }

  bool match(TokenType type) {
    if (check(type)) {
      advance();
      return true;
    }
    return false;
  }

  MathResult<ExpressionNode> parseExpression(int minPrecedence) {
    if (isAtEnd()) {
      return MathFailure(
        SyntaxError(
          message: 'Unexpected end of expression.',
          position: peek().position.offset,
        ),
      );
    }

    // 1. Prefix parsing
    final leftResult = _parsePrefix();
    if (leftResult.isFailure) return leftResult;
    var left = leftResult.valueOrNull!;

    // 2. Infix and postfix loop
    while (true) {
      // Check for postfix factorial operator `!`
      if (check(TokenType.factorial) &&
          OperatorPrecedence.postfix >= minPrecedence) {
        advance();
        left = UnaryOpNode(
          position: left.position,
          operator: UnaryOperator.factorial,
          operand: left,
          isPrefix: false,
        );
        continue;
      }

      // Check for implicit multiplication (e.g. `2x`, `3(4)`, `(a+b)(c+d)`)
      if (_canStartImplicitOperand(peek()) &&
          OperatorPrecedence.implicitMultiplication > minPrecedence) {
        final implicitResult = parseExpression(
          OperatorPrecedence.implicitMultiplication,
        );
        if (implicitResult.isFailure) return implicitResult;
        left = BinaryOpNode(
          position: left.position,
          operator: BinaryOperator.multiply,
          left: left,
          right: implicitResult.valueOrNull!,
          isImplicit: true,
        );
        continue;
      }

      // Check for explicit binary operator
      final infixPrecedence = _getInfixPrecedence(peek().type);
      if (infixPrecedence == null || infixPrecedence < minPrecedence) {
        break;
      }

      final opToken = advance();
      final binaryOp = _toBinaryOp(opToken.type);

      // Exponentiation is right-associative: parse right side with current precedence, not precedence + 1
      final nextMinPrecedence = (opToken.type == TokenType.power)
          ? infixPrecedence
          : infixPrecedence + 1;

      final rightResult = parseExpression(nextMinPrecedence);
      if (rightResult.isFailure) return rightResult;
      final right = rightResult.valueOrNull!;

      left = BinaryOpNode(
        position: left.position,
        operator: binaryOp,
        left: left,
        right: right,
      );
    }

    return MathSuccess(left);
  }

  MathResult<ExpressionNode> _parsePrefix() {
    final token = advance();

    switch (token.type) {
      case TokenType.integer:
      case TokenType.decimal:
      case TokenType.scientificNumber:
        return MathSuccess(
          NumberLiteralNode(
            position: token.position,
            value: token.literalValue!,
          ),
        );

      case TokenType.identifier:
        // Could be a function call: `sin(...)` or a variable/constant: `x`, `pi`
        if (check(TokenType.leftParen)) {
          advance(); // Consume '('
          final args = <ExpressionNode>[];
          if (!check(TokenType.rightParen)) {
            while (true) {
              final argRes = parseExpression(OperatorPrecedence.none);
              if (argRes.isFailure) return argRes;
              args.add(argRes.valueOrNull!);

              if (match(TokenType.comma)) {
                continue;
              } else if (check(TokenType.rightParen)) {
                break;
              } else {
                return MathFailure(
                  SyntaxError(
                    message:
                        'Expected "," or ")" in function arguments for "${token.lexeme}".',
                    position: peek().position.offset,
                    token: peek().lexeme,
                  ),
                );
              }
            }
          }

          if (!match(TokenType.rightParen)) {
            return MathFailure(
              SyntaxError(
                message:
                    'Unclosed parenthesis in function call "${token.lexeme}".',
                position: peek().position.offset,
                token: peek().lexeme,
              ),
            );
          }

          return MathSuccess(
            FunctionCallNode(
              position: token.position,
              name: token.lexeme,
              arguments: List.unmodifiable(args),
            ),
          );
        } else {
          // Identifier: Constant or Variable
          final name = token.lexeme;
          if (_isStandardConstant(name)) {
            return MathSuccess(
              ConstantNode(position: token.position, name: name),
            );
          }
          return MathSuccess(
            VariableNode(position: token.position, name: name),
          );
        }

      case TokenType.plus:
        final operandRes = parseExpression(OperatorPrecedence.prefixUnary);
        if (operandRes.isFailure) return operandRes;
        return MathSuccess(
          UnaryOpNode(
            position: token.position,
            operator: UnaryOperator.plus,
            operand: operandRes.valueOrNull!,
            isPrefix: true,
          ),
        );

      case TokenType.minus:
        final operandRes = parseExpression(OperatorPrecedence.prefixUnary);
        if (operandRes.isFailure) return operandRes;
        return MathSuccess(
          UnaryOpNode(
            position: token.position,
            operator: UnaryOperator.negate,
            operand: operandRes.valueOrNull!,
            isPrefix: true,
          ),
        );

      case TokenType.leftParen:
        final innerRes = parseExpression(OperatorPrecedence.none);
        if (innerRes.isFailure) return innerRes;
        if (!match(TokenType.rightParen)) {
          return MathFailure(
            SyntaxError(
              message: 'Unclosed parenthesis: missing ")".',
              position: peek().position.offset,
              token: peek().lexeme,
            ),
          );
        }
        return MathSuccess(
          GroupNode(position: token.position, inner: innerRes.valueOrNull!),
        );

      default:
        return MathFailure(
          SyntaxError(
            message: 'Unexpected token: "${token.lexeme}".',
            position: token.position.offset,
            token: token.lexeme,
          ),
        );
    }
  }

  static bool _isStandardConstant(String name) {
    const constants = {'pi', 'π', 'e', 'phi', 'ϕ', 'Φ'};
    return constants.contains(name.toLowerCase());
  }

  static bool _canStartImplicitOperand(Token token) {
    switch (token.type) {
      case TokenType.integer:
      case TokenType.decimal:
      case TokenType.scientificNumber:
      case TokenType.identifier:
      case TokenType.leftParen:
        return true;
      default:
        return false;
    }
  }

  static int? _getInfixPrecedence(TokenType type) {
    switch (type) {
      case TokenType.plus:
      case TokenType.minus:
        return OperatorPrecedence.addition;
      case TokenType.multiply:
      case TokenType.divide:
      case TokenType.modulo:
        return OperatorPrecedence.multiplication;
      case TokenType.power:
        return OperatorPrecedence.power;
      default:
        return null;
    }
  }

  static BinaryOperator _toBinaryOp(TokenType type) {
    switch (type) {
      case TokenType.plus:
        return BinaryOperator.add;
      case TokenType.minus:
        return BinaryOperator.subtract;
      case TokenType.multiply:
        return BinaryOperator.multiply;
      case TokenType.divide:
        return BinaryOperator.divide;
      case TokenType.modulo:
        return BinaryOperator.modulo;
      case TokenType.power:
        return BinaryOperator.power;
      default:
        throw ArgumentError('Not a binary operator: $type');
    }
  }
}
