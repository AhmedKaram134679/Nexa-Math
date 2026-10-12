import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Contract and operations for polynomial algebra.
abstract interface class PolynomialOperations {
  /// Adds two polynomials: $A(x) + B(x)$.
  MathResult<Polynomial> add(Polynomial a, Polynomial b);

  /// Subtracts polynomial $B$ from $A$: $A(x) - B(x)$.
  MathResult<Polynomial> subtract(Polynomial a, Polynomial b);

  /// Multiplies two polynomials: $A(x) \times B(x)$.
  MathResult<Polynomial> multiply(Polynomial a, Polynomial b);

  /// Multiplies a polynomial by a scalar: $c \times P(x)$.
  MathResult<Polynomial> scalarMultiply(Polynomial p, ScalarValue scalar);

  /// Negates a polynomial: $-P(x)$.
  MathResult<Polynomial> negate(Polynomial p);

  /// Computes the power of a polynomial: $P(x)^n$ for non-negative integer $n$.
  MathResult<Polynomial> power(Polynomial p, int exponent);

  /// Computes formal derivative with respect to the polynomial's variable: $\frac{d}{dx} P(x)$.
  MathResult<Polynomial> derivative(Polynomial p);

  /// Performs polynomial Euclidean division: $A(x) = Q(x) \cdot B(x) + R(x)$ with $\deg(R) < \deg(B)$.
  MathResult<PolynomialDivisionResult> divide(Polynomial a, Polynomial b);

  /// Evaluates polynomial at $x$.
  MathResult<ScalarValue> evaluate(Polynomial p, ScalarValue x);
}

/// Result of polynomial Euclidean division containing quotient and remainder.
final class PolynomialDivisionResult {
  final Polynomial quotient;
  final Polynomial remainder;

  const PolynomialDivisionResult({
    required this.quotient,
    required this.remainder,
  });

  @override
  String toString() => 'Quotient: $quotient, Remainder: $remainder';
}

/// Canonical production implementation of [PolynomialOperations].
final class DefaultPolynomialOperations implements PolynomialOperations {
  final NumericEngine numericEngine;

  DefaultPolynomialOperations({NumericEngine? numericEngine})
    : numericEngine = numericEngine ?? NumericEngine();

  @override
  MathResult<Polynomial> add(Polynomial a, Polynomial b) {
    if (a.variable != b.variable && !a.isConstant && !b.isConstant) {
      return MathFailure(
        DomainError(
          message:
              'Cannot add polynomials with different variables: "${a.variable}" vs "${b.variable}".',
          functionName: 'add',
        ),
      );
    }
    final variable = !a.isConstant ? a.variable : b.variable;
    final maxLen = math.max(a.coefficients.length, b.coefficients.length);
    final resultCoeffs = <ScalarValue>[];

    for (var i = 0; i < maxLen; i++) {
      final ca = a.getCoefficient(i);
      final cb = b.getCoefficient(i);
      final sum = numericEngine.add(ca, cb).valueOrNull!;
      resultCoeffs.add(sum);
    }

    return MathSuccess(
      Polynomial.fromCoefficients(resultCoeffs, variable: variable),
    );
  }

  @override
  MathResult<Polynomial> subtract(Polynomial a, Polynomial b) {
    final negB = negate(b).valueOrNull!;
    return add(a, negB);
  }

  @override
  MathResult<Polynomial> multiply(Polynomial a, Polynomial b) {
    if (a.isZero || b.isZero) {
      final variable = !a.isConstant ? a.variable : b.variable;
      return MathSuccess(
        Polynomial.constant(IntegerValue.zero, variable: variable),
      );
    }
    if (a.variable != b.variable && !a.isConstant && !b.isConstant) {
      return MathFailure(
        DomainError(
          message:
              'Cannot multiply polynomials with different variables: "${a.variable}" vs "${b.variable}".',
          functionName: 'multiply',
        ),
      );
    }

    final variable = !a.isConstant ? a.variable : b.variable;
    final totalDegree = a.degree + b.degree;
    final resultCoeffs = List<ScalarValue>.filled(
      totalDegree + 1,
      IntegerValue.zero,
      growable: true,
    );

    for (var i = 0; i < a.coefficients.length; i++) {
      final ca = a.coefficients[i];
      if (_isScalarZero(ca)) continue;
      for (var j = 0; j < b.coefficients.length; j++) {
        final cb = b.coefficients[j];
        if (_isScalarZero(cb)) continue;

        final prod = numericEngine.multiply(ca, cb).valueOrNull!;
        final current = resultCoeffs[i + j];
        resultCoeffs[i + j] = numericEngine.add(current, prod).valueOrNull!;
      }
    }

    return MathSuccess(
      Polynomial.fromCoefficients(resultCoeffs, variable: variable),
    );
  }

