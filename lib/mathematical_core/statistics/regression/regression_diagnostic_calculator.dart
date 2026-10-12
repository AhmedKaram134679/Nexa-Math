import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/core/result/math_warning.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';

/// Internal diagnostic result holding original-space regression diagnostics.
final class DiagnosticSums {
  final double sse;
  final double sst;
  final double rSquared;
  final List<MathWarning> warnings;

  const DiagnosticSums({
    required this.sse,
    required this.sst,
    required this.rSquared,
    required this.warnings,
  });
}

/// Regression diagnostic calculator.
///
/// Implements original response-space prediction residuals, SSE, SST, and the exhaustive 4-case
/// non-nullable $R^2$ contract:
/// 1. SST == 0, SSE == 0 -> R^2 = 1.0 + NearZeroWarning('...constant response perfectly fitted')
/// 2. SST == 0, SSE > 0  -> R^2 = 0.0 + NearZeroWarning('...model residuals are non-zero')
/// 3. SST > 0,  SSE == 0 -> R^2 = 1.0 (no warning)
/// 4. SST > 0,  SSE > 0  -> R^2 = 1 - SSE / SST (unclamped, can be negative)
final class RegressionDiagnosticCalculator {
  final PrecisionContext context;

  const RegressionDiagnosticCalculator({
    this.context = PrecisionContext.standard,
  });

  /// Evaluates the 4-case $R^2$ matrix given precomputed SSE and SST values.
  MathResult<DiagnosticSums> calculateRSquared({
    required double sse,
    required double sst,
  }) {
    final zeroTol = context.zeroTolerance;
    final isSstZero = sst.abs() <= zeroTol;
    final isSseZero = sse.abs() <= zeroTol;

    double r2;
    final warnings = <MathWarning>[];

    if (isSstZero && isSseZero) {
      // Case 1: Constant response perfectly fitted
      r2 = 1.0;
      warnings.add(
        const NearZeroWarning(
          message: 'Total sum of squares (SST) is zero; constant response perfectly fitted.',
        ),
      );
    } else if (isSstZero && !isSseZero) {
      // Case 2: Non-fitting model on constant data
      r2 = 0.0;
      warnings.add(
        const NearZeroWarning(
          message: 'Total sum of squares (SST) is zero; model residuals are non-zero.',
        ),
      );
    } else if (!isSstZero && isSseZero) {
      // Case 3: Exact interpolation with response variation
      r2 = 1.0;
    } else {
      // Case 4: General regression fit
      r2 = 1.0 - (sse / sst);
    }

    return MathSuccess(
      DiagnosticSums(sse: sse, sst: sst, rSquared: r2, warnings: warnings),
      metadata: CalculationMetadata(isExact: false, warnings: warnings),
    );
  }

  /// Calculates complete original-space diagnostics given observed $y$ and predicted $\hat{y}$.
  DiagnosticSums evaluateDiagnostics(List<double> yObs, List<double> yPred) {
    assert(yObs.length == yPred.length);
    final n = yObs.length;

    double sumY = 0.0;
    for (var i = 0; i < n; i++) {
      sumY += yObs[i];
    }
    final meanY = sumY / n;

    double sst = 0.0;
    double sse = 0.0;
    for (var i = 0; i < n; i++) {
      final dev = yObs[i] - meanY;
      sst += dev * dev;

      final res = yObs[i] - yPred[i];
      sse += res * res;
    }

    final diagRes = calculateRSquared(sse: sse, sst: sst);
    return diagRes.valueOrNull!;
  }
}
