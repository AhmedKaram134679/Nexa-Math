/// Result model representing a computed numerical derivative.
library;

import '../../numeric/values/decimal_value.dart';
import 'calculus_options.dart';
import 'calculus_trace.dart';

/// Represents the output of a numerical differentiation operation.
final class NumericDerivative {
  /// The evaluated derivative value as a [DecimalValue].
  final DecimalValue value;

  /// The point x at which the derivative was evaluated.
  final DecimalValue point;

  /// The numerical method used for differentiation.
  final DifferentiationMethod method;

  /// The effective step size h used for the computation.
  final double stepSize;

  /// The estimated error of the approximation, if calculated.
  final double? estimatedError;

  /// Whether the numerical method successfully converged within specified tolerance.
  final bool converged;

  /// Optional execution trace for step-by-step auditing and visualization.
  final CalculusTrace? trace;

  /// Creates an immutable [NumericDerivative] result.
  const NumericDerivative({
    required this.value,
    required this.point,
    required this.method,
    required this.stepSize,
    this.estimatedError,
    required this.converged,
    this.trace,
  });

  @override
  String toString() =>
      'NumericDerivative(f\'($point) = $value, method: ${method.name}, error: $estimatedError)';
}
