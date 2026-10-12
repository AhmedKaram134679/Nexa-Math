/// Numerical root-finding via the Secant method.
library;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/evaluator/ast_evaluator.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/solver/models/equation_solution.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_trace.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/solver_strategy.dart';
import 'package:nexa_math/mathematical_core/solver/validation/solution_validator.dart';

/// Solves continuous real equations $f(x) = 0$ via the Secant method:
/// $x_{n+1} = x_n - f(x_n) \frac{x_n - x_{n-1}}{f(x_n) - f(x_{n-1})}$.
final class SecantSolver implements SolverStrategy {
  final AstEvaluator astEvaluator;
  final SolutionValidator validator;

  SecantSolver({AstEvaluator? astEvaluator, SolutionValidator? validator})
    : astEvaluator = astEvaluator ?? AstEvaluator(),
      validator = validator ?? SolutionValidator();

  @override
  SolvingMethod get method => SolvingMethod.secant;

  @override
  bool canSolve(Equation equation, String variable) => true;

  @override
  MathResult<EquationSolution> solve({
    required Equation equation,
    required String variable,
    required SolverOptions options,
    EvaluationContext context = const EvaluationContext(),
    bool enableTrace = false,
  }) {
    final canon = equation.normalizeToZero();
    final steps = <SolverStep>[];

    double evalAt(double x) {
      final updatedVars = Map<String, MathValue>.from(context.variables)
        ..[variable] = DecimalValue.parse(x.toString(), isExact: false);
      final evalCtx = context.copyWith(variables: updatedVars);
      final res = astEvaluator.evaluate(canon.left, evalCtx);
      if (res.isFailure) return double.nan;
      final val = res.valueOrNull!;
      if (val is DecimalValue) return val.toDouble();
      return NumericPromoter.toDecimal(val).toDouble();
    }

    var x0 =
        options.intervalLower ??
        (options.initialGuess != null ? options.initialGuess! - 0.5 : 0.0);
    var x1 =
        options.intervalUpper ??
        (options.initialGuess != null ? options.initialGuess! + 0.5 : 1.0);

    var f0 = evalAt(x0);
    var f1 = evalAt(x1);

    if (f0.isNaN || f1.isNaN) {
      // Shift points
      x0 = 0.5;
      x1 = 1.5;
      f0 = evalAt(x0);
      f1 = evalAt(x1);
    }

    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: 1,
          title: 'Initial Secant Points',
          description: 'x0 = $x0 (f0 = $f0), x1 = $x1 (f1 = $f1)',
          parameters: {'x0': '$x0', 'x1': '$x1', 'f0': '$f0', 'f1': '$f1'},
        ),
      );
    }

    var iteration = 0;
    while (iteration < options.maxIterations) {
      iteration++;
      final denom = f1 - f0;
      if (denom.abs() < 1e-15) {
        return const MathFailure(
          DivisionByZeroError(
            message: 'Secant slope denominator (f(x1) - f(x0)) is zero.',
          ),
        );
      }

      final x2 = x1 - f1 * (x1 - x0) / denom;
      final f2 = evalAt(x2);

      if (f2.isNaN || x2.isInfinite) {
        return MathFailure(
          DomainError(
            message: 'Domain error or divergence at x = $x2 in Secant solver.',
            functionName: 'secant',
          ),
        );
      }

      if (enableTrace) {
        steps.add(
          SolverStep(
            stepIndex: iteration + 1,
            title: 'Secant Iteration $iteration',
            description: 'x2 = $x2, f(x2) = $f2, step = ${(x2 - x1).abs()}',
            intermediateValue: x2.toString(),
            residual: f2.abs(),
            parameters: {'x2': '$x2', 'f2': '$f2'},
          ),
        );
      }

      // Stopping criteria
      if ((x2 - x1).abs() <= options.tolerance &&
          f2.abs() <= options.absoluteTolerance * 100) {
        final trace = enableTrace
            ? SolverTrace(
                methodName: 'Secant Method',
                initialParameters: {'x0': '$x0', 'x1': '$x1'},
                steps: steps,
                success: true,
                finalResidual: f2.abs(),
                iterations: iteration,
              )
            : null;

        final candidate = RootValue(
          value: DecimalValue.parse(x2.toString(), isExact: false),
          multiplicity: 1,
          residual: f2.abs(),
          isExact: false,
        );

        final validRoots = validator.validateRoots(
          equation: equation,
          variable: variable,
          candidates: [candidate],
          options: options,
          baseContext: context,
        );

        if (validRoots.isNotEmpty) {
          return MathSuccess(
            EquationSolution.approximate(
              variable: variable,
              roots: validRoots,
              method: method,
              trace: trace,
            ),
          );
        }
      }

      x0 = x1;
      f0 = f1;
      x1 = x2;
      f1 = f2;
    }

    return MathFailure(
      ConvergenceFailureError(
        method: 'Secant',
        iterations: options.maxIterations,
        message: 'Secant method failed to converge within allowed iterations.',
      ),
    );
  }
}
