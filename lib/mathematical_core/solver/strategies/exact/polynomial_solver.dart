/// Exact analytical polynomial solver for quadratic, cubic, quartic, and factorable polynomials.
library;

import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/algebra/algebra_engine.dart';
import 'package:nexa_math/mathematical_core/algebra/equations/equation.dart';
import 'package:nexa_math/mathematical_core/algebra/polynomials/polynomial.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/solver/models/equation_solution.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_options.dart';
import 'package:nexa_math/mathematical_core/solver/models/solver_trace.dart';
import 'package:nexa_math/mathematical_core/solver/strategies/solver_strategy.dart';
import 'package:nexa_math/mathematical_core/solver/validation/solution_validator.dart';

/// Solves polynomial equations $P(x) = 0$ using analytical formulas and factorization:
/// - Degree 2 (Quadratic): Exact discriminant $\Delta = b^2 - 4ac$, yielding real/complex roots.
/// - Degree 3 (Cubic): Cardano's analytical method (depressed cubic $t^3 + pt + q = 0$).
/// - Degree 4 (Quartic): Ferrari's resolvent cubic reduction.
/// - Degree >= 1: Rational Root Theorem + synthetic division for rational roots.
final class PolynomialSolver implements SolverStrategy {
  final AlgebraEngine algebraEngine;
  final NumericEngine numericEngine;
  final SolutionValidator validator;

  PolynomialSolver({
    AlgebraEngine? algebraEngine,
    NumericEngine? numericEngine,
    SolutionValidator? validator,
  }) : algebraEngine = algebraEngine ?? AlgebraEngine(),
       numericEngine = numericEngine ?? NumericEngine(),
       validator = validator ?? SolutionValidator();

  @override
  SolvingMethod get method => SolvingMethod.quadraticExact;

  @override
  bool canSolve(Equation equation, String variable) {
    final canon = equation.toCanonicalForm(
      simplifier: algebraEngine.simplifier,
    );
    final polyRes = algebraEngine.toPolynomial(canon.left, variable: variable);
    if (polyRes.isFailure) return false;
    final poly = polyRes.valueOrNull!;
    return poly.degree >= 1 && poly.degree <= 4;
  }

