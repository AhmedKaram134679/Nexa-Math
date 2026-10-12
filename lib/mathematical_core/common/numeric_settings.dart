/// Display notation mode for rendering numbers.
enum DisplayNotation {
  /// Standard decimal notation (e.g. 1234.56).
  standard,

  /// Scientific notation (e.g. 1.23456e3).
  scientific,

  /// Engineering notation with exponent in multiples of 3 (e.g. 1.23456e3).
  engineering,

  /// Exact fraction notation where available (e.g. 1/3).
  fraction,
}

/// Numerical calculation settings controlling display and precision.
final class NumericSettings {
  /// General working precision digits.
  final int precision;

  /// Default numerical display notation.
  final DisplayNotation notation;

  /// Optional fixed decimal digits for fixed-point presentation.
  final int? fixedDigits;

  /// Whether engineering notation is forced for large/small numbers.
  final bool engineeringNotation;

  const NumericSettings({
    required this.precision,
    required this.notation,
    this.fixedDigits,
    this.engineeringNotation = false,
  });

  /// Standard default numeric settings.
  static const NumericSettings standard = NumericSettings(
    precision: 34,
    notation: DisplayNotation.standard,
  );

  @override
  String toString() =>
      'NumericSettings(precision: $precision, notation: $notation, fixedDigits: $fixedDigits)';
}
