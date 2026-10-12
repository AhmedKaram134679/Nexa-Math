import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/core.dart';

void main() {
  group('CalculationMetadata and MathWarning Tests', () {
    test('exact and approximate metadata configurations', () {
      expect(CalculationMetadata.exact.isExact, isTrue);
      expect(CalculationMetadata.approximate.isExact, isFalse);

      const approxMeta = ApproximationMetadata(
        method: 'newtonRaphson',
        precision: 16,
        converged: true,
        absoluteError: 1e-12,
        relativeError: 1e-14,
      );

      const metadata = CalculationMetadata(
        isExact: false,
        approximation: approxMeta,
        warnings: [PrecisionLossWarning(), NumericalApproximationWarning()],
      );

      expect(metadata.isExact, isFalse);
      expect(metadata.approximation?.method, equals('newtonRaphson'));
      expect(metadata.approximation?.precision, equals(16));
      expect(metadata.warnings.length, equals(2));
      expect(metadata.warnings.first, isA<PrecisionLossWarning>());
    });

    test('warnings preserve codes and messages', () {
      final warnings = <MathWarning>[
        const PrecisionLossWarning(),
        const NearZeroWarning(),
        const NumericalApproximationWarning(),
        const ConvergenceWarning(),
        const UnitConversionWarning(),
        const GenericMathWarning(
          code: 'CUSTOM_WARN',
          message: 'Custom warning',
        ),
      ];

      for (final warning in warnings) {
        expect(warning.code, isNotEmpty);
        expect(warning.message, isNotEmpty);
      }
    });
  });
}
