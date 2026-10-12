/// Rounding mode algorithms applied when precision truncation is required.
enum RoundingMode {
  /// Rounds towards the nearest neighbor, or up if equidistant (standard arithmetic rounding).
  halfUp,

  /// Rounds towards the nearest neighbor, or towards the nearest even integer if equidistant (banker's rounding).
  halfEven,

  /// Rounds away from zero.
  up,

  /// Rounds towards zero (truncation).
  down,

  /// Rounds towards positive infinity.
  ceiling,

  /// Rounds towards negative infinity.
  floor,
}

/// Precision configuration governing significant digits and rounding algorithms.
final class PrecisionContext {
  /// Maximum number of significant digits preserved during numerical computation.
  final int precisionDigits;

  /// Rounding mode applied when truncating precision.
  final RoundingMode roundingMode;

  /// Absolute tolerance threshold below which quantities are treated as zero.
  final double zeroTolerance;

  const PrecisionContext({
    this.precisionDigits = 34, // Default IEEE 754 decimal128 standard
    this.roundingMode = RoundingMode.halfEven,
    this.zeroTolerance = 1e-15,
  }) : assert(
         precisionDigits > 0,
         'Precision digits must be strictly positive.',
       );

  /// Standard scientific calculator precision configuration.
  static const PrecisionContext standard = PrecisionContext();

  /// High precision context for rigorous numerical algorithms.
  static const PrecisionContext highPrecision = PrecisionContext(
    precisionDigits: 64,
    roundingMode: RoundingMode.halfEven,
    zeroTolerance: 1e-30,
  );

  @override
  String toString() =>
      'PrecisionContext(digits: $precisionDigits, rounding: $roundingMode, zeroTol: $zeroTolerance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrecisionContext &&
          runtimeType == other.runtimeType &&
          precisionDigits == other.precisionDigits &&
          roundingMode == other.roundingMode &&
          zeroTolerance == other.zeroTolerance;

  @override
  int get hashCode => Object.hash(precisionDigits, roundingMode, zeroTolerance);
}
