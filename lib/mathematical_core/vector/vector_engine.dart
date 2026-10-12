import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/vector/default_vector_engine.dart';
import 'package:nexa_math/mathematical_core/vector/vector.dart';

/// Primary interface for vector algebra operations in NexaMath.
abstract interface class VectorEngine {
  /// Default factory constructor creating the canonical production [DefaultVectorEngine].
  factory VectorEngine({NumericEngine? numericEngine}) = DefaultVectorEngine;

  /// Adds two vectors: `left + right`.
  MathResult<Vector> add(Vector left, Vector right);

  /// Subtracts two vectors: `left - right`.
  MathResult<Vector> subtract(Vector left, Vector right);

  /// Multiplies a vector by a scalar: `scalar * vector`.
  MathResult<Vector> scalarMultiply(Vector vector, ScalarValue scalar);

  /// Divides a vector by a non-zero scalar: `vector / scalar`.
  MathResult<Vector> scalarDivide(Vector vector, ScalarValue scalar);

  /// Computes the exact inner dot product: `left · right`.
  MathResult<ScalarValue> dot(Vector left, Vector right);

  /// Computes the exact 3D cross product: `left × right`.
  /// Strictly requires both vectors to have dimension 3.
  MathResult<Vector> cross(Vector left, Vector right);

  /// Computes the exact squared magnitude: `|v|^2 = v · v`.
  MathResult<ScalarValue> magnitudeSquared(Vector vector);

  /// Computes the numerical Euclidean norm / magnitude: `|v| = sqrt(v · v)`.
  MathResult<DecimalValue> magnitude(Vector vector);

  /// Computes the unit vector in the same direction: `v / |v|`.
  MathResult<Vector> normalize(Vector vector);

  /// Computes the angle in radians between two vectors: `arccos((u · v) / (|u| |v|))`.
  MathResult<DecimalValue> angle(Vector left, Vector right);

  /// Computes the vector projection of [vector] onto [onto]: `proj_u(v) = ((v · u) / (u · u)) * u`.
  MathResult<Vector> projection(Vector vector, Vector onto);

  /// Multiplies a matrix by a vector: `matrix * vector` where vector is treated as a column vector.
  MathResult<Vector> multiplyMatrixVector(Matrix matrix, Vector vector);
}
