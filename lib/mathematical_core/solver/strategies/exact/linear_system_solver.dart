/// Exact linear system solver ($A x = b$) utilizing Gaussian elimination and Rouché-Capelli analysis.
library;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/solver/models/equation_solution.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_trace.dart';

/// Solves linear systems of equations $A x = b$ in pure Dart with exact arithmetic.
///
/// Features:
/// - Rouché-Capelli Theorem to explicitly distinguish:
///   - $\text{rank}(A) == \text{rank}(A|b) == n$: Unique solution $x = A^{-1} b$.
///   - $\text{rank}(A) < \text{rank}(A|b)$: Inconsistent system (No solution -> `SystemSolution.noSolution`).
///   - $\text{rank}(A) == \text{rank}(A|b) < n$: Underdetermined system (Infinite solutions -> `SystemSolution.infiniteSolutions`).
final class LinearSystemSolver {
  final MatrixEngine matrixEngine;
  final NumericEngine numericEngine;

  LinearSystemSolver({MatrixEngine? matrixEngine, NumericEngine? numericEngine})
    : matrixEngine = matrixEngine ?? MatrixEngine(),
      numericEngine = numericEngine ?? NumericEngine();

  /// Solves the matrix equation $A x = b$ for ordered [variables].
  MathResult<SystemSolution> solveSystem({
    required Matrix a,
    required List<ScalarValue> b,
    required List<String> variables,
    SolverOptions options = const SolverOptions(),
    bool enableTrace = false,
  }) {
    if (a.rows != b.length) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'solveSystem',
          leftShape: a.shape,
          message:
              'Row count of coefficient matrix A (${a.rows}) does not match vector b length (${b.length}).',
        ),
      );
    }

    if (a.columns != variables.length) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'solveSystem',
          leftShape: a.shape,
          message:
              'Column count of coefficient matrix A (${a.columns}) does not match variable count (${variables.length}).',
        ),
      );
    }

    final steps = <SolverStep>[];
    final m = a.rows;
    final n = a.columns;

    // Build augmented matrix [A | b]
    final augRows = <List<ScalarValue>>[];
    for (var r = 0; r < m; r++) {
      final row = List<ScalarValue>.from(a.values[r])..add(b[r]);
      augRows.add(row);
    }
    final augmented = Matrix.fromRows(augRows);

    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: 1,
          title: 'Augmented System Construction',
          description:
              'Constructed augmented matrix [A | b] with dimensions ${m}x${n + 1}',
          parameters: {'variables': variables.toString()},
        ),
      );
    }

    // Rank of A and rank of [A | b]
    final rankARes = matrixEngine.rank(a);
    if (rankARes.isFailure) return MathFailure(rankARes.errorOrNull!);
    final rankA = rankARes.valueOrNull!;

    final rankAugRes = matrixEngine.rank(augmented);
    if (rankAugRes.isFailure) return MathFailure(rankAugRes.errorOrNull!);
    final rankAug = rankAugRes.valueOrNull!;

    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: 2,
          title: 'Rouché-Capelli Rank Analysis',
          description:
              'Computed rank(A) = $rankA, rank([A | b]) = $rankAug across $n unknowns',
          parameters: {
            'rankA': '$rankA',
            'rankAug': '$rankAug',
            'unknowns': '$n',
          },
        ),
      );
    }

    final trace = enableTrace
        ? SolverTrace(
            methodName: 'Linear System Exact Solver',
            initialParameters: {
              'variables': variables.toString(),
              'rows': '$m',
              'cols': '$n',
            },
            steps: steps,
            success: rankA == rankAug,
            iterations: steps.length,
          )
        : null;

    // Rouché-Capelli Theorem:
    // 1. If rank(A) < rank(A|b), system is inconsistent (no solution)
    if (rankA < rankAug) {
      return MathSuccess(
        SystemSolution.noSolution(
          variables: variables,
          method: SolvingMethod.linearSystem,
          trace: trace,
        ),
      );
    }

    // 2. If rank(A) == rank(A|b) < n, underdetermined (infinite solutions)
    if (rankA < n) {
      return MathSuccess(
        SystemSolution.infiniteSolutions(
          variables: variables,
          method: SolvingMethod.linearSystem,
          trace: trace,
          message: 'Underdetermined system: degree of freedom = ${n - rankA}.',
        ),
      );
    }

    // 3. rank(A) == rank(A|b) == n: Unique solution exists
    // If square (m == n), use inverse x = A^-1 b
    if (m == n) {
      final invRes = matrixEngine.inverse(a);
      if (invRes.isSuccess) {
        final invA = invRes.valueOrNull!;
        final bCol = Matrix.fromRows(b.map((val) => [val]).toList());
        final xRes = matrixEngine.multiply(invA, bCol);
        if (xRes.isSuccess) {
          final xMat = xRes.valueOrNull!;
          final assignment = <String, ScalarValue>{};
          for (var i = 0; i < n; i++) {
            var sol = xMat.values[i][0];
            if (sol is FractionValue && sol.isInteger) {
              sol = IntegerValue(sol.numerator);
            }
            assignment[variables[i]] = sol;
          }
          if (enableTrace) {
            steps.add(
              SolverStep(
                stepIndex: 3,
                title: 'Matrix Inversion Solution',
                description: 'Computed x = A^-1 * b: $assignment',
                intermediateValue: assignment.toString(),
              ),
            );
          }
          return MathSuccess(
            SystemSolution.uniqueExact(
              variables: variables,
              assignment: assignment,
              method: SolvingMethod.linearSystem,
              trace: trace,
            ),
          );
        }
      }
    }

    // General exact Gauss-Jordan elimination on augmented matrix
    final augMat = List<List<ScalarValue>>.generate(
      m,
      (r) => List<ScalarValue>.from(augRows[r]),
    );

    var row = 0;
    for (var col = 0; col < n && row < m; col++) {
      var pivotRow = row;
      while (pivotRow < m && _isZero(augMat[pivotRow][col])) {
        pivotRow++;
      }
      if (pivotRow == m) continue;

      if (pivotRow != row) {
        final temp = augMat[row];
        augMat[row] = augMat[pivotRow];
        augMat[pivotRow] = temp;
      }

      final pivot = augMat[row][col];
      // Normalize pivot row
      for (var k = col; k <= n; k++) {
        augMat[row][k] = numericEngine
            .divide(augMat[row][k], pivot)
            .valueOrNull!;
      }

      // Eliminate other rows
      for (var r = 0; r < m; r++) {
        if (r == row) continue;
        final factor = augMat[r][col];
        if (_isZero(factor)) continue;
        for (var k = col; k <= n; k++) {
          final prod = numericEngine
              .multiply(factor, augMat[row][k])
              .valueOrNull!;
          augMat[r][k] = numericEngine
              .subtract(augMat[r][k], prod)
              .valueOrNull!;
        }
      }
      row++;
    }

    final assignment = <String, ScalarValue>{};
    for (var i = 0; i < n; i++) {
      var sol = augMat[i][n];
      if (sol is FractionValue && sol.isInteger) {
        sol = IntegerValue(sol.numerator);
      }
      assignment[variables[i]] = sol;
    }

    return MathSuccess(
      SystemSolution.uniqueExact(
        variables: variables,
        assignment: assignment,
        method: SolvingMethod.linearSystem,
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
