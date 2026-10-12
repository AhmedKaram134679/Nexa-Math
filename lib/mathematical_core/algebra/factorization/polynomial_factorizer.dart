import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Contract for polynomial factorization.
abstract interface class PolynomialFactorizer {
  /// Factors a univariate polynomial into product of irreducible factors as an AST node.
  MathResult<ExpressionNode> factor(Polynomial polynomial);
}

/// Canonical production implementation of [PolynomialFactorizer].
///
/// Supports:
/// 1. Common monomial factor extraction: $c \cdot x^k$.
/// 2. Difference of squares: $x^2 - a^2 \to (x - a)(x + a)$.
/// 3. Quadratic trinomials: $ax^2 + bx + c$ with integer/rational roots via discriminant.
/// 4. Irreducible polynomials return their canonical AST representation.
final class DefaultPolynomialFactorizer implements PolynomialFactorizer {
  final NumericEngine numericEngine;

  DefaultPolynomialFactorizer({NumericEngine? numericEngine})
    : numericEngine = numericEngine ?? NumericEngine();

  @override
  MathResult<ExpressionNode> factor(Polynomial p) {
    if (p.isConstant || p.degree <= 1) {
      return MathSuccess(_toAst(p));
    }

    // Step 1: Extract greatest common power of x (e.g. 2x^3 + 4x^2 -> x^2 * (2x + 4))
    var minPower = 0;
    while (minPower < p.coefficients.length &&
        _isScalarZero(p.coefficients[minPower])) {
      minPower++;
    }

    if (minPower > 0) {
      final reducedCoeffs = p.coefficients.sublist(minPower);
      final reducedPoly = Polynomial.fromCoefficients(
        reducedCoeffs,
        variable: p.variable,
      );
      final factorMonomial = Polynomial.monomial(
        IntegerValue.one,
        minPower,
        variable: p.variable,
      );

      final innerFactor = factor(reducedPoly).valueOrNull!;
      return MathSuccess(
        BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.multiply,
          left: _toAst(factorMonomial),
          right: innerFactor,
          isImplicit: true,
        ),
      );
    }

    // Step 2: Quadratic trinomials ax^2 + bx + c
    if (p.degree == 2) {
      final quadraticFactor = _factorQuadratic(p);
      if (quadraticFactor != null) {
        return MathSuccess(quadraticFactor);
      }
    }

