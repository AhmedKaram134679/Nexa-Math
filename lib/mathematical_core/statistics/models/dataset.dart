import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Immutable container representing a univariate collection of mathematical scalar observations.
///
/// Encapsulates observations $\mathcal{D} = (x_1, x_2, \dots, x_N)$, supporting arbitrary-precision
/// [IntegerValue], [FractionValue], and [DecimalValue].
///
/// Immutability is strictly maintained via defensive copies. Insertion order is preserved.
final class Dataset {
  final List<ScalarValue> _values;

  /// Creates an immutable [Dataset] from an existing iterable of [ScalarValue]s.
  ///
  /// A defensive copy of [values] is stored. Empty datasets ($N = 0$) are permitted as valid
  /// data containers, but individual statistical operations may require $N \ge 1$ or $N \ge 2$.
  Dataset(Iterable<ScalarValue> values)
    : _values = List<ScalarValue>.unmodifiable(values);

  /// Empty dataset factory constant.
  static final Dataset empty = Dataset(const []);

  /// Convenient factory creating a [Dataset] from platform 64-bit integer values.
  factory Dataset.fromInts(Iterable<int> values) =>
      Dataset(values.map((v) => IntegerValue.fromInt(v)));

  /// Convenient factory creating a [Dataset] from platform 64-bit double values.
  factory Dataset.fromDoubles(Iterable<double> values) => Dataset(
    values.map((v) => DecimalValue.parse(v.toString(), isExact: false)),
  );

  /// Number of observations $N = |\mathcal{D}|$.
  int get length => _values.length;

  /// Whether the dataset contains zero observations.
  bool get isEmpty => _values.isEmpty;

  /// Whether the dataset contains at least one observation.
  bool get isNotEmpty => _values.isNotEmpty;

  /// Immutable view of the underlying scalar observations.
  List<ScalarValue> get values => _values;

  /// Observation at the specified zero-based [index].
  ScalarValue operator [](int index) => _values[index];

  /// Whether all observations in this dataset are mathematically exact representations.
  bool get isExact {
    for (final v in _values) {
      if (v is IntegerValue) continue;
      if (v is FractionValue) continue;
      if (v is DecimalValue && v.isExact) continue;
      return false;
    }
    return true;
  }

  /// Converts all elements to platform 64-bit double floating-point numbers.
  List<double> toDoubles() {
    return _values
        .map((v) {
          if (v is IntegerValue) {
            return v.value.toDouble();
          }
          if (v is FractionValue) {
            return v.numerator.toDouble() / v.denominator.toDouble();
          }
          if (v is DecimalValue) {
            return v.toDouble();
          }
          throw UnsupportedError(
            'Unsupported ScalarValue type: ${v.runtimeType}',
          );
        })
        .toList(growable: false);
  }

  /// Validates that the dataset contains at least [minElements] observations.
  ///
  /// Returns [MathFailure] with [InvalidArgumentError] if validation fails, or null if valid.
  MathFailure<T>? validateMinElements<T>(int minElements, {String? operation}) {
    if (_values.length < minElements) {
      final opMsg = operation != null ? ' for $operation' : '';
      return MathFailure<T>(
        InvalidArgumentError(
          argumentName: 'dataset',
          reason:
              'Dataset must contain at least $minElements observation${minElements == 1 ? '' : 's'}$opMsg.',
        ),
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Dataset || runtimeType != other.runtimeType) {
      return false;
    }
    if (_values.length != other._values.length) {
      return false;
    }
    for (var i = 0; i < _values.length; i++) {
      if (_values[i] != other._values[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_values);

  @override
  String toString() => 'Dataset($_values)';
}
