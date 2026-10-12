import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Represents an immutable mathematical vector in $\mathbb{R}^n$ with exact scalar components.
///
/// Owned canonically by the Vector layer under `mathematical_core/vector/`.
final class Vector extends MathValue {
  /// Unmodifiable list of scalar components: `components[i]`.
  final List<ScalarValue> components;

  /// Private constructor enforcing immutable unmodifiable components list.
  const Vector._(this.components);

  /// Creates a vector from a list of scalar components.
  ///
  /// Enforces:
  /// 1. Dimension $> 0$.
  /// 2. Canonical scalar representations (converts integer fractions `n/1` to `IntegerValue`).
  /// 3. Deep immutability via `List.unmodifiable`.
  factory Vector(List<ScalarValue> elements) {
    if (elements.isEmpty) {
      throw ArgumentError('Vector dimension cannot be zero.');
    }
    final canonical = elements.map((c) {
      if (c is FractionValue && c.isInteger) {
        return IntegerValue(c.numerator);
      }
      return c;
    }).toList();

    return Vector._(List<ScalarValue>.unmodifiable(canonical));
  }

  /// Creates a vector from standard platform 64-bit integers.
  factory Vector.fromInts(List<int> ints) {
    return Vector(ints.map((n) => IntegerValue.fromInt(n)).toList());
  }

  /// Creates a zero vector of dimension [dimension].
  factory Vector.zero(int dimension) {
    if (dimension <= 0) {
      throw ArgumentError('Vector dimension must be positive ($dimension).');
    }
    return Vector._(
      List<ScalarValue>.unmodifiable(
        List<ScalarValue>.filled(dimension, IntegerValue.zero),
      ),
    );
  }

  /// Creates a standard basis vector $e_i$ in $\mathbb{R}^n$ where component at [index] is 1 and all others 0.
  factory Vector.basis(int dimension, int index) {
    if (dimension <= 0) {
      throw ArgumentError('Vector dimension must be positive ($dimension).');
    }
    if (index < 0 || index >= dimension) {
      throw RangeError(
        'Basis index $index out of bounds for dimension $dimension.',
      );
    }
    final list = List<ScalarValue>.filled(dimension, IntegerValue.zero);
    list[index] = IntegerValue.one;
    return Vector._(List<ScalarValue>.unmodifiable(list));
  }

  /// Dimension (number of components) of this vector.
  int get dimension => components.length;

  /// Returns component at 0-indexed [i].
  ScalarValue get(int i) {
    if (i < 0 || i >= components.length) {
      throw RangeError(
        'Component index $i out of bounds for vector of dimension $dimension.',
      );
    }
    return components[i];
  }

  /// Operator index access: `v[i]`.
  ScalarValue operator [](int i) => get(i);

  /// Whether this is the zero vector ($v = \mathbf{0}$).
  bool get isZero {
    for (final c in components) {
      if (!_isScalarZero(c)) return false;
    }
    return true;
  }

  /// Converts this vector to an $n \times 1$ column [Matrix].
  Matrix toColumnMatrix() {
    final rows = components.map((c) => [c]).toList();
    return Matrix.fromRows(rows);
  }

  /// Converts this vector to a $1 \times n$ row [Matrix].
  Matrix toRowMatrix() {
    return Matrix.fromRows([components]);
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
    if (other is! Vector) return false;
    if (dimension != other.dimension) return false;
    for (var i = 0; i < dimension; i++) {
      if (!_scalarEquals(components[i], other.components[i])) {
        return false;
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
  int get hashCode => Object.hash(dimension, Object.hashAll(components));

  @override
  String toString() => '[${components.join(', ')}]';

  /// Returns LaTeX representation: `\begin{bmatrix} v_1 \\ v_2 \\ \dots \end{bmatrix}`.
  String toLaTeX() {
    return r'\begin{bmatrix} ' + components.join(r' \\ ') + r' \end{bmatrix}';
  }
}
