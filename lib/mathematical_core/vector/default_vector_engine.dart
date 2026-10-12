import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/decimal_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/vector/vector.dart';
import 'package:nexa_math/mathematical_core/vector/vector_engine.dart';

/// Canonical production implementation of [VectorEngine].
final class DefaultVectorEngine implements VectorEngine {
  final NumericEngine numericEngine;

  DefaultVectorEngine({NumericEngine? numericEngine})
    : numericEngine = numericEngine ?? NumericEngine();

  @override
  MathResult<Vector> add(Vector left, Vector right) {
    if (left.dimension != right.dimension) {
      return MathFailure(
        DimensionMismatchError(
          expectedDimension: '${left.dimension}',
          actualDimension: '${right.dimension}',
          message:
              'Cannot add vectors of different dimensions (${left.dimension} vs ${right.dimension}).',
        ),
      );
    }

    final newComponents = <ScalarValue>[];
    for (var i = 0; i < left.dimension; i++) {
      final sum = numericEngine.add(left[i], right[i]).valueOrNull!;
      newComponents.add(sum);
    }

    return MathSuccess(
      Vector(newComponents),
      metadata: CalculationMetadata.exact,
    );
  }

  @override
  MathResult<Vector> subtract(Vector left, Vector right) {
    if (left.dimension != right.dimension) {
      return MathFailure(
        DimensionMismatchError(
          expectedDimension: '${left.dimension}',
          actualDimension: '${right.dimension}',
          message:
              'Cannot subtract vectors of different dimensions (${left.dimension} vs ${right.dimension}).',
        ),
      );
    }

    final newComponents = <ScalarValue>[];
    for (var i = 0; i < left.dimension; i++) {
      final diff = numericEngine.subtract(left[i], right[i]).valueOrNull!;
      newComponents.add(diff);
    }

    return MathSuccess(Vector(newComponents));
  }

  @override
  MathResult<Vector> scalarMultiply(Vector vector, ScalarValue scalar) {
    final newComponents = <ScalarValue>[];
    for (var i = 0; i < vector.dimension; i++) {
      final prod = numericEngine.multiply(vector[i], scalar).valueOrNull!;
      newComponents.add(prod);
    }
    return MathSuccess(Vector(newComponents));
  }

  @override
  MathResult<Vector> scalarDivide(Vector vector, ScalarValue scalar) {
    if (_isScalarZero(scalar)) {
      return const MathFailure(DivisionByZeroError());
    }
    final newComponents = <ScalarValue>[];
    for (var i = 0; i < vector.dimension; i++) {
      final div = numericEngine.divide(vector[i], scalar).valueOrNull!;
      newComponents.add(div);
    }
    return MathSuccess(Vector(newComponents));
  }

  @override
  MathResult<ScalarValue> dot(Vector left, Vector right) {
    if (left.dimension != right.dimension) {
      return MathFailure(
        DimensionMismatchError(
          expectedDimension: '${left.dimension}',
          actualDimension: '${right.dimension}',
          message:
              'Dot product requires vectors of equal dimension (${left.dimension} vs ${right.dimension}).',
        ),
      );
    }

    ScalarValue acc = IntegerValue.zero;
    for (var i = 0; i < left.dimension; i++) {
      final prod = numericEngine.multiply(left[i], right[i]).valueOrNull!;
      acc = numericEngine.add(acc, prod).valueOrNull!;
    }

    return MathSuccess(acc, metadata: CalculationMetadata.exact);
  }

  @override
  MathResult<Vector> cross(Vector left, Vector right) {
    if (left.dimension != 3 || right.dimension != 3) {
      return MathFailure(
        DimensionMismatchError(
          expectedDimension: '3',
          actualDimension: '${left.dimension}, ${right.dimension}',
          message:
              'Cross product is strictly defined for 3-dimensional vectors.',
        ),
      );
    }

    // u x v = (u2*v3 - u3*v2, u3*v1 - u1*v3, u1*v2 - u2*v1)
    final u1 = left[0];
    final u2 = left[1];
    final u3 = left[2];

    final v1 = right[0];
    final v2 = right[1];
    final v3 = right[2];

    final u2v3 = numericEngine.multiply(u2, v3).valueOrNull!;
    final u3v2 = numericEngine.multiply(u3, v2).valueOrNull!;
    final c1 = numericEngine.subtract(u2v3, u3v2).valueOrNull!;

    final u3v1 = numericEngine.multiply(u3, v1).valueOrNull!;
    final u1v3 = numericEngine.multiply(u1, v3).valueOrNull!;
    final c2 = numericEngine.subtract(u3v1, u1v3).valueOrNull!;

    final u1v2 = numericEngine.multiply(u1, v2).valueOrNull!;
    final u2v1 = numericEngine.multiply(u2, v1).valueOrNull!;
    final c3 = numericEngine.subtract(u1v2, u2v1).valueOrNull!;

    return MathSuccess(Vector([c1, c2, c3]));
  }

  @override
  MathResult<ScalarValue> magnitudeSquared(Vector vector) {
    return dot(vector, vector);
  }

