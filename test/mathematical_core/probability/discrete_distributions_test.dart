import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/binomial_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/geometric_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/poisson_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_numeric_helper.dart';

void main() {
  group('BinomialDistribution', () {
    test('parameter validation and discrete classification', () {
      final bin = BinomialDistribution.create(
        trials: IntegerValue.fromInt(10),
        probability: FractionValue.half,
      ).valueOrNull!;

      expect(bin.name, equals('BinomialDistribution'));
      expect(bin.isDiscrete, isTrue);
      expect(bin.isContinuous, isFalse);

      final negTrials = BinomialDistribution.create(
        trials: IntegerValue.fromInt(-5),
        probability: FractionValue.half,
      );
      expect(negTrials, isA<MathFailure>());

      final invalidP = BinomialDistribution.create(
        trials: IntegerValue.fromInt(5),
        probability: DecimalValue.parse('1.5', isExact: false),
      );
      expect(invalidP, isA<MathFailure>());
    });

    test('exact rational moments and PMF for Bin(4, 1/2)', () {
      final bin = BinomialDistribution.create(
        trials: IntegerValue.fromInt(4),
        probability: FractionValue.half,
      ).valueOrNull!;

      final m = bin.mean.valueOrNull!;
      expect(ProbabilityNumericHelper.toDouble(m).valueOrNull, equals(2.0));

      final v = bin.variance.valueOrNull!;
      expect(ProbabilityNumericHelper.toDouble(v).valueOrNull, equals(1.0));

      final pmf2 = bin.pmf(IntegerValue.fromInt(2)).valueOrNull!;
      expect(pmf2, isA<FractionValue>());
      expect((pmf2 as FractionValue).numerator, equals(BigInt.from(3)));
      expect(pmf2.denominator, equals(BigInt.from(8)));

      final pmf5 = bin.pmf(IntegerValue.fromInt(5)).valueOrNull!;
      expect(pmf5, equals(IntegerValue.zero));
    });

    test('degenerate cases n = 0, p = 0, p = 1', () {
      final bin0 = BinomialDistribution.create(
        trials: IntegerValue.zero,
        probability: FractionValue.half,
      ).valueOrNull!;
      expect(bin0.pmf(IntegerValue.zero).valueOrNull, equals(IntegerValue.one));
      expect(bin0.pmf(IntegerValue.one).valueOrNull, equals(IntegerValue.zero));

      final binP0 = BinomialDistribution.create(
        trials: IntegerValue.fromInt(5),
        probability: IntegerValue.zero,
      ).valueOrNull!;
      expect(
        binP0.pmf(IntegerValue.zero).valueOrNull,
        equals(IntegerValue.one),
      );
      expect(
        binP0.pmf(IntegerValue.one).valueOrNull,
        equals(IntegerValue.zero),
      );

      final binP1 = BinomialDistribution.create(
        trials: IntegerValue.fromInt(5),
        probability: IntegerValue.one,
      ).valueOrNull!;
      expect(
        binP1.pmf(IntegerValue.fromInt(5)).valueOrNull,
        equals(IntegerValue.one),
      );
      expect(
        binP1.pmf(IntegerValue.fromInt(4)).valueOrNull,
        equals(IntegerValue.zero),
      );
    });

    test('CDF and generalized inverse CDF', () {
      final bin = BinomialDistribution.create(
        trials: IntegerValue.fromInt(4),
        probability: FractionValue.half,
      ).valueOrNull!;

      expect(
        bin.cdf(IntegerValue.minusOne).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(
        bin.cdf(IntegerValue.fromInt(4)).valueOrNull,
        equals(IntegerValue.one),
      );

      expect(
        bin.inverseCdf(IntegerValue.zero).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(
        bin.inverseCdf(IntegerValue.one).valueOrNull,
        equals(IntegerValue.fromInt(4)),
      );

      final qMed = bin.inverseCdf(DecimalValue.half).valueOrNull!;
      expect(qMed, equals(IntegerValue.fromInt(2)));
    });
  });

  group('PoissonDistribution', () {
    test('parameter validation', () {
      final invalid = PoissonDistribution.create(lambda: IntegerValue.zero);
      expect(invalid, isA<MathFailure>());
      expect(
        (invalid as MathFailure).error,
        isA<InvalidDistributionParameterError>(),
      );
    });

    test('moments and PMF reference values for Pois(3)', () {
      final pois = PoissonDistribution.create(lambda: IntegerValue.fromInt(3))
          .valueOrNull!;

      expect(pois.mean.valueOrNull, equals(IntegerValue.fromInt(3)));
      expect(pois.variance.valueOrNull, equals(IntegerValue.fromInt(3)));

      final pmf0 = pois.pmf(IntegerValue.zero).valueOrNull!;
      final pmf0Dbl = ProbabilityNumericHelper.toDouble(pmf0).valueOrNull!;
      expect(pmf0Dbl, closeTo(0.049787068, 1e-6));

      final pmf2 = pois.pmf(IntegerValue.fromInt(2)).valueOrNull!;
      final pmf2Dbl = ProbabilityNumericHelper.toDouble(pmf2).valueOrNull!;
      expect(pmf2Dbl, closeTo(0.2240418, 1e-5));

      expect(
        pois.pmf(IntegerValue.minusOne).valueOrNull,
        equals(IntegerValue.zero),
      );
    });

    test('CDF and generalized inverse CDF', () {
      final pois = PoissonDistribution.create(lambda: IntegerValue.fromInt(2))
          .valueOrNull!;

      expect(
        pois.cdf(IntegerValue.minusOne).valueOrNull,
        equals(IntegerValue.zero),
      );

      final cdf0 = pois.cdf(IntegerValue.zero).valueOrNull!;
      final cdf0Dbl = ProbabilityNumericHelper.toDouble(cdf0).valueOrNull!;
      expect(cdf0Dbl, closeTo(0.135335, 1e-5));

      expect(
        pois.inverseCdf(IntegerValue.zero).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(pois.inverseCdf(IntegerValue.one), isA<MathFailure>());

      // Quantile correctness: CDF(Q(p)) >= p and CDF(Q(p) - 1) < p
      for (final p in [0.01, 0.1, 0.3, 0.5, 0.7, 0.9, 0.99]) {
        final qRes = pois
            .inverseCdf(DecimalValue.parse(p.toString(), isExact: false))
            .valueOrNull!;
        expect(qRes, isA<IntegerValue>());
        final qInt = (qRes as IntegerValue).value.toInt();

        final cdfQRes = pois.cdf(IntegerValue.fromInt(qInt)).valueOrNull!;
        final cdfQ = ProbabilityNumericHelper.toDouble(cdfQRes).valueOrNull!;
        expect(cdfQ >= p, isTrue);

        if (qInt > 0) {
          final cdfPrevRes = pois
              .cdf(IntegerValue.fromInt(qInt - 1))
              .valueOrNull!;
          final cdfPrev = ProbabilityNumericHelper.toDouble(cdfPrevRes)
              .valueOrNull!;
          expect(cdfPrev < p, isTrue);
        }
      }
    });

    test(
      'Poisson large lambda and high probability bounded search (ISS-10-02)',
      () {
        // Large lambda = 10000
        final largePois = PoissonDistribution.create(
          lambda: IntegerValue.fromInt(10000),
        ).valueOrNull!;

        // Probabilities close to 1: 0.9999
        final qRes = largePois.inverseCdf(
          DecimalValue.parse('0.9999', isExact: false),
        );
        expect(qRes, isA<MathSuccess>());
        final qInt = (qRes.valueOrNull! as IntegerValue).value.toInt();
        // For Pois(10000), mean=10000, std=100. Q(0.9999) ~ 10000 + 3.719 * 100 ~ 10372
        expect(qInt, greaterThan(10300));
        expect(qInt, lessThan(10450));

        final cdfQ = ProbabilityNumericHelper.toDouble(
          largePois.cdf(IntegerValue.fromInt(qInt)).valueOrNull!,
        ).valueOrNull!;
        expect(cdfQ >= 0.9999, isTrue);

        final cdfPrev = ProbabilityNumericHelper.toDouble(
          largePois.cdf(IntegerValue.fromInt(qInt - 1)).valueOrNull!,
        ).valueOrNull!;
        expect(cdfPrev < 0.9999, isTrue);
      },
    );
  });

  group('GeometricDistribution', () {
    test('trials-until-first-success convention and parameter domain', () {
      final zeroP = GeometricDistribution.create(
        probability: IntegerValue.zero,
      );
      expect(zeroP, isA<MathFailure>());
      expect(
        (zeroP as MathFailure).error,
        isA<InvalidDistributionParameterError>(),
      );

      final geom = GeometricDistribution.create(probability: FractionValue.half)
          .valueOrNull!;
      expect(geom.name, equals('GeometricDistribution'));
      expect(geom.isDiscrete, isTrue);

      expect(
        geom.pmf(IntegerValue.zero).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(
        geom.cdf(IntegerValue.zero).valueOrNull,
        equals(IntegerValue.zero),
      );
    });

    test('exact rational moments and PMF for Geom(1/2)', () {
      final geom = GeometricDistribution.create(probability: FractionValue.half)
          .valueOrNull!;

      final m = geom.mean.valueOrNull!;
      expect(ProbabilityNumericHelper.toDouble(m).valueOrNull, equals(2.0));

      final v = geom.variance.valueOrNull!;
      expect(ProbabilityNumericHelper.toDouble(v).valueOrNull, equals(2.0));

      final pmf1 = geom.pmf(IntegerValue.one).valueOrNull!;
      expect(pmf1, isA<FractionValue>());
      expect(ProbabilityNumericHelper.toDouble(pmf1).valueOrNull, equals(0.5));

      final pmf2 = geom.pmf(IntegerValue.fromInt(2)).valueOrNull!;
      expect(pmf2, isA<FractionValue>());
      expect(ProbabilityNumericHelper.toDouble(pmf2).valueOrNull, equals(0.25));

      final cdf2 = geom.cdf(IntegerValue.fromInt(2)).valueOrNull!;
      expect(cdf2, isA<FractionValue>());
      expect(ProbabilityNumericHelper.toDouble(cdf2).valueOrNull, equals(0.75));
    });

    test('inverse CDF generalized quantile semantics', () {
      final geom = GeometricDistribution.create(probability: FractionValue.half)
          .valueOrNull!;

      expect(
        geom.inverseCdf(IntegerValue.zero).valueOrNull,
        equals(IntegerValue.one),
      );
      expect(geom.inverseCdf(IntegerValue.one), isA<MathFailure>());

      expect(
        geom.inverseCdf(DecimalValue.half).valueOrNull,
        equals(IntegerValue.one),
      );

      expect(
        geom.inverseCdf(DecimalValue.parse('0.51', isExact: false)).valueOrNull,
        equals(IntegerValue.fromInt(2)),
      );
    });
  });
}