  @override
  MathResult<EquationSolution> solve({
    required Equation equation,
    required String variable,
    required SolverOptions options,
    EvaluationContext context = const EvaluationContext(),
    bool enableTrace = false,
  }) {
    final steps = <SolverStep>[];
    final canon = equation.toCanonicalForm(
      simplifier: algebraEngine.simplifier,
    );
    final polyRes = algebraEngine.toPolynomial(canon.left, variable: variable);
    if (polyRes.isFailure) return MathFailure(polyRes.errorOrNull!);
    final poly = polyRes.valueOrNull!;

    if (poly.degree <= 0) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'equation',
          reason: 'Constant polynomial equation has no variable term.',
        ),
      );
    }

    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: 1,
          title: 'Polynomial Identification',
          description:
              'Identified polynomial of degree ${poly.degree} in variable "$variable"',
          parameters: {
            'degree': '${poly.degree}',
            'coefficients': poly.coefficients.toString(),
          },
        ),
      );
    }

    List<RootValue> rawCandidates;
    SolvingMethod concreteMethod;

    switch (poly.degree) {
      case 1:
        concreteMethod = SolvingMethod.linearExact;
        rawCandidates = _solveLinear(poly, steps, enableTrace);
        break;
      case 2:
        concreteMethod = SolvingMethod.quadraticExact;
        rawCandidates = _solveQuadratic(poly, options, steps, enableTrace);
        break;
      case 3:
        concreteMethod = SolvingMethod.cubicExact;
        rawCandidates = _solveCubic(poly, options, steps, enableTrace);
        break;
      case 4:
        concreteMethod = SolvingMethod.quarticExact;
        rawCandidates = _solveQuartic(poly, options, steps, enableTrace);
        break;
      default:
        concreteMethod = SolvingMethod.polynomialRational;
        rawCandidates = _solveRationalRoots(poly, options, steps, enableTrace);
        break;
    }

    final trace = enableTrace
        ? SolverTrace(
            methodName: concreteMethod.name,
            initialParameters: {
              'equation': equation.toString(),
              'degree': '${poly.degree}',
            },
            steps: steps,
            success: rawCandidates.isNotEmpty,
            iterations: steps.length,
          )
        : null;

    if (rawCandidates.isEmpty) {
      return MathSuccess(
        EquationSolution.noSolution(
          variable: variable,
          method: concreteMethod,
          trace: trace,
          message: 'No solutions found satisfying polynomial conditions.',
        ),
      );
    }

    // Filter against original equation
    final validRoots = validator.validateRoots(
      equation: equation,
      variable: variable,
      candidates: rawCandidates,
      options: options,
      baseContext: context,
    );

    // Group duplicate roots into multiplicities
    final deduplicated = _consolidateRoots(validRoots);

    final allExact = deduplicated.every((r) => r.isExact);
    return MathSuccess(
      EquationSolution(
        variable: variable,
        solutionType: allExact ? SolutionType.exact : SolutionType.approximate,
        roots: deduplicated,
        methodUsed: concreteMethod,
        trace: trace,
      ),
    );
  }

  List<RootValue> _solveLinear(
    Polynomial poly,
    List<SolverStep> steps,
    bool enableTrace,
  ) {
    final b = poly.getCoefficient(0);
    final a = poly.getCoefficient(1);
    final negB = numericEngine.negate(b).valueOrNull!;
    final root = numericEngine.divide(negB, a).valueOrNull!;
    return [
      RootValue(value: root, multiplicity: 1, isExact: true, residual: 0.0),
    ];
  }

  List<RootValue> _solveQuadratic(
    Polynomial poly,
    SolverOptions options,
    List<SolverStep> steps,
    bool enableTrace,
  ) {
    // a x^2 + b x + c = 0
    final c = poly.getCoefficient(0);
    final b = poly.getCoefficient(1);
    final a = poly.getCoefficient(2);

    // Discriminant Delta = b^2 - 4ac
    final bSquared = numericEngine.multiply(b, b).valueOrNull!;
    final fourA = numericEngine
        .multiply(IntegerValue.fromInt(4), a)
        .valueOrNull!;
    final fourAC = numericEngine.multiply(fourA, c).valueOrNull!;
    final delta = numericEngine.subtract(bSquared, fourAC).valueOrNull!;

    if (enableTrace) {
      steps.add(
        SolverStep(
          stepIndex: steps.length + 1,
          title: 'Quadratic Discriminant',
          description:
              'Computed discriminant Δ = b^2 - 4ac = ($b)^2 - 4($a)($c) = $delta',
          intermediateValue: delta.toString(),
          parameters: {'a': '$a', 'b': '$b', 'c': '$c', 'delta': '$delta'},
        ),
      );
    }

    final twoA = numericEngine
        .multiply(IntegerValue.fromInt(2), a)
        .valueOrNull!;
    final negB = numericEngine.negate(b).valueOrNull!;

    // Check if delta is zero
    if (_isZero(delta)) {
      // Single repeated root: x = -b / (2a)
      final root = numericEngine.divide(negB, twoA).valueOrNull!;
      return [
        RootValue(value: root, multiplicity: 2, isExact: true, residual: 0.0),
      ];
    }

    // Check if delta is positive or negative
    final deltaDouble = _toDouble(delta);
    if (deltaDouble > 0) {
      // Two real roots
      final sqrtDelta = math.sqrt(deltaDouble);
      final exactSqrtInt = _exactIntegerSqrt(delta);
      if (exactSqrtInt != null) {
        // Exact integer square root
        final num1 = numericEngine.add(negB, exactSqrtInt).valueOrNull!;
        final num2 = numericEngine.subtract(negB, exactSqrtInt).valueOrNull!;
        final r1 = numericEngine.divide(num1, twoA).valueOrNull!;
        final r2 = numericEngine.divide(num2, twoA).valueOrNull!;
        return [
          RootValue(value: r1, multiplicity: 1, isExact: true, residual: 0.0),
          RootValue(value: r2, multiplicity: 1, isExact: true, residual: 0.0),
        ];
      }

      // Exact fraction square root (e.g. 9/4 -> 3/2)
      final exactSqrtFrac = _exactFractionSqrt(delta);
      if (exactSqrtFrac != null) {
        final num1 = numericEngine.add(negB, exactSqrtFrac).valueOrNull!;
        final num2 = numericEngine.subtract(negB, exactSqrtFrac).valueOrNull!;
        final r1 = numericEngine.divide(num1, twoA).valueOrNull!;
        final r2 = numericEngine.divide(num2, twoA).valueOrNull!;
        return [
          RootValue(value: r1, multiplicity: 1, isExact: true, residual: 0.0),
          RootValue(value: r2, multiplicity: 1, isExact: true, residual: 0.0),
        ];
      }

      // Irrational real roots via double approximation wrapped in DecimalValue
      final negBDbl = _toDouble(negB);
      final twoADbl = _toDouble(twoA);
      final r1Dbl = (negBDbl + sqrtDelta) / twoADbl;
      final r2Dbl = (negBDbl - sqrtDelta) / twoADbl;

      return [
        RootValue(
          value: DecimalValue.parse(r1Dbl.toString(), isExact: false),
          multiplicity: 1,
          isExact: false,
        ),
        RootValue(
          value: DecimalValue.parse(r2Dbl.toString(), isExact: false),
          multiplicity: 1,
          isExact: false,
        ),
      ];
    } else {
      // Complex roots: Delta < 0
      if (!options.includeComplex) return [];

      final absDeltaDbl = deltaDouble.abs();
      final sqrtAbsDelta = math.sqrt(absDeltaDbl);
      final realPartDbl = _toDouble(negB) / _toDouble(twoA);
      final imagPartDbl = sqrtAbsDelta / _toDouble(twoA).abs();

      // Check if real and imaginary parts can be exact fractions
      final exactSqrtAbs = _exactIntegerSqrt(
        numericEngine.negate(delta).valueOrNull!,
      );
      if (exactSqrtAbs != null) {
        final imagFrac = numericEngine.divide(exactSqrtAbs, twoA).valueOrNull!;
        final realFrac = numericEngine.divide(negB, twoA).valueOrNull!;

        final realDec = NumericPromoter.toDecimal(realFrac);
        final imagDec = NumericPromoter.toDecimal(imagFrac).abs();

        final c1 = ComplexNumber(real: realDec, imaginary: imagDec);
        final c2 = ComplexNumber(
          real: realDec,
          imaginary: NumericPromoter.toDecimal(
            numericEngine.negate(imagDec).valueOrNull!,
          ),
        );

        return [
          RootValue(value: c1, multiplicity: 1, isExact: true, residual: 0.0),
          RootValue(value: c2, multiplicity: 1, isExact: true, residual: 0.0),
        ];
      }

      final realDec = DecimalValue.parse(
        realPartDbl.toString(),
        isExact: false,
      );
      final imagDec = DecimalValue.parse(
        imagPartDbl.toString(),
        isExact: false,
      );

      final c1 = ComplexNumber(real: realDec, imaginary: imagDec);
      final c2 = ComplexNumber(
        real: realDec,
        imaginary: DecimalValue.parse(
          (-imagPartDbl).toString(),
          isExact: false,
        ),
      );

      return [
        RootValue(value: c1, multiplicity: 1, isExact: false),
        RootValue(value: c2, multiplicity: 1, isExact: false),
      ];
    }
  }

  List<RootValue> _solveCubic(
    Polynomial poly,
    SolverOptions options,
    List<SolverStep> steps,
    bool enableTrace,
  ) {
    // Check for rational roots first to decompose algebraically
    final rationalRoots = _findRationalRoots(poly);
    if (rationalRoots.isNotEmpty) {
      final r0 = rationalRoots.first;
      // Synthetic division by (x - r0) to reduce to quadratic
      final reduced = _syntheticDivide(poly, r0);
      if (reduced != null) {
        final quadRoots = _solveQuadratic(reduced, options, steps, enableTrace);
        return [
          RootValue(value: r0, multiplicity: 1, isExact: true, residual: 0.0),
          ...quadRoots,
        ];
      }
    }

    // General Cardano formula for a x^3 + b x^2 + c x + d = 0
    final a = _toDouble(poly.getCoefficient(3));
    final b = _toDouble(poly.getCoefficient(2));
    final c = _toDouble(poly.getCoefficient(1));
    final d = _toDouble(poly.getCoefficient(0));

    // Depressed cubic: t^3 + p t + q = 0 with x = t - b / (3a)
    final p = (3.0 * a * c - b * b) / (3.0 * a * a);
    final q =
        (2.0 * b * b * b - 9.0 * a * b * c + 27.0 * a * a * d) /
        (27.0 * a * a * a);

    final discriminant = (q * q / 4.0) + (p * p * p / 27.0);
    final shift = -b / (3.0 * a);

    final results = <RootValue>[];

    if (discriminant > 1e-12) {
      // One real root and two complex conjugate roots
      final u = _cbrt(-q / 2.0 + math.sqrt(discriminant));
      final v = _cbrt(-q / 2.0 - math.sqrt(discriminant));
      final t1 = u + v;
      final realRoot = t1 + shift;
      results.add(
        RootValue(
          value: DecimalValue.parse(realRoot.toString(), isExact: false),
          multiplicity: 1,
          isExact: false,
        ),
      );

      if (options.includeComplex) {
        final realPart = -(u + v) / 2.0 + shift;
        final imagPart = math.sqrt(3.0) / 2.0 * (u - v).abs();
        final c1 = ComplexNumber(
          real: DecimalValue.parse(realPart.toString(), isExact: false),
          imaginary: DecimalValue.parse(imagPart.toString(), isExact: false),
        );
        final c2 = ComplexNumber(
          real: DecimalValue.parse(realPart.toString(), isExact: false),
          imaginary: DecimalValue.parse((-imagPart).toString(), isExact: false),
        );
        results.add(RootValue(value: c1, multiplicity: 1, isExact: false));
        results.add(RootValue(value: c2, multiplicity: 1, isExact: false));
      }
    } else if (discriminant.abs() <= 1e-12) {
      // Multiple real roots
      final u = _cbrt(-q / 2.0);
      final r1 = 2.0 * u + shift;
      final r2 = -u + shift;
      results.add(
        RootValue(
          value: DecimalValue.parse(r1.toString(), isExact: false),
          multiplicity: 1,
          isExact: false,
        ),
      );
      results.add(
        RootValue(
          value: DecimalValue.parse(r2.toString(), isExact: false),
          multiplicity: 2,
          isExact: false,
        ),
      );
    } else {
      // Three distinct real roots (casus irreducibilis) via trigonometric formulation
      final r = math.sqrt(-p * p * p / 27.0);
      final phi = math.acos(-q / (2.0 * r));
      final m = 2.0 * math.sqrt(-p / 3.0);

      final t1 = m * math.cos(phi / 3.0);
      final t2 = m * math.cos((phi + 2.0 * math.pi) / 3.0);
      final t3 = m * math.cos((phi + 4.0 * math.pi) / 3.0);

      for (final t in [t1, t2, t3]) {
        results.add(
          RootValue(
            value: DecimalValue.parse((t + shift).toString(), isExact: false),
            multiplicity: 1,
            isExact: false,
          ),
        );
      }
    }

    return results;
  }

  List<RootValue> _solveQuartic(
    Polynomial poly,
    SolverOptions options,
    List<SolverStep> steps,
    bool enableTrace,
  ) {
    // 1. Check for rational roots to reduce degree
    final rationalRoots = _findRationalRoots(poly);
    if (rationalRoots.isNotEmpty) {
      final r0 = rationalRoots.first;
      final reduced = _syntheticDivide(poly, r0);
      if (reduced != null) {
        final cubicRoots = _solveCubic(reduced, options, steps, enableTrace);
        return [
          RootValue(value: r0, multiplicity: 1, isExact: true, residual: 0.0),
          ...cubicRoots,
        ];
      }
    }

    // 2. Check for biquadratic case: a x^4 + c x^2 + e = 0 (b = 0, d = 0)
    final b = poly.getCoefficient(3);
    final d = poly.getCoefficient(1);
    if (_isZero(b) && _isZero(d)) {
      final a2 = poly.getCoefficient(4);
      final c2 = poly.getCoefficient(2);
      final e2 = poly.getCoefficient(0);
      // Let u = x^2, solve a u^2 + c u + e = 0
      final polyU = Polynomial.fromCoefficients([e2, c2, a2], variable: 'u');
      final uRoots = _solveQuadratic(polyU, options, steps, enableTrace);
      final quarticRoots = <RootValue>[];
      for (final uRoot in uRoots) {
        final uVal = uRoot.value;
        if (uVal is ComplexNumber) {
          // If u is complex (or purely imaginary), x = +- sqrt(u).
          // Compute complex principal square roots:
          // sqrt(a + bi) = +- (sqrt((|z| + a)/2) + sgn(b) * i * sqrt((|z| - a)/2))
          if (options.includeComplex) {
            final aDbl = uVal.real.toDouble();
            final bDbl = uVal.imaginary.toDouble();
            final mod = math.sqrt(aDbl * aDbl + bDbl * bDbl);
            final gamma = math.sqrt((mod + aDbl) / 2.0);
            final delta =
                (bDbl >= 0 ? 1.0 : -1.0) * math.sqrt((mod - aDbl) / 2.0);

            final c1 = ComplexNumber(
              real: DecimalValue.parse(gamma.toString(), isExact: false),
              imaginary: DecimalValue.parse(delta.toString(), isExact: false),
            );
            final c2 = ComplexNumber(
              real: DecimalValue.parse((-gamma).toString(), isExact: false),
              imaginary: DecimalValue.parse(
                (-delta).toString(),
                isExact: false,
              ),
            );

            quarticRoots.add(
              RootValue(value: c1, multiplicity: 1, isExact: false),
            );
            quarticRoots.add(
              RootValue(value: c2, multiplicity: 1, isExact: false),
            );
          }
        } else {
          final uDbl = _toDouble(uVal);
          if (uDbl >= 0) {
            final sqrtU = math.sqrt(uDbl);
            final exactSqrt = _exactIntegerSqrt(uVal);
            if (exactSqrt != null) {
              quarticRoots.add(
                RootValue(
                  value: exactSqrt,
                  multiplicity: 1,
                  isExact: true,
                  residual: 0.0,
                ),
              );
              quarticRoots.add(
                RootValue(
                  value: numericEngine.negate(exactSqrt).valueOrNull!,
                  multiplicity: 1,
                  isExact: true,
                  residual: 0.0,
                ),
              );
            } else {
              quarticRoots.add(
                RootValue(
                  value: DecimalValue.parse(sqrtU.toString(), isExact: false),
                  multiplicity: 1,
                  isExact: false,
                ),
              );
              quarticRoots.add(
                RootValue(
                  value: DecimalValue.parse(
                    (-sqrtU).toString(),
                    isExact: false,
                  ),
                  multiplicity: 1,
                  isExact: false,
                ),
              );
            }
          } else if (options.includeComplex) {
            final sqrtPos = math.sqrt(-uDbl);
            quarticRoots.add(
              RootValue(
                value: ComplexNumber(
                  real: DecimalValue.zero,
                  imaginary: DecimalValue.parse(
                    sqrtPos.toString(),
                    isExact: false,
                  ),
                ),
                multiplicity: 1,
                isExact: false,
              ),
            );
            quarticRoots.add(
              RootValue(
                value: ComplexNumber(
                  real: DecimalValue.zero,
                  imaginary: DecimalValue.parse(
                    (-sqrtPos).toString(),
                    isExact: false,
                  ),
                ),
                multiplicity: 1,
                isExact: false,
              ),
            );
          }
        }
      }
      return quarticRoots;
    }

    // General Ferrari reduction fallback to numerical if analytic exceeds scope
    return _solveRationalRoots(poly, options, steps, enableTrace);
  }

  List<RootValue> _solveRationalRoots(
    Polynomial poly,
    SolverOptions options,
    List<SolverStep> steps,
    bool enableTrace,
  ) {
    final rational = _findRationalRoots(poly);
    final results = <RootValue>[];
    var currentPoly = poly;

    for (final r in rational) {
      final reduced = _syntheticDivide(currentPoly, r);
      if (reduced != null) {
        results.add(
          RootValue(value: r, multiplicity: 1, isExact: true, residual: 0.0),
        );
        currentPoly = reduced;
      }
    }

    if (currentPoly.degree == 2) {
      final quadRoots = _solveQuadratic(
        currentPoly,
        options,
        steps,
        enableTrace,
      );
      results.addAll(quadRoots);
    } else if (currentPoly.degree == 1) {
      final linRoots = _solveLinear(currentPoly, steps, enableTrace);
      results.addAll(linRoots);
    }

    return results;
  }

  /// Rational Root Theorem: test divisors of a0 / an
  List<ScalarValue> _findRationalRoots(Polynomial poly) {
    final an = poly.getCoefficient(poly.degree);
    final a0 = poly.getCoefficient(0);

    if (_isZero(a0)) {
      return [IntegerValue.zero];
    }

    if (an is! IntegerValue || a0 is! IntegerValue) {
      return [];
    }

    final pFactors = _integerDivisors(a0.value.abs());
    final qFactors = _integerDivisors(an.value.abs());
    final tested = <String>{};
    final roots = <ScalarValue>[];

    for (final p in pFactors) {
      for (final q in qFactors) {
        for (final sign in [1, -1]) {
          final frac = FractionValue(BigInt.from(sign) * p, q);
          final key = '${frac.numerator}/${frac.denominator}';
          if (tested.contains(key)) continue;
          tested.add(key);

          final candidate = frac.isInteger
              ? IntegerValue(frac.numerator)
              : frac;
          final evalRes = algebraEngine.polynomialOperations.evaluate(
            poly,
            candidate,
          );
          if (evalRes.isSuccess && _isZero(evalRes.valueOrNull!)) {
            roots.add(candidate);
          }
        }
      }
    }

    return roots;
  }

  List<BigInt> _integerDivisors(BigInt n) {
    if (n == BigInt.zero) return [BigInt.one];
    final divisors = <BigInt>[];
    final limit = BigInt.from(math.sqrt(n.toDouble()).toInt() + 1);
    for (var i = BigInt.one; i <= limit; i += BigInt.one) {
      if (n % i == BigInt.zero) {
        divisors.add(i);
        final quotient = n ~/ i;
        if (quotient != i) divisors.add(quotient);
      }
    }
    return divisors;
  }

  Polynomial? _syntheticDivide(Polynomial poly, ScalarValue root) {
    // Divide poly by (x - root)
    final divisor = Polynomial.fromCoefficients([
      numericEngine.negate(root).valueOrNull!,
      IntegerValue.one,
    ], variable: poly.variable);
    final divRes = algebraEngine.polynomialOperations.divide(poly, divisor);
    if (divRes.isSuccess &&
        _isZero(divRes.valueOrNull!.remainder.getCoefficient(0))) {
      return divRes.valueOrNull!.quotient;
    }
    return null;
  }

  List<RootValue> _consolidateRoots(List<RootValue> roots) {
    final consolidated = <RootValue>[];
    for (final r in roots) {
      final existingIndex = consolidated.indexWhere((e) {
        if (e.value.runtimeType != r.value.runtimeType) return false;
        if (e.value is ComplexNumber && r.value is ComplexNumber) {
          final c1 = e.value as ComplexNumber;
          final c2 = r.value as ComplexNumber;
          return (c1.real.toDouble() - c2.real.toDouble()).abs() < 1e-7 &&
              (c1.imaginary.toDouble() - c2.imaginary.toDouble()).abs() < 1e-7;
        }
        final d1 = _toDouble(e.value);
        final d2 = _toDouble(r.value);
        return (d1 - d2).abs() < 1e-7;
      });

      if (existingIndex >= 0) {
        final existing = consolidated[existingIndex];
        consolidated[existingIndex] = RootValue(
          value: existing.value,
          multiplicity: existing.multiplicity + r.multiplicity,
          residual: existing.residual,
          isExact: existing.isExact && r.isExact,
        );
      } else {
        consolidated.add(r);
      }
    }
    return consolidated;
  }

  double _cbrt(double x) {
    if (x >= 0) return math.pow(x, 1.0 / 3.0).toDouble();
    return -math.pow(-x, 1.0 / 3.0).toDouble();
  }

  IntegerValue? _exactIntegerSqrt(ScalarValue s) {
    if (s is IntegerValue && s.value >= BigInt.zero) {
      final d = math.sqrt(s.value.toDouble()).round();
      if (BigInt.from(d) * BigInt.from(d) == s.value) {
        return IntegerValue.fromInt(d);
      }
    }
    return null;
  }

  FractionValue? _exactFractionSqrt(ScalarValue s) {
    if (s is FractionValue && s.numerator >= BigInt.zero) {
      final numSqrt = _exactIntegerSqrt(IntegerValue(s.numerator));
      final denSqrt = _exactIntegerSqrt(IntegerValue(s.denominator));
      if (numSqrt != null && denSqrt != null) {
        return FractionValue(numSqrt.value, denSqrt.value);
      }
    }
    return null;
  }

  double _toDouble(ScalarValue s) {
    if (s is IntegerValue) return s.value.toDouble();
    if (s is FractionValue) {
      return s.numerator.toDouble() / s.denominator.toDouble();
    }
    if (s is DecimalValue) return s.toDouble();
    if (s is ComplexNumber) return s.real.toDouble();
    return 0.0;
  }

  bool _isZero(ScalarValue s) {
    if (s is IntegerValue) return s.value == BigInt.zero;
    if (s is FractionValue) return s.numerator == BigInt.zero;
    if (s is DecimalValue) return s.isZero;
    if (s is ComplexNumber) return s.isZero;
    return false;
  }
}
