import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/mathematical_core.dart';

void main() {
  group('Phase 9 — Quantile and Quartile Tests (Hyndman-Fan Type 7)', () {
    late StatisticsEngine engine;

    setUp(() {
      engine = StatisticsEngine();
    });

    test('Rejects empty dataset with InvalidArgumentError', () {
      final res = engine.percentile(Dataset.empty, IntegerValue.fromInt(50));
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<InvalidArgumentError>());
    });

    test(
      'Rejects out-of-bounds percentiles p < 0 and p > 100 with DomainError',
      () {
        final ds = Dataset.fromInts([1, 2, 3]);

        final under = engine.percentileNum(ds, -0.01);
        expect(under.isFailure, isTrue);
        expect(under.errorOrNull, isA<DomainError>());

        final over = engine.percentileNum(ds, 100.01);
        expect(over.isFailure, isTrue);
        expect(over.errorOrNull, isA<DomainError>());
      },
    );

    test(
      'Singleton dataset N = 1 yields identical value for any p in [0, 100]',
      () {
        final ds = Dataset.fromInts([17]);

        final p0 = engine.percentileNum(ds, 0);
        final p50 = engine.percentileNum(ds, 50);
        final p100 = engine.percentileNum(ds, 100);

        expect(p0.valueOrNull!.value, equals(IntegerValue.fromInt(17)));
        expect(p50.valueOrNull!.value, equals(IntegerValue.fromInt(17)));
        expect(p100.valueOrNull!.value, equals(IntegerValue.fromInt(17)));
      },
    );

    test('Boundary invariants: P_0 is min and P_100 is max', () {
      final ds = Dataset.fromInts([10, 5, 20, 15]);

      final p0 = engine.percentileNum(ds, 0);
      final p100 = engine.percentileNum(ds, 100);

      expect(p0.valueOrNull!.value, equals(IntegerValue.fromInt(5)));
      expect(p100.valueOrNull!.value, equals(IntegerValue.fromInt(20)));
    });

    test(
      'Reference Type 7: Dataset {1, 2, 3, 4, 5} yields Q1=2, Median=3, Q3=4',
      () {
        final ds = Dataset.fromInts([1, 2, 3, 4, 5]);

        final qRes = engine.quartiles(ds);
        expect(qRes.isSuccess, isTrue);
        final q = qRes.valueOrNull!;

        expect(q.q0, equals(IntegerValue.fromInt(1)));
        expect(q.q1, equals(IntegerValue.fromInt(2)));
        expect(q.q2, equals(IntegerValue.fromInt(3)));
        expect(q.q3, equals(IntegerValue.fromInt(4)));
        expect(q.q4, equals(IntegerValue.fromInt(5)));
        expect(q.iqr, equals(IntegerValue.fromInt(2)));
      },
    );

    test('Reference Type 7 exact interpolation: Dataset {10, 20, 30, 40} p=25 -> 17.5 (35/2)', () {
      // N = 4, p = 25 -> q = 0.25, h = 3 * 0.25 + 1 = 1.75
      // k = 1, f = 0.75 -> P_25 = 10 + 0.75 * (20 - 10) = 17.5 = 35/2
      final ds = Dataset.fromInts([10, 20, 30, 40]);
      final res = engine.percentile(ds, IntegerValue.fromInt(25));

      expect(res.isSuccess, isTrue);
      expect(res.metadata.isExact, isTrue);
      expect(res.valueOrNull!.value, equals(FractionValue.fromInts(35, 2)));
      expect(
        res.valueOrNull!.rank,
        equals(FractionValue.fromInts(7, 4)),
      ); // 1.75
    });

    test('Median invariant: Q2 under Type 7 equals sample median across odd and even datasets', () {
      final oddDs = Dataset.fromInts([9, 2, 5, 1, 7]);
      final evenDs = Dataset.fromInts([1, 2, 3, 4, 5, 6]);

      final medOdd = engine.median(oddDs).valueOrNull!;
      final qOdd = engine.quartiles(oddDs).valueOrNull!;
      expect(qOdd.q2, equals(medOdd));

      final medEven = engine.median(evenDs).valueOrNull!;
      final qEven = engine.quartiles(evenDs).valueOrNull!;
      expect(qEven.q2, equals(medEven));
    });

    test('Approximate path used when percentile parameter or dataset is approximate', () {
      final ds = Dataset.fromDoubles([1.0, 2.0, 3.0, 4.0]);
      final res = engine.percentile(
        ds,
        DecimalValue.parse('25.0', isExact: false),
      );

      expect(res.isSuccess, isTrue);
      expect(res.metadata.isExact, isFalse);
      final valDbl = (res.valueOrNull!.value as DecimalValue).toDouble();
      expect((valDbl - 1.75).abs(), lessThan(1e-12));
    });
  });
}
