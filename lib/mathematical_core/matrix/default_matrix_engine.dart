import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Canonical production implementation of [MatrixEngine].
///
/// Features exact-first arithmetic across [IntegerValue] and [FractionValue],
/// full dimension validation using [MatrixDimensionError], and singularity
/// handling via [SingularMatrixError].
final class DefaultMatrixEngine implements MatrixEngine {
  /// The underlying numeric engine coordinating scalar operations.
  final NumericEngine numericEngine;

  DefaultMatrixEngine({NumericEngine? numericEngine})
    : numericEngine = numericEngine ?? NumericEngine();

  @override
  MathResult<Matrix> add(Matrix left, Matrix right) {
    if (left.rows != right.rows || left.columns != right.columns) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'add',
          leftShape: left.shape,
          rightShape: right.shape,
          message:
              'Cannot add matrices with shapes ${left.shape} and ${right.shape}.',
        ),
      );
    }

    final resultRows = <List<ScalarValue>>[];
    for (var r = 0; r < left.rows; r++) {
      final row = <ScalarValue>[];
      for (var c = 0; c < left.columns; c++) {
        final sum = numericEngine
            .add(left.values[r][c], right.values[r][c])
            .valueOrNull!;
        row.add(sum);
      }
      resultRows.add(row);
    }

    return MathSuccess(
      Matrix.fromRows(resultRows),
      metadata: CalculationMetadata.exact,
    );
  }

  @override
  MathResult<Matrix> subtract(Matrix left, Matrix right) {
    if (left.rows != right.rows || left.columns != right.columns) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'subtract',
          leftShape: left.shape,
          rightShape: right.shape,
          message:
              'Cannot subtract matrices with shapes ${left.shape} and ${right.shape}.',
        ),
      );
    }

    final resultRows = <List<ScalarValue>>[];
    for (var r = 0; r < left.rows; r++) {
      final row = <ScalarValue>[];
      for (var c = 0; c < left.columns; c++) {
        final diff = numericEngine
            .subtract(left.values[r][c], right.values[r][c])
            .valueOrNull!;
        row.add(diff);
      }
      resultRows.add(row);
    }

    return MathSuccess(
      Matrix.fromRows(resultRows),
      metadata: CalculationMetadata.exact,
    );
  }

  @override
  MathResult<Matrix> multiply(Matrix left, Matrix right) {
    if (left.columns != right.rows) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'multiply',
          leftShape: left.shape,
          rightShape: right.shape,
          message:
              'Matrix inner dimensions must agree: ${left.shape} vs ${right.shape}.',
        ),
      );
    }

    final resultRows = <List<ScalarValue>>[];
    for (var r = 0; r < left.rows; r++) {
      final row = <ScalarValue>[];
      for (var c = 0; c < right.columns; c++) {
        ScalarValue acc = IntegerValue.zero;
        for (var k = 0; k < left.columns; k++) {
          final prod = numericEngine
              .multiply(left.values[r][k], right.values[k][c])
              .valueOrNull!;
          acc = numericEngine.add(acc, prod).valueOrNull!;
        }
        row.add(acc);
      }
      resultRows.add(row);
    }

    return MathSuccess(
      Matrix.fromRows(resultRows),
      metadata: CalculationMetadata.exact,
    );
  }

  @override
  MathResult<Matrix> scalarMultiply(Matrix matrix, ScalarValue scalar) {
    final resultRows = <List<ScalarValue>>[];
    for (var r = 0; r < matrix.rows; r++) {
      final row = <ScalarValue>[];
      for (var c = 0; c < matrix.columns; c++) {
        final prod = numericEngine
            .multiply(matrix.values[r][c], scalar)
            .valueOrNull!;
        row.add(prod);
      }
      resultRows.add(row);
    }

    return MathSuccess(
      Matrix.fromRows(resultRows),
      metadata: CalculationMetadata.exact,
    );
  }

  @override
  MathResult<Matrix> transpose(Matrix matrix) {
    final resultRows = <List<ScalarValue>>[];
    for (var c = 0; c < matrix.columns; c++) {
      final row = <ScalarValue>[];
      for (var r = 0; r < matrix.rows; r++) {
        row.add(matrix.values[r][c]);
      }
      resultRows.add(row);
    }

    return MathSuccess(Matrix.fromRows(resultRows));
  }

  @override
  MathResult<ScalarValue> trace(Matrix matrix) {
    if (!matrix.isSquare) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'trace',
          leftShape: matrix.shape,
          message: 'Trace is only defined for square matrices.',
        ),
      );
    }

    ScalarValue acc = IntegerValue.zero;
    for (var i = 0; i < matrix.rows; i++) {
      acc = numericEngine.add(acc, matrix.values[i][i]).valueOrNull!;
    }

    return MathSuccess(acc, metadata: CalculationMetadata.exact);
  }

  @override
  MathResult<ScalarValue> determinant(Matrix matrix) {
    if (!matrix.isSquare) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'determinant',
          leftShape: matrix.shape,
          message: 'Determinant is only defined for square matrices.',
        ),
      );
    }

    final n = matrix.rows;
    if (n == 1) {
      return MathSuccess(matrix.values[0][0]);
    }
    if (n == 2) {
      // ad - bc
      final ad = numericEngine
          .multiply(matrix.values[0][0], matrix.values[1][1])
          .valueOrNull!;
      final bc = numericEngine
          .multiply(matrix.values[0][1], matrix.values[1][0])
          .valueOrNull!;
      final det = numericEngine.subtract(ad, bc).valueOrNull!;
      return MathSuccess(det);
    }
    if (n == 3) {
      // Sarrus rule / Laplace expansion on row 0
      final a = matrix.values[0][0];
      final b = matrix.values[0][1];
      final c = matrix.values[0][2];

      // Minor 0,0
      final m00 = _det2x2(
        matrix.values[1][1],
        matrix.values[1][2],
        matrix.values[2][1],
        matrix.values[2][2],
      );
      // Minor 0,1
      final m01 = _det2x2(
        matrix.values[1][0],
        matrix.values[1][2],
        matrix.values[2][0],
        matrix.values[2][2],
      );
      // Minor 0,2
      final m02 = _det2x2(
        matrix.values[1][0],
        matrix.values[1][1],
        matrix.values[2][0],
        matrix.values[2][1],
      );

      final term1 = numericEngine.multiply(a, m00).valueOrNull!;
      final term2 = numericEngine.multiply(b, m01).valueOrNull!;
      final term3 = numericEngine.multiply(c, m02).valueOrNull!;

      final sub = numericEngine.subtract(term1, term2).valueOrNull!;
      final det = numericEngine.add(sub, term3).valueOrNull!;
      return MathSuccess(det);
    }

    // General n x n exact fraction Gaussian elimination
    return _exactGaussianDeterminant(matrix);
  }

  ScalarValue _det2x2(
    ScalarValue a,
    ScalarValue b,
    ScalarValue c,
    ScalarValue d,
  ) {
    final ad = numericEngine.multiply(a, d).valueOrNull!;
    final bc = numericEngine.multiply(b, c).valueOrNull!;
    return numericEngine.subtract(ad, bc).valueOrNull!;
  }

  MathResult<ScalarValue> _exactGaussianDeterminant(Matrix matrix) {
    final n = matrix.rows;
    // Copy into 2D mutable list of scalars
    final a = List<List<ScalarValue>>.generate(
      n,
      (r) => List<ScalarValue>.from(matrix.values[r]),
    );

    var sign = 1;

    for (var col = 0; col < n; col++) {
      // Pivot selection
      var pivotRow = col;
      while (pivotRow < n && _isZero(a[pivotRow][col])) {
        pivotRow++;
      }
      if (pivotRow == n) {
        // Entire column is 0 -> determinant is 0
        return MathSuccess(IntegerValue.zero);
      }

      if (pivotRow != col) {
        final temp = a[col];
        a[col] = a[pivotRow];
        a[pivotRow] = temp;
        sign = -sign;
      }

      final pivot = a[col][col];

      for (var row = col + 1; row < n; row++) {
        if (_isZero(a[row][col])) continue;
        final factor = numericEngine
            .divide(a[row][col], pivot)
            .valueOrNull!; // exact FractionValue/DecimalValue
        for (var k = col; k < n; k++) {
          final prod = numericEngine.multiply(factor, a[col][k]).valueOrNull!;
          a[row][k] = numericEngine.subtract(a[row][k], prod).valueOrNull!;
        }
      }
    }

    // Product of diagonal elements
    ScalarValue det = IntegerValue.fromInt(sign);
    for (var i = 0; i < n; i++) {
      det = numericEngine.multiply(det, a[i][i]).valueOrNull!;
    }

    if (det is FractionValue && det.isInteger) {
      det = IntegerValue(det.numerator);
    }

    return MathSuccess(det, metadata: CalculationMetadata.exact);
  }

  @override
  MathResult<Matrix> inverse(Matrix matrix) {
    if (!matrix.isSquare) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'inverse',
          leftShape: matrix.shape,
          message: 'Matrix must be square to be invertible.',
        ),
      );
    }

    final n = matrix.rows;
    final detRes = determinant(matrix);
    if (detRes.isFailure) return MathFailure(detRes.errorOrNull!);
    if (_isZero(detRes.valueOrNull!)) {
      return const MathFailure(SingularMatrixError());
    }

    // Exact Gauss-Jordan elimination on augmented matrix [A | I]
    final aug = List<List<ScalarValue>>.generate(n, (r) {
      final row = <ScalarValue>[];
      row.addAll(matrix.values[r]);
      for (var c = 0; c < n; c++) {
        row.add(r == c ? IntegerValue.one : IntegerValue.zero);
      }
      return row;
    });

    for (var col = 0; col < n; col++) {
      var pivotRow = col;
      while (pivotRow < n && _isZero(aug[pivotRow][col])) {
        pivotRow++;
      }
      if (pivotRow == n) {
        return const MathFailure(SingularMatrixError());
      }

      if (pivotRow != col) {
        final temp = aug[col];
        aug[col] = aug[pivotRow];
        aug[pivotRow] = temp;
      }

      final pivot = aug[col][col];
      // Normalize pivot row
      for (var k = 0; k < 2 * n; k++) {
        aug[col][k] = numericEngine.divide(aug[col][k], pivot).valueOrNull!;
      }

      // Eliminate other rows
      for (var row = 0; row < n; row++) {
        if (row == col) continue;
        final factor = aug[row][col];
        if (_isZero(factor)) continue;
        for (var k = 0; k < 2 * n; k++) {
          final prod = numericEngine.multiply(factor, aug[col][k]).valueOrNull!;
          aug[row][k] = numericEngine.subtract(aug[row][k], prod).valueOrNull!;
        }
      }
    }

    // Extract right n x n columns
    final invRows = <List<ScalarValue>>[];
    for (var r = 0; r < n; r++) {
      invRows.add(aug[r].sublist(n, 2 * n));
    }

    return MathSuccess(Matrix.fromRows(invRows));
  }

  @override
  MathResult<int> rank(Matrix matrix) {
    final m = matrix.rows;
    final n = matrix.columns;

    final a = List<List<ScalarValue>>.generate(
      m,
      (r) => List<ScalarValue>.from(matrix.values[r]),
    );

    var rank = 0;
    var row = 0;

    for (var col = 0; col < n && row < m; col++) {
      var pivotRow = row;
      while (pivotRow < m && _isZero(a[pivotRow][col])) {
        pivotRow++;
      }
      if (pivotRow == m) continue;

      if (pivotRow != row) {
        final temp = a[row];
        a[row] = a[pivotRow];
        a[pivotRow] = temp;
      }

      final pivot = a[row][col];
      for (var r = row + 1; r < m; r++) {
        if (_isZero(a[r][col])) continue;
        final factor = numericEngine.divide(a[r][col], pivot).valueOrNull!;
        for (var c = col; c < n; c++) {
          final prod = numericEngine.multiply(factor, a[row][c]).valueOrNull!;
          a[r][c] = numericEngine.subtract(a[r][c], prod).valueOrNull!;
        }
      }

      row++;
      rank++;
    }

    return MathSuccess(rank);
  }

  @override
  MathResult<Matrix> power(Matrix matrix, int exponent) {
    if (!matrix.isSquare) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'power',
          leftShape: matrix.shape,
          message: 'Matrix must be square to compute powers.',
        ),
      );
    }

    if (exponent == 0) {
      return MathSuccess(Matrix.identity(matrix.rows));
    }

    if (exponent < 0) {
      final invRes = inverse(matrix);
      if (invRes.isFailure) return invRes;
      return power(invRes.valueOrNull!, -exponent);
    }

    Matrix result = Matrix.identity(matrix.rows);
    Matrix base = matrix;
    var exp = exponent;

    while (exp > 0) {
      if (exp % 2 == 1) {
        result = multiply(result, base).valueOrNull!;
      }
      if (exp > 1) {
        base = multiply(base, base).valueOrNull!;
      }
      exp ~/= 2;
    }

    return MathSuccess(result);
  }

  bool _isZero(ScalarValue s) {
    if (s is IntegerValue) return s.isZero;
    if (s is FractionValue) return s.isZero;
    if (s is DecimalValue) return s.isZero;
    if (s is ComplexNumber) return s.isZero;
    return false;
  }
}
