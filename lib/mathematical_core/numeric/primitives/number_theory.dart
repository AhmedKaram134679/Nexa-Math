import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Exact number-theoretic primitives for NexaMath.
///
/// Operates exclusively with arbitrary-precision [IntegerValue]s.
final class NumberTheory {
  const NumberTheory();

  /// Computes the Greatest Common Divisor (GCD) of [a] and [b] using the Euclidean algorithm.
  /// `gcd(a, b) >= 0`.
  static IntegerValue gcd(IntegerValue a, IntegerValue b) {
    return IntegerValue(a.value.gcd(b.value));
  }

  /// Computes the Least Common Multiple (LCM) of [a] and [b].
  /// Invariant: `lcm(a, b) = (|a * b|) / gcd(a, b)`.
  /// `lcm(a, 0) = 0`.
  static IntegerValue lcm(IntegerValue a, IntegerValue b) {
    if (a.isZero || b.isZero) {
      return IntegerValue.zero;
    }
    final gcdVal = a.value.gcd(b.value);
    final mult = (a.value * b.value).abs();
    return IntegerValue(mult ~/ gcdVal);
  }

  /// Determines whether [n] is a prime number.
  ///
  /// Mathematical Guarantees:
  /// - Deterministically exact for all integers n < 318,665,857,834,031,151,167,461 using the 12 proven
  ///   deterministic Miller-Rabin bases {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}.
  ///   Because 318,665,857,834,031,151,167,461 > 2^64, this guarantees deterministic classification across
  ///   the entire 64-bit integer range.
  /// - For values at or above the proven deterministic threshold, passing all 12 fixed Miller-Rabin bases
  ///   establishes only that the value passes the strong probable-prime tests for those specific bases.
  ///   It does not constitute an unrestricted proof of primality.
  /// - Known Carmichael numbers (such as 561, 1105, 1729) are correctly rejected by this multi-base configuration.
  static bool isPrime(IntegerValue n) {
    final v = n.value;
    if (v <= BigInt.one) return false;
    if (v == BigInt.two || v == BigInt.from(3)) return true;
    if (v.isEven || v % BigInt.from(3) == BigInt.zero) return false;

    // Trial division up to sqrt(v) for moderate sizes
    var i = BigInt.from(5);
    final two = BigInt.two;
    final six = BigInt.from(6);
    while (i * i <= v) {
      if (v % i == BigInt.zero || v % (i + two) == BigInt.zero) {
        return false;
      }
      i += six;
      // Cap trial steps to avoid indefinite computation on massive integers
      if (i > BigInt.from(1000000)) break;
    }

    if (i * i > v) return true;

    // Miller-Rabin test for larger integers
    return _millerRabin(v);
  }

  static bool _millerRabin(BigInt n) {
    // Write n - 1 as 2^s * d
    var d = n - BigInt.one;
    var s = 0;
    while (d.isEven) {
      d ~/= BigInt.two;
      s++;
    }

    // Deterministic bases for numbers up to 318,665,857,834,031,151,167,461 (> 2^64)
    final bases = [
      BigInt.two,
      BigInt.from(3),
      BigInt.from(5),
      BigInt.from(7),
      BigInt.from(11),
      BigInt.from(13),
      BigInt.from(17),
      BigInt.from(19),
      BigInt.from(23),
      BigInt.from(29),
      BigInt.from(31),
      BigInt.from(37),
    ];

    for (final a in bases) {
      if (n <= a) break;
      var x = a.modPow(d, n);
      if (x == BigInt.one || x == n - BigInt.one) continue;

      var composite = true;
      for (var r = 1; r < s; r++) {
        x = x.modPow(BigInt.two, n);
        if (x == n - BigInt.one) {
          composite = false;
          break;
        }
      }
      if (composite) return false;
    }
    return true;
  }
}
