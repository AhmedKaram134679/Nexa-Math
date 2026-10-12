import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/core/result/math_warning.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/default_probability_engine.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/normal_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/binomial_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/discrete/geometric_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_engine.dart';
import 'package:nexa_math/mathematical_core/probability/probability_numeric_helper.dart';
import 'package:nexa_math/mathematical_core/probability/queries/probability_query.dart';

void main() {
  late ProbabilityEngine engine;

  setUp(() {
    engine = const DefaultProbabilityEngine();
  });

  group('ProbabilityEngine Query Semantics', () {
    test('Continuous point probability is identically zero', () {
      final std = NormalDistribution.standard();
      final res = engine.probability(
        std,
        PointProbabilityQuery(IntegerValue.zero),
      );
      expect(res, isA<MathSuccess>());
      expect(res.valueOrNull?.value, equals(IntegerValue.zero));
    });

    test('Discrete point probability returns exact PMF', () {
      final bin = BinomialDistribution.create(
        trials: IntegerValue.fromInt(4),
        probability: FractionValue.half,
      ).valueOrNull!;

      final res = engine.probability(
        bin,
        PointProbabilityQuery(IntegerValue.fromInt(2)),
      );
      expect(res, isA<MathSuccess>());
      final val = res.valueOrNull?.value;
      expect(val, isA<FractionValue>());
      expect((val as FractionValue).numerator, equals(BigInt.from(3)));
      expect(val.denominator, equals(BigInt.from(8)));
    });

    test('Continuous interval query P(a <= X <= b)', () {
      final std = NormalDistribution.standard();
      // P(-1 <= X <= 1) = Phi(1) - Phi(-1) ~ 0.841344746 - 0.158655254 = 0.682689492
      final res = engine.probability(
        std,
        IntervalProbabilityQuery(
          lower: IntegerValue.minusOne,
          upper: IntegerValue.one,
        ),
      );
      expect(res, isA<MathSuccess>());
      final val = res.valueOrNull!.value;
      final valDbl = ProbabilityNumericHelper.toDouble(val).valueOrNull!;
      expect(valDbl, closeTo(0.682689, 1e-4));
    });

    test('Discrete interval boundary sensitivity', () {
      // Geometric(1/2): P(X = 1) = 0.5, P(X = 2) = 0.25, P(X = 3) = 0.125
      final geom = GeometricDistribution.create(probability: FractionValue.half)
          .valueOrNull!;

      // Inclusive [1, 2]: P(1) + P(2) = 0.75
      final incRes = engine.probability(
        geom,
        IntervalProbabilityQuery(
          lower: IntegerValue.one,
          upper: IntegerValue.fromInt(2),
          includeLower: true,
          includeUpper: true,
        ),
      );
      final incVal = incRes.valueOrNull!.value;
      expect(
        ProbabilityNumericHelper.toDouble(incVal).valueOrNull,
        equals(0.75),
      );

      // Exclusive (1, 2]: only P(2) = 0.25
      final excLowerRes = engine.probability(
        geom,
        IntervalProbabilityQuery(
          lower: IntegerValue.one,
          upper: IntegerValue.fromInt(2),
          includeLower: false,
          includeUpper: true,
        ),
      );
      final excVal = excLowerRes.valueOrNull!.value;
      expect(
        ProbabilityNumericHelper.toDouble(excVal).valueOrNull,
        equals(0.25),
      );
    });

    test('Upper tail and lower tail queries', () {
      final std = NormalDistribution.standard();

      final lowerRes = engine.probability(
        std,
        LowerTailQuery(IntegerValue.zero),
      );
      final lowerVal = lowerRes.valueOrNull!.value;
      expect(
        ProbabilityNumericHelper.toDouble(lowerVal).valueOrNull,
        closeTo(0.5, 1e-15),
      );

      final upperRes = engine.probability(
        std,
        UpperTailQuery(IntegerValue.zero),
      );
      final upperVal = upperRes.valueOrNull!.value;
      expect(
        ProbabilityNumericHelper.toDouble(upperVal).valueOrNull,
        closeTo(0.5, 1e-15),
      );
    });
  });

  group('Decision 1: 1,024-bit Deterministic Rational Resource Policy', () {
    test('Exact computation below threshold preserves exact FractionValue', () {
      // Binomial n = 10, p = 1/2: 2^10 = 1024 (11 bits) << 1024 bits
      final bin = BinomialDistribution.create(
        trials: IntegerValue.fromInt(10),
        probability: FractionValue.half,
      ).valueOrNull!;

      final pmfRes = bin.pmf(IntegerValue.fromInt(5));
      expect(pmfRes, isA<MathSuccess>());
      expect(pmfRes.valueOrNull, isA<FractionValue>());
    });

    test('Predictive resource guard transitions to float representation when > 1024 bits', () {
      // Binomial with n = 2000, p = 1/2:
      // Denominator would be 2^2000 which is 2001 bits > 1024 bits threshold.
      // Must NOT produce an out-of-memory BigInt, but transition to approximate DecimalValue!
      final largeBin = BinomialDistribution.create(
        trials: IntegerValue.fromInt(2000),
        probability: FractionValue.half,
      ).valueOrNull!;

      final pmfRes = largeBin.pmf(IntegerValue.fromInt(1000));
      expect(pmfRes, isA<MathSuccess>());
      expect(pmfRes.valueOrNull, isA<DecimalValue>());
      expect((pmfRes.valueOrNull as DecimalValue).isExact, isFalse);
    });
  });

  group('Decision 2: Representation-Relative Tail Underflow Policy', () {
    test('Positive tail underflow returns DecimalValue.zero with NearZeroWarning and isExact: false', () {
      final std = NormalDistribution.standard();

      // At x = -50, standard normal CDF mathematically > 0 but evaluates to 0.0 in double precision
      final cdfRes = std.cdf(IntegerValue.fromInt(-50));
      expect(cdfRes, isA<MathSuccess>());
      final success = cdfRes as MathSuccess;

      expect(success.value, equals(DecimalValue.zero));
      expect(
        success.value,
        isNot(equals(IntegerValue.zero)),
      ); // NOT exact integer zero!
      expect(success.metadata.isExact, isFalse);
      expect(
        success.metadata.warnings.any((w) => w is NearZeroWarning),
        isTrue,
      );
    });

    test('Structural outside-support values return exact IntegerValue.zero without warning', () {
      // Binomial k = -1 is mathematically impossible (support is 0..n), structural zero!
      final bin = BinomialDistribution.create(
        trials: IntegerValue.fromInt(10),
        probability: FractionValue.half,
      ).valueOrNull!;

      final pmfRes = bin.pmf(IntegerValue.minusOne);
      expect(pmfRes, isA<MathSuccess>());
      expect(pmfRes.valueOrNull, equals(IntegerValue.zero));
      expect(pmfRes.valueOrNull, isA<IntegerValue>());
    });
  });
}
