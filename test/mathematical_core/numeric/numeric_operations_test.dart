import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/complex_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/decimal_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/fraction_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/integer_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('Comprehensive Numeric Operations & Invariants Tests', () {
    test('Integer quotient, modulo, and division by zero', () {
      final a = IntegerValue.fromInt(23);
      final b = IntegerValue.fromInt(5);

      final q = IntegerOperations.quotient(a, b);
      final m = IntegerOperations.modulo(a, b);
      expect(q.valueOrNull, equals(IntegerValue.fromInt(4)));
      expect(m.valueOrNull, equals(IntegerValue.fromInt(3)));

      final divZeroQ = IntegerOperations.quotient(a, IntegerValue.zero);
      expect(divZeroQ.isFailure, isTrue);
      expect(divZeroQ.errorOrNull, isA<DivisionByZeroError>());

      final divZeroM = IntegerOperations.modulo(a, IntegerValue.zero);
      expect(divZeroM.isFailure, isTrue);
      expect(divZeroM.errorOrNull, isA<DivisionByZeroError>());
    });

    test('Integer algebraic identities: a+0=a, a-a=0, a*1=a, a*0=0', () {
      final a = IntegerValue.parse('987654321098765432109876543210');

      expect(
        IntegerOperations.add(a, IntegerValue.zero).valueOrNull,
        equals(a),
      );
      expect(
        IntegerOperations.subtract(a, a).valueOrNull,
        equals(IntegerValue.zero),
      );
      expect(
        IntegerOperations.multiply(a, IntegerValue.one).valueOrNull,
        equals(a),
      );
      expect(
        IntegerOperations.multiply(a, IntegerValue.zero).valueOrNull,
        equals(IntegerValue.zero),
      );
    });

    test('Fraction algebraic identities and division by zero', () {
      final f = FractionValue.fromInts(7, 13);

      expect(
        FractionOperations.add(f, FractionValue.zero).valueOrNull,
        equals(f),
      );
      expect(
        FractionOperations.subtract(f, f).valueOrNull,
        equals(FractionValue.zero),
      );
      expect(
        FractionOperations.multiply(f, FractionValue.one).valueOrNull,
        equals(f),
      );

      final divZero = FractionOperations.divide(f, FractionValue.zero);
      expect(divZero.isFailure, isTrue);
      expect(divZero.errorOrNull, isA<DivisionByZeroError>());
    });

    test(
      'Decimal exactness: 0.1 + 0.2 == 0.3 without binary floating-point drift',
      () {
        final d1 = DecimalValue.parse('0.1');
        final d2 = DecimalValue.parse('0.2');

        final sum = DecimalOperations.add(d1, d2);
        expect(sum.isSuccess, isTrue);
        expect(sum.valueOrNull, equals(DecimalValue.parse('0.3')));
        expect(sum.valueOrNull.toString(), equals('0.3'));
        expect(sum.metadata.isExact, isTrue);
      },
    );

    test('Decimal division with different precision contexts', () {
      final num = DecimalValue.parse('22');
      final den = DecimalValue.parse('7');

      final stdRes = DecimalOperations.divide(
        num,
        den,
        context: PrecisionContext.standard,
      );
      expect(stdRes.isSuccess, isTrue);
      expect(stdRes.metadata.isExact, isFalse);
      expect(stdRes.metadata.approximation!.precision, equals(34));

      final highRes = DecimalOperations.divide(
        num,
        den,
        context: PrecisionContext.highPrecision,
      );
      expect(highRes.isSuccess, isTrue);
      expect(highRes.metadata.approximation!.precision, equals(64));
      expect(
        highRes.valueOrNull.toString().length,
        greaterThan(stdRes.valueOrNull.toString().length),
      );
    });

    test('Decimal square root exact zero and Newton-Raphson approximation', () {
      final zSqrt = DecimalOperations.sqrt(DecimalValue.zero);
      expect(zSqrt.isSuccess, isTrue);
      expect(zSqrt.valueOrNull, equals(DecimalValue.zero));
      expect(zSqrt.metadata.isExact, isTrue);

      final negSqrt = DecimalOperations.sqrt(DecimalValue.parse('-4'));
      expect(negSqrt.isFailure, isTrue);
      expect(negSqrt.errorOrNull, isA<DomainError>());

      final sqrt2 = DecimalOperations.sqrt(DecimalValue.parse('2'));
      expect(sqrt2.isSuccess, isTrue);
      expect(
        sqrt2.valueOrNull.toString().startsWith(
          '1.414213562373095048801688724209698',
        ),
        isTrue,
      );
      expect(sqrt2.metadata.isExact, isFalse);

      final sqrt2High = DecimalOperations.sqrt(
        DecimalValue.parse('2'),
        context: PrecisionContext.highPrecision,
      );
      expect(sqrt2High.isSuccess, isTrue);
      expect(sqrt2High.metadata.approximation!.precision, equals(64));
      expect(
        sqrt2High.valueOrNull.toString().length,
        greaterThan(sqrt2.valueOrNull.toString().length),
      );

      // Independent verification of sqrt(2) at 64 digits
      // Total significant digits: 1 integer digit + 63 fractional digits = 64 significant digits
      // Reference: 1.414213562373095048801688724209698078569671875376948073176679738
      final s2Str = sqrt2High.valueOrNull.toString();
      expect(
        s2Str,
        equals(
          '1.414213562373095048801688724209698078569671875376948073176679738',
        ),
      );

      // Residual check: |x^2 - 2| <= 10^-64
      final xVal = sqrt2High.valueOrNull!;
      final xSquared = DecimalOperations.multiply(xVal, xVal).valueOrNull!;
      final residual = DecimalOperations.subtract(
        xSquared,
        DecimalValue.parse('2'),
      ).valueOrNull!.abs();
      // residual must be less than 10^-63
      expect(
        residual.compareTo(DecimalValue(BigInt.one, 63)),
        lessThanOrEqualTo(0),
      );

      // Perfect square tests
      final sqrt0 = DecimalOperations.sqrt(DecimalValue.zero);
      expect(sqrt0.valueOrNull, equals(DecimalValue.zero));

      final sqrt1 = DecimalOperations.sqrt(DecimalValue.one);
      expect(sqrt1.valueOrNull, equals(DecimalValue.one));

      final sqrt4 = DecimalOperations.sqrt(DecimalValue.parse('4'));
      expect(sqrt4.valueOrNull, equals(DecimalValue.parse('2')));

      final sqrt9 = DecimalOperations.sqrt(DecimalValue.parse('9'));
      expect(sqrt9.valueOrNull, equals(DecimalValue.parse('3')));

      final sqrt1M = DecimalOperations.sqrt(DecimalValue.parse('1000000'));
      expect(sqrt1M.valueOrNull, equals(DecimalValue.parse('1000')));

      // Decimals and extreme values
      final sqrt001 = DecimalOperations.sqrt(DecimalValue.parse('0.01'));
      expect(sqrt001.valueOrNull, equals(DecimalValue.parse('0.1')));

      final sqrt025 = DecimalOperations.sqrt(DecimalValue.parse('0.25'));
      expect(sqrt025.valueOrNull, equals(DecimalValue.parse('0.5')));

      final sqrt10 = DecimalOperations.sqrt(DecimalValue.parse('10'));
      expect(sqrt10.isSuccess, isTrue);
      // Independent reference: sqrt(10) ~ 3.162277660168379331998893544432719
      expect(
        sqrt10.valueOrNull.toString().startsWith(
          '3.162277660168379331998893544432719',
        ),
        isTrue,
      );

      // Extreme value sqrt test beyond IEEE-754 double range (10^400)
      final massive = DecimalValue(BigInt.one, -400); // 10^400
      final sqrtMassive = DecimalOperations.sqrt(massive);
      expect(sqrtMassive.isSuccess, isTrue);
      // sqrt(10^400) = 10^200
      expect(sqrtMassive.valueOrNull, equals(DecimalValue(BigInt.one, -200)));
    });

    test(
      'Power domain and indeterminate form checks across all representations',
      () {
        final zeroPowZeroDec = DecimalOperations.power(
          DecimalValue.zero,
          DecimalValue.zero,
        );
        expect(zeroPowZeroDec.isFailure, isTrue);
        expect(zeroPowZeroDec.errorOrNull, isA<DomainError>());

        final zeroPowZeroInt = IntegerOperations.power(
          IntegerValue.zero,
          IntegerValue.zero,
        );
        expect(zeroPowZeroInt.isFailure, isTrue);
        expect(zeroPowZeroInt.errorOrNull, isA<DomainError>());

        final zeroPowZeroFrac = FractionOperations.power(FractionValue.zero, 0);
        expect(zeroPowZeroFrac.isFailure, isTrue);
        expect(zeroPowZeroFrac.errorOrNull, isA<DomainError>());

        final zeroPowNeg = DecimalOperations.power(
          DecimalValue.zero,
          DecimalValue.parse('-1'),
        );
        expect(zeroPowNeg.isFailure, isTrue);
        expect(zeroPowNeg.errorOrNull, isA<DivisionByZeroError>());

        final negPowFrac = DecimalOperations.power(
          DecimalValue.parse('-4'),
          DecimalValue.parse('0.5'),
        );
        expect(negPowFrac.isFailure, isTrue);
        expect(negPowFrac.errorOrNull, isA<DomainError>());
      },
    );

    test('Complex field arithmetic and conjugate identity conjugate(conjugate(z)) == z', () {
      final z = ComplexNumber.fromInts(5, -7);

      expect(
        ComplexOperations.conjugate(ComplexOperations.conjugate(z).valueOrNull!)
            .valueOrNull,
        equals(z),
      );

      // (5 - 7i) + (-5 + 7i) = 0 + 0i
      final negZ = ComplexOperations.negate(z).valueOrNull!;
      final zeroSum = ComplexOperations.add(z, negZ);
      expect(zeroSum.valueOrNull!.isZero, isTrue);

      // Division by zero complex
      final divZero = ComplexOperations.divide(z, ComplexNumber.zero);
      expect(divZero.isFailure, isTrue);
      expect(divZero.errorOrNull, isA<DivisionByZeroError>());
    });
  });
}
