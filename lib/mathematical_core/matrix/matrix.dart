import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Represents an immutable rectangular mathematical matrix with exact scalar elements.
///
/// Owned canonically by the Matrix layer under `mathematical_core/matrix/`.
final class Matrix extends MathValue {
  /// Number of rows.
  final int rows;

  /// Number of columns.
  final int columns;

  /// 2D row-major list of scalar elements: `values[row][col]`.
  final List<List<ScalarValue>> values;

  /// Private canonical constructor enforcing unmodifiable rows and columns.
  const Matrix._({
    required this.rows,
    required this.columns,
    required this.values,
  });

  /// Creates a matrix from a 2D list of rows.
  ///
  /// Enforces:
  /// 1. Non-empty matrix ($rows > 0$ and $columns > 0$).
  /// 2. Uniform row lengths.
  /// 3. Canonical scalar representation (converts integer fractions `n/1` to `IntegerValue`).
  /// 4. Deep immutability via `List.unmodifiable`.
  factory Matrix.fromRows(List<List<ScalarValue>> rowList) {
    if (rowList.isEmpty) {
      throw ArgumentError('Matrix cannot have zero rows.');
    }
    final rowCount = rowList.length;
    final colCount = rowList.first.length;
    if (colCount == 0) {
      throw ArgumentError('Matrix rows cannot be empty.');
    }

    final unmodifiableRows = List<List<ScalarValue>>.generate(rowCount, (r) {
      final row = rowList[r];
      if (row.length != colCount) {
        throw ArgumentError(
          'Row $r has length ${row.length}, expected uniform length $colCount.',
        );
      }
      return List<ScalarValue>.unmodifiable(
        row.map((val) {
          if (val is FractionValue && val.isInteger) {
            return IntegerValue(val.numerator);
          }
          return val;
        }),
      );
    });

    return Matrix._(
      rows: rowCount,
      columns: colCount,
      values: List<List<ScalarValue>>.unmodifiable(unmodifiableRows),
    );
  }

  /// Creates a matrix from a flat list in row-major order.
  factory Matrix.fromFlat(int rows, int cols, List<ScalarValue> elements) {
    if (rows <= 0 || cols <= 0) {
      throw ArgumentError(
        'Matrix dimensions must be positive ($rows x $cols).',
      );
    }
    if (elements.length != rows * cols) {
      throw ArgumentError(
        'Flat elements length ${elements.length} does not match dimensions $rows x $cols (${rows * cols}).',
      );
    }
    final rowsList = <List<ScalarValue>>[];
    for (var r = 0; r < rows; r++) {
      final start = r * cols;
      rowsList.add(elements.sublist(start, start + cols));
    }
    return Matrix.fromRows(rowsList);
  }

  /// Creates a zero matrix of size [rows] x [cols].
  factory Matrix.zero(int rows, int cols) {
    if (rows <= 0 || cols <= 0) {
      throw ArgumentError(
        'Matrix dimensions must be positive ($rows x $cols).',
      );
    }
    final zeroRow = List<ScalarValue>.filled(cols, IntegerValue.zero);
    final zeroRows = List<List<ScalarValue>>.filled(rows, zeroRow);
    return Matrix.fromRows(zeroRows);
  }

  /// Creates an identity matrix of size [size] x [size].
  factory Matrix.identity(int size) {
    if (size <= 0) {
      throw ArgumentError('Identity matrix size must be positive ($size).');
    }
    final rowsList = List<List<ScalarValue>>.generate(size, (r) {
      return List<ScalarValue>.generate(size, (c) {
        return r == c ? IntegerValue.one : IntegerValue.zero;
      });
    });
    return Matrix.fromRows(rowsList);
  }

  /// Creates a diagonal matrix with the specified elements along the main diagonal.
  factory Matrix.diagonal(List<ScalarValue> diag) {
    if (diag.isEmpty) {
      throw ArgumentError('Diagonal elements list cannot be empty.');
    }
    final size = diag.length;
    final rowsList = List<List<ScalarValue>>.generate(size, (r) {
      return List<ScalarValue>.generate(size, (c) {
        return r == c ? diag[r] : IntegerValue.zero;
      });
    });
    return Matrix.fromRows(rowsList);
  }

