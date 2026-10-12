import 'dart:math' as math;

/// Numerical evaluation helpers for Error Function ($\text{erf}$),
/// Complementary Error Function ($\text{erfc}$), and Inverse Error Function ($\text{erfinv}$).
///
/// Implements Cody / fdlibm minimax rational approximations (W. J. Cody / Sun Microsystems)
/// with full IEEE-754 double-precision accuracy across all regions:
/// - Region 1: $|x| < 0.84375$ (rational minimax approximation for $\text{erf}$, error $< 1$ ULP)
/// - Region 2: $0.84375 \le |x| < 1.25$ (Taylor rational minimax about $x = 1$)
/// - Region 3: $1.25 \le |x| < 2.85714$ (rational minimax for asymptotic $\text{erfc}$)
/// - Region 4: $2.85714 \le |x| < 28.0$ (high-tail rational minimax for asymptotic $\text{erfc}$)
/// - Extreme tail: $|x| \ge 28.0$ (exact saturation / representational underflow)
final class ErrorFunction {
  ErrorFunction._();

  // Constants for approximation to erf on [0, 0.84375]
  static const double _erx = 8.45062911510467529297e-01;
  static const double _efx8 = 1.02703333676410069053e+00;
  static const double _pp0 = 1.28379167095512558561e-01;
  static const double _pp1 = -3.25042107247001499370e-01;
  static const double _pp2 = -2.84817495755985104766e-02;
  static const double _pp3 = -5.77027029648944159157e-03;
  static const double _pp4 = -2.37630166566501626084e-05;

  static const double _qq1 = 3.97917223959155352819e-01;
  static const double _qq2 = 6.50222499887672944485e-02;
  static const double _qq3 = 5.08130628187576562776e-03;
  static const double _qq4 = 1.32494738004321644526e-04;
  static const double _qq5 = -3.96022827877536812320e-06;

  // Coefficients for approximation to erf in [0.84375, 1.25]
  static const double _pa0 = -2.36211856075265944077e-03;
  static const double _pa1 = 4.14856118683748331666e-01;
  static const double _pa2 = -3.72207876035701323847e-01;
  static const double _pa3 = 3.18346619901161753674e-01;
  static const double _pa4 = -1.10894694282396677476e-01;
  static const double _pa5 = 3.54783043256182359371e-02;
  static const double _pa6 = -2.16637559486879084300e-03;

  static const double _qa1 = 1.06420880400844228286e-01;
  static const double _qa2 = 5.40397917702171048937e-01;
  static const double _qa3 = 7.18286544141962662868e-02;
  static const double _qa4 = 1.26171219808761642112e-01;
  static const double _qa5 = 1.36370839120290507362e-02;
  static const double _qa6 = 1.19844998467991074170e-02;

  // Coefficients for approximation to erfc in [1.25, 1/0.35]
  static const double _ra0 = -9.86494403484714822705e-03;
  static const double _ra1 = -6.93858572707181764372e-01;
  static const double _ra2 = -1.05586262253232909814e+01;
  static const double _ra3 = -6.23753324503260060396e+01;
  static const double _ra4 = -1.62396669462573470355e+02;
  static const double _ra5 = -1.84605092906711035994e+02;
  static const double _ra6 = -8.12874355063065934246e+01;
  static const double _ra7 = -9.81432934416914548592e+00;

  static const double _sa1 = 1.96512716674392571292e+01;
  static const double _sa2 = 1.37657754143519042600e+02;
  static const double _sa3 = 4.34565877475229228821e+02;
  static const double _sa4 = 6.45387271733267880336e+02;
  static const double _sa5 = 4.29008140027567833386e+02;
  static const double _sa6 = 1.08635005541779435134e+02;
  static const double _sa7 = 6.57024977031928170135e+00;
  static const double _sa8 = -6.04244152148580987438e-02;

  // Coefficients for approximation to erfc in [1/0.35, 28]
  static const double _rb0 = -9.86494292470009928597e-03;
  static const double _rb1 = -7.99283237680523006574e-01;
  static const double _rb2 = -1.77579549177547519889e+01;
  static const double _rb3 = -1.60636384855821916062e+02;
  static const double _rb4 = -6.37566443368389627722e+02;
  static const double _rb5 = -1.02509513161107724954e+03;
  static const double _rb6 = -4.83519191608651397019e+02;

