import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Represents an immutable univariate polynomial $P(x) = \sum_{i=0}^n a_i x^i$ with exact scalar coefficients.
///
/// Invariants:
/// 1. [coefficients] is stored in ascending order of degree: index `i` is the coefficient for $x^i$.
/// 2. Trailing zero coefficients are removed, except for the canonical zero polynomial which has `[IntegerValue.zero]`.
/// 3. Degree of the zero polynomial is defined as -1 (or 0 for constant zero).
final class Polynomial extends MathValue {
  /// The variable symbol (default is 'x').
  final String variable;

  /// Coefficients from degree 0 up to degree n: $a_0, a_1, \dots, a_n$.
  final List<ScalarValue> coefficients;

  /// Private constructor enforcing canonical representation.
  const Polynomial._(this.variable, this.coefficients);

  /// Canonical zero polynomial: $P(x) = 0$.
  static final Polynomial zero = Polynomial.fromCoefficients([
    IntegerValue.zero,
  ], variable: 'x');

  /// Creates a polynomial from a list of coefficients in ascending order ($a_0 + a_1 x + \dots + a_n x^n$).
  factory Polynomial.fromCoefficients(
    List<ScalarValue> coeffs, {
    String variable = 'x',
  }) {
    if (coeffs.isEmpty) {
      return Polynomial._(variable, [IntegerValue.zero]);
    }

    // Canonicalize integer fractions to IntegerValue and strip trailing zeros
    final canonicalCoeffs = coeffs.map((c) {
      if (c is FractionValue && c.isInteger) {
        return IntegerValue(c.numerator);
      }
      return c;
    }).toList();

    var lastNonZero = canonicalCoeffs.length - 1;
    while (lastNonZero > 0 && _isScalarZero(canonicalCoeffs[lastNonZero])) {
      lastNonZero--;
    }

    final trimmed = canonicalCoeffs.sublist(0, lastNonZero + 1);
    return Polynomial._(variable, List.unmodifiable(trimmed));
  }

  /// Creates a constant polynomial $P(x) = c$.
  factory Polynomial.constant(ScalarValue c, {String variable = 'x'}) =>
      Polynomial.fromCoefficients([c], variable: variable);

  /// Creates a monomial $P(x) = c \cdot x^k$.
  factory Polynomial.monomial(
    ScalarValue coefficient,
    int degree, {
    String variable = 'x',
  }) {
    if (degree < 0) {
      throw ArgumentError.value(
        degree,
        'degree',
        'Polynomial degree cannot be negative.',
      );
    }
    if (_isScalarZero(coefficient)) {
      return Polynomial._(variable, [IntegerValue.zero]);
    }
    final list = List<ScalarValue>.filled(degree + 1, IntegerValue.zero);
    list[degree] = coefficient;
    return Polynomial.fromCoefficients(list, variable: variable);
  }

  /// Returns the degree of this polynomial.
  ///
  /// For non-zero polynomials, this is the highest power with a non-zero coefficient.
  /// For the zero polynomial $P(x) = 0$, this returns 0 (or -1 if isZero is preferred).
  int get degree => isZero ? -1 : coefficients.length - 1;

  /// Whether this is the zero polynomial $P(x) = 0$.
  bool get isZero =>
      coefficients.length == 1 && _isScalarZero(coefficients.first);

  /// Whether this is a constant polynomial ($P(x) = c$).
  bool get isConstant => degree <= 0;

  /// Returns the leading coefficient (coefficient of highest power), or 0 if empty.
  ScalarValue get leadingCoefficient =>
      coefficients.isEmpty ? IntegerValue.zero : coefficients.last;

  /// Returns the coefficient for a specific [power]. Returns [IntegerValue.zero] if [power] > degree or < 0.
  ScalarValue getCoefficient(int power) {
    if (power < 0 || power >= coefficients.length) {
      return IntegerValue.zero;
    }
    return coefficients[power];
  }

  /// Evaluates the polynomial at a given scalar value [x] using Horner's rule.
  ScalarValue evaluate(ScalarValue x, {NumericEngine? engine}) {
    final eng = engine ?? NumericEngine();
    if (isZero) return IntegerValue.zero;
    if (coefficients.length == 1) return coefficients.first;

    // Horner's method: a_n * x + a_{n-1} ...
    ScalarValue result = coefficients.last;
    for (var i = coefficients.length - 2; i >= 0; i--) {
      final mul = eng.multiply(result, x).valueOrNull!;
      result = eng.add(mul, coefficients[i]).valueOrNull!;
    }
    return result;
  }

  static bool _isScalarZero(ScalarValue s) {
    if (s is IntegerValue) return s.isZero;
    if (s is FractionValue) return s.isZero;
    return false;
  }

  static bool _isScalarOne(ScalarValue s) {
    if (s is IntegerValue) return s.value == BigInt.one;
    if (s is FractionValue) return s == FractionValue.one;
    return false;
  }

  static bool _isScalarNegativeOne(ScalarValue s) {
    if (s is IntegerValue) return s.value == -BigInt.one;
    if (s is FractionValue) {
      return s.numerator == -BigInt.one && s.denominator == BigInt.one;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Polynomial) return false;
    if (variable != other.variable) return false;
    if (coefficients.length != other.coefficients.length) return false;
    for (var i = 0; i < coefficients.length; i++) {
      if (!_scalarEquals(coefficients[i], other.coefficients[i])) return false;
    }
    return true;
  }

  static bool _scalarEquals(ScalarValue a, ScalarValue b) {
    if (a == b) return true;
    if (a is IntegerValue && b is FractionValue) {
      return b.isInteger && b.numerator == a.value;
    }
    if (a is FractionValue && b is IntegerValue) {
      return a.isInteger && a.numerator == b.value;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(variable, Object.hashAll(coefficients));

  @override
  String toString() {
    if (isZero) return '0';

    final sb = StringBuffer();
    var first = true;

    for (var i = coefficients.length - 1; i >= 0; i--) {
      final coeff = coefficients[i];
      if (_isScalarZero(coeff)) continue;

      if (!first) {
        sb.write(' + ');
      }
      first = false;

      final isOne = _isScalarOne(coeff);
      final isNegOne = _isScalarNegativeOne(coeff);

      if (i == 0) {
        sb.write(coeff);
      } else if (i == 1) {
        if (isOne) {
          sb.write(variable);
        } else if (isNegOne) {
          sb.write('-$variable');
        } else {
          sb.write('$coeff*$variable');
        }
      } else {
        if (isOne) {
          sb.write('$variable^$i');
        } else if (isNegOne) {
          sb.write('-$variable^$i');
        } else {
          sb.write('$coeff*$variable^$i');
        }
      }
    }

    return sb.toString();
  }
}
