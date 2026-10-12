import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_warning.dart';
import 'package:nexa_math/mathematical_core/mathematical_core.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/regression_diagnostic_calculator.dart';

void main() {
  group('Phase 9 — Regression Analysis & Numerical Stability Tests', () {
    late StatisticsEngine engine;

    setUp(() {
      engine = StatisticsEngine();
    });

    // Helper for scale-aware numerical assertions: |calc - ref| <= atol + rtol * |ref|
    void assertScaleAware(
      double calculated,
      double reference, {
      double atol = 1e-12,
      double rtol = 1e-12,
    }) {
      final diff = (calculated - reference).abs();
      final tol = atol + rtol * reference.abs();
      expect(diff, lessThanOrEqualTo(tol));
    }

    group('Linear Regression Tests', () {
      test('Perfect linear fit: y = 2x + 1 on N = 2 points', () {
        final p = PairedDataset.create(
          Dataset.fromInts([1, 3]),
          Dataset.fromInts([3, 7]),
        ).valueOrNull!;

        final res = engine.linearRegression(p);
        expect(res.isSuccess, isTrue);
        final fit = res.valueOrNull!;

        expect(fit.type, equals(RegressionType.linear));
        expect(fit.coefficients.length, equals(2)); // [b, a]

        final b = fit.coefficients[0].toDouble();
        final a = fit.coefficients[1].toDouble();
        assertScaleAware(b, 1.0);
        assertScaleAware(a, 2.0);

        final r = fit.correlation!.toDouble();
        assertScaleAware(r, 1.0);

        final r2 = fit.rSquared.toDouble();
        assertScaleAware(r2, 1.0);

        final sse = fit.sse.toDouble();
        assertScaleAware(sse, 0.0);
      });

      test(
        'Vertical line (zero variance in X) fails with SingularMatrixError',
        () {
          final p = PairedDataset.create(
            Dataset.fromInts([4, 4, 4]),
            Dataset.fromInts([1, 2, 3]),
          ).valueOrNull!;

          final res = engine.linearRegression(p);
          expect(res.isFailure, isTrue);
          expect(res.errorOrNull, isA<SingularMatrixError>());
        },
      );

      test(
        'Constant response SST = 0 Case 1 yields R^2 = 1.0 and NearZeroWarning',
        () {
          final p = PairedDataset.create(
            Dataset.fromInts([1, 2, 3]),
            Dataset.fromInts([5, 5, 5]),
          ).valueOrNull!;

          final res = engine.linearRegression(p);
          expect(res.isSuccess, isTrue);
          final fit = res.valueOrNull!;

          expect(fit.rSquared.toDouble(), equals(1.0));
          expect(
            fit.metadata.warnings.any((w) => w is NearZeroWarning),
            isTrue,
          );
        },
      );
    });

    group('Polynomial Regression Tests (Quadratic & Cubic)', () {
      test(
        'Underdetermined input N < d + 1 fails with InvalidArgumentError',
        () {
          final p2 = PairedDataset.create(
            Dataset.fromInts([1, 2]),
            Dataset.fromInts([1, 4]),
          ).valueOrNull!;
          final qRes = engine.quadraticRegression(p2);
          expect(qRes.isFailure, isTrue);
          expect(qRes.errorOrNull, isA<InvalidArgumentError>());

          final p3 = PairedDataset.create(
            Dataset.fromInts([1, 2, 3]),
            Dataset.fromInts([1, 8, 27]),
          ).valueOrNull!;
          final cRes = engine.cubicRegression(p3);
          expect(cRes.isFailure, isTrue);
          expect(cRes.errorOrNull, isA<InvalidArgumentError>());
        },
      );

      test(
        'Insufficient distinct X coordinates fails with SingularMatrixError',
        () {
          // Degree 2 with 3 points but only 2 distinct X coordinates
          final p = PairedDataset.create(
            Dataset.fromInts([1, 1, 2]),
            Dataset.fromInts([1, 2, 4]),
          ).valueOrNull!;

          final res = engine.quadraticRegression(p);
          expect(res.isFailure, isTrue);
          expect(res.errorOrNull, isA<SingularMatrixError>());
        },
      );

      test('Exactly Determined Quadratic (N = 3): y = x^2 - x + 2', () {
        // points: (0, 2), (1, 2), (2, 4)
        final p = PairedDataset.create(
          Dataset.fromInts([0, 1, 2]),
          Dataset.fromInts([2, 2, 4]),
        ).valueOrNull!;

        final res = engine.quadraticRegression(p);
        expect(res.isSuccess, isTrue);
        final fit = res.valueOrNull!;

        expect(fit.coefficients.length, equals(3)); // [c, b, a] = [2, -1, 1]
        final c = fit.coefficients[0].toDouble();
        final b = fit.coefficients[1].toDouble();
        final a = fit.coefficients[2].toDouble();

        assertScaleAware(c, 2.0);
        assertScaleAware(b, -1.0);
        assertScaleAware(a, 1.0);

        expect(fit.correlation, isNull);
        assertScaleAware(fit.rSquared.toDouble(), 1.0);
        assertScaleAware(fit.sse.toDouble(), 0.0);
      });

      test('Predictor centering invariant: large shifted calendar coordinates recover canonical coefficients', () {
        // y = 2 * (x - 2000)^2 + 3 * (x - 2000) + 1
        // x in {2000, 2001, 2002}
        // for x = 2000: y = 1
        // for x = 2001: y = 2(1) + 3(1) + 1 = 6
        // for x = 2002: y = 2(4) + 3(2) + 1 = 15
        final p = PairedDataset.create(
          Dataset.fromInts([2000, 2001, 2002]),
          Dataset.fromInts([1, 6, 15]),
        ).valueOrNull!;

        final res = engine.quadraticRegression(p);
        expect(res.isSuccess, isTrue);
        final fit = res.valueOrNull!;

        // y = 2(x^2 - 4000x + 4000000) + 3x - 6000 + 1 = 2x^2 - 7997x + 7994001
        final a = fit.coefficients[2].toDouble();
        final b = fit.coefficients[1].toDouble();
        final c = fit.coefficients[0].toDouble();

        assertScaleAware(a, 2.0);
        assertScaleAware(b, -7997.0);
        assertScaleAware(c, 7994001.0);
      });

      test('Exactly Determined Cubic (N = 4): y = 2x^3 - x^2 + 3x - 5', () {
        final xList = [0, 1, 2, 3];
        final yList = xList
            .map((x) => 2 * x * x * x - x * x + 3 * x - 5)
            .toList();

        final p = PairedDataset.create(
          Dataset.fromInts(xList),
          Dataset.fromInts(yList),
        ).valueOrNull!;

        final res = engine.cubicRegression(p);
        expect(res.isSuccess, isTrue);
        final fit = res.valueOrNull!;

        expect(fit.coefficients.length, equals(4)); // [d, c, b, a]
        final d = fit.coefficients[0].toDouble();
        final c = fit.coefficients[1].toDouble();
        final b = fit.coefficients[2].toDouble();
        final a = fit.coefficients[3].toDouble();

        assertScaleAware(d, -5.0);
        assertScaleAware(c, 3.0);
        assertScaleAware(b, -1.0);
        assertScaleAware(a, 2.0);

        assertScaleAware(fit.rSquared.toDouble(), 1.0);
        assertScaleAware(fit.sse.toDouble(), 0.0);
      });
    });

    group('Transformed Regression Tests', () {
      test(
        'Logarithmic regression rejects non-positive x values with DomainError',
        () {
          final p = PairedDataset.create(
            Dataset.fromInts([0, 1, 2]),
            Dataset.fromInts([1, 2, 3]),
          ).valueOrNull!;

          final res = engine.logarithmicRegression(p);
          expect(res.isFailure, isTrue);
          expect(res.errorOrNull, isA<DomainError>());
        },
      );

      test(
        'Exponential regression rejects non-positive y values with DomainError',
        () {
          final p = PairedDataset.create(
            Dataset.fromInts([1, 2, 3]),
            Dataset.fromInts([2, 0, 4]),
          ).valueOrNull!;

          final res = engine.exponentialRegression(p);
          expect(res.isFailure, isTrue);
          expect(res.errorOrNull, isA<DomainError>());
        },
      );

      test(
        'Power regression rejects non-positive x or y values with DomainError',
        () {
          final p = PairedDataset.create(
            Dataset.fromInts([-1, 2, 3]),
            Dataset.fromInts([2, 3, 4]),
          ).valueOrNull!;

          final res = engine.powerRegression(p);
          expect(res.isFailure, isTrue);
          expect(res.errorOrNull, isA<DomainError>());
        },
      );

      test(
        'Exponential regression fit and original response-space prediction',
        () {
          // y = 2 * e^(0.5 * x)
          // points: x = 0 -> y = 2, x = 2 -> y = 2 * e^1 = 5.4365636569
          final p = PairedDataset.fromDoubles(
            [0.0, 2.0],
            [2.0, 2.0 * 2.718281828459045],
          ).valueOrNull!;

          final res = engine.exponentialRegression(p);
          expect(res.isSuccess, isTrue);
          final fit = res.valueOrNull!;

          expect(fit.coefficients.length, equals(2)); // [a, b]
          final a = fit.coefficients[0].toDouble();
          final b = fit.coefficients[1].toDouble();

          assertScaleAware(a, 2.0);
          assertScaleAware(b, 0.5);
          expect(fit.correlation, isNull);
          assertScaleAware(fit.rSquared.toDouble(), 1.0);
        },
      );

      test('Deterministic negative R^2 test: unconstrained exponential on concave data yields unclamped R^2 < 0', () {
        // Dataset P = {(1, 10), (2, 1), (3, 10)} from specification Section 12.5.1
        final p = PairedDataset.create(
          Dataset.fromInts([1, 2, 3]),
          Dataset.fromInts([10, 1, 10]),
        ).valueOrNull!;

        final res = engine.exponentialRegression(p);
        expect(res.isSuccess, isTrue);
        final fit = res.valueOrNull!;

        final r2 = fit.rSquared.toDouble();
        expect(r2, lessThan(0.0)); // Strictly negative R^2 preserved
        expect((r2 - (-0.31)).abs(), lessThan(0.05));
      });
    });

    group('Diagnostic Calculator & Exhaustive 4-Case R^2 Matrix', () {
      test('Case 1: SST = 0, SSE = 0 -> R^2 = 1.0 and NearZeroWarning', () {
        const diagCalc = RegressionDiagnosticCalculator();
        final res = diagCalc.calculateRSquared(sse: 0.0, sst: 0.0);
        expect(res.isSuccess, isTrue);
        final d = res.valueOrNull!;
        expect(d.rSquared, equals(1.0));
        expect(d.warnings.any((w) => w is NearZeroWarning), isTrue);
      });

      test('Case 2: SST = 0, SSE > 0 -> R^2 = 0.0 and NearZeroWarning', () {
        const diagCalc = RegressionDiagnosticCalculator();
        final res = diagCalc.calculateRSquared(sse: 4.5, sst: 0.0);
        expect(res.isSuccess, isTrue);
        final d = res.valueOrNull!;
        expect(d.rSquared, equals(0.0));
        expect(d.warnings.any((w) => w is NearZeroWarning), isTrue);
      });

      test('Case 3: SST > 0, SSE = 0 -> R^2 = 1.0 and no warnings', () {
        const diagCalc = RegressionDiagnosticCalculator();
        final res = diagCalc.calculateRSquared(sse: 0.0, sst: 10.0);
        expect(res.isSuccess, isTrue);
        final d = res.valueOrNull!;
        expect(d.rSquared, equals(1.0));
        expect(d.warnings, isEmpty);
      });

      test('Case 4: SST > 0, SSE > 0 -> R^2 = 1 - SSE/SST', () {
        const diagCalc = RegressionDiagnosticCalculator();
        final res = diagCalc.calculateRSquared(sse: 2.0, sst: 10.0);
        expect(res.isSuccess, isTrue);
        final d = res.valueOrNull!;
        expect((d.rSquared - 0.8).abs(), lessThan(1e-12));
        expect(d.warnings, isEmpty);
      });
    });

    group('Regression Expression AST & AstEvaluator Integration Tests', () {
      test('Linear regression AST evaluates accurately via AstEvaluator', () {
        final p = PairedDataset.create(
          Dataset.fromInts([1, 2, 3]),
          Dataset.fromInts([5, 7, 9]),
        ).valueOrNull!;

        final fit = engine.linearRegression(p).valueOrNull!;
        final evaluator = AstEvaluator();

        // Evaluate at x = 4: y = 2(4) + 3 = 11
        final evalCtx = EvaluationContext(
          variables: {'x': DecimalValue.parse('4', isExact: false)},
        );
        final evalRes = evaluator.evaluate(fit.equation, evalCtx);
        expect(evalRes.isSuccess, isTrue);
        final yVal = (evalRes.valueOrNull! as DecimalValue).toDouble();
        assertScaleAware(yVal, 11.0);
      });

      test(
        'Quadratic regression AST evaluates accurately via AstEvaluator',
        () {
          // y = x^2 - x + 2
          final p = PairedDataset.create(
            Dataset.fromInts([0, 1, 2]),
            Dataset.fromInts([2, 2, 4]),
          ).valueOrNull!;

          final fit = engine.quadraticRegression(p).valueOrNull!;
          final evaluator = AstEvaluator();

          // Evaluate at x = 3: y = 9 - 3 + 2 = 8
          final evalCtx = EvaluationContext(
            variables: {'x': DecimalValue.parse('3', isExact: false)},
          );
          final evalRes = evaluator.evaluate(fit.equation, evalCtx);
          expect(evalRes.isSuccess, isTrue);
          final yVal = (evalRes.valueOrNull! as DecimalValue).toDouble();
          assertScaleAware(yVal, 8.0);
        },
      );

      test(
        'Logarithmic regression AST evaluates accurately via AstEvaluator',
        () {
          // y = 5 + 2 * ln(x)
          final p = PairedDataset.fromDoubles(
            [1.0, 2.718281828459045],
            [5.0, 7.0],
          ).valueOrNull!;

          final fit = engine.logarithmicRegression(p).valueOrNull!;
          final evaluator = AstEvaluator();

          // Evaluate at x = 1: y = 5
          final evalCtx = EvaluationContext(
            variables: {'x': DecimalValue.parse('1.0', isExact: false)},
          );
          final evalRes = evaluator.evaluate(fit.equation, evalCtx);
          expect(evalRes.isSuccess, isTrue);
          final yVal = (evalRes.valueOrNull! as DecimalValue).toDouble();
          assertScaleAware(yVal, 5.0);
        },
      );

      test('Cubic regression AST evaluates accurately via AstEvaluator', () {
        // y = 2x^3 - x^2 + 3x - 5
        final p = PairedDataset.create(
          Dataset.fromInts([0, 1, 2, 3]),
          Dataset.fromInts([-5, -1, 13, 49]),
        ).valueOrNull!;

        final fit = engine.cubicRegression(p).valueOrNull!;
        final evaluator = AstEvaluator();

        // Evaluate at x = 4: y = 2(64) - 16 + 12 - 5 = 119
        final evalCtx = EvaluationContext(
          variables: {'x': DecimalValue.parse('4', isExact: false)},
        );
        final evalRes = evaluator.evaluate(fit.equation, evalCtx);
        expect(evalRes.isSuccess, isTrue);
        final yVal = (evalRes.valueOrNull! as DecimalValue).toDouble();
        assertScaleAware(yVal, 119.0);
      });

      test(
        'Exponential regression AST evaluates accurately via AstEvaluator',
        () {
          // y = 2 * exp(0.5 * x)
          final p = PairedDataset.fromDoubles(
            [0.0, 2.0],
            [2.0, 2.0 * 2.718281828459045],
          ).valueOrNull!;

          final fit = engine.exponentialRegression(p).valueOrNull!;
          final evaluator = AstEvaluator();

          // Evaluate at x = 0: y = 2 * exp(0) = 2.0
          final evalCtx = EvaluationContext(
            variables: {'x': DecimalValue.parse('0.0', isExact: false)},
          );
          final evalRes = evaluator.evaluate(fit.equation, evalCtx);
          expect(evalRes.isSuccess, isTrue);
          final yVal = (evalRes.valueOrNull! as DecimalValue).toDouble();
          assertScaleAware(yVal, 2.0);
        },
      );

      test('Power regression AST evaluates accurately via AstEvaluator', () {
        // y = 3 * x^2
        final p = PairedDataset.fromDoubles(
          [1.0, 2.0, 3.0],
          [3.0, 12.0, 27.0],
        ).valueOrNull!;

        final fit = engine.powerRegression(p).valueOrNull!;
        final evaluator = AstEvaluator();

        // Evaluate at x = 4: y = 3 * 16 = 48.0
        final evalCtx = EvaluationContext(
          variables: {'x': DecimalValue.parse('4.0', isExact: false)},
        );
        final evalRes = evaluator.evaluate(fit.equation, evalCtx);
        expect(evalRes.isSuccess, isTrue);
        final yVal = (evalRes.valueOrNull! as DecimalValue).toDouble();
        assertScaleAware(yVal, 48.0);
      });
    });

    group('Phase 9 — Numerical Edge-Case & Boundary Hardening Tests', () {
      test('Area C: Exponential regression parameter overflow (alpha > 709.78)', () {
        // Pairs with steep y values where ln(y) intercept exceeds 709.78
        // ln(1e308) ~ 709.089. If we have y = [1e300, 1e308] with x = [-1, 0],
        // alpha = ln(y at 0) = ln(1e308) ~ 709.089.
        // For alpha > 709.78:
        // Let x = [0.0, 1.0], y = [math.exp(709.79), math.exp(709.79)] (or equivalent)
        // Since double max finite is ~1.797e308 and ln(max_finite) ~ 709.7827
        // If we construct two points with intercept > 709.78:
        final pOverflow = PairedDataset.fromDoubles(
          [0.0, 1.0],
          [1.7976931348623157e308, 1.7976931348623157e308],
        ).valueOrNull!;

        final res = engine.exponentialRegression(pOverflow);
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<OverflowError>());
      });

      test('Area C: Exponential regression parameter underflow (alpha < -745.13 -> a == 0.0)', () {
        // Very small y values: ln(1e-324) ~ -745.133
        // If intercept goes below -745.13, exp(alpha) underflows to 0.0.
        // Data coordinates forcing alpha < -745:
        // x = [10.0, 11.0], y = [1e-320, 1e-300]
        // ln(1e-320) = -736.82, ln(1e-300) = -690.77 -> slope b = +46.05
        // alpha = -736.82 - (46.05 * 10) = -1197.32 < -745!
        final pDeepUnderflow = PairedDataset.fromDoubles(
          [10.0, 11.0],
          [1e-320, 1e-300],
        ).valueOrNull!;

        final res = engine.exponentialRegression(pDeepUnderflow);
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<UnderflowError>());
      });

      test('Area C: Positive subnormal coefficient is accepted when -745.13 <= alpha <= -708.40', () {
        // Points with x = [0.0, 1.0], y = [1e-315, 1e-315]
        // ln(1e-315) ~ -725.26, slope b = 0.0, intercept alpha = -725.26
        // exp(-725.26) is a valid positive subnormal double (between 4.94e-324 and 2.22e-308).
        final pSubnormal = PairedDataset.fromDoubles(
          [0.0, 1.0],
          [1e-315, 1e-315],
        ).valueOrNull!;

        final res = engine.exponentialRegression(pSubnormal);
        expect(res.isSuccess, isTrue);
        final fit = res.valueOrNull!;
        final a = fit.coefficients[0].toDouble();
        expect(a, greaterThan(0.0));
        expect(a, lessThan(2.2250738585072014e-308)); // strictly subnormal
      });

      test(
        'Area C: Exponential prediction underflow gracefully flattens to 0.0',
        () {
          // Spec §12.5.4: Prediction underflow to exact 0.0 is permitted and flattens gracefully.
          // Dataset coordinates:
          //   x = [0.0, 10.0], y = [1.0, 5e-324]
          // In the tested Dart runtime:
          //   ln(y[0]) = ln(1.0) = 0.0
          //   ln(y[1]) = ln(5e-324) = -744.4400719213502 (where 5e-324 represents the smallest positive binary64 subnormal)
          // OLS on transformed coordinates (u = x, v = ln(y)):
          //   slope b = (-744.4400719213502 - 0.0) / 10.0 = -74.44400719213502
          //   intercept alpha = 0.0 -> a = exp(0.0) = 1.0
          // At x[1] = 10.0:
          //   exponent = b * x[1] = -74.44400719213502 * 10.0 = -744.4400719213502
          // Observed Dart runtime behavior:
          //   math.exp(-744.4400719213502) evaluates to exact 0.0
          //   yHat = a * 0.0 = 0.0
          final p = PairedDataset.fromDoubles(
            [0.0, 10.0],
            [1.0, 5e-324],
          ).valueOrNull!;

          final fitRes = engine.exponentialRegression(p);
          expect(fitRes.isSuccess, isTrue);
          final fit = fitRes.valueOrNull!;
          // At x = 0.0: prediction is 1.0
          expect(fit.predictions[0].toDouble(), closeTo(1.0, 1e-6));
          // In the tested Dart runtime, the exponential term evaluates to exact
          // 0.0 at x = 10.0, so the prediction is exactly 0.0.
          expect(fit.predictions[1].toDouble(), equals(0.0));
        },
      );

      test(
        'Area C: Exponential prediction exponent overflow (b * x > 709.78)',
        () {
          // Fit data where b = 767.53 and x = [0.1, 1.0]
          // At x = 1.0, exponent = 767.53 > 709.78, caught by the pre-exp check
          final pPredOvf = PairedDataset.fromDoubles(
            [0.1, 1.0],
            [1.0, 1e300],
          ).valueOrNull!;

          final res = engine.exponentialRegression(pPredOvf);
          expect(res.isFailure, isTrue);
          expect(res.errorOrNull, isA<OverflowError>());
        },
      );

      test('Area C: Exponential post-multiplication overflow (a * exp(b * x) overflows while exp is finite)', () {
        // Exponent check is: if (exponent > 709.78) return OverflowError.
        // Suppose exponent = 700.0 <= 709.78. Then math.exp(700.0) is finite (~1.014e304).
        // If a = 1e20, then a * math.exp(700.0) = 1e20 * 1.014e304 = 1.014e324 -> infinity!
        // This reaches line 249: if (yHat.isInfinite) return OverflowError.
        // To construct this via public API:
        // We need intercept alpha such that a = exp(alpha) is large, e.g. alpha = 46.05 -> a = 1e20.
        // And slope b such that for one point x_i, b * x_i = 700.0.
        // Let x = [0.0, 1.0], y = [1e20, 1e20 * exp(700.0)]
        // But 1e20 * exp(700) = 1e324 > DBL_MAX, so we cannot put 1e324 directly in the dataset!
        // However, with 3 points:
        // Let x = [0.0, 0.5, 1.0].
        // If y = [1e20, 1e20 * exp(350), 1e20 * exp(700)], y[2] still exceeds DBL_MAX.
        // What if the line fit extrapolation at one of the points causes yHat to overflow?
        // For instance, a dataset with non-exponential points where the fitted line has large a and large b * x_i:
        // Suppose x = [10.0, 20.0], y = [1e300, 1.0].
        // ln(y[0]) = 690.77, ln(y[1]) = 0.0 -> slope b = -69.077.
        // intercept alpha = 690.77 - (-69.077 * 10) = 1381.54 -> alpha > 709.78 (intercept overflow).
        // Can post-multiplication overflow be triggered on valid finite inputs?
        // Since yHat = a * exp(b * x_i) and ln(yHat) = alpha + b * x_i = ln(y_fit_i).
        // For any point in the dataset, if the transformed line fits y_i exactly (like 2 points),
        // yHat is approximately y_i (which must be a finite double <= 1.79e308).
        // With 3 or more points, least squares can produce a yHat_i that exceeds max(y_i).
        // For example: x = [0.0, 1.0, 2.0], y = [1e150, 1e160, 1e308].
        // ln(y) = [345.38, 368.41, 709.09].
        // Mean x = 1.0, mean ln(y) = 474.29.
        // x - meanX = [-1, 0, 1].
        // Slope b = ((-1)*(345.38 - 474.29) + (1)*(709.09 - 474.29)) / 2 = (128.91 + 234.80) / 2 = 181.85.
        // Intercept alpha = 474.29 - 181.85 * 1.0 = 292.44.
        // a = exp(292.44) ~ 1.35e127 (finite!).
        // At x = 2.0: exponent = b * x = 181.85 * 2.0 = 363.7 <= 709.78!
        // exp(363.7) ~ 1.15e158 (finite!).
        // Total exponent at x = 2.0: alpha + b * x = 292.44 + 363.7 = 656.14 <= 709.78.
        // Now let's adjust so alpha + b * x > 709.78, but b * x <= 709.78 and alpha <= 709.78:
        // Suppose alpha = 400.0 (a = exp(400) ~ 5.22e173).
        // b * x = 350.0 (exp(350) ~ 1.97e152).
        // Both 400 <= 709.78 and 350 <= 709.78!
        // But a * exp(b * x) = exp(750) = infinity!
        // In this case:
        // exponent = 350 <= 709.78 (passes line 233).
        // a = exp(400) (passes line 165).
        // yHat = a * exp(350) = 5.22e173 * 1.97e152 = infinity!
        // It hits line 249: if (yHat.isInfinite) return OverflowError!
        // Let's create this dataset:
        // We want alpha ~ 400, b ~ 350, with x = [0.0, 0.5, 1.0].
        // At x = 0: ln(y) should be near 400 -> y ~ exp(400) ~ 5.2e173.
        // At x = 1: ln(y) should be near 400 + 350 = 750 (which overflows).
        // But with OLS, points can be:
        // x = [-1.0, 0.0, 1.0].
        // At x = -1: y = exp(50) ~ 5.18e21.
        // At x = 0: y = exp(400) ~ 5.22e173.
        // At x = 1: if y = exp(700) ~ 1.01e304.
        // All 3 y values are FINITE and valid doubles!
        // Let's calculate OLS:
        // ln(y) = [50.0, 400.0, 700.0].
        // x = [-1.0, 0.0, 1.0].
        // Mean x = 0.0, mean ln(y) = 383.33.
        // Slope b = ((-1)*(50 - 383.33) + 0 + (1)*(700 - 383.33)) / (1 + 0 + 1) = (333.33 + 316.67) / 2 = 325.0.
        // Intercept alpha = mean ln(y) - b * 0 = 383.33.
        // a = exp(383.33) ~ 2.47e166 (finite, passes alpha <= 709.78).
        // At x = 1.0:
        // exponent = b * x = 325.0 * 1.0 = 325.0 <= 709.78 (passes exponent check!).
        // exp(exponent) = exp(325.0) ~ 1.44e141 (finite).
        // Now: yHat = a * exp(exponent) = exp(383.33) * exp(325.0) = exp(708.33) <= 709.78 (almost overflows).
        // If we shift slope slightly:
        // At x = -1: y = exp(40)
        // At x = 0: y = exp(390)
        // At x = 1: y = exp(709)
        // ln(y) = [40.0, 390.0, 709.0].
        // Mean ln(y) = 379.67.
        // Slope b = ((-1)*(40 - 379.67) + (1)*(709 - 379.67)) / 2 = (339.67 + 329.33) / 2 = 334.5.
        // Intercept alpha = 379.67.
        // a = exp(379.67) (finite).
        // At x = 1.0: exponent = 334.5 <= 709.78 (finite!).
        // yHat = exp(379.67) * exp(334.5) = exp(714.17) -> OVERFLOWS TO INFINITY!
        final pPostMultOvf = PairedDataset.fromDoubles(
          [-1.0, 0.0, 1.0],
          [math.exp(40.0), math.exp(390.0), math.exp(709.0)],
        ).valueOrNull!;

        final res = engine.exponentialRegression(pPostMultOvf);
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<OverflowError>());
      });

      test('Area D: Direct evaluation vs AstEvaluator parity at numerical boundaries', () {
        // 1. Logarithmic regression at domain boundary x <= 0
        final pLog = PairedDataset.fromDoubles(
          [1.0, 2.0],
          [3.0, 5.0],
        ).valueOrNull!;
        final fitLog = engine.logarithmicRegression(pLog).valueOrNull!;
        final evaluator = AstEvaluator();

        // At x = 0: AST evaluation must return MathFailure(DomainError)
        final zeroCtx = EvaluationContext(variables: {'x': DecimalValue.zero});
        final astZeroRes = evaluator.evaluate(fitLog.equation, zeroCtx);
        expect(astZeroRes.isFailure, isTrue);
        expect(astZeroRes.errorOrNull, isA<DomainError>());

        // At negative x: AST evaluation must return MathFailure(DomainError)
        final negCtx = EvaluationContext(
          variables: {'x': DecimalValue.parse('-1.0', isExact: false)},
        );
        final astNegRes = evaluator.evaluate(fitLog.equation, negCtx);
        expect(astNegRes.isFailure, isTrue);
        expect(astNegRes.errorOrNull, isA<DomainError>());

        // 2. Exponential regression near overflow boundary
        // y = 1 * exp(100 * x)
        final pExp = PairedDataset.fromDoubles(
          [0.0, 1.0],
          [1.0, math.exp(100.0)],
        ).valueOrNull!;
        final fitExp = engine.exponentialRegression(pExp).valueOrNull!;

        // At x = 8.0: 100 * 8 = 800 > 709.78 -> overflow
        // Direct evaluation in TransformedRegression returns OverflowError.
        // AST evaluator invokes exp(800) which yields double.infinity, caught and mapped to GenericMathError in function_registry.
        final ovfCtx = EvaluationContext(
          variables: {'x': DecimalValue.parse('8.0', isExact: false)},
        );
        final astOvfRes = evaluator.evaluate(fitExp.equation, ovfCtx);
        expect(astOvfRes.isFailure, isTrue);
        expect(
          astOvfRes.errorOrNull,
          isA<MathError>(),
        ); // Wrapped in GenericMathError
        expect(
          astOvfRes.errorOrNull,
          isNot(isA<OverflowError>()),
        ); // Documents exact error type discrepancy

        // At valid interior points: direct formula vs AST match within 1e-12
        final validCtx = EvaluationContext(
          variables: {'x': DecimalValue.parse('0.5', isExact: false)},
        );
        final astValRes = evaluator.evaluate(fitExp.equation, validCtx);
        expect(astValRes.isSuccess, isTrue);
        final astVal = (astValRes.valueOrNull! as DecimalValue).toDouble();
        final directVal =
            fitExp.coefficients[0].toDouble() *
            math.exp(fitExp.coefficients[1].toDouble() * 0.5);
        expect((astVal - directVal).abs() / directVal, lessThan(1e-12));
      });
    });
  });
}
