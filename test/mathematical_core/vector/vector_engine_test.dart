import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/vector/default_vector_engine.dart';
import 'package:nexa_math/mathematical_core/vector/vector.dart';

void main() {
  final engine = DefaultVectorEngine();

  group('Vector Operations: Addition and Subtraction', () {
    test('Exact integer vector addition', () {
      final u = Vector.fromInts([1, 2, 3]);
      final v = Vector.fromInts([4, 5, 6]);
      final res = engine.add(u, v);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(Vector.fromInts([5, 7, 9])));
      expect(res.metadata.isExact, isTrue);
    });

    test('Addition dimension mismatch fails with DimensionMismatchError', () {
      final u = Vector.fromInts([1, 2]);
      final v = Vector.fromInts([1, 2, 3]);
      final res = engine.add(u, v);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<DimensionMismatchError>());
    });

    test('Vector subtraction identity u - u = 0', () {
      final u = Vector.fromInts([5, -2, 10]);
      final res = engine.subtract(u, u);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(Vector.zero(3)));
    });
  });

  group('Vector Operations: Scalar Scaling', () {
    test('Scalar multiplication', () {
      final v = Vector.fromInts([2, -3, 4]);
      final res = engine.scalarMultiply(v, IntegerValue.fromInt(3));
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(Vector.fromInts([6, -9, 12])));
    });

    test('Scalar division exact by integer producing fractions', () {
      final v = Vector.fromInts([1, 2]);
      final res = engine.scalarDivide(v, IntegerValue.fromInt(2));
      expect(res.isSuccess, isTrue);
      expect(
        res.valueOrNull,
        equals(
          Vector([
            FractionValue.fromInts(1, 2),
            IntegerValue.one, // 2/2 canonicalized to 1
          ]),
        ),
      );
    });

    test('Scalar division by zero fails with DivisionByZeroError', () {
      final v = Vector.fromInts([1, 2]);
      final res = engine.scalarDivide(v, IntegerValue.zero);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<DivisionByZeroError>());
    });
  });

  group('Vector Operations: Dot and Cross Products', () {
    test('Exact dot product of integer vectors', () {
      final u = Vector.fromInts([1, 3, -5]);
      final v = Vector.fromInts([4, -2, -1]);
      // 1*4 + 3*(-2) + (-5)*(-1) = 4 - 6 + 5 = 3
      final res = engine.dot(u, v);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(IntegerValue.fromInt(3)));
    });

    test('Dot product orthogonal vectors is zero', () {
      final u = Vector.fromInts([1, 0]);
      final v = Vector.fromInts([0, 1]);
      final res = engine.dot(u, v);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(IntegerValue.zero));
    });

    test('Cross product of 3D standard basis vectors (i x j = k, j x k = i, k x i = j)', () {
      final i = Vector.fromInts([1, 0, 0]);
      final j = Vector.fromInts([0, 1, 0]);
      final k = Vector.fromInts([0, 0, 1]);

      expect(engine.cross(i, j).valueOrNull, equals(k));
      expect(engine.cross(j, k).valueOrNull, equals(i));
      expect(engine.cross(k, i).valueOrNull, equals(j));
      // Anti-commutativity: j x i = -k
      expect(
        engine.cross(j, i).valueOrNull,
        equals(Vector.fromInts([0, 0, -1])),
      );
    });

    test('Dot product commutativity: u · v = v · u', () {
      final u = Vector.fromInts([2, -7, 4]);
      final v = Vector.fromInts([5, 3, -1]);
      final uv = engine.dot(u, v).valueOrNull!;
      final vu = engine.dot(v, u).valueOrNull!;
      expect(uv, equals(vu));
    });

    test('Cross product self-annihilation: u × u = 0', () {
      final u = Vector.fromInts([3, -5, 7]);
      final res = engine.cross(u, u);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(Vector.zero(3)));
    });

    test('Cross product non-3D vectors fails with DimensionMismatchError', () {
      final u = Vector.fromInts([1, 2]);
      final v = Vector.fromInts([3, 4]);
      final res = engine.cross(u, v);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<DimensionMismatchError>());
    });
  });

  group('Vector Operations: Magnitude, Normalization, Angle & Projection', () {
    test('Exact squared magnitude', () {
      final v = Vector.fromInts([3, 4]);
      final res = engine.magnitudeSquared(v);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(IntegerValue.fromInt(25)));
    });

    test('Magnitude of [3, 4] is 5', () {
      final v = Vector.fromInts([3, 4]);
      final res = engine.magnitude(v);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(DecimalValue.fromInt(5)));
    });

    test('Normalize vector [0, 4] gives [0, 1]', () {
      final v = Vector.fromInts([0, 4]);
      final res = engine.normalize(v);
      expect(res.isSuccess, isTrue);
      expect(
        res.valueOrNull,
        equals(Vector([DecimalValue.fromInt(0), DecimalValue.fromInt(1)])),
      );
    });

    test('Normalize zero vector fails with DomainError', () {
      final z = Vector.zero(3);
      final res = engine.normalize(z);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<DomainError>());
    });

    test('Angle between orthogonal vectors is pi/2', () {
      final u = Vector.fromInts([1, 0]);
      final v = Vector.fromInts([0, 1]);
      final res = engine.angle(u, v);
      expect(res.isSuccess, isTrue);
      final angleVal = res.valueOrNull!.toDouble();
      expect(angleVal, closeTo(math.pi / 2, 1e-10));
    });

    test(
      'Angle between zero and non-zero vectors is rejected with DomainError',
      () {
        final z = Vector.zero(2);
        final v = Vector.fromInts([1, 0]);
        expect(engine.angle(z, v).isFailure, isTrue);
        expect(engine.angle(z, v).errorOrNull, isA<DomainError>());
        expect(engine.angle(v, z).isFailure, isTrue);
        expect(engine.angle(v, z).errorOrNull, isA<DomainError>());
        expect(engine.angle(z, z).isFailure, isTrue);
        expect(engine.angle(z, z).errorOrNull, isA<DomainError>());
      },
    );

    test('Vector projection of u onto v: proj_v(u) = ((u.v)/(v.v)) * v', () {
      final u = Vector.fromInts([3, 4]);
      final v = Vector.fromInts([1, 0]); // onto x-axis
      final proj = engine.projection(u, v);
      expect(proj.isSuccess, isTrue);
      // dot(u,v) = 3, dot(v,v) = 1 => 3 * [1, 0] = [3, 0]
      expect(proj.valueOrNull, equals(Vector.fromInts([3, 0])));
    });

    test('Vector projection onto zero vector fails with DomainError', () {
      final u = Vector.fromInts([3, 4]);
      final z = Vector.zero(2);
      final proj = engine.projection(u, z);
      expect(proj.isFailure, isTrue);
      expect(proj.errorOrNull, isA<DomainError>());
    });
  });

  group('Vector Operations: Matrix-Vector Product', () {
    test('Multiplies 2x2 matrix by 2D column vector', () {
      // [1, 2] * [3] = [1*3 + 2*4] = [11]
      // [0, 5]   [4]   [0*3 + 5*4]   [20]
      final m = Matrix.fromInts([
        [1, 2],
        [0, 5],
      ]);
      final v = Vector.fromInts([3, 4]);
      final res = engine.multiplyMatrixVector(m, v);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(Vector.fromInts([11, 20])));
    });

    test('Dimension mismatch on matrix-vector product fails with MatrixDimensionError', () {
      final m = Matrix.fromInts([
        [1, 2, 3],
      ]);
      final v = Vector.fromInts([1, 2]);
      final res = engine.multiplyMatrixVector(m, v);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<MatrixDimensionError>());
    });
  });
}
