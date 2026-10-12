/// Solver configuration options and numerical method parameters.
library;

/// Method or strategy selected for equation solving.
enum SolvingMethod {
  /// Automatic strategy selection based on equation structure (linear, polynomial, numerical).
  auto,

  /// Exact linear solver for degree 1 equations.
  linearExact,

  /// Exact quadratic solver using analytical discriminant.
  quadraticExact,

  /// Exact cubic solver using Cardano's formula.
  cubicExact,

  /// Exact quartic solver using Ferrari's method.
  quarticExact,

  /// Exact polynomial factoring and rational root theorem.
  polynomialRational,

  /// Numerical Newton-Raphson iteration.
  newtonRaphson,

  /// Numerical Bisection root-bracketing method.
  bisection,

  /// Numerical Secant method.
  secant,

  /// Linear system solver (Gaussian elimination / Rouché-Capelli).
  linearSystem,
}

/// Immutable configuration options for the equation solver.
final class SolverOptions {
  /// Relative tolerance for numerical convergence and residual validation.
  final double tolerance;

  /// Absolute tolerance threshold for residual zero-checks.
  final double absoluteTolerance;

  /// Maximum allowed iterations for numerical solvers.
  final int maxIterations;

  /// Optional initial guess for iterative numerical solvers (Newton-Raphson, Secant).
  final double? initialGuess;

  /// Optional lower bound for bracketed numerical solving (Bisection, Secant).
  final double? intervalLower;

  /// Optional upper bound for bracketed numerical solving (Bisection, Secant).
  final double? intervalUpper;

  /// Whether complex solutions (from negative discriminants) should be computed.
  final bool includeComplex;

  /// Default constructor with robust mathematical defaults.
  const SolverOptions({
    this.tolerance = 1e-7,
    this.absoluteTolerance = 1e-10,
    this.maxIterations = 100,
    this.initialGuess,
    this.intervalLower,
    this.intervalUpper,
    this.includeComplex = true,
  });

  /// Creates a copy of this options object with specified overrides.
  SolverOptions copyWith({
    double? tolerance,
    double? absoluteTolerance,
    int? maxIterations,
    double? initialGuess,
    double? intervalLower,
    double? intervalUpper,
    bool? includeComplex,
  }) {
    return SolverOptions(
      tolerance: tolerance ?? this.tolerance,
      absoluteTolerance: absoluteTolerance ?? this.absoluteTolerance,
      maxIterations: maxIterations ?? this.maxIterations,
      initialGuess: initialGuess ?? this.initialGuess,
      intervalLower: intervalLower ?? this.intervalLower,
      intervalUpper: intervalUpper ?? this.intervalUpper,
      includeComplex: includeComplex ?? this.includeComplex,
    );
  }

  @override
  String toString() =>
      'SolverOptions(tol: $tolerance, absTol: $absoluteTolerance, maxIt: $maxIterations, complex: $includeComplex)';
}
