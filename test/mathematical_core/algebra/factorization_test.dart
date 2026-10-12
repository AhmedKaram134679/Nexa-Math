import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/algebra/factorization/polynomial_factorizer.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('PolynomialFactorizer Unit Tests', () {
    final factorizer = DefaultPolynomialFactorizer();

    test('Common monomial factor extraction: 2x^2 + 4x -> x*(2x + 4)', () {
      // P(x) = 4x + 2x^2
      final p = Polynomial.fromCoefficients([
        IntegerValue.zero,
        IntegerValue.fromInt(4),
        IntegerValue.fromInt(2),
      ]);

      final res = factorizer.factor(p);
      expect(res.isSuccess, isTrue);
      final ast = res.valueOrNull!;
      expect(ast, isA<BinaryOpNode>());
      final bin = ast as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.multiply));
    });

    test('Difference of squares: x^2 - 9 -> (x - 3)(x + 3)', () {
      // P(x) = x^2 - 9
      final p = Polynomial.fromCoefficients([
        IntegerValue.fromInt(-9),
        IntegerValue.zero,
        IntegerValue.fromInt(1),
      ]);

      final res = factorizer.factor(p);
      expect(res.isSuccess, isTrue);
      final ast = res.valueOrNull!;
      expect(ast, isA<BinaryOpNode>());
      final bin = ast as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.multiply));
      expect(bin.left, isA<GroupNode>());
      expect(bin.right, isA<GroupNode>());
    });

    test('Quadratic trinomial: x^2 + 5x + 6 -> (x + 2)(x + 3)', () {
      final p = Polynomial.fromCoefficients([
        IntegerValue.fromInt(6),
        IntegerValue.fromInt(5),
        IntegerValue.fromInt(1),
      ]);

      final res = factorizer.factor(p);
      expect(res.isSuccess, isTrue);
      final ast = res.valueOrNull!;
      expect(ast, isA<BinaryOpNode>());
      final bin = ast as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.multiply));
    });

    test('Non-monic quadratic trinomial: 2x^2 - 5x + 2 -> (2x - 1)(x - 2)', () {
      final p = Polynomial.fromCoefficients([
        IntegerValue.fromInt(2),
        IntegerValue.fromInt(-5),
        IntegerValue.fromInt(2),
      ]);

      final res = factorizer.factor(p);
      expect(res.isSuccess, isTrue);
      final ast = res.valueOrNull!;
      expect(ast, isA<BinaryOpNode>());
      final bin = ast as BinaryOpNode;
      expect(bin.operator, equals(BinaryOperator.multiply));
    });

    test(
      'Irreducible quadratic: x^2 + x + 1 and x^2 - 2 return canonical AST',
      () {
        final p = Polynomial.fromCoefficients([
          IntegerValue.fromInt(1),
          IntegerValue.fromInt(1),
          IntegerValue.fromInt(1),
        ]);

        final res = factorizer.factor(p);
        expect(res.isSuccess, isTrue);
        final ast = res.valueOrNull!;
        expect(ast, isA<BinaryOpNode>());

        // x^2 - 2 (non-rational square root)
        final p2 = Polynomial.fromCoefficients([
          IntegerValue.fromInt(-2),
          IntegerValue.zero,
          IntegerValue.fromInt(1),
        ]);
        final res2 = factorizer.factor(p2);
        expect(res2.isSuccess, isTrue);
        expect(res2.valueOrNull, isA<BinaryOpNode>());
      },
    );
  });
}
