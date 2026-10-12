import 'package:nexa_math/core/result/math_warning.dart';

/// Metadata describing numerical approximation specifics.
final class ApproximationMetadata {
  /// Digits of precision preserved in the approximation.
  final int? precision;

  /// Name or identifier of the approximation method used (e.g. 'rungeKutta4', 'newtonRaphson').
  final String? method;

  /// Absolute error bound if estimable.
  final double? absoluteError;

  /// Relative error bound if estimable.
  final double? relativeError;

  /// Whether the approximation successfully converged within tolerance bounds.
  final bool converged;

  const ApproximationMetadata({
    this.precision,
    this.method,
    this.absoluteError,
    this.relativeError,
    this.converged = true,
  });

  @override
  String toString() =>
      'ApproximationMetadata(method: $method, precision: $precision, converged: $converged)';
}

/// Metadata accompanying every mathematical calculation result.
///
/// Explicitly distinguishes exact results from numerical approximations,
/// communicates approximation quality, and carries non-fatal warnings.
final class CalculationMetadata {
  /// Whether the result is mathematically exact.
  final bool isExact;

  /// Numerical approximation details, if the result is approximate.
  final ApproximationMetadata? approximation;

  /// Non-fatal warnings encountered during computation.
  final List<MathWarning> warnings;

  const CalculationMetadata({
    this.isExact = false,
    this.approximation,
    this.warnings = const [],
  });

  /// Convenience factory for an exact calculation metadata instance.
  static const CalculationMetadata exact = CalculationMetadata(isExact: true);

  /// Convenience factory for an approximate calculation metadata instance.
  static const CalculationMetadata approximate = CalculationMetadata(
    isExact: false,
  );

  @override
  String toString() =>
      'CalculationMetadata(isExact: $isExact, warnings: ${warnings.length})';
}
