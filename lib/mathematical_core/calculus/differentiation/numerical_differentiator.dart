/// High-precision, numerically honest numerical differentiator.
library;

import 'dart:math' as math;

import '../../../core/errors/math_error.dart';
import '../../../core/result/calculation_metadata.dart';
import '../../../core/result/math_result.dart';
import '../../numeric/values/decimal_value.dart';
import '../models/calculus_options.dart';
import '../models/calculus_trace.dart';
import '../models/numeric_derivative.dart';

/// Signature for a real-valued scalar mathematical function evaluation.
///
/// Returns [MathResult<double>] representing f(x) or a typed failure (e.g. DomainError).
typedef RealFunction = MathResult<double> Function(double x);

/// Implements finite-difference schemes and Richardson extrapolation for numerical differentiation.
final class NumericalDifferentiator {
  /// Evaluates the numerical derivative of [f] at point [x] using the specified [options] and [method].
  MathResult<NumericDerivative> differentiate({
    required RealFunction f,
    required double x,
    NumericalCalculusOptions options = const NumericalCalculusOptions(),
    DifferentiationMethod method =
        DifferentiationMethod.richardsonExtrapolation,
    bool enableTrace = false,
  }) {
    if (x.isNaN || x.isInfinite) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'x',
          reason: 'Evaluation point x must be a finite real number.',
        ),
      );
    }
    if (options.stepSize <= 0 ||
        options.stepSize.isNaN ||
        options.stepSize.isInfinite) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'stepSize',
          reason: 'Step size must be a strictly positive finite real number.',
        ),
      );
    }

    return switch (method) {
      DifferentiationMethod.forwardDifference => _forwardDifference(
        f,
        x,
        options,
        enableTrace,
      ),
      DifferentiationMethod.backwardDifference => _backwardDifference(
        f,
        x,
        options,
        enableTrace,
      ),
      DifferentiationMethod.centralDifference => _centralDifference(
        f,
        x,
        options,
        enableTrace,
      ),
      DifferentiationMethod.richardsonExtrapolation => _richardsonExtrapolation(
        f,
        x,
        options,
        enableTrace,
      ),
      DifferentiationMethod.adaptive => _adaptiveDifferentiation(
        f,
        x,
        options,
        enableTrace,
      ),
    };
  }

  MathResult<NumericDerivative> _forwardDifference(
    RealFunction f,
    double x,
    NumericalCalculusOptions options,
    bool enableTrace,
  ) {
    final h = options.stepSize;
    final fxRes = f(x);
    if (fxRes.isFailure) return MathFailure(fxRes.errorOrNull!);
    final fxhRes = f(x + h);
    if (fxhRes.isFailure) return MathFailure(fxhRes.errorOrNull!);

    final fx = fxRes.valueOrNull!;
    final fxh = fxhRes.valueOrNull!;
    if (fx.isNaN || fx.isInfinite || fxh.isNaN || fxh.isInfinite) {
      return const MathFailure(
        DomainError(
          message: 'Non-finite function evaluation during forward difference.',
        ),
      );
    }

    final approx = (fxh - fx) / h;
    final steps = <CalculusStep>[];
    if (enableTrace) {
      steps.add(
        CalculusStep(
          stepIndex: 1,
          title: 'Forward Difference Quotient',
          description: 'Evaluated (f(x + h) - f(x)) / h with h = $h',
          intermediateValue: approx,
          parameters: {'f(x)': '$fx', 'f(x+h)': '$fxh', 'h': '$h'},
        ),
      );
    }

    final trace = enableTrace
        ? CalculusTrace(
            methodName: 'Forward Difference',
            initialParameters: {'x': '$x', 'h': '$h'},
            steps: steps,
            converged: true,
            functionEvaluations: 2,
          )
        : null;

    final approxDec = DecimalValue.parse(approx.toString(), isExact: false);
    final pointDec = DecimalValue.parse(x.toString(), isExact: false);

    return MathSuccess(
      NumericDerivative(
        value: approxDec,
        point: pointDec,
        method: DifferentiationMethod.forwardDifference,
        stepSize: h,
        converged: true,
        trace: trace,
      ),
      metadata: const CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'forwardDifference',
          converged: true,
        ),
      ),
    );
  }

  MathResult<NumericDerivative> _backwardDifference(
    RealFunction f,
    double x,
    NumericalCalculusOptions options,
    bool enableTrace,
  ) {
    final h = options.stepSize;
    final fxRes = f(x);
    if (fxRes.isFailure) return MathFailure(fxRes.errorOrNull!);
    final fxmhRes = f(x - h);
    if (fxmhRes.isFailure) return MathFailure(fxmhRes.errorOrNull!);

    final fx = fxRes.valueOrNull!;
    final fxmh = fxmhRes.valueOrNull!;
    if (fx.isNaN || fx.isInfinite || fxmh.isNaN || fxmh.isInfinite) {
      return const MathFailure(
        DomainError(
          message: 'Non-finite function evaluation during backward difference.',
        ),
      );
    }

    final approx = (fx - fxmh) / h;
    final steps = <CalculusStep>[];
    if (enableTrace) {
      steps.add(
        CalculusStep(
          stepIndex: 1,
          title: 'Backward Difference Quotient',
          description: 'Evaluated (f(x) - f(x - h)) / h with h = $h',
          intermediateValue: approx,
          parameters: {'f(x)': '$fx', 'f(x-h)': '$fxmh', 'h': '$h'},
        ),
      );
    }

    final trace = enableTrace
        ? CalculusTrace(
            methodName: 'Backward Difference',
            initialParameters: {'x': '$x', 'h': '$h'},
            steps: steps,
            converged: true,
            functionEvaluations: 2,
          )
        : null;

    final approxDec = DecimalValue.parse(approx.toString(), isExact: false);
    final pointDec = DecimalValue.parse(x.toString(), isExact: false);

    return MathSuccess(
      NumericDerivative(
        value: approxDec,
        point: pointDec,
        method: DifferentiationMethod.backwardDifference,
        stepSize: h,
        converged: true,
        trace: trace,
      ),
      metadata: const CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'backwardDifference',
          converged: true,
        ),
      ),
    );
  }

  MathResult<NumericDerivative> _centralDifference(
    RealFunction f,
    double x,
    NumericalCalculusOptions options,
    bool enableTrace,
  ) {
    final h = options.stepSize;
    final fxhRes = f(x + h);
    if (fxhRes.isFailure) return MathFailure(fxhRes.errorOrNull!);
    final fxmhRes = f(x - h);
    if (fxmhRes.isFailure) return MathFailure(fxmhRes.errorOrNull!);

    final fxh = fxhRes.valueOrNull!;
    final fxmh = fxmhRes.valueOrNull!;
    if (fxh.isNaN || fxh.isInfinite || fxmh.isNaN || fxmh.isInfinite) {
      return const MathFailure(
        DomainError(
          message: 'Non-finite function evaluation during central difference.',
        ),
      );
    }

    final approx = (fxh - fxmh) / (2.0 * h);
    final steps = <CalculusStep>[];
    if (enableTrace) {
      steps.add(
        CalculusStep(
          stepIndex: 1,
          title: 'Central Difference Quotient',
          description: 'Evaluated (f(x + h) - f(x - h)) / (2h) with h = $h',
          intermediateValue: approx,
          parameters: {'f(x+h)': '$fxh', 'f(x-h)': '$fxmh', 'h': '$h'},
        ),
      );
    }

    final trace = enableTrace
        ? CalculusTrace(
            methodName: 'Central Difference',
            initialParameters: {'x': '$x', 'h': '$h'},
            steps: steps,
            converged: true,
            functionEvaluations: 2,
          )
        : null;

    final approxDec = DecimalValue.parse(approx.toString(), isExact: false);
    final pointDec = DecimalValue.parse(x.toString(), isExact: false);

    return MathSuccess(
      NumericDerivative(
        value: approxDec,
        point: pointDec,
        method: DifferentiationMethod.centralDifference,
        stepSize: h,
        converged: true,
        trace: trace,
      ),
      metadata: const CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'centralDifference',
          converged: true,
        ),
      ),
    );
  }

  MathResult<NumericDerivative> _richardsonExtrapolation(
    RealFunction f,
    double x,
    NumericalCalculusOptions options,
    bool enableTrace,
  ) {
    final maxIt = math.min(options.maxIterations, 10);
    final dTable = List<List<double>>.generate(
      maxIt,
      (_) => List<double>.filled(maxIt, 0.0),
    );
    final steps = <CalculusStep>[];
    int fnEvals = 0;

    double h = options.stepSize;

    for (int i = 0; i < maxIt; i++) {
      final fxhRes = f(x + h);
      if (fxhRes.isFailure) return MathFailure(fxhRes.errorOrNull!);
      final fxmhRes = f(x - h);
      if (fxmhRes.isFailure) return MathFailure(fxmhRes.errorOrNull!);
      fnEvals += 2;

      final fxh = fxhRes.valueOrNull!;
      final fxmh = fxmhRes.valueOrNull!;
      if (fxh.isNaN || fxh.isInfinite || fxmh.isNaN || fxmh.isInfinite) {
        return const MathFailure(
          DomainError(
            message:
                'Non-finite function evaluation in Richardson extrapolation.',
          ),
        );
      }

      dTable[i][0] = (fxh - fxmh) / (2.0 * h);

      double factor = 4.0;
      for (int j = 1; j <= i; j++) {
        dTable[i][j] =
            dTable[i][j - 1] +
            (dTable[i][j - 1] - dTable[i - 1][j - 1]) / (factor - 1.0);
        factor *= 4.0;
      }

      final currentApprox = dTable[i][i];
      final double errorEst = (i > 0)
          ? (dTable[i][i] - dTable[i - 1][i - 1]).abs()
          : double.infinity;

      if (enableTrace) {
        steps.add(
          CalculusStep(
            stepIndex: i + 1,
            title: 'Richardson Order ${2 * (i + 1)}',
            description:
                'h = $h, approx = $currentApprox, errorEst = $errorEst',
            intermediateValue: currentApprox,
            estimatedError: errorEst.isFinite ? errorEst : null,
            parameters: {'h': '$h', 'diagonal': '$currentApprox'},
          ),
        );
      }

      final double tolThreshold = math.max(
        options.absoluteTolerance,
        options.tolerance * math.max(1.0, currentApprox.abs()),
      );

      if (i > 0 && errorEst <= tolThreshold) {
        final trace = enableTrace
            ? CalculusTrace(
                methodName: 'Richardson Extrapolation',
                initialParameters: {
                  'x': '$x',
                  'h0': '${options.stepSize}',
                  'tol': '${options.tolerance}',
                },
                steps: steps,
                converged: true,
                finalErrorEstimate: errorEst,
                functionEvaluations: fnEvals,
              )
            : null;

        final approxDec = DecimalValue.parse(
          currentApprox.toString(),
          isExact: false,
        );
        final pointDec = DecimalValue.parse(x.toString(), isExact: false);

        return MathSuccess(
          NumericDerivative(
            value: approxDec,
            point: pointDec,
            method: DifferentiationMethod.richardsonExtrapolation,
            stepSize: h,
            estimatedError: errorEst,
            converged: true,
            trace: trace,
          ),
          metadata: CalculationMetadata(
            isExact: false,
            approximation: ApproximationMetadata(
              method: 'richardsonExtrapolation',
              converged: true,
              absoluteError: errorEst,
            ),
          ),
        );
      }

      h /= 2.0;
    }

    final finalApprox = dTable[maxIt - 1][maxIt - 1];
    final finalError =
        (dTable[maxIt - 1][maxIt - 1] - dTable[maxIt - 2][maxIt - 2]).abs();

    final double finalTolThreshold = math.max(
      options.absoluteTolerance * 10,
      options.tolerance * 10 * math.max(1.0, finalApprox.abs()),
    );
    final converged = finalError <= finalTolThreshold;
    final trace = enableTrace
        ? CalculusTrace(
            methodName: 'Richardson Extrapolation',
            initialParameters: {'x': '$x', 'h0': '${options.stepSize}'},
            steps: steps,
            converged: converged,
            finalErrorEstimate: finalError,
            functionEvaluations: fnEvals,
          )
        : null;

    if (!converged) {
      return MathFailure(
        ConvergenceFailureError(
          method: 'Richardson Extrapolation',
          iterations: maxIt,
          message:
              'Derivative failed to converge within specified tolerance: error estimate $finalError.',
        ),
      );
    }

    final approxDec = DecimalValue.parse(
      finalApprox.toString(),
      isExact: false,
    );
    final pointDec = DecimalValue.parse(x.toString(), isExact: false);

    return MathSuccess(
      NumericDerivative(
        value: approxDec,
        point: pointDec,
        method: DifferentiationMethod.richardsonExtrapolation,
        stepSize: h * 2.0,
        estimatedError: finalError,
        converged: true,
        trace: trace,
      ),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'richardsonExtrapolation',
          converged: true,
          absoluteError: finalError,
        ),
      ),
    );
  }

  MathResult<NumericDerivative> _adaptiveDifferentiation(
    RealFunction f,
    double x,
    NumericalCalculusOptions options,
    bool enableTrace,
  ) {
    const double eps = 2.220446049250313e-16;
    final double scale = math.max(1.0, x.abs());
    final double optimalH = math.pow(eps, 1.0 / 3.0) * scale;
    final double initialH = (optimalH < 1e-12) ? 1e-6 : optimalH;

    final adaptiveOptions = NumericalCalculusOptions(
      stepSize: initialH,
      tolerance: options.tolerance,
      absoluteTolerance: options.absoluteTolerance,
      maxIterations: options.maxIterations,
    );

    final res = _richardsonExtrapolation(f, x, adaptiveOptions, enableTrace);
    if (res.isFailure) return res;

    final baseDeriv = res.valueOrNull!;
    return MathSuccess(
      NumericDerivative(
        value: baseDeriv.value,
        point: baseDeriv.point,
        method: DifferentiationMethod.adaptive,
        stepSize: baseDeriv.stepSize,
        estimatedError: baseDeriv.estimatedError,
        converged: baseDeriv.converged,
        trace: baseDeriv.trace,
      ),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          method: 'adaptiveDifferentiation',
          converged: true,
          absoluteError: baseDeriv.estimatedError,
        ),
      ),
    );
  }
}
