/// Angle unit mode applied during trigonometric computations.
///
/// Must not be stored globally; passed explicitly via context.
enum AngleMode {
  /// Degrees: 360 degrees in a full circle.
  degrees,

  /// Radians: 2π radians in a full circle.
  radians,

  /// Gradians: 400 gradians in a full circle.
  gradians,
}
