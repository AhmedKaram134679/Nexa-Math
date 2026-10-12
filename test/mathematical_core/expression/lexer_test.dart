import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/expression/lexer/expression_lexer.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/token_type.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('ExpressionLexer Unit Tests', () {
    const lexer = ExpressionLexer();

    test('Tokenizes basic integers and operators', () {
      final res = lexer.tokenize('42 + 100 - 7');
      expect(res.isSuccess, isTrue);
      final tokens = res.valueOrNull!;

      expect(tokens.length, equals(6)); // 42, +, 100, -, 7, EOF
      expect(tokens[0].type, equals(TokenType.integer));
      expect(tokens[0].lexeme, equals('42'));
      expect(tokens[0].literalValue, equals(IntegerValue.fromInt(42)));

      expect(tokens[1].type, equals(TokenType.plus));
      expect(tokens[2].type, equals(TokenType.integer));
      expect(tokens[2].lexeme, equals('100'));
      expect(tokens[3].type, equals(TokenType.minus));
      expect(tokens[4].type, equals(TokenType.integer));
      expect(tokens[4].lexeme, equals('7'));
      expect(tokens[5].type, equals(TokenType.endOfInput));
    });

    test(
      'Tokenizes decimals and scientific notation without float precision loss',
      () {
        final res = lexer.tokenize('3.14159 * 1.23e-4');
        expect(res.isSuccess, isTrue);
        final tokens = res.valueOrNull!;

        expect(tokens[0].type, equals(TokenType.decimal));
        expect(tokens[0].literalValue, isA<DecimalValue>());
        expect(tokens[0].literalValue, equals(DecimalValue.parse('3.14159')));

        expect(tokens[1].type, equals(TokenType.multiply));

        expect(tokens[2].type, equals(TokenType.scientificNumber));
        expect(tokens[2].literalValue, isA<DecimalValue>());
        expect(tokens[2].literalValue, equals(DecimalValue.parse('1.23e-4')));
      },
    );

    test('Tokenizes Unicode operators and identifiers', () {
      final res = lexer.tokenize('2 × sin(π / 2) ÷ 4');
      expect(res.isSuccess, isTrue);
      final tokens = res.valueOrNull!;

      expect(tokens[0].type, equals(TokenType.integer));
      expect(tokens[1].type, equals(TokenType.multiply));
      expect(tokens[2].type, equals(TokenType.identifier));
      expect(tokens[2].lexeme, equals('sin'));
      expect(tokens[3].type, equals(TokenType.leftParen));
      expect(tokens[4].type, equals(TokenType.identifier));
      expect(tokens[4].lexeme, equals('π'));
      expect(tokens[5].type, equals(TokenType.divide));
      expect(tokens[6].type, equals(TokenType.integer));
      expect(tokens[7].type, equals(TokenType.rightParen));
      expect(tokens[8].type, equals(TokenType.divide));
      expect(tokens[9].type, equals(TokenType.integer));
      expect(tokens[10].type, equals(TokenType.endOfInput));
    });

    test('Tokenizes power, factorial, and commas', () {
      final res = lexer.tokenize('gcd(5!, 2^3)');
      expect(res.isSuccess, isTrue);
      final tokens = res.valueOrNull!;

      expect(tokens[0].lexeme, equals('gcd'));
      expect(tokens[1].type, equals(TokenType.leftParen));
      expect(tokens[2].lexeme, equals('5'));
      expect(tokens[3].type, equals(TokenType.factorial));
      expect(tokens[4].type, equals(TokenType.comma));
      expect(tokens[5].lexeme, equals('2'));
      expect(tokens[6].type, equals(TokenType.power));
      expect(tokens[7].lexeme, equals('3'));
      expect(tokens[8].type, equals(TokenType.rightParen));
    });

    test('Source position tracking across newlines', () {
      final res = lexer.tokenize('a\n  + b');
      expect(res.isSuccess, isTrue);
      final tokens = res.valueOrNull!;

      expect(tokens[0].position.line, equals(1));
      expect(tokens[0].position.column, equals(1));

      expect(tokens[1].position.line, equals(2));
      expect(tokens[1].position.column, equals(3)); // 2 leading spaces

      expect(tokens[2].position.line, equals(2));
      expect(tokens[2].position.column, equals(5));
    });

    test('Returns SyntaxError on unexpected characters', () {
      final res = lexer.tokenize('2 @ 3');
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<SyntaxError>());
      final err = res.errorOrNull! as SyntaxError;
      expect(err.position, equals(2));
      expect(err.token, equals('@'));
    });

    test('Returns SyntaxError on malformed scientific notation', () {
      final res = lexer.tokenize('1.23e+');
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<SyntaxError>());
    });
  });
}
