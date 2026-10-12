import 'dart:math' as math;

/// Numerical evaluation helpers for the Gamma family:
/// - Log-Gamma function $\ln \Gamma(x)$ (Lanczos approximation, $g=7, N=9$)
/// - Regularized lower incomplete gamma function $P(a, x) = \frac{\gamma(a, x)}{\Gamma(a)}$
/// - Regularized upper incomplete gamma function $Q(a, x) = \frac{\Gamma(a, x)}{\Gamma(a)} = 1 - P(a, x)$
/// - Inverse regularized incomplete gamma function
final class GammaFunctions {
  GammaFunctions._();

  // Lanczos approximation coefficients for g = 7, N = 9
  static const double _lanczosG = 7.0;
  static const List<double> _lanczosCoefficients = [
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.138571095836524,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];

  /// Evaluates $\ln \Gamma(x)$ for $x > 0$.
  static double logGamma(double x) {
    if (x <= 0.0) {
      if (x == 0.0) return double.infinity;
      // Reflection formula: Gamma(x) * Gamma(1 - x) = pi / sin(pi * x)
      return math.log(math.pi / math.sin(math.pi * x)) - logGamma(1.0 - x);
    }

    if (x < 0.5) {
      // Use reflection formula for small x to maintain stability
      return math.log(math.pi / math.sin(math.pi * x)) - logGamma(1.0 - x);
    }

    final z = x - 1.0;
    var base = _lanczosCoefficients[0];
    for (var i = 1; i < _lanczosCoefficients.length; i++) {
      base += _lanczosCoefficients[i] / (z + i);
    }

    final t = z + _lanczosG + 0.5;
    return 0.5 * math.log(2.0 * math.pi) +
        (z + 0.5) * math.log(t) -
        t +
        math.log(base);
  }

  /// Evaluates the regularized lower incomplete gamma function $P(a, x)$.
  ///
  /// Invariants:
  /// - $P(a, 0) = 0$
  /// - $P(a, \infty) = 1$
  /// - Domain: $a > 0, x \ge 0$.
  static double regularizedGammaP(double a, double x) {
    if (a <= 0.0 || x < 0.0) return double.nan;
    if (x == 0.0) return 0.0;
    if (x.isInfinite) return 1.0;

    if (x < a + 1.0) {
      // Series representation
      return _gammaPSeries(a, x);
    } else {
      // Continued fraction representation: P = 1 - Q
      return 1.0 - _gammaQContinuedFraction(a, x);
    }
  }

  /// Evaluates the regularized upper incomplete gamma function $Q(a, x) = 1 - P(a, x)$.
  ///
  /// Invariants:
  /// - $Q(a, 0) = 1$
  /// - $Q(a, \infty) = 0$
  /// - Avoids subtractive cancellation when $x \gg a$.
  static double regularizedGammaQ(double a, double x) {
    if (a <= 0.0 || x < 0.0) return double.nan;
    if (x == 0.0) return 1.0;
    if (x.isInfinite) return 0.0;

    if (x < a + 1.0) {
      return 1.0 - _gammaPSeries(a, x);
    } else {
      return _gammaQContinuedFraction(a, x);
    }
  }

  /// Series expansion for $P(a, x) = \frac{x^a e^{-x}}{\Gamma(a)} \sum_{n=0}^\infty \frac{x^n}{a(a+1)\dots(a+n)}$.
  static double _gammaPSeries(double a, double x) {
    var ap = a;
    var sum = 1.0 / a;
    var del = sum;

    for (var n = 1; n <= 300; n++) {
      ap += 1.0;
      del = del * x / ap;
      sum += del;
      if (del.abs() < sum.abs() * 1e-15) {
        break;
      }
    }

    return sum * math.exp(-x + a * math.log(x) - logGamma(a));
  }

  /// Modified Lentz continued fraction for $Q(a, x) = \frac{e^{-x} x^a}{\Gamma(a)} \frac{1}{x + \frac{1 - a}{1 + \frac{1}{x + \dots}}}$.
  static double _gammaQContinuedFraction(double a, double x) {
    const tiny = 1e-30;
    var b = x + 1.0 - a;
    var c = 1.0 / tiny;
    var d = 1.0 / b;
    var h = d;

    for (var i = 1; i <= 300; i++) {
      final an = -i * (i - a);
      b += 2.0;
      d = an * d + b;
      if (d.abs() < tiny) d = tiny;
      c = b + an / c;
      if (c.abs() < tiny) c = tiny;
      d = 1.0 / d;
      final del = d * c;
      h *= del;
      if ((del - 1.0).abs() < 1e-15) {
        break;
      }
    }

    return h * math.exp(-x + a * math.log(x) - logGamma(a));
  }

  /// Inverts regularized incomplete gamma: finds $x$ such that $P(a, x) = p$.
  static double inverseGammaP(double a, double p) {
    if (p <= 0.0) return 0.0;
    if (p >= 1.0) return double.infinity;

    // Initial approximation
    double x;
    if (a > 1.0) {
      final v = math.sqrt(2.0 * math.log(1.0 / (1.0 - p)));
      x =
          a *
          math
              .pow(1.0 - 1.0 / (9.0 * a) + v / (3.0 * math.sqrt(a)), 3)
              .toDouble();
    } else {
      x = math.pow(p * a * math.exp(logGamma(a)), 1.0 / a).toDouble();
    }

    if (x <= 0.0) x = 1e-3;

    // Halley's root-finding method
    for (var iter = 0; iter < 100; iter++) {
      final err = regularizedGammaP(a, x) - p;
      if (err.abs() < 1e-13 * p) break;

      final fPrime = math.exp(-x + (a - 1.0) * math.log(x) - logGamma(a));
      if (fPrime == 0.0) break;

      final fDoublePrime = fPrime * ((a - 1.0) / x - 1.0);
      final delta = err / (fPrime - 0.5 * err * fDoublePrime / fPrime);
      x -= delta;
      if (x <= 0.0) x = 0.5 * (x + delta);
    }

    return x;
  }
}
