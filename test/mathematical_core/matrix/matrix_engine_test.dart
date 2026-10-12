import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/matrix/default_matrix_engine.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  final engine = DefaultMatrixEngine();

  group('Matrix Operations: Addition & Subtraction', () {
    test('Exact integer matrix addition', () {
      final a = Matrix.fromInts([
        [1, 2],
        [3, 4],
      ]);
      final b = Matrix.fromInts([
        [5, 6],
        [7, 8],
      ]);
      final res = engine.add(a, b);
      expect(res.isSuccess, isTrue);
      expect(
        res.valueOrNull,
        equals(
          Matrix.fromInts([
            [6, 8],
            [10, 12],
          ]),
        ),
      );
      expect(res.metadata.isExact, isTrue);
    });

    test('Addition dimension mismatch returns MatrixDimensionError', () {
      final a = Matrix.fromInts([
        [1, 2],
      ]);
      final b = Matrix.fromInts([
        [1],
        [2],
      ]);
      final res = engine.add(a, b);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<MatrixDimensionError>());
    });

    test('Exact subtraction: A - A = Zero Matrix', () {
      final a = Matrix.fromInts([
        [7, 8],
        [9, 10],
      ]);
      final res = engine.subtract(a, a);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals(Matrix.zero(2, 2)));
    });
  });

  group('Matrix Operations: Multiplication', () {
    test('Exact integer matrix multiplication', () {
      // [1, 2] * [5, 6] = [1*5+2*7, 1*6+2*8] = [19, 22]
      // [3, 4]   [7, 8]   [3*5+4*7, 3*6+4*8] = [43, 50]
      final a = Matrix.fromInts([
        [1, 2],
        [3, 4],
      ]);
      final b = Matrix.fromInts([
        [5, 6],
        [7, 8],
      ]);
      final res = engine.multiply(a, b);
      expect(res.isSuccess, isTrue);
      expect(
        res.valueOrNull,
        equals(
          Matrix.fromInts([
            [19, 22],
            [43, 50],
          ]),
        ),
      );
    });

    test('Multiplication dimension mismatch returns MatrixDimensionError', () {
      final a = Matrix.fromInts([
        [1, 2],
        [3, 4],
      ]); // 2x2
      final b = Matrix.fromInts([
        [1, 2],
        [3, 4],
        [5, 6],
      ]); // 3x2
      final res = engine.multiply(a, b);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<MatrixDimensionError>());
    });

    test(
      'Identity matrix multiplication property: A * I = A and I * A = A',
      () {
        final a = Matrix.fromInts([
          [2, -1],
          [0, 4],
        ]);
        final id = Matrix.identity(2);
        expect(engine.multiply(a, id).valueOrNull, equals(a));
        expect(engine.multiply(id, a).valueOrNull, equals(a));
      },
    );

    test('Scalar multiplication', () {
      final a = Matrix.fromInts([
        [1, -2],
        [3, 4],
      ]);
      final res = engine.scalarMultiply(a, IntegerValue.fromInt(3));
      expect(res.isSuccess, isTrue);
      expect(
        res.valueOrNull,
        equals(
          Matrix.fromInts([
            [3, -6],
            [9, 12],
          ]),
        ),
      );
    });
  });

  group('Matrix Operations: Transpose and Trace', () {
    test('Transpose of rectangular matrix (2x3 -> 3x2)', () {
      final a = Matrix.fromInts([
        [1, 2, 3],
        [4, 5, 6],
      ]);
      final atRes = engine.transpose(a);
      expect(atRes.isSuccess, isTrue);
      final at = atRes.valueOrNull!;
      expect(at.rowCount, equals(3));
      expect(at.columnCount, equals(2));
      expect(
        at,
        equals(
          Matrix.fromInts([
            [1, 4],
            [2, 5],
            [3, 6],
          ]),
        ),
      );
      // Double transpose identity: (A^T)^T = A
      expect(engine.transpose(at).valueOrNull, equals(a));
    });

    test('Trace of square matrix', () {
      final a = Matrix.fromInts([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ]);
      final tr = engine.trace(a);
      expect(tr.isSuccess, isTrue);
      expect(tr.valueOrNull, equals(IntegerValue.fromInt(15))); // 1 + 5 + 9
    });

    test('Trace of non-square matrix fails with MatrixDimensionError', () {
      final a = Matrix.fromInts([
        [1, 2, 3],
        [4, 5, 6],
      ]);
      final tr = engine.trace(a);
      expect(tr.isFailure, isTrue);
      expect(tr.errorOrNull, isA<MatrixDimensionError>());
    });
  });

  group('Matrix Operations: Exact Determinant', () {
    test('1x1 determinant', () {
      final m = Matrix.fromInts([
        [7],
      ]);
      final det = engine.determinant(m);
      expect(det.isSuccess, isTrue);
      expect(det.valueOrNull, equals(IntegerValue.fromInt(7)));
    });

    test('2x2 determinant', () {
      final m = Matrix.fromInts([
        [3, 8],
        [4, 6],
      ]);
      // 3*6 - 8*4 = 18 - 32 = -14
      final det = engine.determinant(m);
      expect(det.isSuccess, isTrue);
      expect(det.valueOrNull, equals(IntegerValue.fromInt(-14)));
    });

    test('3x3 determinant', () {
      final m = Matrix.fromInts([
        [6, 1, 1],
        [4, -2, 5],
        [2, 8, 7],
      ]);
      // 6(-14-40) - 1(28-10) + 1(32 - (-4)) = 6(-54) - 18 + 36 = -324 - 18 + 36 = -306
      final det = engine.determinant(m);
      expect(det.isSuccess, isTrue);
      expect(det.valueOrNull, equals(IntegerValue.fromInt(-306)));
    });

    test('4x4 determinant via exact fraction Gaussian elimination', () {
      final m = Matrix.fromInts([
        [1, 0, 2, -1],
        [3, 0, 0, 5],
        [2, 1, 4, -3],
        [1, 0, 5, 0],
      ]);
      final det = engine.determinant(m);
      expect(det.isSuccess, isTrue);
      // Expanding along column 2: 1 * (-1)^(3+2) * det([[1,2,-1],[3,0,5],[1,5,0]])
      // = -1 * (1*(0-25) - 2*(0-5) - 1*(15-0)) = -1 * (-25 + 10 - 15) = -1 * (-30) = 30
      expect(det.valueOrNull, equals(IntegerValue.fromInt(30)));
    });

    test('Singular matrix has determinant 0', () {
      final m = Matrix.fromInts([
        [1, 2],
        [2, 4],
      ]);
      final det = engine.determinant(m);
      expect(det.isSuccess, isTrue);
      expect(det.valueOrNull, equals(IntegerValue.zero));
    });

    test('Determinant identity: det(I) = 1', () {
      final id4 = Matrix.identity(4);
      final det = engine.determinant(id4);
      expect(det.isSuccess, isTrue);
      expect(det.valueOrNull, equals(IntegerValue.one));
    });

    test('Determinant multiplicativity: det(A * B) = det(A) * det(B)', () {
      final a = Matrix.fromInts([
        [2, 3],
        [1, 4],
      ]); // det = 8 - 3 = 5
      final b = Matrix.fromInts([
        [5, -2],
        [3, 1],
      ]); // det = 5 - (-6) = 11
      final ab = engine.multiply(a, b).valueOrNull!;
      final detAB = engine.determinant(ab).valueOrNull!; // det = 55
      final detA = engine.determinant(a).valueOrNull!;
      final detB = engine.determinant(b).valueOrNull!;
      final detProd = engine.numericEngine.multiply(detA, detB).valueOrNull!;
      expect(detAB, equals(detProd));
      expect(detAB, equals(IntegerValue.fromInt(55)));
    });
  });

  group('Matrix Operations: Inverse, Rank, and Powers', () {
    test('Exact inverse of 2x2 matrix', () {
      final m = Matrix.fromInts([
        [4, 7],
        [2, 6],
      ]);
      // det = 24 - 14 = 10
      // inv = 1/10 * [6, -7; -2, 4] = [3/5, -7/10; -1/5, 2/5]
      final invRes = engine.inverse(m);
      expect(invRes.isSuccess, isTrue);
      final inv = invRes.valueOrNull!;

      expect(inv[0][0], equals(FractionValue.fromInts(3, 5)));
      expect(inv[0][1], equals(FractionValue.fromInts(-7, 10)));
      expect(inv[1][0], equals(FractionValue.fromInts(-1, 5)));
      expect(inv[1][1], equals(FractionValue.fromInts(2, 5)));

      // M * M^-1 = I and M^-1 * M = I
      final prod1 = engine.multiply(m, inv).valueOrNull!;
      expect(prod1, equals(Matrix.identity(2)));
      final prod2 = engine.multiply(inv, m).valueOrNull!;
      expect(prod2, equals(Matrix.identity(2)));
    });

    test('Exact inverse of 3x3 matrix requiring row swap (zero pivot)', () {
      final m = Matrix.fromInts([
        [0, 1, 2],
        [1, 0, 3],
        [4, -3, 8],
      ]);
      final invRes = engine.inverse(m);
      expect(invRes.isSuccess, isTrue);
      final inv = invRes.valueOrNull!;

      // Verify A * inv(A) = I and inv(A) * A = I
      final prod1 = engine.multiply(m, inv).valueOrNull!;
      expect(prod1, equals(Matrix.identity(3)));
      final prod2 = engine.multiply(inv, m).valueOrNull!;
      expect(prod2, equals(Matrix.identity(3)));
    });

    test('Singular matrix inverse fails with SingularMatrixError', () {
      final m = Matrix.fromInts([
        [1, 2],
        [2, 4],
      ]);
      final invRes = engine.inverse(m);
      expect(invRes.isFailure, isTrue);
      expect(invRes.errorOrNull, isA<SingularMatrixError>());
    });

    test('Matrix rank computation', () {
      final fullRank = Matrix.fromInts([
        [1, 2, 3],
        [0, 1, 4],
        [5, 6, 0],
      ]);
      expect(engine.rank(fullRank).valueOrNull, equals(3));

      final rankDeficient = Matrix.fromInts([
        [1, 2, 3],
        [2, 4, 6],
        [1, 1, 1],
      ]);
      expect(engine.rank(rankDeficient).valueOrNull, equals(2));

      final zeroMat = Matrix.zero(3, 3);
      expect(engine.rank(zeroMat).valueOrNull, equals(0));
    });

    test('Matrix power A^0 = I, A^1 = A, A^3 = A*A*A', () {
      final a = Matrix.fromInts([
        [1, 1],
        [1, 0],
      ]);
      // A^0
      expect(engine.power(a, 0).valueOrNull, equals(Matrix.identity(2)));
      // A^1
      expect(engine.power(a, 1).valueOrNull, equals(a));
      // Fibonacci powers: A^2 = [[2,1],[1,1]], A^3 = [[3,2],[2,1]], A^4 = [[5,3],[3,2]]
      final a4 = engine.power(a, 4).valueOrNull!;
      expect(
        a4,
        equals(
          Matrix.fromInts([
            [5, 3],
            [3, 2],
          ]),
        ),
      );
    });

    test('Matrix negative power A^-1 computes inverse', () {
      final a = Matrix.fromInts([
        [2, 0],
        [0, 4],
      ]);
      final invRes = engine.power(a, -1);
      expect(invRes.isSuccess, isTrue);
      expect(
        invRes.valueOrNull,
        equals(
          Matrix.fromRows([
            [FractionValue.fromInts(1, 2), IntegerValue.zero],
            [IntegerValue.zero, FractionValue.fromInts(1, 4)],
          ]),
        ),
      );
    });

    test('Matrix negative power A^-2 computes (A^-1)^2', () {
      final a = Matrix.fromInts([
        [2, 0],
        [0, 4],
      ]);
      final inv2Res = engine.power(a, -2);
      expect(inv2Res.isSuccess, isTrue);
      expect(
        inv2Res.valueOrNull,
        equals(
          Matrix.fromRows([
            [FractionValue.fromInts(1, 4), IntegerValue.zero],
            [IntegerValue.zero, FractionValue.fromInts(1, 16)],
          ]),
        ),
      );
    });

    test(
      'Matrix negative power of singular matrix fails with SingularMatrixError',
      () {
        final sing = Matrix.fromInts([
          [1, 2],
          [2, 4],
        ]);
        final res = engine.power(sing, -1);
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<SingularMatrixError>());
      },
    );

    test('Matrix non-square power fails with MatrixDimensionError', () {
      final rect = Matrix.fromInts([
        [1, 2, 3],
        [4, 5, 6],
      ]);
      final res = engine.power(rect, 2);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<MatrixDimensionError>());
    });
  });
}
