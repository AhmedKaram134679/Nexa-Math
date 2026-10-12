/// Step-by-step trace and explanation models for equation solver operations.
library;

/// Represents a single discrete step in an equation solving procedure.
final class SolverStep {
  /// Step or iteration index (1-indexed).
  final int stepIndex;

  /// Human-readable title or label of this step.
  final String title;

  /// Structured description explaining the transformation or calculation performed.
  final String description;

  /// Intermediate value, candidate root, or residual at this step, if applicable.
  final String? intermediateValue;

  /// Current residual or error estimate at this step, if applicable.
  final double? residual;

  /// Key-value parameters for this step (e.g. interval bounds [a, b], derivative value f'(x), pivot row).
  final Map<String, String> parameters;

  /// Creates an immutable [SolverStep].
  const SolverStep({
    required this.stepIndex,
    required this.title,
    required this.description,
    this.intermediateValue,
    this.residual,
    this.parameters = const {},
  });

  @override
  String toString() =>
      'SolverStep($stepIndex: $title, value: $intermediateValue, residual: $residual)';
}

/// Represents a deterministic, immutable execution trace of an equation solver algorithm.
final class SolverTrace {
  /// Name of the solving method or strategy executed (e.g. "Linear Exact", "Cardano Cubic", "Newton-Raphson").
  final String methodName;

  /// Initial input parameters recorded for auditing.
  final Map<String, String> initialParameters;

  /// Chronological sequence of computation steps.
  final List<SolverStep> steps;

  /// Whether convergence or solution determination was successfully achieved.
  final bool success;

  /// Final residual or error estimate, if computed.
  final double? finalResidual;

  /// Total number of iterations or major transformation stages.
  final int iterations;

  /// Creates an immutable [SolverTrace].
  const SolverTrace({
    required this.methodName,
    required this.initialParameters,
    required this.steps,
    required this.success,
    this.finalResidual,
    this.iterations = 0,
  });

  @override
  String toString() =>
      'SolverTrace(method: $methodName, steps: ${steps.length}, success: $success, residual: $finalResidual)';
}