  static const double _sb1 = 3.03380607434824582924e+01;
  static const double _sb2 = 3.25792512996573918826e+02;
  static const double _sb3 = 1.53672958608443695994e+03;
  static const double _sb4 = 3.19985821950859553908e+03;
  static const double _sb5 = 2.55305040643316442583e+03;
  static const double _sb6 = 4.74528541206955367215e+02;
  static const double _sb7 = -2.24409524465858183362e+01;

  static double _erfc1(double x) {
    final s = x.abs() - 1.0;
    final p =
        _pa0 +
        s *
            (_pa1 +
                s * (_pa2 + s * (_pa3 + s * (_pa4 + s * (_pa5 + s * _pa6)))));
    final q =
        1.0 +
        s *
            (_qa1 +
                s * (_qa2 + s * (_qa3 + s * (_qa4 + s * (_qa5 + s * _qa6)))));
    return 1.0 - _erx - p / q;
  }

  static double _erfc2(double x) {
    final ax = x.abs();
    if (ax < 1.25) return _erfc1(x);

    final s = 1.0 / (ax * ax);
    double r, sumS;
    if (ax < 2.857142857142857) {
      r =
          _ra0 +
          s *
              (_ra1 +
                  s *
                      (_ra2 +
                          s *
                              (_ra3 +
                                  s *
                                      (_ra4 +
                                          s *
                                              (_ra5 +
                                                  s * (_ra6 + s * _ra7))))));
      sumS =
          1.0 +
          s *
              (_sa1 +
                  s *
                      (_sa2 +
                          s *
                              (_sa3 +
                                  s *
                                      (_sa4 +
                                          s *
                                              (_sa5 +
                                                  s *
                                                      (_sa6 +
                                                          s *
                                                              (_sa7 +
                                                                  s * _sa8)))))));
    } else {
      r =
          _rb0 +
          s *
              (_rb1 +
                  s * (_rb2 + s * (_rb3 + s * (_rb4 + s * (_rb5 + s * _rb6)))));
      sumS =
          1.0 +
          s *
              (_sb1 +
                  s *
                      (_sb2 +
                          s *
                              (_sb3 +
                                  s *
                                      (_sb4 +
                                          s *
                                              (_sb5 +
                                                  s * (_sb6 + s * _sb7))))));
    }
    return math.exp(-ax * ax - 0.5625 + r / sumS) / ax;
  }

  /// Evaluates the error function $\text{erf}(x) = \frac{2}{\sqrt{\pi}} \int_0^x e^{-t^2} dt$.
  static double erf(double x) {
    if (x.isNaN) return double.nan;
    if (x.isInfinite) return x.isNegative ? -1.0 : 1.0;
    if (x == 0.0) return 0.0;

    final ax = x.abs();
    double y;
    if (ax < 0.84375) {
      if (ax < 3.725290298461914e-9) {
        // |x| < 2^-28 avoids underflow in x*x
        return 0.125 * (8.0 * x + _efx8 * x);
      }
      final z = ax * ax;
      final r = _pp0 + z * (_pp1 + z * (_pp2 + z * (_pp3 + z * _pp4)));
      final s =
          1.0 + z * (_qq1 + z * (_qq2 + z * (_qq3 + z * (_qq4 + z * _qq5))));
      y = ax + ax * (r / s);
      return x.isNegative ? -y : y;
    }

    if (ax < 6.0) {
      y = 1.0 - _erfc2(ax);
    } else {
      y = 1.0;
    }
    return x.isNegative ? -y : y;
  }

  /// Evaluates the complementary error function $\text{erfc}(x) = 1 - \text{erf}(x)$
  /// without catastrophic subtractive cancellation in upper tails.
  static double erfc(double x) {
    if (x.isNaN) return double.nan;
    if (x.isInfinite) return x.isNegative ? 2.0 : 0.0;
    if (x == 0.0) return 1.0;

    final ax = x.abs();
    if (ax < 0.84375) {
      if (ax < 1.3877787807814457e-17) {
        // |x| < 2^-56
        return 1.0 - x;
      }
      final z = ax * ax;
      final r = _pp0 + z * (_pp1 + z * (_pp2 + z * (_pp3 + z * _pp4)));
      final s =
          1.0 + z * (_qq1 + z * (_qq2 + z * (_qq3 + z * (_qq4 + z * _qq5))));
      final y = r / s;
      if (x < 0.25) {
        return 1.0 - (x + x * y);
      }
      return 0.5 - (x - 0.5 + x * y);
    }

    if (ax < 28.0) {
      return x.isNegative ? 2.0 - _erfc2(ax) : _erfc2(ax);
    }
    return x.isNegative ? 2.0 : 0.0;
  }

