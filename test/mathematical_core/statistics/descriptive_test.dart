import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/mathematical_core.dart';

void main() {
  group('Phase 9 — Descriptive Statistics Tests', () {
    late StatisticsEngine engine;

    setUp(() {
      engine = StatisticsEngine();
    });

    test('Empty dataset rejects operations requiring N >= 1 with InvalidArgumentError', () {
      final empty = Dataset.empty;

      expect(engine.count(empty), equals(IntegerValue.zero));

      final sumRes = engine.sum(empty);
      expect(sumRes.isSuccess, isTrue);
      expect(sumRes.valueOrNull, equals(IntegerValue.zero));

      final meanRes = engine.mean(empty);
      expect(meanRes.isFailure, isTrue);
      expect(meanRes.errorOrNull, isA<InvalidArgumentError>());

      final medRes = engine.median(empty);
      expect(medRes.isFailure, isTrue);
      expect(medRes.errorOrNull, isA<InvalidArgumentError>());

      final modeRes = engine.mode(empty);
      expect(modeRes.isFailure, isTrue);
      expect(modeRes.errorOrNull, isA<InvalidArgumentError>());

      final minRes = engine.min(empty);
      expect(minRes.isFailure, isTrue);
      expect(minRes.errorOrNull, isA<InvalidArgumentError>());

      final maxRes = engine.max(empty);
      expect(maxRes.isFailure, isTrue);
      expect(maxRes.errorOrNull, isA<InvalidArgumentError>());

      final rangeRes = engine.range(empty);
      expect(rangeRes.isFailure, isTrue);
      expect(rangeRes.errorOrNull, isA<InvalidArgumentError>());

      final popVarRes = engine.populationVariance(empty);
      expect(popVarRes.isFailure, isTrue);
      expect(popVarRes.errorOrNull, isA<InvalidArgumentError>());

      final smpVarRes = engine.sampleVariance(empty);
      expect(smpVarRes.isFailure, isTrue);
      expect(smpVarRes.errorOrNull, isA<InvalidArgumentError>());
    });

    test('Singleton dataset N = 1 yields exact trivial metrics and rejects sample variance', () {
      final ds = Dataset.fromInts([42]);

      expect(engine.count(ds), equals(IntegerValue.one));
      expect(engine.sum(ds).valueOrNull, equals(IntegerValue(BigInt.from(42))));
      expect(
        engine.mean(ds).valueOrNull,
        equals(IntegerValue(BigInt.from(42))),
      );
      expect(
        engine.median(ds).valueOrNull,
        equals(IntegerValue(BigInt.from(42))),
      );
      expect(
        engine.mode(ds).valueOrNull,
        equals([IntegerValue(BigInt.from(42))]),
      );
      expect(engine.min(ds).valueOrNull, equals(IntegerValue(BigInt.from(42))));
      expect(engine.max(ds).valueOrNull, equals(IntegerValue(BigInt.from(42))));
      expect(engine.range(ds).valueOrNull, equals(IntegerValue.zero));
      expect(
        engine.populationVariance(ds).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(
        engine.populationStandardDeviation(ds).valueOrNull,
        equals(IntegerValue.zero),
      );

      final smpVarRes = engine.sampleVariance(ds);
      expect(smpVarRes.isFailure, isTrue);
      expect(smpVarRes.errorOrNull, isA<InvalidArgumentError>());

      final smpStdRes = engine.sampleStandardDeviation(ds);
      expect(smpStdRes.isFailure, isTrue);
      expect(smpStdRes.errorOrNull, isA<InvalidArgumentError>());
    });

    group('NexaMath Mode Convention Tests', () {
      test('All identical values e.g. {5, 5, 5, 5} yields unique mode [5]', () {
        final ds = Dataset.fromInts([5, 5, 5, 5]);
        final res = engine.mode(ds);
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull, equals([IntegerValue.fromInt(5)]));
      });

      test(
        'All unique values e.g. {1, 2, 3, 4} yields empty list [] (no mode)',
        () {
          final ds = Dataset.fromInts([1, 2, 3, 4]);
          final res = engine.mode(ds);
          expect(res.isSuccess, isTrue);
          expect(res.valueOrNull, isEmpty);
        },
      );

      test('Multi-element identical-frequency tie across entire dataset e.g. {1, 1, 2, 2, 3, 3} yields []', () {
        final ds = Dataset.fromInts([1, 1, 2, 2, 3, 3]);
        final res = engine.mode(ds);
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull, isEmpty);
      });

      test('Unimodal dataset e.g. {1, 2, 2, 3} yields [2]', () {
        final ds = Dataset.fromInts([1, 2, 2, 3]);
        final res = engine.mode(ds);
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull, equals([IntegerValue.fromInt(2)]));
      });

      test('Multimodal dataset e.g. {1, 1, 2, 3, 3, 4} yields [1, 3] sorted ascending', () {
        final ds = Dataset.fromInts([3, 1, 4, 3, 2, 1]);
        final res = engine.mode(ds);
        expect(res.isSuccess, isTrue);
        expect(
          res.valueOrNull,
          equals([IntegerValue.fromInt(1), IntegerValue.fromInt(3)]),
        );
      });
    });

    group('Exact Rational Statistics Tests', () {
      test('Exact rational sample mean: {1, 2} -> FractionValue(3, 2)', () {
        final ds = Dataset.fromInts([1, 2]);
        final res = engine.mean(ds);
        expect(res.isSuccess, isTrue);
        expect(res.valueOrNull, equals(FractionValue.fromInts(3, 2)));
        expect(res.metadata.isExact, isTrue);
      });

      test(
        'Exact rational variance: {1, 2, 3, 4} popVar = 5/4, sampleVar = 5/3',
        () {
          final ds = Dataset.fromInts([1, 2, 3, 4]);
          final popVar = engine.populationVariance(ds);
          expect(popVar.isSuccess, isTrue);
          expect(popVar.valueOrNull, equals(FractionValue.fromInts(5, 4)));
          expect(popVar.metadata.isExact, isTrue);

          final smpVar = engine.sampleVariance(ds);
          expect(smpVar.isSuccess, isTrue);
          expect(smpVar.valueOrNull, equals(FractionValue.fromInts(5, 3)));
          expect(smpVar.metadata.isExact, isTrue);
        },
      );

      test(
        'Exact standard deviation for perfect rational square variances',
        () {
          // Dataset with population variance = 1/4: {-0.5, 0.5} -> mean = 0, sumSq = 0.25 + 0.25 = 0.5, popVar = 0.5 / 2 = 1/4
          final ds = Dataset([
            FractionValue.fromInts(-1, 2),
            FractionValue.fromInts(1, 2),
          ]);
          final popVar = engine.populationVariance(ds);
          expect(popVar.valueOrNull, equals(FractionValue.fromInts(1, 4)));

          final popStd = engine.populationStandardDeviation(ds);
          expect(popStd.isSuccess, isTrue);
          expect(popStd.valueOrNull, equals(FractionValue.fromInts(1, 2)));
          expect(popStd.metadata.isExact, isTrue);
        },
      );

      test(
        'Approximate standard deviation for non-perfect square variances',
        () {
          // Dataset {0, 2}: mean = 1, popVar = ((0-1)^2 + (2-1)^2) / 2 = 1 -> std = 1
          // Dataset {1, 3}: mean = 2, dev = -1, 1, sampleVar = (1 + 1)/1 = 2 -> sqrt(2) approx
          final ds = Dataset.fromInts([1, 3]);
          final smpStd = engine.sampleStandardDeviation(ds);
          expect(smpStd.isSuccess, isTrue);
          expect(smpStd.metadata.isExact, isFalse);
          final stdDbl = (smpStd.valueOrNull! as DecimalValue).toDouble();
          expect((stdDbl - 1.4142135623730951).abs(), lessThan(1e-12));
        },
      );
    });

    test('Descriptive aggregate model calculateAll populates all fields', () {
      final ds = Dataset.fromInts([2, 4, 4, 4, 5, 5, 7, 9]);
      final res = engine.descriptive(ds);
      expect(res.isSuccess, isTrue);
      final stats = res.valueOrNull!;

      expect(stats.count, equals(IntegerValue.fromInt(8)));
      expect(stats.min, equals(IntegerValue.fromInt(2)));
      expect(stats.max, equals(IntegerValue.fromInt(9)));
      expect(stats.range, equals(IntegerValue.fromInt(7)));
      expect(stats.modes, equals([IntegerValue.fromInt(4)]));
      expect(stats.sampleVariance, isNotNull);
      expect(stats.sampleStandardDeviation, isNotNull);
    });

    test('Dataset defensive copy prevents external mutation', () {
      final list = <ScalarValue>[
        IntegerValue.fromInt(1),
        IntegerValue.fromInt(2),
      ];
      final ds = Dataset(list);

      list.add(IntegerValue.fromInt(3));
      expect(ds.length, equals(2));
    });

    test('Exact rational standard deviation with large integer squares', () {
      // sigma^2 = (123456789 / 987654321)^2
      final numSquare = BigInt.from(123456789) * BigInt.from(123456789);
      final denSquare = BigInt.from(987654321) * BigInt.from(987654321);
      final fracVar = FractionValue(numSquare, denSquare);

      // Construct dataset with two points: mean = 0, x = -sqrt(fracVar), +sqrt(fracVar)
      final rootFrac = FractionValue(
        BigInt.from(123456789),
        BigInt.from(987654321),
      );
      final ds = Dataset([
        FractionValue(-rootFrac.numerator, rootFrac.denominator),
        rootFrac,
      ]);

      final popVar = engine.populationVariance(ds);
      expect(popVar.isSuccess, isTrue);
      expect(popVar.metadata.isExact, isTrue);
      expect(popVar.valueOrNull, equals(fracVar));

      final popStd = engine.populationStandardDeviation(ds);
      expect(popStd.isSuccess, isTrue);
      expect(popStd.metadata.isExact, isTrue);
      expect(popStd.valueOrNull, equals(rootFrac));
    });
  });
}