  @override
  MathResult<Polynomial> scalarMultiply(Polynomial p, ScalarValue scalar) {
    if (_isScalarZero(scalar) || p.isZero) {
      return MathSuccess(
        Polynomial.constant(IntegerValue.zero, variable: p.variable),
      );
    }
    final newCoeffs = <ScalarValue>[];
    for (final c in p.coefficients) {
      final mul = numericEngine.multiply(c, scalar).valueOrNull!;
      newCoeffs.add(mul);
    }
    return MathSuccess(
      Polynomial.fromCoefficients(newCoeffs, variable: p.variable),
    );
  }

  @override
  MathResult<Polynomial> negate(Polynomial p) {
    final newCoeffs = <ScalarValue>[];
    for (final c in p.coefficients) {
      final neg = numericEngine.negate(c).valueOrNull!;
      newCoeffs.add(neg);
    }
    return MathSuccess(
      Polynomial.fromCoefficients(newCoeffs, variable: p.variable),
    );
  }

  @override
  MathResult<Polynomial> power(Polynomial p, int exponent) {
    if (exponent < 0) {
      return const MathFailure(
        DomainError(
          message: 'Polynomial power exponent must be non-negative integer.',
          functionName: 'power',
        ),
      );
    }
    if (exponent == 0) {
      return MathSuccess(
        Polynomial.constant(IntegerValue.one, variable: p.variable),
      );
    }
    if (exponent == 1) {
      return MathSuccess(p);
    }

    var result = Polynomial.constant(IntegerValue.one, variable: p.variable);
    var base = p;
    var exp = exponent;

    while (exp > 0) {
      if (exp % 2 == 1) {
        result = multiply(result, base).valueOrNull!;
      }
      if (exp > 1) {
        base = multiply(base, base).valueOrNull!;
      }
      exp ~/= 2;
    }

    return MathSuccess(result);
  }

  @override
  MathResult<Polynomial> derivative(Polynomial p) {
    if (p.isConstant) {
      return MathSuccess(
        Polynomial.constant(IntegerValue.zero, variable: p.variable),
      );
    }

    final newCoeffs = <ScalarValue>[];
    for (var i = 1; i < p.coefficients.length; i++) {
      final c = p.coefficients[i];
      final powerScalar = IntegerValue.fromInt(i);
      final derivedCoeff = numericEngine.multiply(c, powerScalar).valueOrNull!;
      newCoeffs.add(derivedCoeff);
    }

    return MathSuccess(
      Polynomial.fromCoefficients(newCoeffs, variable: p.variable),
    );
  }

  @override
  MathResult<PolynomialDivisionResult> divide(Polynomial a, Polynomial b) {
    if (b.isZero) {
      return const MathFailure(DivisionByZeroError());
    }
    if (a.variable != b.variable && !a.isConstant && !b.isConstant) {
      return const MathFailure(
        DomainError(
          message: 'Cannot divide polynomials with different variables.',
          functionName: 'divide',
        ),
      );
    }

    final variable = !b.isConstant ? b.variable : a.variable;

    if (a.isZero || a.degree < b.degree) {
      return MathSuccess(
        PolynomialDivisionResult(
          quotient: Polynomial.constant(IntegerValue.zero, variable: variable),
          remainder: a,
        ),
      );
    }

    final remCoeffs = List<ScalarValue>.from(a.coefficients);
    final bDeg = b.degree;
    final bLead = b.leadingCoefficient;

    final quotientDegree = a.degree - bDeg;
    final quotientCoeffs = List<ScalarValue>.filled(
      quotientDegree + 1,
      IntegerValue.zero,
      growable: true,
    );

    while (true) {
      // Find degree of current remainder
      var remDeg = remCoeffs.length - 1;
      while (remDeg >= 0 && _isScalarZero(remCoeffs[remDeg])) {
        remDeg--;
      }
      if (remDeg < bDeg) {
        break;
      }

      final remLead = remCoeffs[remDeg];
      final qCoeff = numericEngine.divide(remLead, bLead).valueOrNull!;
      final qDeg = remDeg - bDeg;
      quotientCoeffs[qDeg] = qCoeff;

      // Subtract qCoeff * x^qDeg * b from remainder
      for (var i = 0; i <= bDeg; i++) {
        final bCoeff = b.getCoefficient(i);
        final termCoeff = numericEngine.multiply(qCoeff, bCoeff).valueOrNull!;
        final targetIndex = qDeg + i;
        final cur = remCoeffs[targetIndex];
        remCoeffs[targetIndex] = numericEngine
            .subtract(cur, termCoeff)
            .valueOrNull!;
      }
    }

    return MathSuccess(
      PolynomialDivisionResult(
        quotient: Polynomial.fromCoefficients(
          quotientCoeffs,
          variable: variable,
        ),
        remainder: Polynomial.fromCoefficients(remCoeffs, variable: variable),
      ),
    );
  }

  @override
  MathResult<ScalarValue> evaluate(Polynomial p, ScalarValue x) {
    return MathSuccess(p.evaluate(x, engine: numericEngine));
  }

  static bool _isScalarZero(ScalarValue s) {
    if (s is IntegerValue) return s.isZero;
    if (s is FractionValue) return s.isZero;
    return false;
  }
}
