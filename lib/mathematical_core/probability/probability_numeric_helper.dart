import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/core/result/math_warning.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Central numerical and conversion helper for Phase 10 Probability Engine.
///
/// Handles:
/// - Complex number rejection
/// - ScalarValue unboxing to double
/// - Jitter clamping at $[0.0, 1.0]$ boundaries
/// - Representation-relative tail underflow clamping
/// - 1,024-bit rational resource guarding
final class ProbabilityNumericHelper {
  ProbabilityNumericHelper._();

  /// Floating-point jitter clamp tolerance $\epsilon_{\text{clamp}} = 10^{-15}$.
  static const double jitterEpsilon = 1e-15;

  /// Max bit length threshold for exact rational evaluation (1,024 bits).
  static const int maxRationalBitLength = 1024;

  /// Validates [value] and converts it to a standard Dart [double].
  ///
  /// Rejects [ComplexNumber] with non-zero imaginary part with typed [DomainError].
  /// Unboxes pure real [ComplexNumber] to its real decimal scalar.
  static MathResult<double> toDouble(
    ScalarValue value, {
    String functionName = 'ProbabilityDistribution',
    String argumentName = 'x',
  }) {
    if (value is ComplexNumber) {
      if (!value.isReal) {
        return MathFailure(
          DomainError(
            functionName: functionName,
            argument: argumentName,
            message:
                'Complex numbers with imaginary components are not supported '
                'in real probability distributions.',
          ),
        );
      }
      return MathSuccess(value.real.toDouble());
    }

    if (value is IntegerValue) {
      return MathSuccess(value.value.toDouble());
    }

    if (value is FractionValue) {
      return MathSuccess(
        value.numerator.toDouble() / value.denominator.toDouble(),
      );
    }

    if (value is DecimalValue) {
      return MathSuccess(value.toDouble());
    }

    return MathFailure(
      DomainError(
        functionName: functionName,
        argument: argumentName,
        message: 'Unsupported scalar representation for numerical evaluation.',
      ),
    );
  }

  /// Clamps floating-point probability [p] near 0.0 and 1.0 to eliminate floating-point jitter.
  ///
  /// Emits [NearZeroWarning] if negative jitter $[-\epsilon, 0.0)$ is clamped to 0.0.
  /// Emits [PrecisionLossWarning] if upper jitter $(1.0, 1.0 + \epsilon]$ is clamped to 1.0.
  static MathResult<ScalarValue> clampProbability(double p) {
    if (p.isNaN) {
      return const MathFailure(
        ConvergenceFailureError(
          message: 'Probability calculation produced NaN.',
        ),
      );
    }

    if (p < 0.0) {
      if (p >= -jitterEpsilon) {
        // Clamped negative jitter
        return MathSuccess(
          DecimalValue.zero,
          metadata: const CalculationMetadata(
            isExact: false,
            warnings: [NearZeroWarning()],
          ),
        );
      }
      return const MathFailure(
        InvalidProbabilityError(
          value: -1.0,
          message: 'Calculated probability is strictly negative.',
        ),
      );
    }

    if (p > 1.0) {
      if (p <= 1.0 + jitterEpsilon) {
        // Clamped upper jitter (ISS-10-03)
        return MathSuccess(
          DecimalValue.one,
          metadata: const CalculationMetadata(
            isExact: false,
            warnings: [
              NumericalApproximationWarning(
                message: 'Probability slightly exceeded 1.0 due to floating-point rounding and was clamped to 1.0.',
              ),
            ],
          ),
        );
      }
      return const MathFailure(
        InvalidProbabilityError(
          value: 2.0,
          message: 'Calculated probability exceeds 1.0.',
        ),
      );
    }

    // Normal probability in [0.0, 1.0]
    if (p == 0.0) {
      return MathSuccess(
        DecimalValue.zero,
        metadata: const CalculationMetadata(isExact: false),
      );
    }
    if (p == 1.0) {
      return MathSuccess(
        DecimalValue.one,
        metadata: const CalculationMetadata(isExact: false),
      );
    }

    return MathSuccess(
      DecimalValue.parse(p.toString(), isExact: false),
      metadata: const CalculationMetadata(isExact: false),
    );
  }

  /// Handles positive tail probabilities that underflow below representable floating-point bounds.
  ///
  /// If [p] is mathematically strictly positive but evaluated to `0.0` or denormal underflow,
  /// returns representational zero (`DecimalValue.zero`) accompanied by `NearZeroWarning()`
  /// and `isExact: false`. Underflowed positive probabilities MUST NOT be returned as exact `IntegerValue.zero`.
  static MathResult<ScalarValue> handleTailUnderflow() {
    return MathSuccess(
      DecimalValue.zero,
      metadata: const CalculationMetadata(
        isExact: false,
        warnings: [NearZeroWarning()],
      ),
    );
  }

  /// Checks if a rational representation exceeds the 1,024-bit engineering resource policy.
  static bool exceedsRationalResourceLimit(
    BigInt numerator,
    BigInt denominator,
  ) {
    return numerator.bitLength > maxRationalBitLength ||
        denominator.bitLength > maxRationalBitLength;
  }
}
