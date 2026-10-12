import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/mathematical_core.dart';
import 'package:nexa_math/mathematical_core/statistics/bivariate/bivariate_calculator.dart';

void main() {
  group('Phase 9 — Bivariate Statistics & Correlation Tests', () {
    late StatisticsEngine engine;

    setUp(() {
      engine = StatisticsEngine();
    });

    test('PairedDataset dimension mismatch throws or returns DimensionMismatchError', () {
      final x = Dataset.fromInts([1, 2, 3]);
      final y = Dataset.fromInts([1, 2]);

      expect(() => PairedDataset(x, y), throwsArgumentError);

      final res = PairedDataset.create(x, y);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<DimensionMismatchError>());
    });

    test('Singleton paired dataset N = 1 yields popCov = 0 and rejects sampleCov with InvalidArgumentError', () {
      final pRes = PairedDataset.create(
        Dataset.fromInts([5]),
        Dataset.fromInts([10]),
      );
      expect(pRes.isSuccess, isTrue);
      final p = pRes.valueOrNull!;

      final popCov = engine.populationCovariance(p);
      expect(popCov.isSuccess, isTrue);
      expect(popCov.valueOrNull, equals(IntegerValue.zero));

      final smpCov = engine.sampleCovariance(p);
      expect(smpCov.isFailure, isTrue);
      expect(smpCov.errorOrNull, isA<InvalidArgumentError>());
    });

    test('Exact rational covariance on exact integer inputs', () {
      // X = {1, 2, 3}, Y = {2, 4, 7}
      // meanX = 2, meanY = 13/3
      // dx = {-1, 0, 1}, dy = {-7/3, -1/3, 8/3}
      // sumProd = 7/3 + 0 + 8/3 = 15/3 = 5
      // popCov = 5 / 3 (exact FractionValue)
      // smpCov = 5 / 2 (exact FractionValue)
      final p = PairedDataset.create(
        Dataset.fromInts([1, 2, 3]),
        Dataset.fromInts([2, 4, 7]),
      ).valueOrNull!;

      final popCov = engine.populationCovariance(p);
      expect(popCov.isSuccess, isTrue);
      expect(popCov.valueOrNull, equals(FractionValue.fromInts(5, 3)));
      expect(popCov.metadata.isExact, isTrue);

      final smpCov = engine.sampleCovariance(p);
      expect(smpCov.isSuccess, isTrue);
      expect(smpCov.valueOrNull, equals(FractionValue.fromInts(5, 2)));
      expect(smpCov.metadata.isExact, isTrue);
    });

    test('Perfect positive and negative Pearson correlation', () {
      final posP = PairedDataset.create(
        Dataset.fromInts([1, 2, 3, 4]),
        Dataset.fromInts([2, 4, 6, 8]),
      ).valueOrNull!;

      final posR = engine.pearsonCorrelation(posP);
      expect(posR.isSuccess, isTrue);
      final posDbl = (posR.valueOrNull!).toDouble();
      expect((posDbl - 1.0).abs(), lessThan(1e-12));

      final negP = PairedDataset.create(
        Dataset.fromInts([1, 2, 3, 4]),
        Dataset.fromInts([8, 6, 4, 2]),
      ).valueOrNull!;

      final negR = engine.pearsonCorrelation(negP);
      expect(negR.isSuccess, isTrue);
      final negDbl = (negR.valueOrNull!).toDouble();
      expect((negDbl - (-1.0)).abs(), lessThan(1e-12));
    });

    test('Orthogonal data yields zero correlation', () {
      // X = {-1, 0, 1}, Y = {1, 0, 1}
      final p = PairedDataset.create(
        Dataset.fromInts([-1, 0, 1]),
        Dataset.fromInts([1, 0, 1]),
      ).valueOrNull!;

      final rRes = engine.pearsonCorrelation(p);
      expect(rRes.isSuccess, isTrue);
      expect(rRes.valueOrNull!.toDouble().abs(), lessThan(1e-12));
    });

    test('Zero variance in X or Y fails with DomainError', () {
      // Constant X
      final constX = PairedDataset.create(
        Dataset.fromInts([5, 5, 5]),
        Dataset.fromInts([1, 2, 3]),
      ).valueOrNull!;

      final resX = engine.pearsonCorrelation(constX);
      expect(resX.isFailure, isTrue);
      expect(resX.errorOrNull, isA<DomainError>());

      // Constant Y
      final constY = PairedDataset.create(
        Dataset.fromInts([1, 2, 3]),
        Dataset.fromInts([7, 7, 7]),
      ).valueOrNull!;

      final resY = engine.pearsonCorrelation(constY);
      expect(resY.isFailure, isTrue);
      expect(resY.errorOrNull, isA<DomainError>());
    });

    test('Comprehensive correlation result container', () {
      final p = PairedDataset.create(
        Dataset.fromInts([1, 2, 3]),
        Dataset.fromInts([1, 3, 2]),
      ).valueOrNull!;

      final res = engine.correlation(p);
      expect(res.isSuccess, isTrue);
      final corr = res.valueOrNull!;

      expect(corr.sampleCovariance, isNotNull);
      expect(corr.coefficient, isA<DecimalValue>());
    });

    test('Pearson correlation bounded clamping accepts round-off within zero tolerance', () {
      // Direct calculator testing with synthetic boundary
      const bivCalc = BivariateCalculator();
      final p = PairedDataset.create(
        Dataset.fromInts([1, 2, 3, 4, 5]),
        Dataset.fromInts([2, 4, 6, 8, 10]),
      ).valueOrNull!;

      final res = bivCalc.pearsonCorrelation(p);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull!.toDouble(), equals(1.0));
    });

    test('Pearson correlation with extreme magnitude inputs preserves exception containment', () {
      final pOverflow = PairedDataset.fromDoubles(
        [1e200, -1e200],
        [1e200, -1e200],
      ).valueOrNull!;

      final res = engine.pearsonCorrelation(pOverflow);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<PrecisionLossError>());
    });
  });
}
