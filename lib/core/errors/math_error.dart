import 'package:nexa_math/core/errors/nexa_math_error.dart';

/// Authoritative root for all mathematical failures in NexaMath.
///
/// Every mathematical engine reports failures using strongly typed subtypes of [MathError].
/// Errors are immutable, machine-readable, and independent of presentation concerns.
sealed class MathError implements NexaMathError {
  /// Technical description of the mathematical failure.
  final String message;

  /// Unique machine-readable error code.
  @override
  final String code;

  const MathError({required this.message, required this.code});

  @override
  String get technicalMessage => message;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// Attempted division by zero in scalar or numerical operations.
final class DivisionByZeroError extends MathError {
  const DivisionByZeroError({
    super.message = 'Division by zero is undefined.',
    super.code = 'DIVISION_BY_ZERO',
  });
}

/// Operation evaluated outside the mathematical domain of the function or operator.
final class DomainError extends MathError {
  final String? functionName;
  final String? argument;

  const DomainError({
    super.message = 'Value is outside the valid mathematical domain.',
    super.code = 'DOMAIN_ERROR',
    this.functionName,
    this.argument,
  });
}

/// Numerical calculation exceeded the maximum representable finite magnitude.
final class OverflowError extends MathError {
  const OverflowError({
    super.message =
        'Numerical result exceeded maximum representable finite bound.',
    super.code = 'OVERFLOW',
  });
}

/// Numerical calculation underflowed below the minimum representable non-zero bound.
final class UnderflowError extends MathError {
  const UnderflowError({
    super.message =
        'Numerical result underflowed below minimum representable bound.',
    super.code = 'UNDERFLOW',
  });
}

/// Expression is structurally or syntactically invalid for calculation.
final class InvalidExpressionError extends MathError {
  final int? position;

  const InvalidExpressionError({
    super.message = 'Invalid expression structure.',
    super.code = 'INVALID_EXPRESSION',
    this.position,
  });
}

/// Expression parsing failed due to grammar or token syntax violation.
final class SyntaxError extends MathError {
  final int? position;
  final String? token;

  const SyntaxError({
    super.message = 'Syntax error in mathematical expression.',
    super.code = 'SYNTAX_ERROR',
    this.position,
    this.token,
  });
}

/// Unknown variable, constant, or identifier encountered during evaluation.
final class UnknownIdentifierError extends MathError {
  final String identifier;

  const UnknownIdentifierError({
    required this.identifier,
    super.message = 'Unknown identifier referenced.',
    super.code = 'UNKNOWN_IDENTIFIER',
  });
}

/// Unknown or unregistered function called in expression.
final class UnknownFunctionError extends MathError {
  final String functionName;

  const UnknownFunctionError({
    required this.functionName,
    super.message = 'Unknown function referenced.',
    super.code = 'UNKNOWN_FUNCTION',
  });
}

/// Invalid argument count or invalid argument type passed to an operation or function.
final class InvalidArgumentError extends MathError {
  final String argumentName;
  final String? reason;

  const InvalidArgumentError({
    required this.argumentName,
    this.reason,
    super.message = 'Invalid argument provided.',
    super.code = 'INVALID_ARGUMENT',
  });
}

/// Incompatible dimensional quantities or unit mismatch.
final class DimensionMismatchError extends MathError {
  final String? expectedDimension;
  final String? actualDimension;

  const DimensionMismatchError({
    super.message =
        'Dimension or unit mismatch in physical quantity calculation.',
    super.code = 'DIMENSION_MISMATCH',
    this.expectedDimension,
    this.actualDimension,
  });
}

/// Unit specification is invalid, unrecognized, or malformed.
final class InvalidUnitError extends MathError {
  final String unit;

  const InvalidUnitError({
    required this.unit,
    super.message = 'Invalid or unrecognized unit specification.',
    super.code = 'INVALID_UNIT',
  });
}

/// Incompatible matrix dimensions for the requested operation.
final class MatrixDimensionError extends MathError {
  final String operation;
  final (int, int) leftShape;
  final (int, int)? rightShape;

