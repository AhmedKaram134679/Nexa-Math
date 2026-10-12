import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/core.dart';

void main() {
  group('MathResult Contract Tests', () {
    test('MathSuccess stores value, isSuccess=true, and default metadata', () {
      const result = MathSuccess<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.value, equals(42));
      expect(result.valueOrNull, equals(42));
      expect(result.errorOrNull, isNull);
      expect(result.metadata.isExact, isFalse);
    });

    test('MathFailure stores error, isFailure=true', () {
      const error = DivisionByZeroError();
      const result = MathFailure<int>(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.error, equals(error));
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, equals(error));
    });

    test('fold() handles both branches properly', () {
      const success = MathSuccess<int>(10);
      final successValue = success.fold(
        onSuccess: (val, meta) => 'Value: $val',
        onFailure: (err, meta) => 'Error: ${err.code}',
      );
      expect(successValue, equals('Value: 10'));

      const failure = MathFailure<int>(OverflowError());
      final failureValue = failure.fold(
        onSuccess: (val, meta) => 'Value: $val',
        onFailure: (err, meta) => 'Error: ${err.code}',
      );
      expect(failureValue, equals('Error: OVERFLOW'));
    });

    test('map() transforms success and passes through failure', () {
      const success = MathSuccess<int>(5);
      final mappedSuccess = success.map((x) => x * 2);
      expect(mappedSuccess, equals(const MathSuccess<int>(10)));

      const failure = MathFailure<int>(UnderflowError());
      final mappedFailure = failure.map((x) => x * 2);
      expect(mappedFailure, equals(const MathFailure<int>(UnderflowError())));
    });

    test('flatMap() chains dependent fallible operations', () {
      MathResult<int> safeDivide(int a, int b) {
        if (b == 0) return const MathFailure(DivisionByZeroError());
        return MathSuccess(a ~/ b);
      }

      final res1 = safeDivide(10, 2).flatMap((v) => safeDivide(v, 0));
      expect(res1.isFailure, isTrue);
      expect(res1.errorOrNull, isA<DivisionByZeroError>());

      final res2 = safeDivide(10, 2).flatMap((v) => safeDivide(v, 2));
      expect(res2.isSuccess, isTrue);
      expect(res2.valueOrNull, equals(2));
    });
  });
}