  // Acklam rational approximation coefficients for inverse normal / erfinv
  static const List<double> _acklamA = [
    -3.969683028665376e+01,
    2.209460984245205e+02,
    -2.759285104469687e+02,
    1.383577518672690e+02,
    -3.066479806614716e+01,
    2.506628277459239e+00,
  ];

  static const List<double> _acklamB = [
    -5.447609879822406e+01,
    1.615858368580409e+02,
    -1.556989798598866e+02,
    6.680131188771972e+01,
    -1.328068155288572e+01,
  ];

  static const List<double> _acklamC = [
    -7.784894002430293e-03,
    -3.223964580411365e-01,
    -2.400758277161838e+00,
    -2.549732539343734e+00,
    4.374664141464968e+00,
    2.938163982698783e+00,
  ];

  static const List<double> _acklamD = [
    7.784695709041462e-03,
    3.224671290700398e-01,
    2.445134137142996e+00,
    3.754408661907416e+00,
  ];

  /// Evaluates the inverse error function $\text{erfinv}(y)$ for $y \in (-1, 1)$
  /// using Peter J. Acklam's rational minimax approximation with Halley polishing.
  static double erfinv(double y) {
    if (y.isNaN) return double.nan;
    if (y < -1.0 || y > 1.0) return double.nan;
    if (y == 0.0) return 0.0;
    if (y == 1.0) return double.infinity;
    if (y == -1.0) return double.negativeInfinity;

    final p = 0.5 * (y + 1.0);
    double z;

    if (p < 0.02425) {
      // Lower tail
      final q = math.sqrt(-2.0 * math.log(p));
      z =
          (((((_acklamC[0] * q + _acklamC[1]) * q + _acklamC[2]) * q +
                              _acklamC[3]) *
                          q +
                      _acklamC[4]) *
                  q +
              _acklamC[5]) /
          ((((_acklamD[0] * q + _acklamD[1]) * q + _acklamD[2]) * q +
                      _acklamD[3]) *
                  q +
              1.0);
    } else if (p <= 0.97575) {
      // Central region
      final q = p - 0.5;
      final r = q * q;
      z =
          (((((_acklamA[0] * r + _acklamA[1]) * r + _acklamA[2]) * r +
                              _acklamA[3]) *
                          r +
                      _acklamA[4]) *
                  r +
              _acklamA[5]) *
          q /
          (((((_acklamB[0] * r + _acklamB[1]) * r + _acklamB[2]) * r +
                              _acklamB[3]) *
                          r +
                      _acklamB[4]) *
                  r +
              1.0);
    } else {
      // Upper tail
      final q = math.sqrt(-2.0 * math.log(1.0 - p));
      z =
          -(((((_acklamC[0] * q + _acklamC[1]) * q + _acklamC[2]) * q +
                              _acklamC[3]) *
                          q +
                      _acklamC[4]) *
                  q +
              _acklamC[5]) /
          ((((_acklamD[0] * q + _acklamD[1]) * q + _acklamD[2]) * q +
                      _acklamD[3]) *
                  q +
              1.0);
    }

    // High-accuracy Halley polishing on standard normal distribution:
    // Phi(z) = 0.5 * erfc(-z / sqrt(2))
    // Phi'(z) = 1/sqrt(2*pi) * exp(-0.5 * z^2)
    // Halley step: delta = (Phi(z) - p) / (Phi'(z) + 0.5 * z * (Phi(z) - p))
    for (var iter = 0; iter < 2; iter++) {
      final phi = 0.5 * erfc(-z / 1.4142135623730950488016887242097);
      final f = phi - p;
      final fPrime =
          0.39894228040143267793994605993438 * math.exp(-0.5 * z * z);
      if (fPrime == 0.0) break;
      final delta = f / (fPrime + 0.5 * z * f);
      z -= delta;
      if (delta.abs() < 1e-15 * (z.abs() + 1.0)) break;
    }

    // Convert standard normal quantile z = Phi^-1(p) to erfinv(y):
    // erfinv(2p - 1) = z / sqrt(2)
    return z / 1.4142135623730950488016887242097;
  }
}
