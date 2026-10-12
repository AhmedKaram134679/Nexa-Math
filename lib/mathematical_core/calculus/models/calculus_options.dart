/// Numerical differentiation and integration options.
library;

/// Numerical differentiation schemes.
enum DifferentiationMethod {
  /// Forward difference quotient: (f(x + h) - f(x)) / h.
  forwardDifference,

  /// Backward difference quotient: (f(x) - f(x - h)) / h.
  backwardDifference,

  /// Central difference quotient: (f(x + h) - f(x - h)) / (2h).
  centralDifference,

  /// Richardson extrapolation applied to central differences for higher-order accuracy.
  richardsonExtrapolation,

  /// Adaptive step size determination based on convergence and local curvature.
  adaptive,
}

/// Numerical integration (quadrature) methods.
enum IntegrationMethod {
  /// Composite trapezoidal rule.
  trapezoidal,

  /// Composite Simpson's 1/3 rule (requires even subdivision count).
  simpsonsOneThird,

  /// Composite Simpson's 3/8 rule (requires subdivision count multiple of 3).
  simpsonsThreeEighths,

  /// Gauss-Legendre quadrature (fixed order n in 2..5).
  gaussLegendre,

  /// Adaptive Simpson quadrature with recursive local error control.
  adaptiveSimpson,
}

/// Configuration options for numerical differentiation and integration.
final class NumericalCalculusOptions {
  /// Step size h for differentiation. Defaults to 1e-6.
  final double stepSize;

  /// Relative tolerance for adaptive methods. Defaults to 1e-7.
  final double tolerance;

  /// Absolute tolerance threshold. Defaults to 1e-10.
  final double absoluteTolerance;

  /// Number of subdivisions for composite integration rules. Defaults to 1200 (compatible with both Simpson 1/3 and 3/8).
  final int subdivisions;

  /// Maximum allowed recursion depth for adaptive integration. Defaults to 50.
  final int maxRecursionDepth;

  /// Maximum allowed iterations for Richardson extrapolation. Defaults to 10.
  final int maxIterations;

  /// Quadrature order for Gauss-Legendre quadrature (2, 3, 4, or 5). Defaults to 5.
  final int gaussLegendreOrder;

  /// Creates an immutable options set for numerical calculus operations.
  const NumericalCalculusOptions({
    this.stepSize = 1e-6,
    this.tolerance = 1e-7,
    this.absoluteTolerance = 1e-10,
    this.subdivisions = 1200,
    this.maxRecursionDepth = 50,
    this.maxIterations = 10,
    this.gaussLegendreOrder = 5,
  }) : assert(stepSize > 0, 'stepSize must be strictly positive'),
       assert(tolerance > 0, 'tolerance must be strictly positive'),
       assert(subdivisions > 0, 'subdivisions must be strictly positive'),
       assert(
         maxRecursionDepth > 0,
         'maxRecursionDepth must be strictly positive',
       ),
       assert(maxIterations > 0, 'maxIterations must be strictly positive'),
       assert(
         gaussLegendreOrder >= 2 && gaussLegendreOrder <= 5,
         'gaussLegendreOrder must be between 2 and 5',
       );
}
