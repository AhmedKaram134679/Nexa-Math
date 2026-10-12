import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/statistics/models/dataset.dart';

/// Immutable container representing a paired collection of bivariate coordinate observations $(x_i, y_i)$.
///
/// Invariant: $|X| = |Y| = N$. If lengths mismatch, construction fails with [DimensionMismatchError].
/// Duplicate coordinates are completely valid bivariate observations.
final class PairedDataset {
  final Dataset _x;
  final Dataset _y;

  /// Private constructor storing validated coordinate datasets.
  const PairedDataset._(this._x, this._y);

  /// Canonical factory constructor validating that [x] and [y] have identical lengths.
  ///
  /// Throws [ArgumentError] if lengths mismatch. For safe validation returning [MathResult],
  /// use [PairedDataset.fromResult] or [PairedDataset.create].
  factory PairedDataset(Dataset x, Dataset y) {
    if (x.length != y.length) {
      throw ArgumentError(
        'Dimension mismatch: x.length (${x.length}) must equal y.length (${y.length}).',
      );
    }
    return PairedDataset._(x, y);
  }

  /// Safe factory creating a [PairedDataset] returning [MathResult].
  ///
  /// Returns [MathFailure] with [DimensionMismatchError] if lengths mismatch.
  static MathResult<PairedDataset> create(Dataset x, Dataset y) {
    if (x.length != y.length) {
      return MathFailure(
        DimensionMismatchError(
          expectedDimension: '${x.length}',
          actualDimension: '${y.length}',
          message:
              'PairedDataset requires identical coordinate lengths: x has ${x.length}, y has ${y.length}.',
        ),
      );
    }
    return MathSuccess(PairedDataset._(x, y));
  }

  /// Factory creating [PairedDataset] from raw coordinate lists.
  static MathResult<PairedDataset> fromIterables(
    Iterable<ScalarValue> x,
    Iterable<ScalarValue> y,
  ) {
    final dsX = Dataset(x);
    final dsY = Dataset(y);
    return create(dsX, dsY);
  }

  /// Convenient factory creating [PairedDataset] from platform double pairs.
  static MathResult<PairedDataset> fromDoubles(
    Iterable<double> x,
    Iterable<double> y,
  ) {
    final dsX = Dataset.fromDoubles(x);
    final dsY = Dataset.fromDoubles(y);
    return create(dsX, dsY);
  }

  /// The independent predictor dataset $X$.
  Dataset get x => _x;

  /// The dependent response dataset $Y$.
  Dataset get y => _y;

  /// Number of paired coordinate observations $N = |X| = |Y|$.
  int get length => _x.length;

  /// Whether the paired dataset contains zero observations.
  bool get isEmpty => _x.isEmpty;

  /// Whether the paired dataset contains at least one observation.
  bool get isNotEmpty => _x.isNotEmpty;

  /// Whether both $X$ and $Y$ datasets consist entirely of exact representations.
  bool get isExact => _x.isExact && _y.isExact;

  /// Returns the paired coordinate at the given zero-based [index].
  (ScalarValue, ScalarValue) operator [](int index) => (_x[index], _y[index]);

  /// Validates that the paired dataset contains at least [minPairs] observations.
  MathFailure<T>? validateMinPairs<T>(int minPairs, {String? operation}) {
    if (length < minPairs) {
      final opMsg = operation != null ? ' for $operation' : '';
      return MathFailure<T>(
        InvalidArgumentError(
          argumentName: 'dataset',
          reason:
              'PairedDataset must contain at least $minPairs observation pair${minPairs == 1 ? '' : 's'}$opMsg.',
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
    if (other is! PairedDataset || runtimeType != other.runtimeType) {
      return false;
    }
    return _x == other._x && _y == other._y;
  }

  @override
  int get hashCode => Object.hash(_x, _y);

  @override
  String toString() => 'PairedDataset(x: $_x, y: $_y)';
}
