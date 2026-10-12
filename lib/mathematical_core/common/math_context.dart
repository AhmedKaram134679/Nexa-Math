import 'package:nexa_math/mathematical_core/common/angle_mode.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';

/// Immutable evaluation context passed to mathematical engines during computation.
final class EvaluationContext {
  /// Active angular mode for trigonometric calculations.
  final AngleMode angleMode;

  /// Precision context specifying digits and rounding.
  final PrecisionContext precision;

  /// Immutable map of variable bindings currently in scope.
  final Map<String, MathValue> variables;

  /// Immutable map of constant definitions currently in scope.
  final Map<String, MathValue> constants;

  const EvaluationContext({
    this.angleMode = AngleMode.radians,
    this.precision = PrecisionContext.standard,
    this.variables = const {},
    this.constants = const {},
  });

  /// Standard default evaluation context.
  static const EvaluationContext standard = EvaluationContext();

  /// Creates a copy of this context with updated properties.
  EvaluationContext copyWith({
    AngleMode? angleMode,
    PrecisionContext? precision,
    Map<String, MathValue>? variables,
    Map<String, MathValue>? constants,
  }) {
    return EvaluationContext(
      angleMode: angleMode ?? this.angleMode,
      precision: precision ?? this.precision,
      variables: variables ?? this.variables,
      constants: constants ?? this.constants,
    );
  }

  @override
  String toString() =>
      'EvaluationContext(angleMode: $angleMode, precision: ${precision.precisionDigits}, vars: ${variables.length})';
}

/// Unified context combining evaluation environment with precision configuration.
final class MathContext {
  /// Evaluation environment containing variables, constants, and angle settings.
  final EvaluationContext evaluation;

  /// Precision configuration governing significant digits and rounding.
  final PrecisionContext precision;

  const MathContext({
    this.evaluation = EvaluationContext.standard,
    this.precision = PrecisionContext.standard,
  });

  /// Standard default math context.
  static const MathContext standard = MathContext();

  @override
  String toString() =>
      'MathContext(evaluation: $evaluation, precision: $precision)';
}
