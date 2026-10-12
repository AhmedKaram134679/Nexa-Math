import 'dart:math' as math;

import 'package:nexa_math/mathematical_core/probability/special_functions/gamma_functions.dart';

/// Numerical evaluation helpers for the Beta family:
/// - Log-Beta function $\ln \text{B}(a, b) = \ln \Gamma(a) + \ln \Gamma(b) - \ln \Gamma(a + b)$
/// - Regularized incomplete beta function $I_x(a, b) = \frac{\text{B}(x; a, b)}{\text{B}(a, b)}$
/// - Inverse regularized incomplete beta function $I^{-1}_p(a, b)$
final class BetaFunctions {
  BetaFunctions._();

  /// Evaluates $\ln \text{B}(a, b)$ for $a > 0, b > 0$.
  static double logBeta(double a, double b) {
    return GammaFunctions.logGamma(a) +
        GammaFunctions.logGamma(b) -
        GammaFunctions.logGamma(a + b);
  }

  /// Evaluates the regularized incomplete beta function $I_x(a, b)$ for $x \in [0, 1], a > 0, b > 0$.
  ///
  /// Invariants:
  /// - $I_0(a, b) = 0$
  /// - $I_1(a, b) = 1$
  /// - Symmetry identity: $I_x(a, b) = 1 - I_{1 - x}(b, a)$
  static double regularizedBeta(double a, double b, double x) {
    if (a <= 0.0 || b <= 0.0) return double.nan;
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;

    // Symmetry transformation for faster and stable convergence
    if (x > (a + 1.0) / (a + b + 2.0)) {
      return 1.0 - regularizedBeta(b, a, 1.0 - x);
    }

    // Evaluate via continued fraction
    final factor = math.exp(
      a * math.log(x) + b * math.log(1.0 - x) - logBeta(a, b),
    );

    return factor * _betaContinuedFraction(a, b, x) / a;
  }

  /// Modified Lentz continued fraction for $I_x(a, b)$ (Numerical Recipes 6.4).
  static double _betaContinuedFraction(double a, double b, double x) {
    const tiny = 1e-30;
    const maxIter = 300;

    final qab = a + b;
    final qap = a + 1.0;
    final qam = a - 1.0;

    var c = 1.0;
    var d = 1.0 - qab * x / qap;
    if (d.abs() < tiny) d = tiny;
    d = 1.0 / d;
    var h = d;

    for (var m = 1; m <= maxIter; m++) {
      final m2 = 2 * m;

      // Even step
      var aa = m * (b - m) * x / ((qam + m2) * (a + m2));
      d = 1.0 + aa * d;
      if (d.abs() < tiny) d = tiny;
      c = 1.0 + aa / c;
      if (c.abs() < tiny) c = tiny;
      d = 1.0 / d;
      h *= d * c;

      // Odd step
      aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
      d = 1.0 + aa * d;
      if (d.abs() < tiny) d = tiny;
      c = 1.0 + aa / c;
      if (c.abs() < tiny) c = tiny;
      d = 1.0 / d;
      final del = d * c;
      h *= del;

      if ((del - 1.0).abs() < 1e-15) {
        break;
      }
    }

    return h;
  }

  /// Inverts regularized incomplete beta: finds $x$ such that $I_x(a, b) = p$.
  static double inverseBeta(double a, double b, double p) {
    if (p <= 0.0) return 0.0;
    if (p >= 1.0) return 1.0;

    // Initial approximation using normal approximation / Cornish-Fisher
    var x = a / (a + b);
    var lo = 0.0;
    var hi = 1.0;

    // Bisection / Halley hybrid
    for (var iter = 0; iter < 100; iter++) {
      final val = regularizedBeta(a, b, x);
      final err = val - p;

      if (err.abs() < 1e-13 * p) break;

      if (err > 0.0) {
        hi = x;
      } else {
        lo = x;
      }

      final fPrime = math.exp(
        (a - 1.0) * math.log(x) + (b - 1.0) * math.log(1.0 - x) - logBeta(a, b),
      );

      if (fPrime == 0.0) {
        x = 0.5 * (lo + hi);
      } else {
        final delta = err / fPrime;
        final xNew = x - delta;
        if (xNew <= lo || xNew >= hi) {
          x = 0.5 * (lo + hi);
        } else {
          x = xNew;
        }
      }
    }

    return x;
  }
}
