/// Primary public interface for the NexaMath Equation Solver Engine.
library;

import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/solver/default_solver_engine.dart';
import 'package:nexa_math/mathematical_core/solver/models/equation_solution.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';

/// Primary façade interface for solving equations and systems in NexaMath.
///
/// Features:
/// - Exact analytical solving for linear, quadratic, cubic, quartic, and factorable polynomial equations.
/// - Numerical root finding (Newton-Raphson with CalculusEngine derivatives, Bisection interval bracketing, Secant method).
/// - Exact linear system solving ($A x = b$) with Rouché-Capelli classification.
/// - Full domain preservation and back-substitution validation against the original equation AST.
abstract interface class SolverEngine {
  /// Default factory constructor creating the canonical production [DefaultSolverEngine].
  factory SolverEngine() = DefaultSolverEngine;

  /// Solves a parsed [equation] with respect to [variable].
  ///
  /// Automatically selects the most appropriate exact or numerical strategy, or respects
  /// the explicit [method] chosen in [options].
  MathResult<EquationSolution> solve(
    Equation equation, {
    String variable = 'x',
    SolvingMethod method = SolvingMethod.auto,
    SolverOptions options = const SolverOptions(),
    EvaluationContext context = const EvaluationContext(),
    bool enableTrace = false,
  });

  /// Parses and solves an equation string: e.g. `"2x + 4 = 10"`, `"x^2 - 5x + 6 = 0"`, `"cos(x) = x"`.
  MathResult<EquationSolution> solveString(
    String equationString, {
    String variable = 'x',
    SolvingMethod method = SolvingMethod.auto,
    SolverOptions options = const SolverOptions(),
    EvaluationContext context = const EvaluationContext(),
    bool enableTrace = false,
  });

  /// Solves a linear system of equations represented by coefficient matrix [a] and constant vector [b].
  MathResult<SystemSolution> solveLinearSystem({
    required Matrix a,
    required List<ScalarValue> b,
    required List<String> variables,
    SolverOptions options = const SolverOptions(),
    bool enableTrace = false,
  });
}
