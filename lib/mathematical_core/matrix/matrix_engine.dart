import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/matrix/default_matrix_engine.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';

/// Primary interface for matrix algebra operations in NexaMath.
///
/// Dispatches and coordinates matrix arithmetic, determinant, inverse, rank,
/// trace, transpose, and matrix powers.
abstract interface class MatrixEngine {
  /// Default factory constructor creating the canonical production [DefaultMatrixEngine].
  factory MatrixEngine({NumericEngine? numericEngine}) = DefaultMatrixEngine;

  /// Adds two matrices: `left + right`.
  MathResult<Matrix> add(Matrix left, Matrix right);

  /// Subtracts two matrices: `left - right`.
  MathResult<Matrix> subtract(Matrix left, Matrix right);

  /// Multiplies two matrices: `left * right`.
  MathResult<Matrix> multiply(Matrix left, Matrix right);

  /// Multiplies a matrix by a scalar: `scalar * matrix`.
  MathResult<Matrix> scalarMultiply(Matrix matrix, ScalarValue scalar);

  /// Transposes a matrix: `matrix^T`.
  MathResult<Matrix> transpose(Matrix matrix);

  /// Computes the exact determinant of a square matrix.
  MathResult<ScalarValue> determinant(Matrix matrix);

  /// Computes the inverse of a non-singular square matrix: `matrix^-1`.
  MathResult<Matrix> inverse(Matrix matrix);

  /// Computes the rank of a matrix (number of linearly independent rows/columns).
  MathResult<int> rank(Matrix matrix);

  /// Computes the trace of a square matrix (sum of main diagonal elements).
  MathResult<ScalarValue> trace(Matrix matrix);

  /// Computes the integer power of a square matrix: `matrix^exponent`.
  MathResult<Matrix> power(Matrix matrix, int exponent);
}
