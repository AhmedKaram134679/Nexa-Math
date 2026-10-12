import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';

/// Authoritative result contract for all fallible mathematical computations in NexaMath.
///
/// Sealed hierarchy with [MathSuccess] and [MathFailure].
sealed class MathResult<T> {
  const MathResult();

  /// Whether the operation succeeded and yielded a value of type [T].
  bool get isSuccess => this is MathSuccess<T>;

  /// Whether the operation failed and contains a [MathError].
  bool get isFailure => this is MathFailure<T>;

  /// Returns the computed value if successful, or null if failure.
  T? get valueOrNull => switch (this) {
    MathSuccess<T>(:final value) => value,
    MathFailure<T>() => null,
  };

  /// Returns the error if failed, or null if success.
  MathError? get errorOrNull => switch (this) {
    MathSuccess<T>() => null,
    MathFailure<T>(:final error) => error,
  };

  /// Metadata describing exactness, approximation parameters, and warnings.
  CalculationMetadata get metadata => switch (this) {
    MathSuccess<T>(:final metadata) => metadata,
    MathFailure<T>(:final metadata) => metadata,
  };

  /// Transforms the result by applying [onSuccess] or [onFailure].
  R fold<R>({
    required R Function(T value, CalculationMetadata metadata) onSuccess,
    required R Function(MathError error, CalculationMetadata metadata)
    onFailure,
  }) {
    return switch (this) {
      MathSuccess<T>(:final value, :final metadata) => onSuccess(
        value,
        metadata,
      ),
      MathFailure<T>(:final error, :final metadata) => onFailure(
        error,
        metadata,
      ),
    };
  }

  /// Maps the successful value to another type [R] using [transform], preserving metadata.
  MathResult<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      MathSuccess<T>(:final value, :final metadata) => MathSuccess<R>(
        transform(value),
        metadata: metadata,
      ),
      MathFailure<T>(:final error, :final metadata) => MathFailure<R>(
        error,
        metadata: metadata,
      ),
    };
  }

  /// Chains another fallible operation returning a [MathResult<R>].
  MathResult<R> flatMap<R>(MathResult<R> Function(T value) transform) {
    return switch (this) {
      MathSuccess<T>(:final value) => transform(value),
      MathFailure<T>(:final error, :final metadata) => MathFailure<R>(
        error,
        metadata: metadata,
      ),
    };
  }
}

/// Represents a successful mathematical calculation yielding [value].
final class MathSuccess<T> extends MathResult<T> {
  final T value;

  @override
  final CalculationMetadata metadata;

  const MathSuccess(this.value, {this.metadata = const CalculationMetadata()});

  @override
  String toString() => 'MathSuccess($value, metadata: $metadata)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MathSuccess<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Represents a failed mathematical calculation containing [error].
final class MathFailure<T> extends MathResult<T> {
  final MathError error;

  @override
  final CalculationMetadata metadata;

  const MathFailure(this.error, {this.metadata = const CalculationMetadata()});

  @override
  String toString() => 'MathFailure($error, metadata: $metadata)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MathFailure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}
