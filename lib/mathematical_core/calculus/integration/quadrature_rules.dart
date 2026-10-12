/// High-precision, numerically honest quadrature methods for numerical integration.
library;

import '../../../core/errors/math_error.dart';
import '../../../core/result/calculation_metadata.dart';
import '../../../core/result/math_result.dart';
import '../../numeric/values/decimal_value.dart';
import '../differentiation/numerical_differentiator.dart';
import '../models/calculus_options.dart';
import '../models/calculus_trace.dart';

/// Implements composite and adaptive quadrature rules.
final class QuadratureRules {
  /// Evaluates definite integral ∫[a, b] f(x) dx using the specified [method].
  MathResult<DecimalValue> integrate({
    required RealFunction f,
    required double a,
    required double b,
    IntegrationMethod method = IntegrationMethod.adaptiveSimpson,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
    CalculusTrace? outTrace,
  }) {
    if (a.isNaN || a.isInfinite) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'a',
          reason: 'Lower integration boundary must be a finite real number.',
        ),
      );
    }
    if (b.isNaN || b.isInfinite) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'b',
          reason: 'Upper integration boundary must be a finite real number.',
        ),
      );
    }

    // Boundary condition: equal boundaries
    if (a == b) {
      return MathSuccess(
        DecimalValue.zero,
        metadata: CalculationMetadata.exact,
      );
    }

    // Boundary condition: reversed boundaries ∫[a, b] = -∫[b, a]
    if (a > b) {
      final res = integrate(f: f, a: b, b: a, method: method, options: options);
      if (res.isFailure) return res;
      return MathSuccess(-res.valueOrNull!, metadata: res.metadata);
    }

    return switch (method) {
      IntegrationMethod.trapezoidal => _trapezoidal(f, a, b, options),
      IntegrationMethod.simpsonsOneThird => _simpsonsOneThird(f, a, b, options),
      IntegrationMethod.simpsonsThreeEighths => _simpsonsThreeEighths(
        f,
        a,
        b,
        options,
      ),
      IntegrationMethod.gaussLegendre => _gaussLegendre(f, a, b, options),
      IntegrationMethod.adaptiveSimpson => _adaptiveSimpson(f, a, b, options),
    };
  }

  /// Composite Trapezoidal Rule: ∫[a, b] f(x) dx ≈ h * [ (f(a) + f(b))/2 + ∑ f(a + i*h) ]
  MathResult<DecimalValue> _trapezoidal(
    RealFunction f,
    double a,
    double b,
    NumericalCalculusOptions options,
  ) {
    final n = options.subdivisions;
    if (n < 1) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'subdivisions',
          reason: 'Subdivisions must be at least 1.',
        ),
      );
    }

    final h = (b - a) / n;
    final faRes = f(a);
    if (faRes.isFailure) return MathFailure(faRes.errorOrNull!);
    final fbRes = f(b);
    if (fbRes.isFailure) return MathFailure(fbRes.errorOrNull!);

    final fa = faRes.valueOrNull!;
    final fb = fbRes.valueOrNull!;
    if (fa.isNaN || fa.isInfinite || fb.isNaN || fb.isInfinite) {
      return const MathFailure(
        DomainError(
          message: 'Non-finite integrand evaluation at integration boundary.',
        ),
      );
    }

    double sum = 0.5 * (fa + fb);
    for (int i = 1; i < n; i++) {
      final xi = a + i * h;
      final fxiRes = f(xi);
      if (fxiRes.isFailure) return MathFailure(fxiRes.errorOrNull!);
      final fxi = fxiRes.valueOrNull!;
      if (fxi.isNaN || fxi.isInfinite) {
        return MathFailure(
          DomainError(message: 'Non-finite integrand evaluation at x = $xi.'),
        );
      }
      sum += fxi;
    }

    final result = sum * h;
    return MathSuccess(
      DecimalValue.parse(result.toString(), isExact: false),
      metadata: const CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'trapezoidalRule',
          converged: true,
        ),
      ),
    );
  }

  /// Composite Simpson's 1/3 Rule: requires n even.
  MathResult<DecimalValue> _simpsonsOneThird(
    RealFunction f,
    double a,
    double b,
    NumericalCalculusOptions options,
  ) {
    final n = options.subdivisions;
    if (n < 2 || n % 2 != 0) {
      return MathFailure(
        InvalidArgumentError(
          argumentName: 'subdivisions',
          reason:
              'Simpson\'s 1/3 rule requires an even number of subdivisions (received $n).',
        ),
      );
    }

    final h = (b - a) / n;
    final faRes = f(a);
    if (faRes.isFailure) return MathFailure(faRes.errorOrNull!);
    final fbRes = f(b);
    if (fbRes.isFailure) return MathFailure(fbRes.errorOrNull!);

    final fa = faRes.valueOrNull!;
    final fb = fbRes.valueOrNull!;
    if (fa.isNaN || fa.isInfinite || fb.isNaN || fb.isInfinite) {
      return const MathFailure(
        DomainError(message: 'Non-finite integrand evaluation at boundary.'),
      );
    }

    double sumOdd = 0.0;
    double sumEven = 0.0;

    for (int i = 1; i < n; i++) {
      final xi = a + i * h;
      final fxiRes = f(xi);
      if (fxiRes.isFailure) return MathFailure(fxiRes.errorOrNull!);
      final fxi = fxiRes.valueOrNull!;
      if (fxi.isNaN || fxi.isInfinite) {
        return MathFailure(
          DomainError(message: 'Non-finite integrand evaluation at x = $xi.'),
        );
      }

      if (i % 2 == 1) {
        sumOdd += fxi;
      } else {
        sumEven += fxi;
      }
    }

    final result = (h / 3.0) * (fa + 4.0 * sumOdd + 2.0 * sumEven + fb);
    return MathSuccess(
      DecimalValue.parse(result.toString(), isExact: false),
      metadata: const CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'simpsonsOneThird',
          converged: true,
        ),
      ),
    );
  }

  /// Composite Simpson's 3/8 Rule: requires n % 3 == 0.
  MathResult<DecimalValue> _simpsonsThreeEighths(
    RealFunction f,
    double a,
    double b,
    NumericalCalculusOptions options,
  ) {
    final n = options.subdivisions;
    if (n < 3 || n % 3 != 0) {
      return MathFailure(
        InvalidArgumentError(
          argumentName: 'subdivisions',
          reason:
              'Simpson\'s 3/8 rule requires subdivisions to be a multiple of 3 (received $n).',
        ),
      );
    }

    final h = (b - a) / n;
    final faRes = f(a);
    if (faRes.isFailure) return MathFailure(faRes.errorOrNull!);
    final fbRes = f(b);
    if (fbRes.isFailure) return MathFailure(fbRes.errorOrNull!);

    final fa = faRes.valueOrNull!;
    final fb = fbRes.valueOrNull!;
    if (fa.isNaN || fa.isInfinite || fb.isNaN || fb.isInfinite) {
      return const MathFailure(
        DomainError(message: 'Non-finite integrand evaluation at boundary.'),
      );
    }

    double sum = fa + fb;
    for (int i = 1; i < n; i++) {
      final xi = a + i * h;
      final fxiRes = f(xi);
      if (fxiRes.isFailure) return MathFailure(fxiRes.errorOrNull!);
      final fxi = fxiRes.valueOrNull!;
      if (fxi.isNaN || fxi.isInfinite) {
        return MathFailure(
          DomainError(message: 'Non-finite integrand evaluation at x = $xi.'),
        );
      }

      if (i % 3 == 0) {
        sum += 2.0 * fxi;
      } else {
        sum += 3.0 * fxi;
      }
    }

    final result = (3.0 * h / 8.0) * sum;
    return MathSuccess(
      DecimalValue.parse(result.toString(), isExact: false),
      metadata: const CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'simpsonsThreeEighths',
          converged: true,
        ),
      ),
    );
  }

  /// Gauss-Legendre Quadrature for orders n ∈ {2, 3, 4, 5}.
  MathResult<DecimalValue> _gaussLegendre(
    RealFunction f,
    double a,
    double b,
    NumericalCalculusOptions options,
  ) {
    final order = options.gaussLegendreOrder;
    final (nodes, weights) = switch (order) {
      2 => (
        const [-0.57735026918962576451, 0.57735026918962576451],
        const [1.0, 1.0],
      ),
      3 => (
        const [-0.77459666924148337704, 0.0, 0.77459666924148337704],
        const [
          0.55555555555555555556,
          0.88888888888888888889,
          0.55555555555555555556,
        ],
      ),
      4 => (
        const [
          -0.86113631159405257522,
          -0.33998104358485626480,
          0.33998104358485626480,
          0.86113631159405257522,
        ],
        const [
          0.34785484513745385737,
          0.65214515486254614263,
          0.65214515486254614263,
          0.34785484513745385737,
        ],
      ),
      5 => (
        const [
          -0.90617984593866399280,
          -0.53846931010568309104,
          0.0,
          0.53846931010568309104,
          0.90617984593866399280,
        ],
        const [
          0.23692688505618908751,
          0.47862867049936646804,
          0.56888888888888888889,
          0.47862867049936646804,
          0.23692688505618908751,
        ],
      ),
      _ => throw StateError('Unsupported order'),
    };

    final mid = (b + a) / 2.0;
    final halfLength = (b - a) / 2.0;

    double sum = 0.0;
    for (int i = 0; i < nodes.length; i++) {
      final x = mid + halfLength * nodes[i];
      final fxRes = f(x);
      if (fxRes.isFailure) return MathFailure(fxRes.errorOrNull!);
      final fx = fxRes.valueOrNull!;
      if (fx.isNaN || fx.isInfinite) {
        return MathFailure(
          DomainError(
            message: 'Non-finite integrand evaluation at Gauss node x = $x.',
          ),
        );
      }
      sum += weights[i] * fx;
    }

    final result = halfLength * sum;
    return MathSuccess(
      DecimalValue.parse(result.toString(), isExact: false),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'gaussLegendreOrder$order',
          converged: true,
        ),
      ),
    );
  }

  /// Adaptive Simpson's Quadrature with recursive error estimation.
  MathResult<DecimalValue> _adaptiveSimpson(
    RealFunction f,
    double a,
    double b,
    NumericalCalculusOptions options,
  ) {
    final faRes = f(a);
    if (faRes.isFailure) return MathFailure(faRes.errorOrNull!);
    final fbRes = f(b);
    if (fbRes.isFailure) return MathFailure(fbRes.errorOrNull!);
    final m = (a + b) / 2.0;
    final fmRes = f(m);
    if (fmRes.isFailure) return MathFailure(fmRes.errorOrNull!);

    final fa = faRes.valueOrNull!;
    final fb = fbRes.valueOrNull!;
    final fm = fmRes.valueOrNull!;
    if (fa.isNaN ||
        fa.isInfinite ||
        fb.isNaN ||
        fb.isInfinite ||
        fm.isNaN ||
        fm.isInfinite) {
      return const MathFailure(
        DomainError(
          message: 'Non-finite integrand evaluation in initial Simpson step.',
        ),
      );
    }

    final initialSimpson = (b - a) / 6.0 * (fa + 4.0 * fm + fb);

    final result = _adaptiveSimpsonRecursive(
      f: f,
      a: a,
      b: b,
      fa: fa,
      fm: fm,
      fb: fb,
      whole: initialSimpson,
      tol: options.tolerance,
      depth: options.maxRecursionDepth,
    );

    if (result.isFailure) return MathFailure(result.errorOrNull!);
    return MathSuccess(
      DecimalValue.parse(result.valueOrNull!.toString(), isExact: false),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'adaptiveSimpson',
          converged: true,
          relativeError: options.tolerance,
        ),
      ),
    );
  }

  MathResult<double> _adaptiveSimpsonRecursive({
    required RealFunction f,
    required double a,
    required double b,
    required double fa,
    required double fm,
    required double fb,
    required double whole,
    required double tol,
    required int depth,
  }) {
    final m = (a + b) / 2.0;
    final lm = (a + m) / 2.0;
    final rm = (m + b) / 2.0;

    final flmRes = f(lm);
    if (flmRes.isFailure) return flmRes;
    final frmRes = f(rm);
    if (frmRes.isFailure) return frmRes;

    final flm = flmRes.valueOrNull!;
    final frm = frmRes.valueOrNull!;
    if (flm.isNaN || flm.isInfinite || frm.isNaN || frm.isInfinite) {
      return const MathFailure(
        DomainError(
          message:
              'Non-finite integrand evaluation during adaptive subdivision.',
        ),
      );
    }

    final left = (m - a) / 6.0 * (fa + 4.0 * flm + fm);
    final right = (b - m) / 6.0 * (fm + 4.0 * frm + fb);
    final delta = left + right - whole;

    if (delta.abs() <= 15.0 * tol) {
      return MathSuccess(left + right + delta / 15.0);
    }

    if (depth <= 0) {
      return MathFailure(
        ConvergenceFailureError(
          method: 'Adaptive Simpson Quadrature',
          iterations: depth,
          message: 'Adaptive quadrature reached maximum recursion depth without achieving target tolerance.',
        ),
      );
    }

    final leftRes = _adaptiveSimpsonRecursive(
      f: f,
      a: a,
      b: m,
      fa: fa,
      fm: flm,
      fb: fm,
      whole: left,
      tol: tol / 2.0,
      depth: depth - 1,
    );
    if (leftRes.isFailure) return leftRes;

    final rightRes = _adaptiveSimpsonRecursive(
      f: f,
      a: m,
      b: b,
      fa: fm,
      fm: frm,
      fb: fb,
      whole: right,
      tol: tol / 2.0,
      depth: depth - 1,
    );
    if (rightRes.isFailure) return rightRes;

    return MathSuccess(leftRes.valueOrNull! + rightRes.valueOrNull!);
  }
}
