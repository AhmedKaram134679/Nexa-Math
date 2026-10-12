import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('Polynomial & PolynomialOperations Unit Tests', () {
    final ops = DefaultPolynomialOperations();

    test('Canonical construction and degree normalization', () {
      // Zero polynomial
      final p0 = Polynomial.zero;
      expect(p0.isZero, isTrue);
      expect(p0.degree, equals(-1));
      expect(p0.toString(), equals('0'));

      // Monomial: 3x^2
      final m1 = Polynomial.monomial(IntegerValue.fromInt(3), 2);
      expect(m1.degree, equals(2));
      expect(m1.leadingCoefficient, equals(IntegerValue.fromInt(3)));
      expect(m1.getCoefficient(2), equals(IntegerValue.fromInt(3)));
      expect(m1.getCoefficient(1), equals(IntegerValue.zero));
      expect(m1.getCoefficient(0), equals(IntegerValue.zero));
      expect(m1.toString(), equals('3*x^2'));

      // Trimming trailing zero coefficients: [1, 2, 0, 0] -> degree 1
      final pTrim = Polynomial.fromCoefficients([
        IntegerValue.fromInt(1),
        IntegerValue.fromInt(2),
        IntegerValue.zero,
        IntegerValue.zero,
      ]);
      expect(pTrim.degree, equals(1));
      expect(pTrim.coefficients.length, equals(2));
    });

    test('Polynomial addition and subtraction', () {
      // P1: 2x + 3
      final p1 = Polynomial.fromCoefficients([
        IntegerValue.fromInt(3),
        IntegerValue.fromInt(2),
      ]);
      // P2: x^2 - 2x + 1
      final p2 = Polynomial.fromCoefficients([
        IntegerValue.fromInt(1),
        IntegerValue.fromInt(-2),
        IntegerValue.fromInt(1),
      ]);

      // P1 + P2 = x^2 + 4
      final sumRes = ops.add(p1, p2);
      expect(sumRes.isSuccess, isTrue);
      final sum = sumRes.valueOrNull!;
      expect(sum.degree, equals(2));
      expect(sum.getCoefficient(2), equals(IntegerValue.fromInt(1)));
      expect(sum.getCoefficient(1), equals(IntegerValue.zero));
      expect(sum.getCoefficient(0), equals(IntegerValue.fromInt(4)));

      // P1 - P2 = -x^2 + 4x + 2
      final diffRes = ops.subtract(p1, p2);
      expect(diffRes.isSuccess, isTrue);
      final diff = diffRes.valueOrNull!;
      expect(diff.degree, equals(2));
      expect(diff.getCoefficient(2), equals(IntegerValue.fromInt(-1)));
      expect(diff.getCoefficient(1), equals(IntegerValue.fromInt(4)));
      expect(diff.getCoefficient(0), equals(IntegerValue.fromInt(2)));
    });

    test('Polynomial multiplication and powers', () {
      // (x + 2)(x + 3) = x^2 + 5x + 6
      final f1 = Polynomial.fromCoefficients([
        IntegerValue.fromInt(2),
        IntegerValue.fromInt(1),
      ]);
      final f2 = Polynomial.fromCoefficients([
        IntegerValue.fromInt(3),
        IntegerValue.fromInt(1),
      ]);

      final prodRes = ops.multiply(f1, f2);
      expect(prodRes.isSuccess, isTrue);
      final prod = prodRes.valueOrNull!;
      expect(prod.degree, equals(2));
      expect(prod.getCoefficient(2), equals(IntegerValue.fromInt(1)));
      expect(prod.getCoefficient(1), equals(IntegerValue.fromInt(5)));
      expect(prod.getCoefficient(0), equals(IntegerValue.fromInt(6)));

      // (x - 1)^3 = x^3 - 3x^2 + 3x - 1
      final base = Polynomial.fromCoefficients([
        IntegerValue.fromInt(-1),
        IntegerValue.fromInt(1),
      ]);
      final cubeRes = ops.power(base, 3);
      expect(cubeRes.isSuccess, isTrue);
      final cube = cubeRes.valueOrNull!;
      expect(cube.degree, equals(3));
      expect(cube.getCoefficient(3), equals(IntegerValue.fromInt(1)));
      expect(cube.getCoefficient(2), equals(IntegerValue.fromInt(-3)));
      expect(cube.getCoefficient(1), equals(IntegerValue.fromInt(3)));
      expect(cube.getCoefficient(0), equals(IntegerValue.fromInt(-1)));
    });

    test('Polynomial formal derivative', () {
      // P(x) = 4x^3 - 5x^2 + 7x - 9
      // P'(x) = 12x^2 - 10x + 7
      final p = Polynomial.fromCoefficients([
        IntegerValue.fromInt(-9),
        IntegerValue.fromInt(7),
        IntegerValue.fromInt(-5),
        IntegerValue.fromInt(4),
      ]);

      final dRes = ops.derivative(p);
      expect(dRes.isSuccess, isTrue);
      final d = dRes.valueOrNull!;
      expect(d.degree, equals(2));
      expect(d.getCoefficient(2), equals(IntegerValue.fromInt(12)));
      expect(d.getCoefficient(1), equals(IntegerValue.fromInt(-10)));
      expect(d.getCoefficient(0), equals(IntegerValue.fromInt(7)));
    });

    test('Polynomial evaluation via Horner method', () {
      // P(x) = 2x^2 - 3x + 5
      final p = Polynomial.fromCoefficients([
        IntegerValue.fromInt(5),
        IntegerValue.fromInt(-3),
        IntegerValue.fromInt(2),
      ]);

      // P(2) = 2(4) - 3(2) + 5 = 8 - 6 + 5 = 7
      final eval2 = ops.evaluate(p, IntegerValue.fromInt(2));
      expect(eval2.isSuccess, isTrue);
      expect(eval2.valueOrNull, equals(IntegerValue.fromInt(7)));

      // P(1/2) = 2(1/4) - 3(1/2) + 5 = 1/2 - 3/2 + 5 = -1 + 5 = 4
      final evalHalf = ops.evaluate(p, FractionValue.fromInts(1, 2));
      expect(evalHalf.isSuccess, isTrue);
      expect(evalHalf.valueOrNull, equals(FractionValue.fromInts(4, 1)));
    });

    test('Polynomial Euclidean division', () {
      // (x^2 - 1) / (x - 1) = x + 1, rem 0
      final num = Polynomial.fromCoefficients([
        IntegerValue.fromInt(-1),
        IntegerValue.zero,
        IntegerValue.fromInt(1),
      ]);
      final den = Polynomial.fromCoefficients([
        IntegerValue.fromInt(-1),
        IntegerValue.fromInt(1),
      ]);

      final divRes = ops.divide(num, den);
      expect(divRes.isSuccess, isTrue);
      final div = divRes.valueOrNull!;
      expect(div.quotient.degree, equals(1));
      expect(div.quotient.getCoefficient(1), equals(IntegerValue.fromInt(1)));
      expect(div.quotient.getCoefficient(0), equals(IntegerValue.fromInt(1)));
      expect(div.remainder.isZero, isTrue);
    });

    test('Polynomial Euclidean division invariant: A = Q * B + R with deg(R) < deg(B)', () {
      // A(x) = 2x^3 + 3x^2 + 4x + 5, B(x) = 2x + 1
      final a = Polynomial.fromCoefficients([
        IntegerValue.fromInt(5),
        IntegerValue.fromInt(4),
        IntegerValue.fromInt(3),
        IntegerValue.fromInt(2),
      ]);
      final b = Polynomial.fromCoefficients([
        IntegerValue.fromInt(1),
        IntegerValue.fromInt(2),
      ]);

      final divRes = ops.divide(a, b);
      expect(divRes.isSuccess, isTrue);
      final div = divRes.valueOrNull!;
      expect(div.remainder.degree < b.degree, isTrue);

      // Verify exact identity A = Q * B + R
      final qTimesB = ops.multiply(div.quotient, b).valueOrNull!;
      final reconstructedA = ops.add(qTimesB, div.remainder).valueOrNull!;
      expect(reconstructedA, equals(a));
    });

    test('Polynomial Euclidean division with rational coefficients and zero divisor check', () {
      // (x^2 + 1) / (2x - 1) -> quotient = 1/2 x + 1/4, rem = 5/4
      final a = Polynomial.fromCoefficients([
        IntegerValue.fromInt(1),
        IntegerValue.zero,
        IntegerValue.fromInt(1),
      ]);
      final b = Polynomial.fromCoefficients([
        IntegerValue.fromInt(-1),
        IntegerValue.fromInt(2),
      ]);

      final divRes = ops.divide(a, b);
      expect(divRes.isSuccess, isTrue);
      final div = divRes.valueOrNull!;

      // Invariant check: Q * B + R == A
      final qb = ops.multiply(div.quotient, b).valueOrNull!;
      final recon = ops.add(qb, div.remainder).valueOrNull!;
      expect(recon, equals(a));

      // Division by zero polynomial returns DivisionByZeroError
      final zeroDiv = ops.divide(a, Polynomial.zero);
      expect(zeroDiv.isFailure, isTrue);
    });

    test('Horner evaluation vs Arithmetic invariants: P(A*B) == P(A)*P(B)', () {
      final p1 = Polynomial.fromCoefficients([
        IntegerValue.fromInt(2),
        IntegerValue.fromInt(3),
      ]);
      final p2 = Polynomial.fromCoefficients([
        IntegerValue.fromInt(-1),
        IntegerValue.fromInt(4),
      ]);
      final prod = ops.multiply(p1, p2).valueOrNull!;

      final xVal = IntegerValue.fromInt(5);
      final eval1 = ops.evaluate(p1, xVal).valueOrNull!;
      final eval2 = ops.evaluate(p2, xVal).valueOrNull!;
      final evalProd = ops.evaluate(prod, xVal).valueOrNull!;

      // p1(5) = 2 + 15 = 17
      // p2(5) = -1 + 20 = 19
      // prod(5) = 17 * 19 = 323
      expect(eval1, equals(IntegerValue.fromInt(17)));
      expect(eval2, equals(IntegerValue.fromInt(19)));
      expect(evalProd, equals(IntegerValue.fromInt(323)));
    });

    test('Polynomial equality and hashCode consistency across equivalent representations', () {
      final pInt = Polynomial.fromCoefficients([
        IntegerValue.fromInt(3),
        IntegerValue.fromInt(2),
      ]);
      final pFrac = Polynomial.fromCoefficients([
        FractionValue.fromInts(3, 1),
        FractionValue.fromInts(2, 1),
      ]);
      final pMonomial = Polynomial.monomial(FractionValue.fromInts(5, 1), 2);
      final pMonomialInt = Polynomial.monomial(IntegerValue.fromInt(5), 2);

      // Equality check
      expect(pInt == pFrac, isTrue);
      expect(pMonomial == pMonomialInt, isTrue);

      // HashCode consistency invariant: a == b => a.hashCode == b.hashCode
      expect(pInt.hashCode, equals(pFrac.hashCode));
      expect(pMonomial.hashCode, equals(pMonomialInt.hashCode));

      // Hash collection verification
      final set = <Polynomial>{pInt, pMonomial};
      expect(set.contains(pFrac), isTrue);
      expect(set.contains(pMonomialInt), isTrue);
    });
  });
}
