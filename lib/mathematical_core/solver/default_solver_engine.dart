/// Canonical production implementation of [SolverEngine].
library;

import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/algebra_engine.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/calculus/calculus_engine.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/solver/models/equation_solution.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';
import 'package:nexa_math/mathematical_core/solver/solver_engine.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/exact/linear_solver.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/exact/linear_system_solver.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/exact/polynomial_solver.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/numerical/bisection_solver.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/numerical/newton_raphson_solver.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/numerical/secant_solver.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/solver_strategy.dart';
import 'package:nexa_math/mathematical_core/solver/validation/solution_validator.dart';

/// Canonical production implementation of [SolverEngine].
final class DefaultSolverEngine implements SolverEngine {
  final AlgebraEngine algebraEngine;
  final NumericEngine numericEngine;
  final MatrixEngine matrixEngine;
  final CalculusEngine calculusEngine;
  final SolutionValidator validator;

  late final LinearSolver _linearSolver;
  late final PolynomialSolver _polynomialSolver;
  late final LinearSystemSolver _linearSystemSolver;
  late final NewtonRaphsonSolver _newtonRaphsonSolver;
  late final BisectionSolver _bisectionSolver;
  late final SecantSolver _secantSolver;

  DefaultSolverEngine({
    AlgebraEngine? algebraEngine,
    NumericEngine? numericEngine,
    MatrixEngine? matrixEngine,
    CalculusEngine? calculusEngine,
    SolutionValidator? validator,
  }) : algebraEngine = algebraEngine ?? AlgebraEngine(),
       numericEngine = numericEngine ?? NumericEngine(),
       matrixEngine = matrixEngine ?? MatrixEngine(),
       calculusEngine = calculusEngine ?? CalculusEngine(),
       validator = validator ?? SolutionValidator() {
    _linearSolver = LinearSolver(
      algebraEngine: this.algebraEngine,
      numericEngine: this.numericEngine,
      validator: this.validator,
    );
    _polynomialSolver = PolynomialSolver(
      algebraEngine: this.algebraEngine,
      numericEngine: this.numericEngine,
      validator: this.validator,
    );
    _linearSystemSolver = LinearSystemSolver(
      matrixEngine: this.matrixEngine,
      numericEngine: this.numericEngine,
    );
    _newtonRaphsonSolver = NewtonRaphsonSolver(
      calculusEngine: this.calculusEngine,
      validator: this.validator,
    );
    _bisectionSolver = BisectionSolver(validator: this.validator);
    _secantSolver = SecantSolver(validator: this.validator);
  }

  @override
  MathResult<EquationSolution> solve(
    Equation equation, {
    String variable = 'x',
    SolvingMethod method = SolvingMethod.auto,
    SolverOptions options = const SolverOptions(),
    EvaluationContext context = const EvaluationContext(),
    bool enableTrace = false,
  }) {
    final strategy = _selectStrategy(equation, variable, method);
    return strategy.solve(
      equation: equation,
      variable: variable,
      options: options,
      context: context,
      enableTrace: enableTrace,
    );
  }

  @override
  MathResult<EquationSolution> solveString(
    String equationString, {
    String variable = 'x',
    SolvingMethod method = SolvingMethod.auto,
    SolverOptions options = const SolverOptions(),
    EvaluationContext context = const EvaluationContext(),
    bool enableTrace = false,
  }) {
    final parseRes = algebraEngine.parseEquation(equationString);
    if (parseRes.isFailure) return MathFailure(parseRes.errorOrNull!);
    final equation = parseRes.valueOrNull!;

    return solve(
      equation,
      variable: variable,
      method: method,
      options: options,
      context: context,
      enableTrace: enableTrace,
    );
  }

  @override
  MathResult<SystemSolution> solveLinearSystem({
    required Matrix a,
    required List<ScalarValue> b,
    required List<String> variables,
    SolverOptions options = const SolverOptions(),
    bool enableTrace = false,
  }) {
    return _linearSystemSolver.solveSystem(
      a: a,
      b: b,
      variables: variables,
      options: options,
      enableTrace: enableTrace,
    );
  }

  SolverStrategy _selectStrategy(
    Equation equation,
    String variable,
    SolvingMethod requestedMethod,
  ) {
    switch (requestedMethod) {
      case SolvingMethod.linearExact:
        return _linearSolver;
      case SolvingMethod.quadraticExact:
      case SolvingMethod.cubicExact:
      case SolvingMethod.quarticExact:
      case SolvingMethod.polynomialRational:
        return _polynomialSolver;
      case SolvingMethod.newtonRaphson:
        return _newtonRaphsonSolver;
      case SolvingMethod.bisection:
        return _bisectionSolver;
      case SolvingMethod.secant:
        return _secantSolver;
      case SolvingMethod.linearSystem:
        throw UnsupportedError(
          'Linear system solving requires solveLinearSystem().',
        );
      case SolvingMethod.auto:
        // 1. Try exact linear
        if (_linearSolver.canSolve(equation, variable)) {
          return _linearSolver;
        }
        // 2. Try exact polynomial
        if (_polynomialSolver.canSolve(equation, variable)) {
          return _polynomialSolver;
        }
        // 3. Fallback to Newton-Raphson numerical root finding
        return _newtonRaphsonSolver;
    }
  }
}
