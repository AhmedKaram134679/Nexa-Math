import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/algebra/algebra_engine.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('AlgebraEngine Façade & Integration Tests', () {
    final algebra = AlgebraEngine();

    test('Algebraic simplification via string façade', () {
      final res = algebra.simplifyString('3x + 2x - x');
      expect(res.isSuccess, isTrue);
      final ast = res.valueOrNull!;
      expect(ast, isA<BinaryOpNode>());
      final bin = ast as BinaryOpNode;
      expect(
        (bin.left as NumberLiteralNode).value,
        equals(IntegerValue.fromInt(4)),
      );
    });

    test('Algebraic expansion via string façade: (x + 1)^2', () {
      final res = algebra.expandString('(x + 1)^2');
      expect(res.isSuccess, isTrue);
    });

    test('Polynomial conversion via toPolynomial', () {
      final parser = algebra.simplifyString('x^2 + 3x + 2').valueOrNull!;
      final polyRes = algebra.toPolynomial(parser, variable: 'x');
      expect(polyRes.isSuccess, isTrue);
      final p = polyRes.valueOrNull!;
      expect(p.degree, equals(2));
      expect(p.getCoefficient(2), equals(IntegerValue.fromInt(1)));
      expect(p.getCoefficient(1), equals(IntegerValue.fromInt(3)));
      expect(p.getCoefficient(0), equals(IntegerValue.fromInt(2)));
    });

    test('Factorization of polynomial via façade', () {
      final p = Polynomial.fromCoefficients([
        IntegerValue.fromInt(-4),
        IntegerValue.zero,
        IntegerValue.fromInt(1),
      ]);
      final factorRes = algebra.factor(p);
      expect(factorRes.isSuccess, isTrue);
    });

    test('Equation parsing via façade', () {
      final eqRes = algebra.parseEquation('2x + 1 = 9');
      expect(eqRes.isSuccess, isTrue);
      final eq = eqRes.valueOrNull!;
      expect(eq.left, isA<BinaryOpNode>());
      expect(eq.right, isA<NumberLiteralNode>());
    });
  });
}
