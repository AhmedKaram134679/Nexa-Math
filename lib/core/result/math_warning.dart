/// Non-fatal diagnostic warning emitted during mathematical computation.
sealed class MathWarning {
  /// Machine-readable warning code.
  final String code;

  /// Technical explanation of the warning condition.
  final String message;

  const MathWarning({required this.code, required this.message});

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// Emitted when precision was reduced or digits truncated.
final class PrecisionLossWarning extends MathWarning {
  const PrecisionLossWarning({
    super.code = 'PRECISION_LOSS_WARNING',
    super.message = 'Precision loss occurred during numerical evaluation.',
  });
}

/// Emitted when a quantity is extraordinarily close to zero and may cause numerical instability.
final class NearZeroWarning extends MathWarning {
  const NearZeroWarning({
    super.code = 'NEAR_ZERO_WARNING',
    super.message = 'Operand is near zero, which may cause instability or loss of significance.',
  });
}

/// Emitted when an exact mathematical value was replaced by a numerical approximation.
final class NumericalApproximationWarning extends MathWarning {
  const NumericalApproximationWarning({
    super.code = 'NUMERICAL_APPROXIMATION_WARNING',
    super.message = 'Result is a numerical approximation rather than an exact symbolic form.',
  });
}

/// Emitted when an algorithm converged slowly or marginally satisfied tolerance.
final class ConvergenceWarning extends MathWarning {
  const ConvergenceWarning({
    super.code = 'CONVERGENCE_WARNING',
    super.message = 'Algorithm converged with marginal tolerance.',
  });
}

/// Emitted when unit conversion was performed with potential unit discrepancy.
final class UnitConversionWarning extends MathWarning {
  const UnitConversionWarning({
    super.code = 'UNIT_CONVERSION_WARNING',
    super.message = 'Unit conversion was applied.',
  });
}

/// Generic non-fatal mathematical warning.
final class GenericMathWarning extends MathWarning {
  const GenericMathWarning({required super.code, required super.message});
}