  @override
  MathResult<DecimalValue> magnitude(Vector vector) {
    final magSqRes = magnitudeSquared(vector);
    if (magSqRes.isFailure) return MathFailure(magSqRes.errorOrNull!);
    final magSq = magSqRes.valueOrNull!;

    DecimalValue decVal;
    if (magSq is DecimalValue) {
      decVal = magSq;
    } else if (magSq is IntegerValue) {
      decVal = DecimalValue.fromInteger(magSq);
    } else if (magSq is FractionValue) {
      final div = DecimalOperations.divide(
        DecimalValue(magSq.numerator, 0),
        DecimalValue(magSq.denominator, 0),
      );
      decVal = div.valueOrNull!;
    } else {
      decVal = DecimalValue.parse(magSq.toString());
    }

    return DecimalOperations.sqrt(decVal);
  }

  @override
  MathResult<Vector> normalize(Vector vector) {
    if (vector.isZero) {
      return const MathFailure(
        DomainError(
          message: 'Cannot normalize the zero vector.',
          functionName: 'normalize',
        ),
      );
    }

    final magRes = magnitude(vector);
    if (magRes.isFailure) return MathFailure(magRes.errorOrNull!);
    final mag = magRes.valueOrNull!;

    return scalarDivide(vector, mag);
  }

  @override
  MathResult<DecimalValue> angle(Vector left, Vector right) {
    if (left.dimension != right.dimension) {
      return MathFailure(
        DimensionMismatchError(
          expectedDimension: '${left.dimension}',
          actualDimension: '${right.dimension}',
          message: 'Vectors must have the same dimension to compute angle.',
        ),
      );
    }
    if (left.isZero || right.isZero) {
      return const MathFailure(
        DomainError(
          message: 'Angle is undefined for zero vectors.',
          functionName: 'angle',
        ),
      );
    }

    final dotRes = dot(left, right);
    if (dotRes.isFailure) return MathFailure(dotRes.errorOrNull!);
    final magLeft = magnitude(left).valueOrNull!;
    final magRight = magnitude(right).valueOrNull!;

    final denom = DecimalOperations.multiply(magLeft, magRight).valueOrNull!;
    DecimalValue dotDec;
    final dotVal = dotRes.valueOrNull!;
    if (dotVal is DecimalValue) {
      dotDec = dotVal;
    } else if (dotVal is IntegerValue) {
      dotDec = DecimalValue.fromInteger(dotVal);
    } else if (dotVal is FractionValue) {
      dotDec = DecimalOperations.divide(
        DecimalValue(dotVal.numerator, 0),
        DecimalValue(dotVal.denominator, 0),
      ).valueOrNull!;
    } else {
      dotDec = DecimalValue.parse(dotVal.toString());
    }

    final cosThetaRes = DecimalOperations.divide(dotDec, denom);
    if (cosThetaRes.isFailure) return MathFailure(cosThetaRes.errorOrNull!);
    var cosThetaDbl = cosThetaRes.valueOrNull!.toDouble();

    // Clamp for float precision
    if (cosThetaDbl > 1.0) cosThetaDbl = 1.0;
    if (cosThetaDbl < -1.0) cosThetaDbl = -1.0;

    final angleRad = math.acos(cosThetaDbl);
    return MathSuccess(
      DecimalValue.parse(angleRad.toString(), isExact: false),
      metadata: const CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: 34,
          method: 'acos',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<Vector> projection(Vector vector, Vector onto) {
    if (vector.dimension != onto.dimension) {
      return MathFailure(
        DimensionMismatchError(
          expectedDimension: '${onto.dimension}',
          actualDimension: '${vector.dimension}',
          message: 'Vectors must have the same dimension for projection.',
        ),
      );
    }
    if (onto.isZero) {
      return const MathFailure(
        DomainError(
          message: 'Cannot project onto the zero vector.',
          functionName: 'projection',
        ),
      );
    }

    // proj_u(v) = (v · u / (u · u)) * u
    final numRes = dot(vector, onto);
    final denRes = dot(onto, onto);
    if (numRes.isFailure) return MathFailure(numRes.errorOrNull!);
    if (denRes.isFailure) return MathFailure(denRes.errorOrNull!);

    final scalarFactor = numericEngine
        .divide(numRes.valueOrNull!, denRes.valueOrNull!)
        .valueOrNull!;
    return scalarMultiply(onto, scalarFactor);
  }

  @override
  MathResult<Vector> multiplyMatrixVector(Matrix matrix, Vector vector) {
    if (matrix.columns != vector.dimension) {
      return MathFailure(
        MatrixDimensionError(
          operation: 'multiplyMatrixVector',
          leftShape: matrix.shape,
          rightShape: (vector.dimension, 1),
          message:
              'Matrix column count (${matrix.columns}) must match vector dimension (${vector.dimension}).',
        ),
      );
    }

    final resultComponents = <ScalarValue>[];
    for (var r = 0; r < matrix.rows; r++) {
      ScalarValue acc = IntegerValue.zero;
      for (var c = 0; c < matrix.columns; c++) {
        final prod = numericEngine
            .multiply(matrix.values[r][c], vector[c])
            .valueOrNull!;
        acc = numericEngine.add(acc, prod).valueOrNull!;
      }
      resultComponents.add(acc);
    }

    return MathSuccess(Vector(resultComponents));
  }

  static bool _isScalarZero(ScalarValue s) {
    if (s is IntegerValue) return s.isZero;
    if (s is FractionValue) return s.isZero;
    if (s is DecimalValue) return s.isZero;
    if (s is ComplexNumber) return s.isZero;
    return false;
  }
}
