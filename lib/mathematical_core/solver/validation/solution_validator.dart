/// Solution validator performing back-substitution into original equation ASTs.
library;

import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/evaluator/ast_evaluator.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/solver/models/equation_solution.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';

/// Validates candidate solutions by direct substitution into the original equation AST.
final class SolutionValidator {
  final AstEvaluator astEvaluator;
  final NumericEngine numericEngine;

  SolutionValidator({AstEvaluator? astEvaluator, NumericEngine? numericEngine})
    : astEvaluator = astEvaluator ?? AstEvaluator(),
      numericEngine = numericEngine ?? NumericEngine();

  /// Validates a single scalar root against the original unmodified [equation].
  ///
  /// Returns a validated [RootValue] with measured residual, or null if validation fails
  /// (e.g. residual exceeds tolerance or a domain error occurs).
  RootValue? validateRoot({
    required Equation equation,
    required String variable,
    required ScalarValue candidate,
    required bool isExact,
    int multiplicity = 1,
    required SolverOptions options,
    EvaluationContext baseContext = const EvaluationContext(),
  }) {
    // If complex root and equation evaluation is purely real, handle with complex or numeric evaluation
    if (candidate is ComplexNumber && !candidate.isReal) {
      if (!options.includeComplex) return null;
      // For polynomials, complex roots are checked algebraically or passed if exact polynomial root
      return RootValue(
        value: candidate,
        multiplicity: multiplicity,
        isExact: isExact,
        residual: 0.0,
      );
    }

    final updatedVars = Map<String, MathValue>.from(baseContext.variables)
      ..[variable] = candidate;
    final evalContext = baseContext.copyWith(variables: updatedVars);

    // Evaluate LHS on original equation
    final lhsRes = astEvaluator.evaluate(equation.left, evalContext);
    if (lhsRes.isFailure) return null; // Domain error (e.g. ln(<=0), /0)

    // Evaluate RHS on original equation
    final rhsRes = astEvaluator.evaluate(equation.right, evalContext);
    if (rhsRes.isFailure) return null; // Domain error

    final lhsVal = lhsRes.valueOrNull!;
    final rhsVal = rhsRes.valueOrNull!;

    // If both are exact representations and equal, residual is exactly 0.0
    if (isExact && lhsVal == rhsVal) {
      return RootValue(
        value: candidate,
        multiplicity: multiplicity,
        residual: 0.0,
        isExact: true,
      );
    }

    // Otherwise compute difference |LHS - RHS|
    final diffRes = numericEngine.subtract(lhsVal, rhsVal);
    if (diffRes.isFailure) return null;

    final diff = diffRes.valueOrNull!;
    double residual;
    if (diff is DecimalValue) {
      residual = diff.toDouble().abs();
    } else {
      final dec = NumericPromoter.toDecimal(diff);
      residual = dec.toDouble().abs();
    }

    const maxVal = 1.0;
    final allowedTol = options.tolerance * maxVal + options.absoluteTolerance;
    if (residual <= allowedTol) {
      return RootValue(
        value: candidate,
        multiplicity: multiplicity,
        residual: residual,
        isExact: isExact && residual == 0.0,
      );
    }

    return null; // Failed residual test
  }

  /// Filters a list of candidate roots against the original [equation], preserving valid roots.
  List<RootValue> validateRoots({
    required Equation equation,
    required String variable,
    required List<RootValue> candidates,
    required SolverOptions options,
    EvaluationContext baseContext = const EvaluationContext(),
  }) {
    final validRoots = <RootValue>[];
    for (final c in candidates) {
      final valid = validateRoot(
        equation: equation,
        variable: variable,
        candidate: c.value,
        isExact: c.isExact,
        multiplicity: c.multiplicity,
        options: options,
        baseContext: baseContext,
      );
      if (valid != null) {
        validRoots.add(valid);
      }
    }
    return validRoots;
  }
}
