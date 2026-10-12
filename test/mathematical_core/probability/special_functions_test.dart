import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/probability/special_functions/beta_functions.dart';
import 'package:nexa_math/mathematical_core/probability/special_functions/error_function.dart';
import 'package:nexa_math/mathematical_core/probability/special_functions/gamma_functions.dart';

void main() {
  group('ErrorFunction (erf, erfc, erfinv)', () {
    test('erf symmetry and high-accuracy reference values (ISS-10-01)', () {
      // High-precision reference values from MPMath / NIST DLMF
      expect(ErrorFunction.erf(0.0), equals(0.0));
      expect(ErrorFunction.erf(0.5), closeTo(0.5204998778130465, 1e-14));
      expect(ErrorFunction.erf(1.0), closeTo(0.8427007929497149, 1e-14));
      expect(ErrorFunction.erf(-1.0), closeTo(-0.8427007929497149, 1e-14));
      expect(ErrorFunction.erf(1.5), closeTo(0.9661051464753108, 1e-14));
      expect(ErrorFunction.erf(2.0), closeTo(0.9953222650189527, 1e-14));
      expect(ErrorFunction.erf(3.0), closeTo(0.9999779095030014, 1e-14));
      expect(ErrorFunction.erf(6.5), equals(1.0));
      expect(ErrorFunction.erf(-6.5), equals(-1.0));
    });

    test('erfc complement consistency and high-accuracy reference values (ISS-10-01)', () {
      // High-precision reference values from MPMath / NIST DLMF
      expect(ErrorFunction.erfc(0.0), equals(1.0));
      expect(ErrorFunction.erfc(0.5), closeTo(0.4795001221869535, 1e-14));
      expect(ErrorFunction.erfc(1.0), closeTo(0.1572992070502851, 1e-14));
      expect(ErrorFunction.erfc(2.0), closeTo(0.004677734981047266, 1e-14));
      expect(ErrorFunction.erfc(3.0), closeTo(2.209049699858544e-5, 1e-18));
      expect(ErrorFunction.erfc(5.0), closeTo(1.537459794428035e-12, 1e-24));
      // Extreme tail underflow
      expect(ErrorFunction.erfc(28.0), equals(0.0));
    });

    test(
      'erfinv inverse identity erf(erfinv(y)) == y with double precision',
      () {
        for (final y in [-0.99, -0.9, -0.5, -0.1, 0.0, 0.1, 0.5, 0.9, 0.99]) {
          final x = ErrorFunction.erfinv(y);
          final evaluated = ErrorFunction.erf(x);
          expect(evaluated, closeTo(y, 1e-14));
        }
        expect(ErrorFunction.erfinv(0.0), equals(0.0));
        expect(ErrorFunction.erfinv(1.0), equals(double.infinity));
        expect(ErrorFunction.erfinv(-1.0), equals(double.negativeInfinity));
      },
    );
  });

  group('GammaFunctions (logGamma, regularizedGammaP, regularizedGammaQ)', () {
    test('logGamma factorial identity ln(n!) = logGamma(n + 1)', () {
      // 1! = 1 -> log = 0
      expect(GammaFunctions.logGamma(2.0), closeTo(0.0, 1e-11));
      // 5! = 120 -> log(120) ~ 4.787491742782046
      expect(GammaFunctions.logGamma(6.0), closeTo(math.log(120.0), 1e-11));
      // Gamma(0.5) = sqrt(pi) -> log(sqrt(pi)) ~ 0.5723649429247001
      expect(
        GammaFunctions.logGamma(0.5),
        closeTo(math.log(math.sqrt(math.pi)), 1e-11),
      );
    });

    test('regularized incomplete gamma P and Q complement identity', () {
      const a = 3.0;
      const x = 2.5;
      final p = GammaFunctions.regularizedGammaP(a, x);
      final q = GammaFunctions.regularizedGammaQ(a, x);
      expect(p + q, closeTo(1.0, 1e-12));
    });

    test('regularized gamma boundaries', () {
      expect(GammaFunctions.regularizedGammaP(2.0, 0.0), equals(0.0));
      expect(GammaFunctions.regularizedGammaQ(2.0, 0.0), equals(1.0));
      expect(GammaFunctions.regularizedGammaP(2.0, 50.0), closeTo(1.0, 1e-12));
    });
  });

  group('BetaFunctions (logBeta, regularizedBeta)', () {
    test('logBeta identity B(a, b) = Gamma(a)*Gamma(b)/Gamma(a+b)', () {
      const a = 2.0;
      const b = 3.0;
      // B(2, 3) = 1! * 2! / 4! = 2 / 24 = 1/12
      final expected = math.log(1.0 / 12.0);
      expect(BetaFunctions.logBeta(a, b), closeTo(expected, 1e-11));
    });

    test('regularizedBeta endpoints and symmetry', () {
      expect(BetaFunctions.regularizedBeta(2.0, 3.0, 0.0), equals(0.0));
      expect(BetaFunctions.regularizedBeta(2.0, 3.0, 1.0), equals(1.0));

      // I_x(a, b) = 1 - I_{1-x}(b, a)
      const a = 2.5;
      const b = 4.5;
      const x = 0.35;
      final left = BetaFunctions.regularizedBeta(a, b, x);
      final right = 1.0 - BetaFunctions.regularizedBeta(b, a, 1.0 - x);
      expect(left, closeTo(right, 1e-14));
    });
  });
}
