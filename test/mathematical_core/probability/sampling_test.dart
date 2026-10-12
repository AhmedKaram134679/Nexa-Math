import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/default_probability_engine.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/exponential_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/normal_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/uniform_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/binomial_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/geometric_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/poisson_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_engine.dart';
import 'package:nexa_math/mathematical_core/probability/sampling/standard_random_source.dart';

void main() {
  late ProbabilityEngine engine;
  late StandardRandomSource rng;

  setUp(() {
    engine = const DefaultProbabilityEngine();
    rng = StandardRandomSource(42); // Deterministic seed for reproducible tests
  });

  group('Distribution Sampling', () {
    test('Count validation', () {
      final std = NormalDistribution.standard();

      // Count <= 0 fails
      final zeroCount = engine.sample(std, 0, rng);
      expect(zeroCount, isA<MathFailure>());
      expect((zeroCount as MathFailure).error, isA<InvalidArgumentError>());

      // Excessive count fails
      final overLimit = engine.sample(std, 2000000, rng);
      expect(overLimit, isA<MathFailure>());
    });

    test('Normal sampling empirical moments', () {
      final norm = NormalDistribution.create(
        mean: IntegerValue.fromInt(10),
        standardDeviation: IntegerValue.fromInt(2),
      ).valueOrNull!;

      final sampleRes = engine.sample(norm, 5000, rng);
      expect(sampleRes, isA<MathSuccess>());
      final dataset = sampleRes.valueOrNull!;
      expect(dataset.length, equals(5000));

      final doubles = dataset.toDoubles();
      final empiricalMean = doubles.reduce((a, b) => a + b) / doubles.length;
      expect(empiricalMean, closeTo(10.0, 0.15));
    });

    test('Uniform sampling bounds compliance', () {
      final u = UniformDistribution.create(
        a: IntegerValue.fromInt(5),
        b: IntegerValue.fromInt(15),
      ).valueOrNull!;

      final sampleRes = engine.sample(u, 1000, rng);
      expect(sampleRes, isA<MathSuccess>());
      final dataset = sampleRes.valueOrNull!;

      for (final val in dataset.toDoubles()) {
        expect(val >= 5.0 && val <= 15.0, isTrue);
      }
    });

    test('Exponential sampling non-negativity and mean', () {
      final exp = ExponentialDistribution.create(rate: IntegerValue.fromInt(2))
          .valueOrNull!;

      final sampleRes = engine.sample(exp, 5000, rng);
      expect(sampleRes, isA<MathSuccess>());
      final dataset = sampleRes.valueOrNull!;

      for (final val in dataset.toDoubles()) {
        expect(val >= 0.0, isTrue);
      }

      final doubles = dataset.toDoubles();
      final empiricalMean = doubles.reduce((a, b) => a + b) / doubles.length;
      // Theoretical mean is 1/2 = 0.5
      expect(empiricalMean, closeTo(0.5, 0.05));
    });

    test('Binomial discrete support compliance and mean', () {
      final bin = BinomialDistribution.create(
        trials: IntegerValue.fromInt(10),
        probability: FractionValue.half,
      ).valueOrNull!;

      final sampleRes = engine.sample(bin, 1000, rng);
      expect(sampleRes, isA<MathSuccess>());
      final dataset = sampleRes.valueOrNull!;

      for (final val in dataset.toDoubles()) {
        expect(val >= 0 && val <= 10, isTrue);
        expect(val, equals(val.roundToDouble())); // Must be integer counts
      }
    });

    test('Geometric support compliance (k >= 1) and empirical mean', () {
      final geom = GeometricDistribution.create(probability: FractionValue.half)
          .valueOrNull!;

      final sampleRes = engine.sample(geom, 2000, rng);
      expect(sampleRes, isA<MathSuccess>());
      final dataset = sampleRes.valueOrNull!;

      for (final val in dataset.toDoubles()) {
        expect(val >= 1.0, isTrue); // Support strictly k >= 1
        expect(val, equals(val.roundToDouble()));
      }

      final doubles = dataset.toDoubles();
      final empiricalMean = doubles.reduce((a, b) => a + b) / doubles.length;
      // Theoretical mean = 1 / 0.5 = 2.0
      expect(empiricalMean, closeTo(2.0, 0.15));
    });

    test('Poisson discrete support compliance and empirical mean', () {
      final pois = PoissonDistribution.create(lambda: IntegerValue.fromInt(4))
          .valueOrNull!;

      final sampleRes = engine.sample(pois, 3000, rng);
      expect(sampleRes, isA<MathSuccess>());
      final dataset = sampleRes.valueOrNull!;

      for (final val in dataset.toDoubles()) {
        expect(val >= 0.0, isTrue);
        expect(val, equals(val.roundToDouble()));
      }

      final doubles = dataset.toDoubles();
      final empiricalMean = doubles.reduce((a, b) => a + b) / doubles.length;
      expect(empiricalMean, closeTo(4.0, 0.15));
    });
  });
}
