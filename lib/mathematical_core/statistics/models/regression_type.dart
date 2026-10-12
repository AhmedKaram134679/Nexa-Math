/// Approved mathematical regression model categories in NexaMath Phase 9.
enum RegressionType {
  /// Linear regression: $y = a x + b$.
  linear,

  /// Quadratic polynomial regression: $y = a x^2 + b x + c$.
  quadratic,

  /// Cubic polynomial regression: $y = a x^3 + b x^2 + c x + d$.
  cubic,

  /// Logarithmic regression: $y = a + b \ln(x)$ (for $x > 0$).
  logarithmic,

  /// Exponential regression: $y = a e^{b x}$ (for $y > 0$, with $a > 0$).
  exponential,

  /// Power regression: $y = a x^b$ (for $x > 0, y > 0$, with $a > 0$).
  power,
}
