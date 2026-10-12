import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/mathematical_core.dart';

// Test implementation of MathValue for contract hierarchy verification
final class DummyScalar extends ScalarValue {
  const DummyScalar();
}

void main() {
  group('MathValue Hierarchy Contracts Tests', () {
    test('ScalarValue extends MathValue', () {
      const scalar = DummyScalar();
      expect(scalar, isA<ScalarValue>());
      expect(scalar, isA<MathValue>());
    });
  });
}
