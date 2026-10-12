/// Numerical root-finding via the Newton-Raphson method with Phase 7 CalculusEngine integration.
library;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/calculus/calculus_engine.dart';
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

/// Solves equations $f(x) = 0$ via the Newton-Raphson scheme:
/// $x_{n+1} = x_n - \frac{f(x_n)}{f'(x_n)}$
///
/// Features quadratic local convergence for simple roots where $f'(x) \neq 0$.
/// Derivatives are evaluated through the Phase 7 [CalculusEngine] public contract.
final class NewtonRaphsonSolver implements SolverStrategy {
  final AstEvaluator astEvaluator;
  final CalculusEngine calculusEngine;
  final SolutionValidator validator;

  NewtonRaphsonSolver({
    AstEvaluator? astEvaluator,
    CalculusEngine? calculusEngine,
    SolutionValidator? validator,
  }) : astEvaluator = astEvaluator ?? AstEvaluator(),
       calculusEngine = calculusEngine ?? CalculusEngine(),
       validator = validator ?? SolutionValidator();

  @override
  SolvingMethod get method => SolvingMethod.newtonRaphson;

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

    double evalF(double x) {
      final updatedVars = Map<String, MathValue>.from(context.variables)
        ..[variable] = DecimalValue.parse(x.toString(), isExact: false);
      final evalCtx = context.copyWith(variables: updatedVars);
      final res = astEvaluator.evaluate(canon.left, evalCtx);
      if (res.isFailure) return double.nan;
      final val = res.valueOrNull!;
      if (val is DecimalValue) return val.toDouble();
      return NumericPromoter.toDecimal(val).toDouble();
    }

    double evalDF(double x) {
      final derivRes = calculusEngine.numericalDerivativeOfExpression(
        canon.left,
        x,
        variable: variable,
        baseContext: context,
      );
      if (derivRes.isFailure) return double.nan;
      return derivRes.valueOrNull!.value.toDouble();
    }

    var x = options.initialGuess ?? 1.0;
    var fx = evalF(x);

    // If starting guess causes NaN, try alternate initial guesses
    if (fx.isNaN) {
      for (final alt in [0.0, 0.5, -1.0, 2.0]) {
        x = alt;
        fx = evalF(x);
        if (!fx.isNaN) break;
      }
      if (fx.isNaN) {
        return const MathFailure(
          DomainError(
            message: 'Domain failure evaluating equation at initial guess.',
            functionName: 'newtonRaphson',
          ),
        );
      }
    }

    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: 1,
          title: 'Initial Guess',
          description: 'x0 = $x, f(x0) = $fx',
          parameters: {'x0': '$x', 'f0': '$fx'},
        ),
      );
    }

    var iteration = 0;
    while (iteration < options.maxIterations) {
      iteration++;

      if (fx.abs() <= options.absoluteTolerance) {
        break;
      }

      final dfx = evalDF(x);
      if (dfx.isNaN || dfx.abs() < 1e-14) {
        // If derivative is 0 and f(x) != 0, tangent is horizontal.
        // If function is constant non-zero (like (x-2)/(x-2) - 0 = 1 - 0 = 1 != 0), no root exists.
        return MathSuccess(
          EquationSolution.noSolution(
            variable: variable,
            method: method,
            trace: enableTrace
                ? SolverTrace(
                    methodName: 'Newton-Raphson Method',
                    initialParameters: {
                      'x0': '$x',
                      'tol': '${options.tolerance}',
                    },
                    steps: steps,
                    success: false,
                    iterations: iteration,
                  )
                : null,
            message:
                'Newton-Raphson encountered horizontal tangent f\'(x) = $dfx at x = $x without zero crossing.',
          ),
        );
      }

      final delta = fx / dfx;
      final nextX = x - delta;
      final nextFx = evalF(nextX);

      if (nextFx.isNaN || nextX.isInfinite) {
        // Function left domain during root search
        return MathSuccess(
          EquationSolution.noSolution(
            variable: variable,
            method: method,
            trace: enableTrace
                ? SolverTrace(
                    methodName: 'Newton-Raphson Method',
                    initialParameters: {
                      'x0': '$x',
                      'tol': '${options.tolerance}',
                    },
                    steps: steps,
                    success: false,
                    iterations: iteration,
                  )
                : null,
            message: 'Newton-Raphson iterated into an undefined domain region.',
          ),
        );
      }

      if (enableTrace) {
        steps.add(
          SolverStep(
            stepIndex: iteration + 1,
            title: 'Newton Iteration $iteration',
            description:
                'x = $nextX, f(x) = $nextFx, f\'(x) = $dfx, step = ${delta.abs()}',
            intermediateValue: nextX.toString(),
            residual: nextFx.abs(),
            parameters: {'x': '$nextX', 'fx': '$nextFx', 'dfx': '$dfx'},
          ),
        );
      }

      final errorEst = (nextX - x).abs();
      x = nextX;
      fx = nextFx;

      if (errorEst <= options.tolerance ||
          fx.abs() <= options.absoluteTolerance) {
        break;
      }
    }

    final converged =
        fx.abs() <= (options.tolerance + options.absoluteTolerance * 10);
    if (!converged) {
      return MathFailure(
        ConvergenceFailureError(
          method: 'Newton-Raphson',
          iterations: iteration,
          message:
              'Newton-Raphson failed to converge to a valid root (residual = ${fx.abs()}).',
        ),
      );
    }

    final trace = enableTrace
        ? SolverTrace(
            methodName: 'Newton-Raphson Method',
            initialParameters: {
              'x0': '${options.initialGuess}',
              'tol': '${options.tolerance}',
            },
            steps: steps,
            success: true,
            finalResidual: fx.abs(),
            iterations: iteration,
          )
        : null;

    final candidate = RootValue(
      value: DecimalValue.parse(x.toString(), isExact: false),
      multiplicity: 1,
      residual: fx.abs(),
      isExact: false,
    );

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
          message: 'Newton-Raphson candidate root failed domain validation on original equation.',
        ),
      );
    }

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
