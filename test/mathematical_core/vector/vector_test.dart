import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/vector/vector.dart';

void main() {
  group('Vector Model Invariants and Construction', () {
    test('Constructs vector with given components', () {
      final v = Vector([
        IntegerValue.fromInt(1),
        IntegerValue.fromInt(2),
        IntegerValue.fromInt(3),
      ]);
      expect(v.dimension, equals(3));
      expect(v[0], equals(IntegerValue.fromInt(1)));
      expect(v[1], equals(IntegerValue.fromInt(2)));
      expect(v[2], equals(IntegerValue.fromInt(3)));
      expect(v.isZero, isFalse);
    });

    test('Rejects empty vector construction', () {
      expect(() => Vector([]), throwsArgumentError);
    });

    test('Constructs fromInts helper', () {
      final v = Vector.fromInts([4, -5, 6]);
      expect(v.dimension, equals(3));
      expect(v[1], equals(IntegerValue.fromInt(-5)));
    });

    test('Zero vector factory', () {
      final z = Vector.zero(4);
      expect(z.dimension, equals(4));
      expect(z.isZero, isTrue);
      for (var i = 0; i < 4; i++) {
        expect(z[i], equals(IntegerValue.zero));
      }
    });

    test('Standard basis vector factory', () {
      final e2 = Vector.basis(3, 1);
      expect(e2.dimension, equals(3));
      expect(e2[0], equals(IntegerValue.zero));
      expect(e2[1], equals(IntegerValue.one));
      expect(e2[2], equals(IntegerValue.zero));
    });

    test('Rejects out-of-range index in basis vector', () {
      expect(() => Vector.basis(3, 3), throwsRangeError);
      expect(() => Vector.basis(3, -1), throwsRangeError);
    });

    test('Immutability: components list cannot be mutated', () {
      final v = Vector.fromInts([1, 2]);
      expect(() => v.components[0] = IntegerValue.zero, throwsUnsupportedError);
    });

    test('Immutability: mutating external source list does not affect existing Vector', () {
      final source = [IntegerValue.fromInt(1), IntegerValue.fromInt(2)];
      final v = Vector(source);
      source.add(IntegerValue.fromInt(3));
      source[0] = IntegerValue.fromInt(99);

      expect(v.dimension, equals(2));
      expect(v[0], equals(IntegerValue.fromInt(1)));
    });

    test('Converts to column and row matrices correctly', () {
      final v = Vector.fromInts([1, 2, 3]);
      final col = v.toColumnMatrix();
      expect(col.rowCount, equals(3));
      expect(col.columnCount, equals(1));
      expect(col[0][0], equals(IntegerValue.fromInt(1)));
      expect(col[1][0], equals(IntegerValue.fromInt(2)));
      expect(col[2][0], equals(IntegerValue.fromInt(3)));

      final row = v.toRowMatrix();
      expect(row.rowCount, equals(1));
      expect(row.columnCount, equals(3));
      expect(row[0][0], equals(IntegerValue.fromInt(1)));
      expect(row[0][1], equals(IntegerValue.fromInt(2)));
      expect(row[0][2], equals(IntegerValue.fromInt(3)));
    });

    test('Structural equality between integer and fraction representations in Sets and Maps', () {
      final vInt = Vector.fromInts([1, 2]);
      final vFrac = Vector([
        FractionValue.fromInts(1, 1),
        FractionValue.fromInts(2, 1),
      ]);
      expect(vInt, equals(vFrac));
      expect(vInt.hashCode, equals(vFrac.hashCode));

      final vectorSet = {vInt};
      expect(vectorSet.contains(vFrac), isTrue);

      final vectorMap = {vInt: 'item'};
      expect(vectorMap[vFrac], equals('item'));
    });

    test('LaTeX generation formats correct column bmatrix', () {
      final v = Vector.fromInts([1, 2, 3]);
      expect(
        v.toLaTeX(),
        equals('\\begin{bmatrix} 1 \\\\ 2 \\\\ 3 \\end{bmatrix}'),
      );
    });
  });
}
