/// Exact analytical solver for linear equations $a x + b = 0$.
library;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/algebra_engine.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/solver/models/equation_solution.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_trace.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/solver_strategy.dart';
import 'package:nexa_math/mathematical_core/solver/validation/solution_validator.dart';

/// Solves linear equations $a x + b = 0$ exactly in pure Dart.
///
/// Handles:
/// - Unique solution: $x = -b / a$ (exact Integer/Fraction).
/// - No solution (inconsistent): $0 x + b = 0$ where $b \neq 0$ (e.g. $2x + 1 = 2x + 3$).
/// - Infinitely many solutions (identity): $0 x + 0 = 0$ (e.g. $2(x + 1) = 2x + 2$).
final class LinearSolver implements SolverStrategy {
  final AlgebraEngine algebraEngine;
  final NumericEngine numericEngine;
  final SolutionValidator validator;

  LinearSolver({
    AlgebraEngine? algebraEngine,
    NumericEngine? numericEngine,
    SolutionValidator? validator,
  }) : algebraEngine = algebraEngine ?? AlgebraEngine(),
       numericEngine = numericEngine ?? NumericEngine(),
       validator = validator ?? SolutionValidator();

  @override
  SolvingMethod get method => SolvingMethod.linearExact;

  @override
  bool canSolve(Equation equation, String variable) {
    final canon = equation.toCanonicalForm(
      simplifier: algebraEngine.simplifier,
    );
    final polyRes = algebraEngine.toPolynomial(canon.left, variable: variable);
    if (polyRes.isFailure) return false;
    final poly = polyRes.valueOrNull!;
    return poly.degree <= 1;
  }

  @override
  MathResult<EquationSolution> solve({
    required Equation equation,
    required String variable,
    required SolverOptions options,
    EvaluationContext context = const EvaluationContext(),
    bool enableTrace = false,
  }) {
    final steps = <SolverStep>[];

    // Canonicalize to LHS - RHS = 0
    final canon = equation.toCanonicalForm(
      simplifier: algebraEngine.simplifier,
    );
    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: 1,
          title: 'Canonical Reduction',
          description: 'Reduced equation to zero-form: ${canon.left} = 0',
          parameters: {'canonicalForm': '${canon.left} = 0'},
        ),
      );
    }

    final polyRes = algebraEngine.toPolynomial(canon.left, variable: variable);
    if (polyRes.isFailure) return MathFailure(polyRes.errorOrNull!);
    final poly = polyRes.valueOrNull!;

    if (poly.degree > 1) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'equation',
          reason: 'Equation is not linear (degree > 1).',
        ),
      );
    }

    final trace = enableTrace
        ? SolverTrace(
            methodName: 'Linear Exact Solver',
            initialParameters: {
              'equation': equation.toString(),
              'variable': variable,
            },
            steps: steps,
            success: true,
            iterations: 1,
          )
        : null;

    // Case degree 0: c = 0
    if (poly.degree <= 0) {
      final c = poly.getCoefficient(0);
      if (_isZero(c)) {
        // Identity: 0 = 0 -> Infinitely many solutions
        return MathSuccess(
          EquationSolution.infiniteSolutions(
            variable: variable,
            method: method,
            trace: trace,
          ),
        );
      } else {
        // Contradiction: c = 0 with c != 0 -> No solution
        return MathSuccess(
          EquationSolution.noSolution(
            variable: variable,
            method: method,
            trace: trace,
          ),
        );
      }
    }

    // Case degree 1: a x + b = 0
    final b = poly.getCoefficient(0);
    final a = poly.getCoefficient(1);

    if (_isZero(a)) {
      if (_isZero(b)) {
        return MathSuccess(
          EquationSolution.infiniteSolutions(
            variable: variable,
            method: method,
            trace: trace,
          ),
        );
      }
      return MathSuccess(
        EquationSolution.noSolution(
          variable: variable,
          method: method,
          trace: trace,
        ),
      );
    }

    // x = -b / a
    final negB = numericEngine.negate(b).valueOrNull!;
    final rootScalar = numericEngine.divide(negB, a).valueOrNull!;

    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: 2,
          title: 'Isolate Variable',
          description:
              'Calculated exact root x = -b / a = -($b) / ($a) = $rootScalar',
          intermediateValue: rootScalar.toString(),
          parameters: {'a': '$a', 'b': '$b', 'x': '$rootScalar'},
        ),
      );
    }

    final candidate = RootValue(
      value: rootScalar,
      multiplicity: 1,
      residual: 0.0,
      isExact: true,
    );

    // Validate root against original equation
    final validRoots = validator.validateRoots(
      equation: equation,
      variable: variable,
      candidates: [candidate],
      options: options,
      baseContext: context,
    );

    if (validRoots.isEmpty) {
      return MathSuccess(
        EquationSolution.noSolution(
          variable: variable,
          method: method,
          trace: trace,
          message: 'Computed candidate root failed domain validation on original equation.',
        ),
      );
    }

    return MathSuccess(
      EquationSolution.exact(
        variable: variable,
        roots: validRoots,
        method: method,
        trace: trace,
      ),
    );
  }

  bool _isZero(ScalarValue s) {
    if (s is IntegerValue) return s.value == BigInt.zero;
    if (s is FractionValue) return s.numerator == BigInt.zero;
    return false;
  }
}