  const MatrixDimensionError({
    required this.operation,
    required this.leftShape,
    this.rightShape,
    super.message = 'Matrix dimensions are incompatible for operation.',
    super.code = 'MATRIX_DIMENSION_ERROR',
  });
}

/// Matrix is singular (determinant is zero) and cannot be inverted.
final class SingularMatrixError extends MathError {
  const SingularMatrixError({
    super.message = 'Matrix is singular and cannot be inverted.',
    super.code = 'SINGULAR_MATRIX',
  });
}

/// Matrix structure or components are invalid.
final class InvalidMatrixError extends MathError {
  const InvalidMatrixError({
    super.message = 'Matrix structure or components are invalid.',
    super.code = 'INVALID_MATRIX',
  });
}

/// Vector structure or components are invalid.
final class InvalidVectorError extends MathError {
  const InvalidVectorError({
    super.message = 'Vector structure or components are invalid.',
    super.code = 'INVALID_VECTOR',
  });
}

/// Equation or system has no solution.
final class NoSolutionError extends MathError {
  const NoSolutionError({
    super.message = 'No solution exists for equation or system.',
    super.code = 'NO_SOLUTION',
  });
}

/// Equation or system has infinitely many solutions.
final class InfiniteSolutionsError extends MathError {
  const InfiniteSolutionsError({
    super.message = 'Infinitely many solutions exist for equation or system.',
    super.code = 'INFINITE_SOLUTIONS',
  });
}

/// Numerical approximation algorithm failed to converge within the allowed iterations.
final class ConvergenceFailureError extends MathError {
  final int? iterations;
  final String? method;

  const ConvergenceFailureError({
    super.message = 'Numerical algorithm failed to converge within tolerance.',
    super.code = 'CONVERGENCE_FAILURE',
    this.iterations,
    this.method,
  });
}

/// Catastrophic or unacceptable precision loss occurred during calculation.
final class PrecisionLossError extends MathError {
  const PrecisionLossError({
    super.message = 'Catastrophic precision loss occurred during calculation.',
    super.code = 'PRECISION_LOSS',
  });
}

/// Operation is unsupported for the given operands or engine state.
final class UnsupportedOperationError extends MathError {
  final String operation;

  const UnsupportedOperationError({
    required this.operation,
    super.message = 'Operation is unsupported for the given operands.',
    super.code = 'UNSUPPORTED_OPERATION',
  });
}

/// Radix/base is outside valid bounds (2..36).
final class InvalidBaseError extends MathError {
  final int base;

  const InvalidBaseError({
    required this.base,
    super.message = 'Invalid radix/base specification.',
    super.code = 'INVALID_BASE',
  });
}

/// Integer bit-width is invalid or unsupported.
final class InvalidBitWidthError extends MathError {
  final int bitWidth;

  const InvalidBitWidthError({
    required this.bitWidth,
    super.message = 'Invalid bit-width specification.',
    super.code = 'INVALID_BIT_WIDTH',
  });
}

/// Value is not a valid probability ([0.0, 1.0]).
final class InvalidProbabilityError extends MathError {
  final double? value;

  const InvalidProbabilityError({
    this.value,
    super.message = 'Probability must be in the range [0, 1].',
    super.code = 'INVALID_PROBABILITY',
  });
}

/// Parameter passed to probability distribution is invalid.
final class InvalidDistributionParameterError extends MathError {
  final String parameterName;
  final String? reason;

  const InvalidDistributionParameterError({
    required this.parameterName,
    this.reason,
    super.message = 'Invalid parameter for probability distribution.',
    super.code = 'INVALID_DISTRIBUTION_PARAMETER',
  });
}

/// Required input variable for formula is missing.
final class FormulaInputMissingError extends MathError {
  final String variableName;

  const FormulaInputMissingError({
    required this.variableName,
    super.message = 'Required formula input variable is missing.',
    super.code = 'FORMULA_INPUT_MISSING',
  });
}

/// Input variable for formula has an invalid value.
final class FormulaInputInvalidError extends MathError {
  final String variableName;
  final String? reason;

  const FormulaInputInvalidError({
    required this.variableName,
    this.reason,
    super.message = 'Formula input variable has invalid value.',
    super.code = 'FORMULA_INPUT_INVALID',
  });
}

/// Circular reference detected in spreadsheet or expression dependencies.
final class CircularReferenceError extends MathError {
  final String? path;

  const CircularReferenceError({
    this.path,
    super.message = 'Circular dependency detected.',
    super.code = 'CIRCULAR_REFERENCE',
  });
}

/// Dependency evaluation failure.
final class DependencyError extends MathError {
  final String dependencyName;

  const DependencyError({
    required this.dependencyName,
    super.message = 'Dependency evaluation failed.',
    super.code = 'DEPENDENCY_ERROR',
  });
}

/// Generic mathematical error fallback when a more specific category does not apply.
final class GenericMathError extends MathError {
  const GenericMathError({required super.message, super.code = 'MATH_ERROR'});
}
