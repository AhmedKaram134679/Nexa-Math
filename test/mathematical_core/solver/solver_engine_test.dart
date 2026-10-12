import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/matrix/matrix.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/solver/solver.dart';

void main() {
  group('NexaMath Phase 8 — Equation Solver Engine', () {
    late final SolverEngine solver;

    setUpAll(() {
      solver = SolverEngine();
    });

    group('Exact Linear Equations', () {
      test('2x + 4 = 10 -> x = 3', () {
        final res = solver.solveString('2x + 4 = 10', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.exact));
        expect(sol.roots.length, equals(1));
        expect(sol.roots.first.value, equals(IntegerValue.fromInt(3)));
        expect(sol.roots.first.isExact, isTrue);
      });

      test('5x - 10 = 0 -> x = 2', () {
        final res = solver.solveString('5x - 10 = 0', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.roots.first.value, equals(IntegerValue.fromInt(2)));
      });

      test('Fractional root: 3x + 1 = 0 -> x = -1/3', () {
        final res = solver.solveString('3x + 1 = 0', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.roots.first.value, equals(FractionValue.fromInts(-1, 3)));
      });

      test('No solution (inconsistent): 2x + 1 = 2x + 3', () {
        final res = solver.solveString('2x + 1 = 2x + 3', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.noSolution));
        expect(sol.roots, isEmpty);
      });

      test('Infinite solutions (identity): 2(x + 1) = 2x + 2', () {
        final res = solver.solveString('2(x + 1) = 2x + 2', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.infiniteSolutions));
        expect(sol.roots, isEmpty);
      });
    });

    group('Exact Quadratic Equations', () {
      test('x^2 - 5x + 6 = 0 -> x = 2, x = 3', () {
        final res = solver.solveString('x^2 - 5x + 6 = 0', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.exact));
        expect(sol.roots.length, equals(2));
        final values = sol.roots.map((r) => r.value).toSet();
        expect(values.contains(IntegerValue.fromInt(2)), isTrue);
        expect(values.contains(IntegerValue.fromInt(3)), isTrue);
      });

      test('Difference of squares: x^2 - 4 = 0 -> x = -2, x = 2', () {
        final res = solver.solveString('x^2 - 4 = 0', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        final values = sol.roots.map((r) => r.value).toSet();
        expect(values.contains(IntegerValue.fromInt(-2)), isTrue);
        expect(values.contains(IntegerValue.fromInt(2)), isTrue);
      });

      test('Repeated root: x^2 - 4x + 4 = 0 -> x = 2 with multiplicity 2', () {
        final res = solver.solveString('x^2 - 4x + 4 = 0', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.roots.length, equals(1));
        expect(sol.roots.first.value, equals(IntegerValue.fromInt(2)));
        expect(sol.roots.first.multiplicity, equals(2));
      });

      test('Complex roots: x^2 + 1 = 0 -> x = +i, x = -i', () {
        final res = solver.solveString(
          'x^2 + 1 = 0',
          variable: 'x',
          options: const SolverOptions(includeComplex: true),
        );
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.roots.length, equals(2));
        expect(sol.complexRoots.length, equals(2));
        final vals = sol.complexRoots
            .map((r) => r.value as ComplexNumber)
            .toList();
        expect(
          vals.any((c) => c.real.isZero && c.imaginary == DecimalValue.one),
          isTrue,
        );
        expect(
          vals.any(
            (c) => c.real.isZero && c.imaginary == DecimalValue.fromInt(-1),
          ),
          isTrue,
        );
      });

      test('Complex roots excluded when includeComplex: false', () {
        final res = solver.solveString(
          'x^2 + 1 = 0',
          variable: 'x',
          options: const SolverOptions(includeComplex: false),
        );
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.noSolution));
      });
    });

    group('Exact Higher-Degree Polynomials', () {
      test(
        'Cubic with 3 rational roots: x^3 - 6x^2 + 11x - 6 = 0 -> {1, 2, 3}',
        () {
          final res = solver.solveString(
            'x^3 - 6x^2 + 11x - 6 = 0',
            variable: 'x',
          );
          expect(res.isSuccess, isTrue);
          final sol = res.valueOrNull!;
          final vals = sol.roots.map((r) => r.value).toSet();
          expect(vals.contains(IntegerValue.fromInt(1)), isTrue);
          expect(vals.contains(IntegerValue.fromInt(2)), isTrue);
          expect(vals.contains(IntegerValue.fromInt(3)), isTrue);
        },
      );

      test(
        'Cubic with repeated root: x^3 - 3x + 2 = 0 -> {1 (mult 2), -2}',
        () {
          final res = solver.solveString('x^3 - 3x + 2 = 0', variable: 'x');
          expect(res.isSuccess, isTrue);
          final sol = res.valueOrNull!;
          expect(sol.hasSolution, isTrue);
          final roots = sol.roots;
          expect(
            roots.any(
              (r) => r.value == IntegerValue.fromInt(1) && r.multiplicity == 2,
            ),
            isTrue,
          );
          expect(roots.any((r) => r.value == IntegerValue.fromInt(-2)), isTrue);
        },
      );

      test('Biquadratic quartic: x^4 - 5x^2 + 4 = 0 -> {1, -1, 2, -2}', () {
        final res = solver.solveString('x^4 - 5x^2 + 4 = 0', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        final vals = sol.roots.map((r) => r.value).toSet();
        expect(vals.contains(IntegerValue.fromInt(1)), isTrue);
        expect(vals.contains(IntegerValue.fromInt(-1)), isTrue);
        expect(vals.contains(IntegerValue.fromInt(2)), isTrue);
        expect(vals.contains(IntegerValue.fromInt(-2)), isTrue);
      });

      test('Biquadratic complex roots: x^4 + 1 = 0 -> 4 complex roots', () {
        final res = solver.solveString(
          'x^4 + 1 = 0',
          variable: 'x',
          options: const SolverOptions(includeComplex: true),
        );
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.roots.length, equals(4));
        expect(sol.complexRoots.length, equals(4));
        for (final r in sol.complexRoots) {
          final c = r.value as ComplexNumber;
          expect(c.real.toDouble().abs(), closeTo(0.70710678, 1e-5));
          expect(c.imaginary.toDouble().abs(), closeTo(0.70710678, 1e-5));
        }
      });

      test(
        'Irrational quadratic: x^2 - 2 = 0 marked approximate, not exact',
        () {
          final res = solver.solveString('x^2 - 2 = 0', variable: 'x');
          expect(res.isSuccess, isTrue);
          final sol = res.valueOrNull!;
          expect(sol.solutionType, equals(SolutionType.approximate));
          expect(sol.roots.length, equals(2));
          expect(sol.roots.every((r) => !r.isExact), isTrue);
          final vals = sol.roots
              .map((r) => (r.value as DecimalValue).toDouble().abs())
              .toSet();
          expect(vals.first, closeTo(1.41421356, 1e-6));
        },
      );
    });

    group('Numerical Solvers (Newton-Raphson, Bisection, Secant)', () {
      test('Newton-Raphson: cos(x) = x (Dottie number x ≈ 0.739085)', () {
        final res = solver.solveString(
          'cos(x) = x',
          variable: 'x',
          method: SolvingMethod.newtonRaphson,
          options: const SolverOptions(initialGuess: 0.5),
        );
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.approximate));
        final root = (sol.roots.first.value as DecimalValue).toDouble();
        expect(root, closeTo(0.7390851332, 1e-6));
      });

      test('Bisection: cos(x) = x on [0, 1]', () {
        final res = solver.solveString(
          'cos(x) = x',
          variable: 'x',
          method: SolvingMethod.bisection,
          options: const SolverOptions(intervalLower: 0.0, intervalUpper: 1.0),
        );
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        final root = (sol.roots.first.value as DecimalValue).toDouble();
        expect(root, closeTo(0.7390851332, 1e-5));
      });

      test('Secant: cos(x) = x with starting points 0.0 and 1.0', () {
        final res = solver.solveString(
          'cos(x) = x',
          variable: 'x',
          method: SolvingMethod.secant,
          options: const SolverOptions(intervalLower: 0.0, intervalUpper: 1.0),
        );
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        final root = (sol.roots.first.value as DecimalValue).toDouble();
        expect(root, closeTo(0.7390851332, 1e-6));
      });

      test(
        'Auto method on transcendental equation chooses numerical solver',
        () {
          final res = solver.solveString('exp(x) - 3x = 0', variable: 'x');
          expect(res.isSuccess, isTrue);
          final sol = res.valueOrNull!;
          expect(sol.solutionType, equals(SolutionType.approximate));
        },
      );

      test('Micro-Audit A1: Newton-Raphson on f(x) = x^2 with x0 = 0 recognizes root despite f\'(0)=0', () {
        final res = solver.solveString(
          'x^2 = 0',
          variable: 'x',
          method: SolvingMethod.newtonRaphson,
          options: const SolverOptions(initialGuess: 0.0),
        );
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.hasSolution, isTrue);
        expect(sol.roots.length, equals(1));
        final rootVal = (sol.roots.first.value as DecimalValue).toDouble();
        expect(rootVal.abs(), closeTo(0.0, 1e-10));
      });

      test('Final Gate A: Newton-Raphson on f(x) = x^3 - 3x + 1 with stationary x0 = 1 returns noSolution with message', () {
        final res = solver.solveString(
          'x^3 - 3x + 1 = 0',
          variable: 'x',
          method: SolvingMethod.newtonRaphson,
          options: const SolverOptions(initialGuess: 1.0),
        );
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.noSolution));
        expect(sol.roots, isEmpty);
        expect(sol.message, contains('horizontal tangent'));
      });

      test('Final Gate B: Near-threshold Cardano discriminant perturbation Δ ~ 1e-12', () {
        // q = 2.0 + 1e-11 => Delta slightly positive (~1.1e-8) -> 1 real + 2 complex
        final resPos = solver.solveString(
          'x^3 - 3x + 2.00000000001 = 0',
          variable: 'x',
          options: const SolverOptions(includeComplex: true),
        );
        expect(resPos.isSuccess, isTrue);
        final solPos = resPos.valueOrNull!;
        expect(solPos.roots.length, equals(3));
        expect(solPos.complexRoots.length, equals(2));

        // q = 2.0 - 1e-8 => Delta negative (~ -1e-8) -> 3 distinct real roots (casus irreducibilis)
        final resNeg = solver.solveString(
          'x^3 - 3x + 1.99999999 = 0',
          variable: 'x',
          options: const SolverOptions(includeComplex: false),
        );
        expect(resNeg.isSuccess, isTrue);
        final solNeg = resNeg.valueOrNull!;
        expect(solNeg.roots.length, equals(3));
        expect(solNeg.complexRoots, isEmpty);

        // Within threshold region |Δ| <= 1e-12 (repeated-root branch)
        final resThreshold = solver.solveString(
          'x^3 - 3x + 2.00000000000001 = 0',
          variable: 'x',
          options: const SolverOptions(includeComplex: true),
        );
        expect(resThreshold.isSuccess, isTrue);
        final solThresh = resThreshold.valueOrNull!;
        expect(
          solThresh.roots.length,
          equals(2),
        ); // Repeated root branch returns 2 distinct values (mult 1 and 2)
      });

      test(
        'Cardano variable scaling characterization under substitution x = k*y',
        () {
          // Base cubic: x^3 - 3x + 1 = 0 has 3 distinct real roots in [-2, 2]
          // Base solution:
          final resBase = solver.solveString('x^3 - 3x + 1 = 0', variable: 'x');
          expect(resBase.isSuccess, isTrue);
          final solBase = resBase.valueOrNull!;
          expect(solBase.roots.length, equals(3));

          // Under variable scaling x = 2*y (k = 2):
          // (2y)^3 - 3(2y) + 1 = 0 => 8y^3 - 6y + 1 = 0
          final resScaled = solver.solveString(
            '8y^3 - 6y + 1 = 0',
            variable: 'y',
          );
          expect(resScaled.isSuccess, isTrue);
          final solScaled = resScaled.valueOrNull!;
          expect(solScaled.roots.length, equals(3));

          // Map roots back: x_mapped = 2 * y
          final mappedRoots =
              solScaled.roots
                  .map((r) => ((r.value as DecimalValue).toDouble()) * 2.0)
                  .toList()
                ..sort();
          final baseRoots =
              solBase.roots
                  .map((r) => (r.value as DecimalValue).toDouble())
                  .toList()
                ..sort();

          for (var i = 0; i < 3; i++) {
            expect(mappedRoots[i], closeTo(baseRoots[i], 1e-6));
          }
        },
      );

      test(
        'Cardano severe variable scaling limitation characterization (k = 10)',
        () {
          // Base cubic with small negative discriminant:
          // x^3 - 3x + 1.99999999 = 0
          // In standard scale (k = 1), Delta ~ -1e-8 (< -1e-12), which is outside the
          // threshold region and resolves to 3 distinct real roots.
          final resBase = solver.solveString(
            'x^3 - 3x + 1.99999999 = 0',
            variable: 'x',
            options: const SolverOptions(includeComplex: false),
          );
          expect(resBase.isSuccess, isTrue);
          final solBase = resBase.valueOrNull!;
          expect(solBase.roots.length, equals(3));

          // Under moderate-to-severe coordinate scaling x = 10 * y (k = 10):
          // Transformed equation: (10y)^3 - 3(10y) + 1.99999999 = 0
          // => 1000 y^3 - 30 y + 1.99999999 = 0.
          // Because Delta(y) = k^-6 * Delta(x) = 10^-6 * (-1e-8) = -1e-14.
          // The scaled discriminant |-1e-14| <= 1e-12 falls directly inside the
          // implementation's fixed absolute repeated-root threshold (|Delta| <= 1e-12).
          final resScaled = solver.solveString(
            '1000y^3 - 30y + 1.99999999 = 0',
            variable: 'y',
            options: const SolverOptions(includeComplex: false),
          );
          expect(resScaled.isSuccess, isTrue);
          final solScaled = resScaled.valueOrNull!;

          // Documented limitation characterization:
          // Because Delta(y) has contracted from -1e-8 to -1e-14 (|Delta| <= 1e-12),
          // the solver switches branch from 3 distinct roots (casus irreducibilis)
          // into the repeated-root branch (2 distinct root values: mult 1 and mult 2).
          // Both roots pass AST residual validation at this scale.
          expect(solScaled.roots.length, equals(2));
          expect(solScaled.roots.any((r) => r.multiplicity == 2), isTrue);
        },
      );
    });

    group('Linear Systems Solving', () {
      test('Unique 2x2 system: 2x + y = 5, x - y = 1 -> x = 2, y = 1', () {
        final a = Matrix.fromRows([
          [IntegerValue.fromInt(2), IntegerValue.one],
          [IntegerValue.one, IntegerValue.fromInt(-1)],
        ]);
        final b = [IntegerValue.fromInt(5), IntegerValue.one];

        final res = solver.solveLinearSystem(
          a: a,
          b: b,
          variables: ['x', 'y'],
          enableTrace: true,
        );

        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.exact));
        expect(sol.assignment!['x'], equals(IntegerValue.fromInt(2)));
        expect(sol.assignment!['y'], equals(IntegerValue.one));
        expect(sol.trace, isNotNull);
      });

      test('Inconsistent 2x2 system: x + y = 2, x + y = 3 -> noSolution', () {
        final a = Matrix.fromRows([
          [IntegerValue.one, IntegerValue.one],
          [IntegerValue.one, IntegerValue.one],
        ]);
        final b = [IntegerValue.fromInt(2), IntegerValue.fromInt(3)];

        final res = solver.solveLinearSystem(a: a, b: b, variables: ['x', 'y']);

        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.noSolution));
      });

      test('Underdetermined 2x2 system: x + y = 2, 2x + 2y = 4 -> infiniteSolutions', () {
        final a = Matrix.fromRows([
          [IntegerValue.one, IntegerValue.one],
          [IntegerValue.fromInt(2), IntegerValue.fromInt(2)],
        ]);
        final b = [IntegerValue.fromInt(2), IntegerValue.fromInt(4)];

        final res = solver.solveLinearSystem(a: a, b: b, variables: ['x', 'y']);

        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.infiniteSolutions));
      });
    });

    group('Domain Safety & Extraneous Root Filtering', () {
      test('Original equation domain safety rejects invalid substitutions', () {
        // sqrt(x) = -1 has no real solution because sqrt(x) >= 0.
        // Squaring both sides yields x = 1, but sqrt(1) = 1 != -1.
        final res = solver.solveString('sqrt(x) = -1', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.noSolution));
      });

      test('Logarithmic domain boundary: ln(x) = 0 -> x = 1', () {
        final res = solver.solveString('ln(x) = 0', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        final r = (sol.roots.first.value as DecimalValue).toDouble();
        expect(r, closeTo(1.0, 1e-6));
      });

      test('Rational equation with denominator zero check: (x - 2) / (x - 2) = 0 -> noSolution', () {
        // x = 2 causes division by zero in the original equation
        final res = solver.solveString('(x - 2) / (x - 2) = 0', variable: 'x');
        expect(res.isSuccess, isTrue);
        final sol = res.valueOrNull!;
        expect(sol.solutionType, equals(SolutionType.noSolution));
      });
    });

    group('Convergence and Numerical Failures', () {
      test('Non-convergent configuration produces failure or noSolution rather than false success', () {
        // Solving with maxIterations: 1 on a distant starting point
        final res = solver.solveString(
          'cos(x) = x',
          variable: 'x',
          method: SolvingMethod.secant,
          options: const SolverOptions(
            maxIterations: 1,
            intervalLower: 100.0,
            intervalUpper: 200.0,
          ),
        );
        expect(res.isFailure, isTrue);
      });
    });
  });
}