  /// Creates a scalar matrix of size [size] x [size] with [scalar] along the diagonal.
  factory Matrix.scalar(int size, ScalarValue scalar) {
    if (size <= 0) {
      throw ArgumentError('Scalar matrix size must be positive ($size).');
    }
    final rowsList = List<List<ScalarValue>>.generate(size, (r) {
      return List<ScalarValue>.generate(size, (c) {
        return r == c ? scalar : IntegerValue.zero;
      });
    });
    return Matrix.fromRows(rowsList);
  }

  /// Convenient aliases for dimensions
  int get rowCount => rows;
  int get columnCount => columns;

  /// Convenience factory creating an integer matrix from a 2D list of `int`s.
  factory Matrix.fromInts(List<List<int>> intRows) {
    return Matrix.fromRows(
      intRows.map((row) => row.map(IntegerValue.fromInt).toList()).toList(),
    );
  }

  /// Returns whether this is a square matrix (`rows == columns`).
  bool get isSquare => rows == columns;

  /// Returns whether all elements in the matrix are mathematically zero.
  bool get isZero {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        if (!_isScalarZero(values[r][c])) return false;
      }
    }
    return true;
  }

  /// Returns the shape tuple: `(rows, columns)`.
  (int, int) get shape => (rows, columns);

  /// Index operator accessing row [r] as a list of elements: `matrix[r][c]`.
  List<ScalarValue> operator [](int r) => values[r];

  /// Access element at [row] and [col] (0-indexed).
  ScalarValue get(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) {
      throw RangeError(
        'Index ($row, $col) out of bounds for matrix with shape $rows x $columns.',
      );
    }
    return values[row][col];
  }

  /// Access row [r] as an unmodifiable list of scalar values.
  List<ScalarValue> getRow(int r) {
    if (r < 0 || r >= rows) {
      throw RangeError(
        'Row index $r out of bounds for matrix with $rows rows.',
      );
    }
    return values[r];
  }

  /// Access column [c] as a list of scalar values.
  List<ScalarValue> getColumn(int c) {
    if (c < 0 || c >= columns) {
      throw RangeError(
        'Column index $c out of bounds for matrix with $columns columns.',
      );
    }
    return List<ScalarValue>.unmodifiable(
      List<ScalarValue>.generate(rows, (r) => values[r][c]),
    );
  }

  static bool _isScalarZero(ScalarValue s) {
    if (s is IntegerValue) return s.isZero;
    if (s is FractionValue) return s.isZero;
    if (s is DecimalValue) return s.isZero;
    if (s is ComplexNumber) return s.isZero;
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Matrix) return false;
    if (rows != other.rows || columns != other.columns) return false;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        if (!_scalarEquals(values[r][c], other.values[r][c])) {
          return false;
        }
      }
    }
    return true;
  }

  static bool _scalarEquals(ScalarValue a, ScalarValue b) {
    if (a == b) return true;
    if (a is IntegerValue && b is FractionValue) {
      return b.isInteger && b.numerator == a.value;
    }
    if (a is FractionValue && b is IntegerValue) {
      return a.isInteger && a.numerator == b.value;
    }
    if (a is IntegerValue && b is DecimalValue) {
      return b.scale == 0 && b.unscaledValue == a.value;
    }
    if (a is DecimalValue && b is IntegerValue) {
      return a.scale == 0 && a.unscaledValue == b.value;
    }
    if (a is FractionValue && b is DecimalValue) {
      return a == b.toFraction();
    }
    if (a is DecimalValue && b is FractionValue) {
      return a.toFraction() == b;
    }
    return false;
  }

  @override
  int get hashCode {
    var h = Object.hash(rows, columns);
    for (final row in values) {
      h = Object.hash(h, Object.hashAll(row));
    }
    return h;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('[\n');
    for (var r = 0; r < rows; r++) {
      sb.write('  [');
      sb.write(values[r].join(', '));
      sb.write(']');
      if (r < rows - 1) sb.write(',');
      sb.write('\n');
    }
    sb.write(']');
    return sb.toString();
  }

  /// Returns the LaTeX representation of this matrix: `\begin{bmatrix} ... \end{bmatrix}`.
  String toLaTeX() {
    final sb = StringBuffer(r'\begin{bmatrix} ');
    for (var r = 0; r < rows; r++) {
      sb.write(values[r].join(' & '));
      if (r < rows - 1) sb.write(r' \\ ');
    }
    sb.write(r' \end{bmatrix}');
    return sb.toString();
  }
}
