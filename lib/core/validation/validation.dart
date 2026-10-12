import 'package:nexa_math/core/errors/nexa_math_error.dart';

/// Specialized error indicating failure to pass a validation rule.
final class ValidationError implements NexaMathError {
  final String property;

  @override
  final String technicalMessage;

  @override
  final String code;

  const ValidationError({
    required this.property,
    required this.technicalMessage,
    this.code = 'VALIDATION_ERROR',
  });

  @override
  String toString() =>
      'ValidationError(property: $property, code: $code, message: $technicalMessage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationError &&
          runtimeType == other.runtimeType &&
          property == other.property &&
          code == other.code;

  @override
  int get hashCode => Object.hash(property, code);
}

/// Strongly typed result of validating an entity or input parameter.
sealed class ValidationResult {
  const ValidationResult();

  bool get isValid => this is ValidationValid;
  bool get isInvalid => this is ValidationInvalid;

  static const ValidationResult valid = ValidationValid();

  factory ValidationResult.invalid(List<ValidationError> errors) =
      ValidationInvalid;
}

final class ValidationValid extends ValidationResult {
  const ValidationValid();

  @override
  String toString() => 'ValidationValid()';
}

final class ValidationInvalid extends ValidationResult {
  final List<ValidationError> errors;

  const ValidationInvalid(this.errors);

  @override
  String toString() => 'ValidationInvalid(errors: $errors)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationInvalid &&
          runtimeType == other.runtimeType &&
          errors.length == other.errors.length;

  @override
  int get hashCode => errors.hashCode;
}

/// Generic validation contract for validating items of type [T].
abstract interface class Validator<T> {
  ValidationResult validate(T item);
}
