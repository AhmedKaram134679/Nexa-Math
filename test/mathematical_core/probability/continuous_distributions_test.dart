import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/core/result/math_warning.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/exponential_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/normal_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/distributions/continuous/uniform_distribution.dart';
import 'package:nexa_math/mathematical_core/probability/probability_numeric_helper.dart';

void main() {
  group('NormalDistribution', () {
    test('parameter validation and error handling', () {
      final zeroStd = NormalDistribution.create(
        standardDeviation: IntegerValue.zero,
      );
      expect(zeroStd, isA<MathFailure>());
      expect(
        (zeroStd as MathFailure).error,
        isA<InvalidDistributionParameterError>(),
      );

      final negStd = NormalDistribution.create(
        standardDeviation: IntegerValue(BigInt.from(-2)),
      );
      expect(negStd, isA<MathFailure>());

      final std = NormalDistribution.standard();
      expect(std.name, equals('NormalDistribution'));
      expect(std.isContinuous, isTrue);
      expect(std.isDiscrete, isFalse);
    });

    test('moments', () {
      final norm = NormalDistribution.create(
        mean: IntegerValue.fromInt(10),
        standardDeviation: IntegerValue.fromInt(3),
      ).valueOrNull!;

      expect(norm.mean.valueOrNull, equals(IntegerValue.fromInt(10)));
      expect(norm.variance.valueOrNull, equals(IntegerValue.fromInt(9)));
      expect(
        norm.standardDeviation.valueOrNull,
        equals(IntegerValue.fromInt(3)),
      );
    });

    test('standard normal PDF and CDF reference values', () {
      final std = NormalDistribution.standard();

      // PDF at x = 0 is 1 / sqrt(2*pi) ~ 0.3989422804
      final pdf0 = std.pdf(IntegerValue.zero).valueOrNull!;
      final pdf0Dbl = ProbabilityNumericHelper.toDouble(pdf0).valueOrNull!;
      expect(pdf0Dbl, closeTo(0.3989422804, 1e-9));

      // CDF symmetry: Phi(0) = 0.5
      final cdf0 = std.cdf(IntegerValue.zero).valueOrNull!;
      final cdf0Dbl = ProbabilityNumericHelper.toDouble(cdf0).valueOrNull!;
      expect(cdf0Dbl, closeTo(0.5, 1e-15));

      // High precision reference values for Phi(x)
      // Reference: Phi(x) = 0.5 * erfc(-x / sqrt(2))
      final cdfMinus3 = std.cdf(IntegerValue.fromInt(-3)).valueOrNull!;
      expect(
        ProbabilityNumericHelper.toDouble(cdfMinus3).valueOrNull!,
        closeTo(0.0013498980316300946, 1e-15),
      );

      final cdfMinus2 = std.cdf(IntegerValue.fromInt(-2)).valueOrNull!;
      expect(
        ProbabilityNumericHelper.toDouble(cdfMinus2).valueOrNull!,
        closeTo(0.022750131948179195, 1e-15),
      );

      final cdfMinus1 = std.cdf(IntegerValue.minusOne).valueOrNull!;
      expect(
        ProbabilityNumericHelper.toDouble(cdfMinus1).valueOrNull!,
        closeTo(0.15865525393145705, 1e-15),
      );

      final cdf1 = std.cdf(IntegerValue.one).valueOrNull!;
      final cdf1Dbl = ProbabilityNumericHelper.toDouble(cdf1).valueOrNull!;
      expect(cdf1Dbl, closeTo(0.8413447460685429, 1e-15));

      final cdf2 = std.cdf(IntegerValue.fromInt(2)).valueOrNull!;
      expect(
        ProbabilityNumericHelper.toDouble(cdf2).valueOrNull!,
        closeTo(0.9772498680518208, 1e-15),
      );

      final cdf3 = std.cdf(IntegerValue.fromInt(3)).valueOrNull!;
      expect(
        ProbabilityNumericHelper.toDouble(cdf3).valueOrNull!,
        closeTo(0.9986501019683699, 1e-15),
      );

      // CDF + Survival function complement identity
      final s1 = std.survivalFunction(IntegerValue.one).valueOrNull!;
      final s1Dbl = ProbabilityNumericHelper.toDouble(s1).valueOrNull!;
      expect(cdf1Dbl + s1Dbl, closeTo(1.0, 1e-14));
    });

    test('extreme tail underflow with NearZeroWarning', () {
      final std = NormalDistribution.standard();

      // Deep left tail: x = -40 -> CDF underflows
      final deepTailRes = std.cdf(IntegerValue.fromInt(-40));
      expect(deepTailRes, isA<MathSuccess>());
      final success = deepTailRes as MathSuccess;
      expect(success.value, equals(DecimalValue.zero));
      expect(success.metadata.isExact, isFalse);
      expect(
        success.metadata.warnings.any((w) => w is NearZeroWarning),
        isTrue,
      );
    });

    test('inverse CDF quantiles and endpoints', () {
      final std = NormalDistribution.standard();

      // Q(0.5) = 0
      final med = std.inverseCdf(DecimalValue.half).valueOrNull!;
      final medDbl = ProbabilityNumericHelper.toDouble(med).valueOrNull!;
      expect(medDbl, closeTo(0.0, 1e-14));

      // Q(Phi(1)) ~ 1 with high accuracy (ISS-10-01)
      final q1 = std
          .inverseCdf(DecimalValue.parse('0.8413447460685429', isExact: false))
          .valueOrNull!;
      final q1Dbl = ProbabilityNumericHelper.toDouble(q1).valueOrNull!;
      expect(q1Dbl, closeTo(1.0, 1e-12));

      // Representative quantiles: 0.001, 0.01, 0.025, 0.05, 0.95, 0.975, 0.99, 0.999
      final testPs = [0.001, 0.01, 0.025, 0.05, 0.5, 0.95, 0.975, 0.99, 0.999];
      for (final p in testPs) {
        final qVal = std
            .inverseCdf(DecimalValue.parse(p.toString(), isExact: false))
            .valueOrNull!;
        final x = ProbabilityNumericHelper.toDouble(qVal).valueOrNull!;
        final cdfBack = std
            .cdf(DecimalValue.parse(x.toString(), isExact: false))
            .valueOrNull!;
        final pBack = ProbabilityNumericHelper.toDouble(cdfBack).valueOrNull!;
        expect(pBack, closeTo(p, 1e-12));
      }

      // Round trip: inverseCdf(cdf(x)) ≈ x for representative x
      for (final x in [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0]) {
        final cdfVal = std
            .cdf(DecimalValue.parse(x.toString(), isExact: false))
            .valueOrNull!;
        final p = DecimalValue.parse(
          ProbabilityNumericHelper.toDouble(cdfVal).valueOrNull!.toString(),
          isExact: false,
        );
        final qVal = std.inverseCdf(p).valueOrNull!;
        final xBack = ProbabilityNumericHelper.toDouble(qVal).valueOrNull!;
        expect(xBack, closeTo(x, 1e-12));
      }

      // Endpoints
      final q0 = std.inverseCdf(IntegerValue.zero);
      expect(q0, isA<MathFailure>());
      expect((q0 as MathFailure).error, isA<DomainError>());

      final q1End = std.inverseCdf(IntegerValue.one);
      expect(q1End, isA<MathFailure>());
    });
  });

  group('UniformDistribution', () {
    test('parameter validation', () {
      final invalid = UniformDistribution.create(
        a: IntegerValue.fromInt(5),
        b: IntegerValue.fromInt(2),
      );
      expect(invalid, isA<MathFailure>());
      expect(
        (invalid as MathFailure).error,
        isA<InvalidDistributionParameterError>(),
      );
    });

    test('exact rational moments and PDF for U(0, 2)', () {
      final u = UniformDistribution.create(
        a: IntegerValue.zero,
        b: IntegerValue.fromInt(2),
      ).valueOrNull!;

      final meanVal = u.mean.valueOrNull!;
      final meanDbl = ProbabilityNumericHelper.toDouble(meanVal).valueOrNull!;
      expect(meanDbl, equals(1.0));

      // Variance = (2 - 0)^2 / 12 = 4/12 = 1/3 (exact fraction)
      final varVal = u.variance.valueOrNull!;
      expect(varVal, isA<FractionValue>());
      expect((varVal as FractionValue).numerator, equals(BigInt.one));
      expect(varVal.denominator, equals(BigInt.from(3)));

      // PDF inside support is exact 1/2
      final pdfMid = u.pdf(IntegerValue.one).valueOrNull!;
      expect(pdfMid, isA<FractionValue>());
      expect((pdfMid as FractionValue).numerator, equals(BigInt.one));
      expect(pdfMid.denominator, equals(BigInt.two));

      // PDF outside support is exact 0
      final pdfOut = u.pdf(IntegerValue.fromInt(5)).valueOrNull!;
      expect(pdfOut, equals(IntegerValue.zero));
    });

    test('CDF step behavior and exactness', () {
      final u = UniformDistribution.create(
        a: IntegerValue.zero,
        b: IntegerValue.fromInt(4),
      ).valueOrNull!;

      expect(
        u.cdf(IntegerValue.minusOne).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(
        u.cdf(IntegerValue.fromInt(5)).valueOrNull,
        equals(IntegerValue.one),
      );

      // Inside: x = 1 -> CDF = 1/4 (exact fraction)
      final cdf1 = u.cdf(IntegerValue.one).valueOrNull!;
      expect(cdf1, isA<FractionValue>());
      expect((cdf1 as FractionValue).numerator, equals(BigInt.one));
      expect(cdf1.denominator, equals(BigInt.from(4)));
    });

    test('inverse CDF and endpoints', () {
      final u = UniformDistribution.create(
        a: IntegerValue.fromInt(2),
        b: IntegerValue.fromInt(10),
      ).valueOrNull!;

      expect(
        u.inverseCdf(IntegerValue.zero).valueOrNull,
        equals(IntegerValue.fromInt(2)),
      );
      expect(
        u.inverseCdf(IntegerValue.one).valueOrNull,
        equals(IntegerValue.fromInt(10)),
      );
      final qMed = u.inverseCdf(FractionValue.half).valueOrNull!;
      final qMedDbl = ProbabilityNumericHelper.toDouble(qMed).valueOrNull!;
      expect(qMedDbl, equals(6.0));
    });
  });

  group('ExponentialDistribution', () {
    test('parameter validation', () {
      final invalid = ExponentialDistribution.create(rate: IntegerValue.zero);
      expect(invalid, isA<MathFailure>());
      expect(
        (invalid as MathFailure).error,
        isA<InvalidDistributionParameterError>(),
      );
    });

    test('moments and exactness', () {
      final exp = ExponentialDistribution.create(rate: IntegerValue.fromInt(2))
          .valueOrNull!;
      final m = exp.mean.valueOrNull!;
      expect(m, isA<FractionValue>());
      expect((m as FractionValue).numerator, equals(BigInt.one));
      expect(m.denominator, equals(BigInt.two));

      final v = exp.variance.valueOrNull!;
      expect(v, isA<FractionValue>());
      expect((v as FractionValue).numerator, equals(BigInt.one));
      expect(v.denominator, equals(BigInt.from(4)));
    });

    test('PDF and CDF boundary behavior', () {
      final exp = ExponentialDistribution.create(rate: IntegerValue.one)
          .valueOrNull!;

      expect(
        exp.pdf(IntegerValue.minusOne).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(
        exp.cdf(IntegerValue.minusOne).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(exp.cdf(IntegerValue.zero).valueOrNull, equals(IntegerValue.zero));

      final cdf1 = exp.cdf(IntegerValue.one).valueOrNull!;
      final cdf1Dbl = ProbabilityNumericHelper.toDouble(cdf1).valueOrNull!;
      expect(cdf1Dbl, closeTo(0.6321205588, 1e-6));

      final s1 = exp.survivalFunction(IntegerValue.one).valueOrNull!;
      final s1Dbl = ProbabilityNumericHelper.toDouble(s1).valueOrNull!;
      expect(s1Dbl, closeTo(0.36787944117, 1e-6));
    });

    test('inverse CDF and endpoints', () {
      final exp = ExponentialDistribution.create(rate: IntegerValue.one)
          .valueOrNull!;
      expect(
        exp.inverseCdf(IntegerValue.zero).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(exp.inverseCdf(IntegerValue.one), isA<MathFailure>());

      final q = exp
          .inverseCdf(DecimalValue.parse('0.6321205588', isExact: false))
          .valueOrNull!;
      final qDbl = ProbabilityNumericHelper.toDouble(q).valueOrNull!;
      expect(qDbl, closeTo(1.0, 1e-5));
    });
  });
}
