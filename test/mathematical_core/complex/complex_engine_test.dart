import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/mathematical_core/complex/default_complex_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  final engine = DefaultComplexEngine();

  group('ComplexEngine: Basic Arithmetic', () {
    test('Addition and Subtraction of complex numbers', () {
      final z1 = ComplexNumber.fromInts(3, 4);
      final z2 = ComplexNumber.fromInts(1, -2);

      final sum = engine.add(z1, z2);
      expect(sum.isSuccess, isTrue);
      expect(sum.valueOrNull!.real, equals(DecimalValue.fromInt(4)));
      expect(sum.valueOrNull!.imaginary, equals(DecimalValue.fromInt(2)));

      final diff = engine.subtract(z1, z2);
      expect(diff.isSuccess, isTrue);
      expect(diff.valueOrNull!.real, equals(DecimalValue.fromInt(2)));
      expect(diff.valueOrNull!.imaginary, equals(DecimalValue.fromInt(6)));
    });

    test(
      'Multiplication: (3 + 2i)(1 - 4i) = 3 - 12i + 2i - 8i^2 = 11 - 10i',
      () {
        final z1 = ComplexNumber.fromInts(3, 2);
        final z2 = ComplexNumber.fromInts(1, -4);

        final prod = engine.multiply(z1, z2);
        expect(prod.isSuccess, isTrue);
        expect(prod.valueOrNull!.real, equals(DecimalValue.fromInt(11)));
        expect(prod.valueOrNull!.imaginary, equals(DecimalValue.fromInt(-10)));
      },
    );

    test('Division: (1 + 2i) / (1 - i) = (1+2i)(1+i) / 2 = (-1 + 3i)/2 = -0.5 + 1.5i', () {
      final z1 = ComplexNumber.fromInts(1, 2);
      final z2 = ComplexNumber.fromInts(1, -1);

      final div = engine.divide(z1, z2);
      expect(div.isSuccess, isTrue);
      expect(div.valueOrNull!.real.toDouble(), closeTo(-0.5, 1e-10));
      expect(div.valueOrNull!.imaginary.toDouble(), closeTo(1.5, 1e-10));
    });

    test('Complex multiplication associativity: (z * w) * v = z * (w * v)', () {
      final z = ComplexNumber.fromInts(1, 2);
      final w = ComplexNumber.fromInts(3, -1);
      final v = ComplexNumber.fromInts(-2, 4);

      final zw = engine.multiply(z, w).valueOrNull!;
      final left = engine.multiply(zw, v).valueOrNull!;

      final wv = engine.multiply(w, v).valueOrNull!;
      final right = engine.multiply(z, wv).valueOrNull!;

      expect(left.real.toDouble(), closeTo(right.real.toDouble(), 1e-10));
      expect(
        left.imaginary.toDouble(),
        closeTo(right.imaginary.toDouble(), 1e-10),
      );
    });

    test('Complex division identity: (z / w) * w = z for w != 0', () {
      final z = ComplexNumber.fromInts(7, -3);
      final w = ComplexNumber.fromInts(2, 5);

      final div = engine.divide(z, w).valueOrNull!;
      final prod = engine.multiply(div, w).valueOrNull!;

      expect(prod.real.toDouble(), closeTo(z.real.toDouble(), 1e-10));
      expect(prod.imaginary.toDouble(), closeTo(z.imaginary.toDouble(), 1e-10));
    });

    test('Division by zero fails with DivisionByZeroError', () {
      final z1 = ComplexNumber.fromInts(1, 2);
      final z0 = ComplexNumber.zero;

      final div = engine.divide(z1, z0);
      expect(div.isFailure, isTrue);
      expect(div.errorOrNull, isA<DivisionByZeroError>());
    });
  });

  group('ComplexEngine: Invariants, Conjugate, Reciprocal & Norms', () {
    test('Conjugate: conj(a + bi) = a - bi', () {
      final z = ComplexNumber.fromInts(5, -7);
      final cRes = engine.conjugate(z);
      expect(cRes.isSuccess, isTrue);
      final c = cRes.valueOrNull!;
      expect(c.real, equals(DecimalValue.fromInt(5)));
      expect(c.imaginary, equals(DecimalValue.fromInt(7)));
      // Double conjugate identity: conj(conj(z)) == z
      expect(engine.conjugate(c).valueOrNull, equals(z));
    });

    test('Squared magnitude: |3 + 4i|^2 = 25', () {
      final z = ComplexNumber.fromInts(3, 4);
      final magSq = engine.magnitudeSquared(z);
      expect(magSq.isSuccess, isTrue);
      expect(magSq.valueOrNull, equals(DecimalValue.fromInt(25)));
    });

    test('Magnitude: |3 + 4i| = 5', () {
      final z = ComplexNumber.fromInts(3, 4);
      final mag = engine.magnitude(z);
      expect(mag.isSuccess, isTrue);
      expect(mag.valueOrNull, equals(DecimalValue.fromInt(5)));
    });

    test('Phase: arg(1 + i) = pi/4', () {
      final z = ComplexNumber.fromInts(1, 1);
      final ph = engine.phase(z);
      expect(ph.isSuccess, isTrue);
      expect(ph.valueOrNull!.toDouble(), closeTo(math.pi / 4, 1e-10));
    });

    test('Phase of zero fails with DomainError', () {
      final ph = engine.phase(ComplexNumber.zero);
      expect(ph.isFailure, isTrue);
      expect(ph.errorOrNull, isA<DomainError>());
    });

    test('Reciprocal of 2i is -0.5i', () {
      final z = ComplexNumber.fromInts(0, 2);
      final rec = engine.reciprocal(z);
      expect(rec.isSuccess, isTrue);
      expect(rec.valueOrNull!.real.toDouble(), closeTo(0, 1e-10));
      expect(rec.valueOrNull!.imaginary.toDouble(), closeTo(-0.5, 1e-10));
    });
  });

  group('ComplexEngine: Square Root and Powers', () {
    test('Principal square root of -1 is i', () {
      final z = ComplexNumber.fromInts(-1, 0);
      final sq = engine.sqrt(z);
      expect(sq.isSuccess, isTrue);
      expect(sq.valueOrNull!.real.toDouble(), closeTo(0, 1e-10));
      expect(sq.valueOrNull!.imaginary.toDouble(), closeTo(1, 1e-10));
    });

    test('Principal square root of -4 is 2i', () {
      final z = ComplexNumber.fromInts(-4, 0);
      final sq = engine.sqrt(z);
      expect(sq.isSuccess, isTrue);
      expect(sq.valueOrNull!.real.toDouble(), closeTo(0, 1e-10));
      expect(sq.valueOrNull!.imaginary.toDouble(), closeTo(2, 1e-10));
    });

    test('Complex power: i^2 = -1', () {
      final i = ComplexNumber.i;
      final powRes = engine.power(i, IntegerValue.fromInt(2));
      expect(powRes.isSuccess, isTrue);
      expect(powRes.valueOrNull!.real.toDouble(), closeTo(-1, 1e-10));
      expect(powRes.valueOrNull!.imaginary.toDouble(), closeTo(0, 1e-10));
    });

    test('Complex power: i^4 = 1', () {
      final i = ComplexNumber.i;
      final powRes = engine.power(i, IntegerValue.fromInt(4));
      expect(powRes.isSuccess, isTrue);
      expect(powRes.valueOrNull!.real.toDouble(), closeTo(1, 1e-10));
      expect(powRes.valueOrNull!.imaginary.toDouble(), closeTo(0, 1e-10));
    });

    test('Complex power: 0^0 rejects with DomainError indeterminate form', () {
      final powRes = engine.power(ComplexNumber.zero, IntegerValue.zero);
      expect(powRes.isFailure, isTrue);
      expect(powRes.errorOrNull, isA<DomainError>());
    });

    test('Complex power: (-1)^(1/2) yields i via principal branch', () {
      final minusOne = ComplexNumber.fromInts(-1, 0);
      final powRes = engine.power(minusOne, FractionValue.fromInts(1, 2));
      expect(powRes.isSuccess, isTrue);
      expect(powRes.valueOrNull!.real.toDouble(), closeTo(0, 1e-7));
      expect(powRes.valueOrNull!.imaginary.toDouble(), closeTo(1, 1e-7));
    });

    test(
      'Algebraic invariant: z * conj(z) has zero imaginary and equals |z|^2',
      () {
        final z = ComplexNumber.fromInts(3, -4);
        final conj = engine.conjugate(z).valueOrNull!;
        final prod = engine.multiply(z, conj).valueOrNull!;
        expect(prod.imaginary.toDouble(), equals(0.0));
        expect(prod.real.toDouble(), equals(25.0));

        final magSq = engine.magnitudeSquared(z).valueOrNull!;
        expect(magSq.toDouble(), equals(prod.real.toDouble()));
      },
    );
  });

  group('ComplexEngine: Transcendentals (exp, ln, sin, cos)', () {
    test("Euler's formula: exp(i * pi) = -1", () {
      final iPi = ComplexNumber(
        real: DecimalValue.fromInt(0),
        imaginary: DecimalValue.parse(math.pi.toString()),
      );
      final expRes = engine.exp(iPi);
      expect(expRes.isSuccess, isTrue);
      expect(expRes.valueOrNull!.real.toDouble(), closeTo(-1, 1e-7));
      expect(expRes.valueOrNull!.imaginary.toDouble(), closeTo(0, 1e-7));
    });

    test('Natural log of -1 is i * pi', () {
      final minusOne = ComplexNumber.fromInts(-1, 0);
      final lnRes = engine.ln(minusOne);
      expect(lnRes.isSuccess, isTrue);
      expect(lnRes.valueOrNull!.real.toDouble(), closeTo(0, 1e-10));
      expect(lnRes.valueOrNull!.imaginary.toDouble(), closeTo(math.pi, 1e-7));
    });

    test('Natural log of zero fails with DomainError', () {
      final lnRes = engine.ln(ComplexNumber.zero);
      expect(lnRes.isFailure, isTrue);
      expect(lnRes.errorOrNull, isA<DomainError>());
    });

    test('Trigonometric identity: sin^2(z) + cos^2(z) = 1 for complex z', () {
      final z = ComplexNumber.fromInts(1, 2);
      final sinZ = engine.sin(z).valueOrNull!;
      final cosZ = engine.cos(z).valueOrNull!;

      final sinSq = engine.multiply(sinZ, sinZ).valueOrNull!;
      final cosSq = engine.multiply(cosZ, cosZ).valueOrNull!;

      final sum = engine.add(sinSq, cosSq).valueOrNull!;
      expect(sum.real.toDouble(), closeTo(1.0, 1e-10));
      expect(sum.imaginary.toDouble(), closeTo(0.0, 1e-10));
    });
  });
}
