import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/core.dart';

void main() {
  group('Validation and Configuration Contracts Tests', () {
    test('ValidationResult valid and invalid states', () {
      const valid = ValidationResult.valid;
      expect(valid.isValid, isTrue);
      expect(valid.isInvalid, isFalse);

      final invalid = ValidationResult.invalid([
        const ValidationError(
          property: 'expression',
          technicalMessage: 'Cannot be empty',
        ),
      ]);
      expect(invalid.isValid, isFalse);
      expect(invalid.isInvalid, isTrue);
      expect(
        (invalid as ValidationInvalid).errors.first.property,
        equals('expression'),
      );
    });

    test('AppConfiguration and FeatureFlags defaults', () {
      const appConfig = AppConfiguration();
      expect(appConfig.applicationName, equals('NexaMath'));
      expect(appConfig.version, equals('1.0.0'));
      expect(appConfig.isDiagnosticsEnabled, isFalse);

      const flags = FeatureFlags();
      expect(flags.enableExtendedPrecision, isTrue);
      expect(flags.enableExperimentalEngines, isFalse);
    });
  });
}
