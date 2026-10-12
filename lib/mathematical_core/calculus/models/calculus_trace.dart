/// Step-by-step trace and explanation models for calculus operations.
library;

/// Represents a single discrete step in a numerical calculus computation.
final class CalculusStep {
  /// Step or iteration index (1-indexed).
  final int stepIndex;

  /// Human-readable title or label of this step.
  final String title;

  /// Structured description explaining the transformation or calculation performed.
  final String description;

  /// Current evaluated approximation at this step, if applicable.
  final double? intermediateValue;

  /// Current estimated error or tolerance at this step, if applicable.
  final double? estimatedError;

  /// Key-value metrics for this step (e.g. subinterval bounds, node coordinates, weights).
  final Map<String, String> parameters;

  /// Creates an immutable [CalculusStep].
  const CalculusStep({
    required this.stepIndex,
    required this.title,
    required this.description,
    this.intermediateValue,
    this.estimatedError,
    this.parameters = const {},
  });

  @override
  String toString() =>
      'CalculusStep($stepIndex: $title, value: $intermediateValue, error: $estimatedError)';
}

/// Represents a deterministic, immutable execution trace of a calculus algorithm.
final class CalculusTrace {
  /// Name of the method or algorithm executed (e.g. "Richardson Extrapolation", "Adaptive Simpson").
  final String methodName;

  /// Initial input parameters recorded for auditing.
  final Map<String, String> initialParameters;

  /// Chronological sequence of computation steps.
  final List<CalculusStep> steps;

  /// Whether convergence was successfully achieved.
  final bool converged;

  /// Final error estimate, if computed.
  final double? finalErrorEstimate;

  /// Total number of function evaluations performed during the trace.
  final int functionEvaluations;

  /// Creates an immutable [CalculusTrace].
  const CalculusTrace({
    required this.methodName,
    this.initialParameters = const {},
    this.steps = const [],
    required this.converged,
    this.finalErrorEstimate,
    this.functionEvaluations = 0,
  });

  @override
  String toString() =>
      'CalculusTrace(method: $methodName, steps: ${steps.length}, converged: $converged)';
}
