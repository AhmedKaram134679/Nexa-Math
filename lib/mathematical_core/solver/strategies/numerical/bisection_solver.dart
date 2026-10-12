/// Numerical root-finding via the Bisection method.
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

/// Solves continuous real equations $f(x) = 0$ numerically via the Bisection method.
///
/// Guarantees linear convergence on a bracketed interval $[a, b]$ where $f(a) \cdot f(b) \le 0$.
final class BisectionSolver implements SolverStrategy {
  final AstEvaluator astEvaluator;
  final SolutionValidator validator;

  BisectionSolver({AstEvaluator? astEvaluator, SolutionValidator? validator})
    : astEvaluator = astEvaluator ?? AstEvaluator(),
      validator = validator ?? SolutionValidator();

  @override
  SolvingMethod get method => SolvingMethod.bisection;

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

    // Determine initial bracket [a, b]
    double a = options.intervalLower ?? -10.0;
    double b = options.intervalUpper ?? 10.0;

    if (a >= b) {
      return MathFailure(
        InvalidArgumentError(
          argumentName: 'interval',
          reason:
              'Lower bracket ($a) must be strictly less than upper bracket ($b).',
        ),
      );
    }

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

    var fa = evalAt(a);
    var fb = evalAt(b);

    // If initial bracket does not bracket a root, perform heuristic stepping search
    if (fa.isNaN || fb.isNaN || fa * fb > 0) {
      final bracket = _searchBracket(evalAt, a, b);
      if (bracket == null) {
        return const MathFailure(
          ConvergenceFailureError(
            method: 'Bisection',
            message: 'Unable to locate a sign-change bracket [a, b] where f(a)*f(b) <= 0.',
          ),
        );
      }
      a = bracket.$1;
      b = bracket.$2;
      fa = evalAt(a);
      fb = evalAt(b);
    }

    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: 1,
          title: 'Initial Root Bracket',
          description: 'Established bracket [$a, $b] with f(a)=$fa, f(b)=$fb',
          parameters: {'a': '$a', 'b': '$b', 'fa': '$fa', 'fb': '$fb'},
        ),
      );
    }

    var mid = (a + b) / 2.0;
    var fMid = evalAt(mid);
    var iteration = 0;

    while (iteration < options.maxIterations) {
      iteration++;
      mid = (a + b) / 2.0;
      fMid = evalAt(mid);

      if (fMid.isNaN) {
        return MathFailure(
          DomainError(
            message: 'Domain error encountered at x = $mid during bisection.',
            functionName: 'bisection',
          ),
        );
      }

      final errorEst = (b - a).abs() / 2.0;

      if (enableTrace) {
        steps.add(
          SolverStep(
            stepIndex: iteration + 1,
            title: 'Bisection Iteration $iteration',
            description:
                'x_mid = $mid, f(x_mid) = $fMid, interval width = ${b - a}',
            intermediateValue: mid.toString(),
            residual: fMid.abs(),
            parameters: {'a': '$a', 'b': '$b', 'fMid': '$fMid'},
          ),
        );
      }

      // Stopping condition: interval sufficiently narrow or residual within tolerance
      if (errorEst <= options.tolerance ||
          fMid.abs() <= options.absoluteTolerance) {
        break;
      }

      if (fa * fMid <= 0) {
        b = mid;
        fb = fMid;
      } else {
        a = mid;
        fa = fMid;
      }
    }

    final trace = enableTrace
        ? SolverTrace(
            methodName: 'Bisection Method',
            initialParameters: {
              'interval': '[$a, $b]',
              'tol': '${options.tolerance}',
            },
            steps: steps,
            success: true,
            finalResidual: fMid.abs(),
            iterations: iteration,
          )
        : null;

    final candidateRoot = RootValue(
      value: DecimalValue.parse(mid.toString(), isExact: false),
      multiplicity: 1,
      residual: fMid.abs(),
      isExact: false,
    );

    // Validate against original equation
    final validRoots = validator.validateRoots(
      equation: equation,
      variable: variable,
      candidates: [candidateRoot],
      options: options,
      baseContext: context,
    );

    if (validRoots.isEmpty) {
      return MathFailure(
        ConvergenceFailureError(
          method: 'Bisection',
          iterations: iteration,
          message:
              'Bisection root failed residual validation on original equation.',
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

  (double, double)? _searchBracket(
    double Function(double) f,
    double start,
    double end,
  ) {
    const steps = 100;
    final h = (end - start) / steps;
    var prevX = start;
    var prevF = f(prevX);

    for (var i = 1; i <= steps; i++) {
      final x = start + i * h;
      final fx = f(x);
      if (!prevF.isNaN && !fx.isNaN && prevF * fx <= 0) {
        return (prevX, x);
      }
      prevX = x;
      prevF = fx;
    }
    return null;
  }
}
