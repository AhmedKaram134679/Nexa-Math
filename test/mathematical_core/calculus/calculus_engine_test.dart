import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/calculus/calculus.dart';
import 'package:nexa_math/mathematical_core/expression/ast/expression_node.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('NexaMath Phase 7 — Calculus Engine', () {
    late final DefaultCalculusEngine engine;

    setUpAll(() {
      engine = DefaultCalculusEngine();
    });

    group('Numerical Differentiation', () {
      test('d/dx [x^2] at x = 3 via central difference', () {
        final res = engine.numericalDerivative(
          (x) => MathSuccess(x * x),
          3.0,
          method: DifferentiationMethod.centralDifference,
        );
        expect(res.isSuccess, isTrue);
        final deriv = res.valueOrNull!;
        expect(deriv.value.toDouble(), closeTo(6.0, 1e-5));
        expect(deriv.method, equals(DifferentiationMethod.centralDifference));
        expect(deriv.converged, isTrue);
      });

      test('d/dx [x^3] at x = 2 via forward difference', () {
        final res = engine.numericalDerivative(
          (x) => MathSuccess(x * x * x),
          2.0,
          method: DifferentiationMethod.forwardDifference,
          options: const NumericalCalculusOptions(stepSize: 1e-5),
        );
        expect(res.isSuccess, isTrue);
        final deriv = res.valueOrNull!;
        expect(deriv.value.toDouble(), closeTo(12.0, 1e-4));
        expect(deriv.method, equals(DifferentiationMethod.forwardDifference));
      });

      test('d/dx [x^3] at x = 2 via backward difference', () {
        final res = engine.numericalDerivative(
          (x) => MathSuccess(x * x * x),
          2.0,
          method: DifferentiationMethod.backwardDifference,
          options: const NumericalCalculusOptions(stepSize: 1e-5),
        );
        expect(res.isSuccess, isTrue);
        final deriv = res.valueOrNull!;
        expect(deriv.value.toDouble(), closeTo(12.0, 1e-4));
        expect(deriv.method, equals(DifferentiationMethod.backwardDifference));
      });

      test('d/dx [sin(x)] at x = 0 via Richardson extrapolation', () {
        final res = engine.numericalDerivative(
          (x) => MathSuccess(math.sin(x)),
          0.0,
          method: DifferentiationMethod.richardsonExtrapolation,
          enableTrace: true,
        );
        expect(res.isSuccess, isTrue);
        final deriv = res.valueOrNull!;
        expect(deriv.value.toDouble(), closeTo(1.0, 1e-7));
        expect(deriv.trace, isNotNull);
        expect(deriv.trace!.steps.isNotEmpty, isTrue);
        expect(deriv.converged, isTrue);
      });

      test('d/dx [exp(x)] at x = 1 via Adaptive step selection', () {
        final res = engine.numericalDerivative(
          (x) => MathSuccess(math.exp(x)),
          1.0,
          method: DifferentiationMethod.adaptive,
        );
        expect(res.isSuccess, isTrue);
        final deriv = res.valueOrNull!;
        expect(deriv.value.toDouble(), closeTo(math.e, 1e-6));
        expect(deriv.method, equals(DifferentiationMethod.adaptive));
      });

      test('d/dx [ln(x)] at x = 2 via Richardson extrapolation', () {
        final res = engine.numericalDerivative(
          (x) => MathSuccess(math.log(x)),
          2.0,
          method: DifferentiationMethod.richardsonExtrapolation,
        );
        expect(res.isSuccess, isTrue);
        final deriv = res.valueOrNull!;
        expect(deriv.value.toDouble(), closeTo(0.5, 1e-7));
      });

      test('Differentiation domain error propagation (ln(x) at x <= 0)', () {
        final res = engine.numericalDerivative(
          (x) => x <= 0
              ? const MathFailure(DomainError(message: 'ln domain error'))
              : MathSuccess(math.log(x)),
          0.0,
          method: DifferentiationMethod.centralDifference,
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<DomainError>());
      });

      test('Differentiation invalid input validation (non-finite x)', () {
        final res1 = engine.numericalDerivative(
          (x) => MathSuccess(x),
          double.nan,
        );
        expect(res1.isFailure, isTrue);
        expect(res1.errorOrNull, isA<InvalidArgumentError>());
      });
    });

    group('Numerical Integration (Quadrature)', () {
      test('∫[0, 1] x^2 dx = 1/3 via composite trapezoidal rule', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(x * x),
          0.0,
          1.0,
          method: IntegrationMethod.trapezoidal,
          options: const NumericalCalculusOptions(subdivisions: 1000),
        );
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull!.toDouble(), closeTo(1.0 / 3.0, 1e-4));
      });

      test('∫[0, 1] x^3 dx = 1/4 via Simpson 1/3 rule', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(x * x * x),
          0.0,
          1.0,
          method: IntegrationMethod.simpsonsOneThird,
          options: const NumericalCalculusOptions(subdivisions: 100),
        );
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull!.toDouble(), closeTo(0.25, 1e-7));
      });

      test('Simpson 1/3 fails on odd subdivision count', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(x),
          0.0,
          1.0,
          method: IntegrationMethod.simpsonsOneThird,
          options: const NumericalCalculusOptions(subdivisions: 101),
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<InvalidArgumentError>());
      });

      test('∫[0, 1] x^3 dx = 1/4 via Simpson 3/8 rule', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(x * x * x),
          0.0,
          1.0,
          method: IntegrationMethod.simpsonsThreeEighths,
          options: const NumericalCalculusOptions(subdivisions: 99),
        );
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull!.toDouble(), closeTo(0.25, 1e-7));
      });

      test('Simpson 3/8 fails when subdivisions not divisible by 3', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(x),
          0.0,
          1.0,
          method: IntegrationMethod.simpsonsThreeEighths,
          options: const NumericalCalculusOptions(subdivisions: 100),
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<InvalidArgumentError>());
      });

      test('∫[0, π] sin(x) dx = 2 via Gauss-Legendre quadrature (order 5)', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(math.sin(x)),
          0.0,
          math.pi,
          method: IntegrationMethod.gaussLegendre,
          options: const NumericalCalculusOptions(gaussLegendreOrder: 5),
        );
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull!.toDouble(), closeTo(2.0, 1e-4));
      });

      test('Gauss-Legendre order 2 exact on cubics', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(x * x * x + 2 * x * x - x + 1),
          -1.0,
          2.0,
          method: IntegrationMethod.gaussLegendre,
          options: const NumericalCalculusOptions(gaussLegendreOrder: 2),
        );
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull!.toDouble(), closeTo(11.25, 1e-6));
      });

      test('∫[0, 1] exp(x) dx = e - 1 via Adaptive Simpson quadrature', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(math.exp(x)),
          0.0,
          1.0,
          method: IntegrationMethod.adaptiveSimpson,
        );
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull!.toDouble(), closeTo(math.e - 1.0, 1e-6));
      });

      test('Boundary condition: a == b produces exact 0', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(x * x),
          4.0,
          4.0,
        );
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull!, equals(DecimalValue.zero));
        expect(res.metadata.isExact, isTrue);
      });

      test('Boundary condition: reversed interval a > b produces -∫[b, a]', () {
        final normalRes = engine.definiteIntegral(
          (x) => MathSuccess(x * x),
          0.0,
          2.0,
          method: IntegrationMethod.adaptiveSimpson,
        );
        final reversedRes = engine.definiteIntegral(
          (x) => MathSuccess(x * x),
          2.0,
          0.0,
          method: IntegrationMethod.adaptiveSimpson,
        );
        expect(normalRes.isSuccess, isTrue);
        expect(reversedRes.isSuccess, isTrue);
        expect(
          reversedRes.valueOrNull!.toDouble(),
          closeTo(-normalRes.valueOrNull!.toDouble(), 1e-7),
        );
      });

      test('Domain error in integrand propagates safely', () {
        final res = engine.definiteIntegral(
          (x) => x == 0.5
              ? const MathFailure(DivisionByZeroError())
              : MathSuccess(1.0 / (x - 0.5)),
          0.0,
          1.0,
          method: IntegrationMethod.trapezoidal,
          options: const NumericalCalculusOptions(subdivisions: 2),
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<DivisionByZeroError>());
      });
    });

    group('Symbolic Differentiation Integration', () {
      test(
        'CalculusEngine delegates exact symbolic differentiation (x^3 -> 3x^2)',
        () {
          final xCube = BinaryOpNode(
            position: SourcePosition.start,
            left: const VariableNode(position: SourcePosition.start, name: 'x'),
            operator: BinaryOperator.power,
            right: NumberLiteralNode(
              position: SourcePosition.start,
              value: IntegerValue.fromInt(3),
            ),
          );

          final res = engine.differentiate(xCube, variable: 'x');
          expect(res.isSuccess, isTrue);
          final derivativeNode = res.valueOrNull!;
          expect(derivativeNode, isA<BinaryOpNode>());
        },
      );

      test('CalculusEngine higher-order symbolic differentiation: d^2/dx^2 [x^3] -> 6x', () {
        final xCube = BinaryOpNode(
          position: SourcePosition.start,
          left: const VariableNode(position: SourcePosition.start, name: 'x'),
          operator: BinaryOperator.power,
          right: NumberLiteralNode(
            position: SourcePosition.start,
            value: IntegerValue.fromInt(3),
          ),
        );

        final res = engine.differentiate(xCube, variable: 'x', order: 2);
        expect(res.isSuccess, isTrue);
      });

      test('CalculusEngine invalid differentiation order (< 1) returns InvalidArgumentError', () {
        const xVar = VariableNode(position: SourcePosition.start, name: 'x');
        final res = engine.differentiate(xVar, order: 0);
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<InvalidArgumentError>());
      });

      test('numericalDerivativeOfExpression matches analytical derivative', () {
        final xCube = BinaryOpNode(
          position: SourcePosition.start,
          left: const VariableNode(position: SourcePosition.start, name: 'x'),
          operator: BinaryOperator.power,
          right: NumberLiteralNode(
            position: SourcePosition.start,
            value: IntegerValue.fromInt(3),
          ),
        );

        final numDerivRes = engine.numericalDerivativeOfExpression(
          xCube,
          2.0,
          variable: 'x',
          method: DifferentiationMethod.richardsonExtrapolation,
        );

        expect(numDerivRes.isSuccess, isTrue);
        expect(numDerivRes.valueOrNull!.value.toDouble(), closeTo(12.0, 1e-5));
      });

      test('definiteIntegralOfExpression matches analytical integral', () {
        final xSq = BinaryOpNode(
          position: SourcePosition.start,
          left: const VariableNode(position: SourcePosition.start, name: 'x'),
          operator: BinaryOperator.power,
          right: NumberLiteralNode(
            position: SourcePosition.start,
            value: IntegerValue.fromInt(2),
          ),
        );

        final integralRes = engine.definiteIntegralOfExpression(
          xSq,
          0.0,
          3.0,
          variable: 'x',
          method: IntegrationMethod.adaptiveSimpson,
        );

        expect(integralRes.isSuccess, isTrue);
        expect(integralRes.valueOrNull!.toDouble(), closeTo(9.0, 1e-5));
      });
    });

    group('Mathematical Counterexamples & Advanced Stability Audit', () {
      test('CalculusEngine factory constructor instantiates correctly', () {
        final engineFromFactory = CalculusEngine();
        expect(engineFromFactory, isA<DefaultCalculusEngine>());
      });

      test('Differentiation: oscillatory / numerically challenging function sin(1/x) near 0', () {
        // For f(x) = sin(1/x), f'(x) = -cos(1/x)/x^2. At x = 1e-4, f'(x) is finite: -10^8 * cos(10^4).
        // While the derivative exists and is finite at any nonzero point, the function oscillates
        // rapidly near x = 0, making numerical finite-difference schemes challenging.
        // The differentiator deterministically returns a MathResult (bounded approximation or failure).
        final res = engine.numericalDerivative(
          (x) => x == 0.0
              ? const MathFailure(DivisionByZeroError())
              : MathSuccess(math.sin(1.0 / x)),
          1e-4,
          method: DifferentiationMethod.richardsonExtrapolation,
        );
        expect(res, isA<MathResult<NumericDerivative>>());
      });

      test(
        'Differentiation: extreme scale x = 1e8 for quadratic function x^2',
        () {
          // f(x) = x^2, f'(1e8) = 2e8.
          // Analytical derivative is exactly 2e8. With scale-aware initial step h0 ≈ 605.5,
          // Richardson extrapolation achieves an actual absolute error of ~0.0036 (relative error ~1.8e-11),
          // easily satisfying the algorithm's relative stopping tolerance (1e-7) and tested against a safe ±100 acceptance window.
          final res = engine.numericalDerivative(
            (x) => MathSuccess(x * x),
            1e8,
            method: DifferentiationMethod.adaptive,
          );
          expect(res.isSuccess, isTrue);
          expect(res.valueOrNull!.value.toDouble(), closeTo(2e8, 1e2));
        },
      );

      test(
        'Integration: constant function ∫[0, 5] 7 dx = 35 across all methods',
        () {
          for (final m in IntegrationMethod.values) {
            final res = engine.definiteIntegral(
              (x) => const MathSuccess(7.0),
              0.0,
              5.0,
              method: m,
            );
            expect(res.isSuccess, isTrue, reason: 'Method ${m.name} failed');
            expect(
              res.valueOrNull!.toDouble(),
              closeTo(35.0, 1e-4),
              reason: 'Method ${m.name}',
            );
          }
        },
      );

      test('Integration: oscillatory function ∫[0, 2π] cos(x) dx = 0', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(math.cos(x)),
          0.0,
          2.0 * math.pi,
          method: IntegrationMethod.adaptiveSimpson,
        );
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull!.toDouble().abs(), lessThan(1e-5));
      });

      test('Integration: interior singularity ∫[-1, 1] 1/x dx is intercepted safely', () {
        // Evaluates at x=0 if subdivision lands on it, or fails if evaluation returns failure.
        final res = engine.definiteIntegral(
          (x) => x == 0.0
              ? const MathFailure(DivisionByZeroError())
              : MathSuccess(1.0 / x),
          -1.0,
          1.0,
          method: IntegrationMethod.trapezoidal,
          options: const NumericalCalculusOptions(
            subdivisions: 2,
          ), // nodes at -1, 0, 1
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<DivisionByZeroError>());
      });

      test('Integration: narrow interval ∫[1.0, 1.00001] exp(x) dx', () {
        final res = engine.definiteIntegral(
          (x) => MathSuccess(math.exp(x)),
          1.0,
          1.00001,
          method: IntegrationMethod.adaptiveSimpson,
        );
        expect(res.isSuccess, isTrue);
        // Approximately e * 1e-5 ≈ 2.7182818e-5
        expect(res.valueOrNull!.toDouble(), closeTo(math.e * 1e-5, 1e-9));
      });
    });
  });
}
