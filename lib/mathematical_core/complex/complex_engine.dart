import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/complex/default_complex_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';

/// Primary interface for high-level complex number operations and functions in NexaMath.
///
/// Builds on Phase 2 [ComplexNumber] and [ComplexOperations] primitives, adding
/// transcendental complex functions (exp, ln, sqrt, trig, hyperbolic, powers).
abstract interface class ComplexEngine {
  /// Default factory constructor creating the canonical production [DefaultComplexEngine].
  factory ComplexEngine({
    NumericEngine? numericEngine,
    PrecisionContext context,
  }) = DefaultComplexEngine;

  /// Active precision context governing precision digits and rounding behavior.
  PrecisionContext get context;

  /// Adds two complex numbers: `left + right`.
  MathResult<ComplexNumber> add(ComplexNumber left, ComplexNumber right);

  /// Subtracts two complex numbers: `left - right`.
  MathResult<ComplexNumber> subtract(ComplexNumber left, ComplexNumber right);

  /// Multiplies two complex numbers: `left * right`.
  MathResult<ComplexNumber> multiply(ComplexNumber left, ComplexNumber right);

  /// Divides two complex numbers: `left / right`.
  MathResult<ComplexNumber> divide(ComplexNumber left, ComplexNumber right);

  /// Negates a complex number: `-z`.
  MathResult<ComplexNumber> negate(ComplexNumber z);

  /// Conjugate of a complex number: `z* = a - bi`.
  MathResult<ComplexNumber> conjugate(ComplexNumber z);

  /// Multiplicative inverse of a complex number: `1 / z`.
  MathResult<ComplexNumber> reciprocal(ComplexNumber z);

  /// Squared magnitude: `|z|^2 = a^2 + b^2`.
  MathResult<DecimalValue> magnitudeSquared(ComplexNumber z);

  /// Absolute value / modulus / magnitude: `|z| = sqrt(a^2 + b^2)`.
  MathResult<DecimalValue> magnitude(ComplexNumber z);

  /// Argument / phase angle in radians in `(-pi, pi]`: `arg(z) = atan2(b, a)`.
  MathResult<DecimalValue> phase(ComplexNumber z);

  /// Principal square root of complex number: `sqrt(z)`.
  MathResult<ComplexNumber> sqrt(ComplexNumber z);

  /// Principal complex power: `base ^ exponent`.
  MathResult<ComplexNumber> power(ComplexNumber base, ScalarValue exponent);

  /// Complex exponential: `e^z = e^a * (cos(b) + i * sin(b))`.
  MathResult<ComplexNumber> exp(ComplexNumber z);

  /// Principal complex natural logarithm: `ln(z) = ln|z| + i * arg(z)`.
  MathResult<ComplexNumber> ln(ComplexNumber z);

  /// Complex sine: `sin(z) = (e^(iz) - e^(-iz)) / (2i)`.
  MathResult<ComplexNumber> sin(ComplexNumber z);

  /// Complex cosine: `cos(z) = (e^(iz) + e^(-iz)) / 2`.
  MathResult<ComplexNumber> cos(ComplexNumber z);

  /// Complex tangent: `tan(z) = sin(z) / cos(z)`.
  MathResult<ComplexNumber> tan(ComplexNumber z);

  /// Complex hyperbolic sine: `sinh(z) = (e^z - e^(-z)) / 2`.
  MathResult<ComplexNumber> sinh(ComplexNumber z);

  /// Complex hyperbolic cosine: `cosh(z) = (e^z + e^(-z)) / 2`.
  MathResult<ComplexNumber> cosh(ComplexNumber z);

  /// Complex hyperbolic tangent: `tanh(z) = sinh(z) / cosh(z)`.
  MathResult<ComplexNumber> tanh(ComplexNumber z);
}
