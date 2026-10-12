import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/lexer/expression_lexer.dart';
import 'package:nexa_math/mathematical_core/expression/parser/pratt_parser.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('PrattParser Unit Tests', () {
    const lexer = ExpressionLexer();
    const parser = PrattParser();

    ExpressionNode parse(String input) {
      final tokens = lexer.tokenize(input).valueOrNull!;
      final res = parser.parse(tokens);
      expect(res.isSuccess, isTrue, reason: 'Failed parsing: $input');
      return res.valueOrNull!;
    }

    test('Parses primary literals and identifiers', () {
      final node = parse('42');
      expect(node, isA<NumberLiteralNode>());
      expect(
        (node as NumberLiteralNode).value,
        equals(IntegerValue.fromInt(42)),
      );

      final vNode = parse('x');
      expect(vNode, isA<VariableNode>());
      expect((vNode as VariableNode).name, equals('x'));

      final cNode = parse('pi');
      expect(cNode, isA<ConstantNode>());
      expect((cNode as ConstantNode).name, equals('pi'));
    });

    test('Operator precedence: multiplication over addition', () {
      // 2 + 3 * 4 -> 2 + (3 * 4)
      final node = parse('2 + 3 * 4');
      expect(node, isA<BinaryOpNode>());
      final bin = node as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.add));
      expect(bin.left, isA<NumberLiteralNode>());
      expect(bin.right, isA<BinaryOpNode>());
      final rightBin = bin.right as BinaryOpNode;
      expect(rightBin.operator, equals(BinaryOperator.multiply));
    });

    test('Right-associativity of power operator', () {
      // 2 ^ 3 ^ 4 -> 2 ^ (3 ^ 4)
      final node = parse('2 ^ 3 ^ 4');
      expect(node, isA<BinaryOpNode>());
      final bin = node as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.power));
      expect(
        (bin.left as NumberLiteralNode).value,
        equals(IntegerValue.fromInt(2)),
      );
      expect(bin.right, isA<BinaryOpNode>());
      final rightBin = bin.right as BinaryOpNode;
      expect(rightBin.operator, equals(BinaryOperator.power));
      expect(
        (rightBin.left as NumberLiteralNode).value,
        equals(IntegerValue.fromInt(3)),
      );
      expect(
        (rightBin.right as NumberLiteralNode).value,
        equals(IntegerValue.fromInt(4)),
      );
    });

    test('Prefix unary operators and precedence', () {
      // -5 + 2 -> (-5) + 2
      final node = parse('-5 + 2');
      expect(node, isA<BinaryOpNode>());
      final bin = node as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.add));
      expect(bin.left, isA<UnaryOpNode>());
      expect((bin.left as UnaryOpNode).operator, equals(UnaryOperator.negate));
    });

    test('Postfix factorial operator binds tightly', () {
      // 5! * 2 -> (5!) * 2
      final node = parse('5! * 2');
      expect(node, isA<BinaryOpNode>());
      final bin = node as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.multiply));
      expect(bin.left, isA<UnaryOpNode>());
      expect(
        (bin.left as UnaryOpNode).operator,
        equals(UnaryOperator.factorial),
      );
    });

    test('Implicit multiplication', () {
      // 2pi -> 2 * pi
      final node = parse('2pi');
      expect(node, isA<BinaryOpNode>());
      final bin = node as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.multiply));
      expect(bin.isImplicit, isTrue);
      expect(bin.left, isA<NumberLiteralNode>());
      expect(bin.right, isA<ConstantNode>());

      // 3(4) -> 3 * (4)
      final node2 = parse('3(4)');
      expect(node2, isA<BinaryOpNode>());
      expect((node2 as BinaryOpNode).isImplicit, isTrue);
    });

    test('Function calls with single and multiple arguments', () {
      final f1 = parse('sin(pi / 2)');
      expect(f1, isA<FunctionCallNode>());
      final call1 = f1 as FunctionCallNode;
      expect(call1.name, equals('sin'));
      expect(call1.arguments.length, equals(1));

      final f2 = parse('gcd(12, 18)');
      expect(f2, isA<FunctionCallNode>());
      final call2 = f2 as FunctionCallNode;
      expect(call2.name, equals('gcd'));
      expect(call2.arguments.length, equals(2));
    });

    test('Audit Area A: Precedence and Grouping AST structure', () {
      // 2 + 3 * 4 -> 2 + (3 * 4)
      final n1 = parse('2 + 3 * 4') as BinaryOpNode;
      expect(n1.operator, equals(BinaryOperator.add));
      expect(
        n1.left,
        equals(
          NumberLiteralNode(
            position: n1.left.position,
            value: IntegerValue.fromInt(2),
          ),
        ),
      );
      expect(n1.right, isA<BinaryOpNode>());
      final r1 = n1.right as BinaryOpNode;
      expect(r1.operator, equals(BinaryOperator.multiply));

      // 2 * 3 + 4 -> (2 * 3) + 4
      final n2 = parse('2 * 3 + 4') as BinaryOpNode;
      expect(n2.operator, equals(BinaryOperator.add));
      expect(n2.left, isA<BinaryOpNode>());
      expect(
        (n2.left as BinaryOpNode).operator,
        equals(BinaryOperator.multiply),
      );

      // 20 / 5 + 2 -> (20 / 5) + 2
      final n3 = parse('20 / 5 + 2') as BinaryOpNode;
      expect(n3.operator, equals(BinaryOperator.add));
      expect(n3.left, isA<BinaryOpNode>());
      expect((n3.left as BinaryOpNode).operator, equals(BinaryOperator.divide));

      // 20 / (5 + 2)
      final n4 = parse('20 / (5 + 2)') as BinaryOpNode;
      expect(n4.operator, equals(BinaryOperator.divide));
      expect(n4.right, isA<GroupNode>());
      final g4 = n4.right as GroupNode;
      expect(g4.inner, isA<BinaryOpNode>());
      expect((g4.inner as BinaryOpNode).operator, equals(BinaryOperator.add));

      // ((2 + 3)) double grouping
      final n5 = parse('((2 + 3))') as GroupNode;
      expect(n5.inner, isA<GroupNode>());
      final g5 = n5.inner as GroupNode;
      expect(g5.inner, isA<BinaryOpNode>());
    });

    test('Audit Area B: Unary minus vs exponentiation AST structure', () {
      // -2^2 -> -(2^2)
      final n1 = parse('-2^2') as UnaryOpNode;
      expect(n1.operator, equals(UnaryOperator.negate));
      expect(n1.operand, isA<BinaryOpNode>());
      final pow1 = n1.operand as BinaryOpNode;
      expect(pow1.operator, equals(BinaryOperator.power));

      // (-2)^2 -> ((-2))^2
      final n2 = parse('(-2)^2') as BinaryOpNode;
      expect(n2.operator, equals(BinaryOperator.power));
      expect(n2.left, isA<GroupNode>());
      final g2 = n2.left as GroupNode;
      expect(g2.inner, isA<UnaryOpNode>());

      // -(2^2)
      final n3 = parse('-(2^2)') as UnaryOpNode;
      expect(n3.operator, equals(UnaryOperator.negate));
      expect(n3.operand, isA<GroupNode>());

      // 2^-2 -> 2^(-2)
      final n4 = parse('2^-2') as BinaryOpNode;
      expect(n4.operator, equals(BinaryOperator.power));
      expect(n4.right, isA<UnaryOpNode>());
      expect((n4.right as UnaryOpNode).operator, equals(UnaryOperator.negate));
    });

    test('Audit Area C: Factorial precedence and unary minus interaction', () {
      // -3! -> -(3!)
      final n1 = parse('-3!') as UnaryOpNode;
      expect(n1.operator, equals(UnaryOperator.negate));
      expect(n1.operand, isA<UnaryOpNode>());
      final fact1 = n1.operand as UnaryOpNode;
      expect(fact1.operator, equals(UnaryOperator.factorial));
      expect(fact1.isPrefix, isFalse);

      // (-3)!
      final n2 = parse('(-3)!') as UnaryOpNode;
      expect(n2.operator, equals(UnaryOperator.factorial));
      expect(n2.isPrefix, isFalse);
      expect(n2.operand, isA<GroupNode>());

      // 3!! -> (3!)!
      final n3 = parse('3!!') as UnaryOpNode;
      expect(n3.operator, equals(UnaryOperator.factorial));
      expect(n3.operand, isA<UnaryOpNode>());
      final innerFact = n3.operand as UnaryOpNode;
      expect(innerFact.operator, equals(UnaryOperator.factorial));

      // 2 * 3! -> 2 * (3!)
      final n4 = parse('2 * 3!') as BinaryOpNode;
      expect(n4.operator, equals(BinaryOperator.multiply));
      expect(n4.right, isA<UnaryOpNode>());
      expect(
        (n4.right as UnaryOpNode).operator,
        equals(UnaryOperator.factorial),
      );
    });

    test(
      'Audit Area D: Implicit multiplication AST structure and precedence',
      () {
        // 2x -> 2 * x (implicit)
        final n1 = parse('2x') as BinaryOpNode;
        expect(n1.operator, equals(BinaryOperator.multiply));
        expect(n1.isImplicit, isTrue);
        expect(n1.left, isA<NumberLiteralNode>());
        expect(n1.right, isA<VariableNode>());

        // (2 + 3)(4 + 5) -> (2 + 3) * (4 + 5)
        final n2 = parse('(2 + 3)(4 + 5)') as BinaryOpNode;
        expect(n2.operator, equals(BinaryOperator.multiply));
        expect(n2.isImplicit, isTrue);
        expect(n2.left, isA<GroupNode>());
        expect(n2.right, isA<GroupNode>());

        // 2x^2 -> 2 * (x^2) because power (40) > implicit (25)
        final n3 = parse('2x^2') as BinaryOpNode;
        expect(n3.operator, equals(BinaryOperator.multiply));
        expect(n3.isImplicit, isTrue);
        expect(n3.left, isA<NumberLiteralNode>());
        expect(n3.right, isA<BinaryOpNode>());
        expect(
          (n3.right as BinaryOpNode).operator,
          equals(BinaryOperator.power),
        );

        // 2/3x -> (2 / 3) * x because left-to-right evaluation at explicit divide vs implicit
        // Wait: 2 / 3x: 2 / (3 * x) or (2 / 3) * x?
        // Since implicit mult is 25 and divide is 20, 3x parses with precedence 25, so 2 / (3 * x)!
        final n4 = parse('2/3x') as BinaryOpNode;
        expect(n4.operator, equals(BinaryOperator.divide));
        expect(n4.right, isA<BinaryOpNode>());
        expect((n4.right as BinaryOpNode).isImplicit, isTrue);

        // 2x/3 -> (2 * x) / 3
        final n5 = parse('2x/3') as BinaryOpNode;
        expect(n5.operator, equals(BinaryOperator.divide));
        expect(n5.left, isA<BinaryOpNode>());
        expect((n5.left as BinaryOpNode).isImplicit, isTrue);

        // -2x -> (-2) * x (BinaryOpNode with left=-(2) and right=x)
        final n6 = parse('-2x') as BinaryOpNode;
        expect(n6.operator, equals(BinaryOperator.multiply));
        expect(n6.isImplicit, isTrue);
        expect(n6.left, isA<UnaryOpNode>());
        expect((n6.left as UnaryOpNode).operator, equals(UnaryOperator.negate));
        expect(n6.right, isA<VariableNode>());
      },
    );

    test('Audit Area L & Unicode operator and symbol parsing', () {
      final mulUnicode = parse('2 × 3') as BinaryOpNode;
      expect(mulUnicode.operator, equals(BinaryOperator.multiply));

      final dotUnicode = parse('2 · 3') as BinaryOpNode;
      expect(dotUnicode.operator, equals(BinaryOperator.multiply));

      final divUnicode = parse('6 ÷ 2') as BinaryOpNode;
      expect(divUnicode.operator, equals(BinaryOperator.divide));

      final minusUnicode = parse('5 − 2') as BinaryOpNode;
      expect(minusUnicode.operator, equals(BinaryOperator.subtract));

      final piUnicode = parse('π') as ConstantNode;
      expect(piUnicode.name, equals('π'));
    });

    test(
      'Audit Area M: Malformed input robustness producing structured errors',
      () {
        const inputs = [
          '',
          '   ',
          '2 +',
          '+',
          '*',
          '2 + * 3',
          '(2 + 3',
          '2 + 3)',
          '(((',
          ')))',
          '1e',
          '1e+',
          '1e-',
          '.',
          '..',
          'sin(',
        ];

        for (final s in inputs) {
          final tokensRes = lexer.tokenize(s);
          if (tokensRes.isFailure) {
            expect(tokensRes.errorOrNull, isA<SyntaxError>());
          } else {
            final parseRes = parser.parse(tokensRes.valueOrNull!);
            expect(
              parseRes.isFailure,
              isTrue,
              reason: 'Expected error for "$s"',
            );
            expect(parseRes.errorOrNull, isA<SyntaxError>());
          }
        }
      },
    );

    test('Syntax error reporting on invalid expressions', () {
      final tokens1 = lexer.tokenize('(2 + 3').valueOrNull!;
      final res1 = parser.parse(tokens1);
      expect(res1.isFailure, isTrue);
      expect(res1.errorOrNull, isA<SyntaxError>());

      final tokens2 = lexer.tokenize('2 + * 3').valueOrNull!;
      final res2 = parser.parse(tokens2);
      expect(res2.isFailure, isTrue);
      expect(res2.errorOrNull, isA<SyntaxError>());
    });
  });
}
