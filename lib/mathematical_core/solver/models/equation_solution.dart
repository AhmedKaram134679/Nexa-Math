/// Structured solution models for univariate equations and systems of equations.
library;

import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_trace.dart';

/// Classification of a mathematical solution status.
enum SolutionType {
  /// Exactly determined mathematical solution (e.g. IntegerValue, FractionValue).
  exact,

  /// Approximate numerical solution satisfying configured tolerance (e.g. DecimalValue with isExact: false).
  approximate,

  /// Inconsistent equation or system with mathematically proven empty solution set.
  noSolution,

  /// Underdetermined equation or identity with infinitely many solutions.
  infiniteSolutions,
}

/// Represents a single discrete root of an equation with its multiplicity and residual.
final class RootValue {
  /// The computed value of the root (e.g. IntegerValue, FractionValue, DecimalValue, or ComplexNumber).
  final ScalarValue value;

  /// Multiplicity of this root (e.g. 2 for repeated root (x - 2)^2 = 0).
  final int multiplicity;

  /// Absolute residual $|LHS(x) - RHS(x)|$ evaluated at this root, if computed.
  final double? residual;

  /// Whether this root was determined exactly or approximately.
  final bool isExact;

  const RootValue({
    required this.value,
    this.multiplicity = 1,
    this.residual,
    required this.isExact,
  });

  /// True if this root is a real number.
  bool get isReal => value is! ComplexNumber || (value as ComplexNumber).isReal;

  /// True if this root is a non-real complex number.
  bool get isComplex => !isReal;

  @override
  String toString() {
    final multStr = multiplicity > 1 ? ' (mult $multiplicity)' : '';
    final exactStr = isExact ? 'exact' : 'approx';
    return '$value$multStr [$exactStr]';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RootValue &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          multiplicity == other.multiplicity &&
          isExact == other.isExact;

  @override
  int get hashCode => Object.hash(value, multiplicity, isExact);
}

/// Structured outcome of solving a univariate equation.
final class EquationSolution {
  /// The target variable solved for (typically 'x').
  final String variable;

  /// High-level mathematical classification of the solution.
  final SolutionType solutionType;

  /// The list of verified distinct roots found.
  final List<RootValue> roots;

  /// Method or strategy used to solve the equation.
  final SolvingMethod methodUsed;

  /// Execution trace of the solving procedure, if enabled.
  final SolverTrace? trace;

  /// Optional message providing additional context (e.g. for infinite solutions or domain caveats).
  final String? message;

  const EquationSolution({
    required this.variable,
    required this.solutionType,
    required this.roots,
    required this.methodUsed,
    this.trace,
    this.message,
  });

  /// Factory creating an exact solution set.
  factory EquationSolution.exact({
    required String variable,
    required List<RootValue> roots,
    required SolvingMethod method,
    SolverTrace? trace,
  }) => EquationSolution(
    variable: variable,
    solutionType: SolutionType.exact,
    roots: List.unmodifiable(roots),
    methodUsed: method,
    trace: trace,
  );

  /// Factory creating an approximate numerical solution set.
  factory EquationSolution.approximate({
    required String variable,
    required List<RootValue> roots,
    required SolvingMethod method,
    SolverTrace? trace,
  }) => EquationSolution(
    variable: variable,
    solutionType: SolutionType.approximate,
    roots: List.unmodifiable(roots),
    methodUsed: method,
    trace: trace,
  );

  /// Factory creating an explicit no-solution outcome.
  factory EquationSolution.noSolution({
    required String variable,
    required SolvingMethod method,
    SolverTrace? trace,
    String? message,
  }) => EquationSolution(
    variable: variable,
    solutionType: SolutionType.noSolution,
    roots: const [],
    methodUsed: method,
    trace: trace,
    message: message ?? 'No solution exists in the mathematical domain.',
  );

  /// Factory creating an explicit infinite-solutions outcome.
  factory EquationSolution.infiniteSolutions({
    required String variable,
    required SolvingMethod method,
    SolverTrace? trace,
    String? message,
  }) => EquationSolution(
    variable: variable,
    solutionType: SolutionType.infiniteSolutions,
    roots: const [],
    methodUsed: method,
    trace: trace,
    message: message ?? 'Infinitely many solutions exist (identity equation).',
  );

  /// Returns only the real roots.
  List<RootValue> get realRoots => roots.where((r) => r.isReal).toList();

  /// Returns only the non-real complex roots.
  List<RootValue> get complexRoots => roots.where((r) => r.isComplex).toList();

  /// True if at least one solution exists.
  bool get hasSolution =>
      solutionType == SolutionType.exact ||
      solutionType == SolutionType.approximate ||
      solutionType == SolutionType.infiniteSolutions;

  @override
  String toString() {
    switch (solutionType) {
      case SolutionType.noSolution:
        return 'No Solution for $variable via ${methodUsed.name}';
      case SolutionType.infiniteSolutions:
        return 'Infinite Solutions for $variable (Identity) via ${methodUsed.name}';
      case SolutionType.exact:
      case SolutionType.approximate:
        return 'Solution for $variable (${solutionType.name}, ${methodUsed.name}): $roots';
    }
  }
}

/// Structured outcome of solving a system of equations (e.g. $A x = b$).
final class SystemSolution {
  /// Variable names corresponding to solution coordinates in order (e.g. ['x', 'y', 'z']).
  final List<String> variables;

  /// High-level mathematical classification.
  final SolutionType solutionType;

  /// Solution assignment mapping variable name to scalar value.
  /// Null if no solution or infinite solutions exist.
  final Map<String, ScalarValue>? assignment;

  /// Method used to solve the system.
  final SolvingMethod methodUsed;

  /// Execution trace of the system solver.
  final SolverTrace? trace;

  /// Optional contextual message.
  final String? message;

  const SystemSolution({
    required this.variables,
    required this.solutionType,
    this.assignment,
    required this.methodUsed,
    this.trace,
    this.message,
  });

  /// Factory for unique exact system solution.
  factory SystemSolution.uniqueExact({
    required List<String> variables,
    required Map<String, ScalarValue> assignment,
    required SolvingMethod method,
    SolverTrace? trace,
  }) => SystemSolution(
    variables: List.unmodifiable(variables),
    solutionType: SolutionType.exact,
    assignment: Map.unmodifiable(assignment),
    methodUsed: method,
    trace: trace,
  );

  /// Factory for inconsistent system (no solution).
  factory SystemSolution.noSolution({
    required List<String> variables,
    required SolvingMethod method,
    SolverTrace? trace,
    String? message,
  }) => SystemSolution(
    variables: List.unmodifiable(variables),
    solutionType: SolutionType.noSolution,
    methodUsed: method,
    trace: trace,
    message: message ?? 'Inconsistent system: no solution exists.',
  );

  /// Factory for underdetermined system (infinitely many solutions).
  factory SystemSolution.infiniteSolutions({
    required List<String> variables,
    required SolvingMethod method,
    SolverTrace? trace,
    String? message,
  }) => SystemSolution(
    variables: List.unmodifiable(variables),
    solutionType: SolutionType.infiniteSolutions,
    methodUsed: method,
    trace: trace,
    message:
        message ?? 'Underdetermined system: infinitely many solutions exist.',
  );

  @override
  String toString() {
    switch (solutionType) {
      case SolutionType.noSolution:
        return 'System: No Solution via ${methodUsed.name}';
      case SolutionType.infiniteSolutions:
        return 'System: Infinitely Many Solutions via ${methodUsed.name}';
      case SolutionType.exact:
      case SolutionType.approximate:
        return 'System Solution (${solutionType.name}): $assignment';
    }
  }
}
