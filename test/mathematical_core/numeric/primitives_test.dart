import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/mathematical_core/numeric/primitives/combinatorics.dart';
import 'package:nexa_math/mathematical_core/numeric/primitives/number_theory.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

void main() {
  group('Number Theory & Combinatorics Unit Tests', () {
    test('GCD calculations', () {
      expect(
        NumberTheory.gcd(IntegerValue.fromInt(48), IntegerValue.fromInt(18)),
        equals(IntegerValue.fromInt(6)),
      );
      expect(
        NumberTheory.gcd(IntegerValue.fromInt(17), IntegerValue.fromInt(19)),
        equals(IntegerValue.fromInt(1)),
      );
      expect(
        NumberTheory.gcd(IntegerValue.fromInt(0), IntegerValue.fromInt(5)),
        equals(IntegerValue.fromInt(5)),
      );
      expect(
        NumberTheory.gcd(IntegerValue.fromInt(0), IntegerValue.fromInt(0)),
        equals(IntegerValue.zero),
      );
      expect(
        NumberTheory.gcd(IntegerValue.fromInt(-12), IntegerValue.fromInt(18)),
        equals(IntegerValue.fromInt(6)),
      );
      expect(
        NumberTheory.gcd(IntegerValue.fromInt(-12), IntegerValue.fromInt(-18)),
        equals(IntegerValue.fromInt(6)),
      );
    });

    test('LCM calculations', () {
      expect(
        NumberTheory.lcm(IntegerValue.fromInt(12), IntegerValue.fromInt(18)),
        equals(IntegerValue.fromInt(36)),
      );
      expect(
        NumberTheory.lcm(IntegerValue.fromInt(7), IntegerValue.fromInt(5)),
        equals(IntegerValue.fromInt(35)),
      );
      expect(
        NumberTheory.lcm(IntegerValue.fromInt(0), IntegerValue.fromInt(5)),
        equals(IntegerValue.zero),
      );
      expect(
        NumberTheory.lcm(IntegerValue.fromInt(0), IntegerValue.fromInt(0)),
        equals(IntegerValue.zero),
      );
      expect(
        NumberTheory.lcm(IntegerValue.fromInt(-12), IntegerValue.fromInt(18)),
        equals(IntegerValue.fromInt(36)),
      );
    });

    test('Primality test (isPrime)', () {
      expect(NumberTheory.isPrime(IntegerValue.fromInt(1)), isFalse);
      expect(NumberTheory.isPrime(IntegerValue.fromInt(2)), isTrue);
      expect(NumberTheory.isPrime(IntegerValue.fromInt(3)), isTrue);
      expect(NumberTheory.isPrime(IntegerValue.fromInt(4)), isFalse);
      expect(NumberTheory.isPrime(IntegerValue.fromInt(29)), isTrue);
      expect(NumberTheory.isPrime(IntegerValue.fromInt(100)), isFalse);

      // Carmichael numbers (pseudoprimes that fail simple Fermat tests)
      expect(NumberTheory.isPrime(IntegerValue.fromInt(561)), isFalse);
      expect(NumberTheory.isPrime(IntegerValue.fromInt(1105)), isFalse);
      expect(NumberTheory.isPrime(IntegerValue.fromInt(1729)), isFalse);

      // Large known primes (Mersenne prime 2^31 - 1)
      expect(NumberTheory.isPrime(IntegerValue.parse('2147483647')), isTrue);
      // Large composite
      expect(NumberTheory.isPrime(IntegerValue.parse('2147483649')), isFalse);
    });

    test('Factorial exact computation', () {
      expect(
        Combinatorics.factorial(IntegerValue.fromInt(0)).valueOrNull,
        equals(IntegerValue.fromInt(1)),
      );
      expect(
        Combinatorics.factorial(IntegerValue.fromInt(1)).valueOrNull,
        equals(IntegerValue.fromInt(1)),
      );
      expect(
        Combinatorics.factorial(IntegerValue.fromInt(5)).valueOrNull,
        equals(IntegerValue.fromInt(120)),
      );
      expect(
        Combinatorics.factorial(IntegerValue.fromInt(10)).valueOrNull,
        equals(IntegerValue.fromInt(3628800)),
      );

      // Negative factorial returns domain error
      expect(
        Combinatorics.factorial(IntegerValue.fromInt(-1)).isFailure,
        isTrue,
      );
    });

    test('Permutations P(n, k)', () {
      // P(5, 2) = 5 * 4 = 20
      expect(
        Combinatorics.permutations(
          IntegerValue.fromInt(5),
          IntegerValue.fromInt(2),
        ).valueOrNull,
        equals(IntegerValue.fromInt(20)),
      );
      // P(5, 5) = 120
      expect(
        Combinatorics.permutations(
          IntegerValue.fromInt(5),
          IntegerValue.fromInt(5),
        ).valueOrNull,
        equals(IntegerValue.fromInt(120)),
      );
      // P(5, 6) domain error
      expect(
        Combinatorics.permutations(
          IntegerValue.fromInt(5),
          IntegerValue.fromInt(6),
        ).isFailure,
        isTrue,
      );
    });

    test('Combinations C(n, k)', () {
      // C(5, 2) = 10
      expect(
        Combinatorics.combinations(
          IntegerValue.fromInt(5),
          IntegerValue.fromInt(2),
        ).valueOrNull,
        equals(IntegerValue.fromInt(10)),
      );
      // C(10, 3) = 120
      expect(
        Combinatorics.combinations(
          IntegerValue.fromInt(10),
          IntegerValue.fromInt(3),
        ).valueOrNull,
        equals(IntegerValue.fromInt(120)),
      );
      // C(5, 0) = 1
      expect(
        Combinatorics.combinations(
          IntegerValue.fromInt(5),
          IntegerValue.fromInt(0),
        ).valueOrNull,
        equals(IntegerValue.fromInt(1)),
      );
    });
  });
}
