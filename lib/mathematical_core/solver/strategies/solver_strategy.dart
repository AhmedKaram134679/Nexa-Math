/// Abstract base strategy for equation solving algorithms.
library;

import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/solver/models/equation_solution.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';

/// Contract for an equation solving strategy.
abstract interface class SolverStrategy {
  /// Unique identifier of this solving strategy.
  SolvingMethod get method;

  /// Returns true if this strategy is capable of solving the given [equation] in [variable].
  bool canSolve(Equation equation, String variable);

  /// Solves the given [equation] with respect to [variable].
  MathResult<EquationSolution> solve({
    required Equation equation,
    required String variable,
    required SolverOptions options,
    EvaluationContext context = const EvaluationContext(),
    bool enableTrace = false,
  });
}