    // Default: irreducible polynomial as canonical AST
    return MathSuccess(_toAst(p));
  }

  ExpressionNode? _factorQuadratic(Polynomial p) {
    // p(x) = a x^2 + b x + c
    final c = p.getCoefficient(0);
    final b = p.getCoefficient(1);
    final a = p.getCoefficient(2);

    if (a is! IntegerValue || b is! IntegerValue || c is! IntegerValue) {
      return null;
    }

    final aInt = a.value;
    final bInt = b.value;
    final cInt = c.value;

    // Discriminant D = b^2 - 4ac
    final discriminant = bInt * bInt - BigInt.from(4) * aInt * cInt;
    if (discriminant < BigInt.zero) return null; // No real roots

    final sqrtD = _exactIntegerSqrt(discriminant);
    if (sqrtD == null) return null; // Non-rational roots

    // Roots: r = (-b +/- sqrtD) / (2a)
    // Factors: (a1*x - r1_num) * (a2*x - r2_num)
    // Difference of squares special case: x^2 - k^2 (b=0, a=1, c = -k^2)
    if (bInt == BigInt.zero && aInt == BigInt.one && cInt < BigInt.zero) {
      final k = _exactIntegerSqrt(-cInt);
      if (k != null) {
        // (x - k)(x + k)
        final left = BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.subtract,
          left: VariableNode(position: SourcePosition.start, name: p.variable),
          right: NumberLiteralNode(
            position: SourcePosition.start,
            value: IntegerValue(k),
          ),
        );
        final right = BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.add,
          left: VariableNode(position: SourcePosition.start, name: p.variable),
          right: NumberLiteralNode(
            position: SourcePosition.start,
            value: IntegerValue(k),
          ),
        );
        return BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.multiply,
          left: GroupNode(position: SourcePosition.start, inner: left),
          right: GroupNode(position: SourcePosition.start, inner: right),
          isImplicit: true,
        );
      }
    }

    // Rational roots via discriminant: r = (-b +/- sqrtD) / (2a)
    // Factors: (p1 * x - q1) * (p2 * x - q2) where roots are q1/p1 and q2/p2
    final twoA = BigInt.two * aInt;
    final rootNum1 = -bInt + sqrtD;
    final rootNum2 = -bInt - sqrtD;

    // Root 1 in lowest terms: rootNum1 / twoA = q1 / p1
    var q1 = rootNum1;
    var p1 = twoA;
    if (p1 < BigInt.zero) {
      q1 = -q1;
      p1 = -p1;
    }
    final gcd1 = q1.abs().gcd(p1);
    if (gcd1 > BigInt.one) {
      q1 ~/= gcd1;
      p1 ~/= gcd1;
    }

    // Root 2 in lowest terms: rootNum2 / twoA = q2 / p2
    var q2 = rootNum2;
    var p2 = twoA;
    if (p2 < BigInt.zero) {
      q2 = -q2;
      p2 = -p2;
    }
    final gcd2 = q2.abs().gcd(p2);
    if (gcd2 > BigInt.one) {
      q2 ~/= gcd2;
      p2 ~/= gcd2;
    }

    // Check if leading coefficient equals p1 * p2
    // If a = p1 * p2, then a(x - r1)(x - r2) = (p1*x - q1)(p2*x - q2)
    if (p1 * p2 == aInt) {
      final f1 = _buildLinearFactorWithCoeff(p.variable, p1, -q1);
      final f2 = _buildLinearFactorWithCoeff(p.variable, p2, -q2);
      return BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.multiply,
        left: GroupNode(position: SourcePosition.start, inner: f1),
        right: GroupNode(position: SourcePosition.start, inner: f2),
        isImplicit: true,
      );
    }

    return null;
  }

  ExpressionNode _buildLinearFactorWithCoeff(
    String variable,
    BigInt coeff,
    BigInt constant,
  ) {
    ExpressionNode varPart = VariableNode(
      position: SourcePosition.start,
      name: variable,
    );
    if (coeff != BigInt.one) {
      varPart = BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.multiply,
        left: NumberLiteralNode(
          position: SourcePosition.start,
          value: IntegerValue(coeff),
        ),
        right: varPart,
        isImplicit: true,
      );
    }
    if (constant == BigInt.zero) return varPart;
    if (constant > BigInt.zero) {
      return BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.add,
        left: varPart,
        right: NumberLiteralNode(
          position: SourcePosition.start,
          value: IntegerValue(constant),
        ),
      );
    } else {
      return BinaryOpNode(
        position: SourcePosition.start,
        operator: BinaryOperator.subtract,
        left: varPart,
        right: NumberLiteralNode(
          position: SourcePosition.start,
          value: IntegerValue(-constant),
        ),
      );
    }
  }

  BigInt? _exactIntegerSqrt(BigInt n) {
    if (n < BigInt.zero) return null;
    if (n == BigInt.zero) return BigInt.zero;
    if (n == BigInt.one) return BigInt.one;

    var x0 = n ~/ BigInt.two;
    if (x0 == BigInt.zero) x0 = BigInt.one;
    var x1 = (x0 + n ~/ x0) ~/ BigInt.two;
    while (x1 < x0) {
      x0 = x1;
      x1 = (x0 + n ~/ x0) ~/ BigInt.two;
    }
    if (x0 * x0 == n) return x0;
    return null;
  }

  ExpressionNode _toAst(Polynomial p) {
    if (p.isZero) {
      return NumberLiteralNode(
        position: SourcePosition.start,
        value: IntegerValue.zero,
      );
    }
    ExpressionNode? result;
    for (var i = p.coefficients.length - 1; i >= 0; i--) {
      final c = p.coefficients[i];
      if (_isScalarZero(c)) continue;

      ExpressionNode termNode;
      if (i == 0) {
        termNode = NumberLiteralNode(position: SourcePosition.start, value: c);
      } else {
        ExpressionNode varPart = VariableNode(
          position: SourcePosition.start,
          name: p.variable,
        );
        if (i > 1) {
          varPart = BinaryOpNode(
            position: SourcePosition.start,
            operator: BinaryOperator.power,
            left: varPart,
            right: NumberLiteralNode(
              position: SourcePosition.start,
              value: IntegerValue.fromInt(i),
            ),
          );
        }
        if (c is IntegerValue && c.value == BigInt.one) {
          termNode = varPart;
        } else if (c is IntegerValue && c.value == -BigInt.one) {
          termNode = UnaryOpNode(
            position: SourcePosition.start,
            operator: UnaryOperator.negate,
            operand: varPart,
            isPrefix: true,
          );
        } else {
          termNode = BinaryOpNode(
            position: SourcePosition.start,
            operator: BinaryOperator.multiply,
            left: NumberLiteralNode(position: SourcePosition.start, value: c),
            right: varPart,
            isImplicit: true,
          );
        }
      }

      if (result == null) {
        result = termNode;
      } else {
        result = BinaryOpNode(
          position: SourcePosition.start,
          operator: BinaryOperator.add,
          left: result,
          right: termNode,
        );
      }
    }
    return result!;
  }

  static bool _isScalarZero(ScalarValue s) {
    if (s is IntegerValue) return s.isZero;
    if (s is FractionValue) return s.isZero;
    return false;
  }
}
