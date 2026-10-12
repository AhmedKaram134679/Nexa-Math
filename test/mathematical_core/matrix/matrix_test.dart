import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('Matrix Model Invariants and Construction', () {
    test('Constructs 2x2 integer matrix from list of rows', () {
      final m = Matrix.fromRows([
        [IntegerValue.fromInt(1), IntegerValue.fromInt(2)],
        [IntegerValue.fromInt(3), IntegerValue.fromInt(4)],
      ]);

      expect(m.rowCount, equals(2));
      expect(m.columnCount, equals(2));
      expect(m.isSquare, isTrue);
      expect(m[0][0], equals(IntegerValue.fromInt(1)));
      expect(m[0][1], equals(IntegerValue.fromInt(2)));
      expect(m[1][0], equals(IntegerValue.fromInt(3)));
      expect(m[1][1], equals(IntegerValue.fromInt(4)));
    });

    test('Rejects empty row matrix construction', () {
      expect(() => Matrix.fromRows([]), throwsArgumentError);
    });

    test('Rejects ragged rows matrix construction', () {
      expect(
        () => Matrix.fromRows([
          [IntegerValue.fromInt(1), IntegerValue.fromInt(2)],
          [IntegerValue.fromInt(3)],
        ]),
        throwsArgumentError,
      );
    });

    test('Constructs fromFlat with dimensions matching', () {
      final m = Matrix.fromFlat(2, 3, [
        IntegerValue.fromInt(1),
        IntegerValue.fromInt(2),
        IntegerValue.fromInt(3),
        IntegerValue.fromInt(4),
        IntegerValue.fromInt(5),
        IntegerValue.fromInt(6),
      ]);
      expect(m.rowCount, equals(2));
      expect(m.columnCount, equals(3));
      expect(m.isSquare, isFalse);
      expect(m[1][2], equals(IntegerValue.fromInt(6)));
    });

    test('Rejects fromFlat with mismatched elements count', () {
      expect(
        () => Matrix.fromFlat(2, 2, [
          IntegerValue.fromInt(1),
          IntegerValue.fromInt(2),
        ]),
        throwsArgumentError,
      );
    });

    test('Identity and zero matrix factories', () {
      final id3 = Matrix.identity(3);
      expect(id3.rowCount, equals(3));
      expect(id3.columnCount, equals(3));
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          if (r == c) {
            expect(id3[r][c], equals(IntegerValue.one));
          } else {
            expect(id3[r][c], equals(IntegerValue.zero));
          }
        }
      }

      final zero2x4 = Matrix.zero(2, 4);
      expect(zero2x4.rowCount, equals(2));
      expect(zero2x4.columnCount, equals(4));
      expect(zero2x4.isZero, isTrue);
    });

    test('Diagonal matrix factory', () {
      final diag = Matrix.diagonal([
        IntegerValue.fromInt(2),
        IntegerValue.fromInt(5),
        IntegerValue.fromInt(-3),
      ]);
      expect(diag.rowCount, equals(3));
      expect(diag.columnCount, equals(3));
      expect(diag[0][0], equals(IntegerValue.fromInt(2)));
      expect(diag[1][1], equals(IntegerValue.fromInt(5)));
      expect(diag[2][2], equals(IntegerValue.fromInt(-3)));
      expect(diag[0][1], equals(IntegerValue.zero));
    });

    test('Immutability: row and column lists are unmodifiable', () {
      final m = Matrix.fromInts([
        [1, 2],
        [3, 4],
      ]);
      expect(() => m.values.add([]), throwsUnsupportedError);
      expect(() => m.values[0][0] = IntegerValue.zero, throwsUnsupportedError);
    });

    test('Immutability: mutating external source list does not affect existing Matrix', () {
      final sourceRow = [IntegerValue.fromInt(1), IntegerValue.fromInt(2)];
      final sourceRows = [
        sourceRow,
        [IntegerValue.fromInt(3), IntegerValue.fromInt(4)],
      ];
      final m = Matrix.fromRows(sourceRows);

      // Mutate outer list and inner list
      sourceRows.add([IntegerValue.fromInt(5), IntegerValue.fromInt(6)]);
      sourceRow[0] = IntegerValue.fromInt(99);

      expect(m.rowCount, equals(2));
      expect(m[0][0], equals(IntegerValue.fromInt(1)));
    });

    test('Structural equality between equivalent integer and fraction 1/1 representations in Sets and Maps', () {
      final mInt = Matrix.fromInts([
        [1, 2],
        [3, 4],
      ]);
      final mFrac = Matrix.fromRows([
        [FractionValue.fromInts(1, 1), FractionValue.fromInts(2, 1)],
        [FractionValue.fromInts(3, 1), FractionValue.fromInts(4, 1)],
      ]);
      expect(mInt, equals(mFrac));
      expect(mInt.hashCode, equals(mFrac.hashCode));

      final matrixSet = {mInt};
      expect(matrixSet.contains(mFrac), isTrue);

      final matrixMap = {mInt: 'value'};
      expect(matrixMap[mFrac], equals('value'));
    });

    test('LaTeX generation formats correct bmatrix', () {
      final m = Matrix.fromInts([
        [1, 2],
        [3, 4],
      ]);
      expect(
        m.toLaTeX(),
        equals('\\begin{bmatrix} 1 & 2 \\\\ 3 & 4 \\end{bmatrix}'),
      );
    });
  });
}
