import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Exact combinatorial primitives for NexaMath.
///
/// Implements factorial, permutations, and combinations with domain validation
/// and arbitrary-precision integer results.
final class Combinatorics {
  const Combinatorics();

  /// Computes the factorial of a non-negative integer [n]!
  ///
  /// Invariants:
  /// - `0! = 1`
  /// - `n! = n * (n - 1)!` for `n > 0`
  /// - `n < 0` produces [DomainError]
  static MathResult<IntegerValue> factorial(IntegerValue n) {
    if (n.isNegative) {
      return const MathFailure(
        DomainError(
          message: 'Factorial is undefined for negative integers.',
          functionName: 'factorial',
        ),
      );
    }

    if (n.isZero || n == IntegerValue.one) {
      return MathSuccess(IntegerValue.one, metadata: CalculationMetadata.exact);
    }

    // Safety threshold for factorial computation to avoid out-of-memory
    if (n.value > BigInt.from(10000)) {
      return const MathFailure(
        OverflowError(
          message: 'Factorial input is too large for finite memory evaluation.',
        ),
      );
    }

    var result = BigInt.one;
    var current = n.value;
    while (current > BigInt.one) {
      result *= current;
      current -= BigInt.one;
    }

    return MathSuccess(
      IntegerValue(result),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Computes the number of permutations `P(n, k) = n! / (n - k)!`.
  ///
  /// Domain: `n >= 0`, `k >= 0`, and `k <= n`.
  static MathResult<IntegerValue> permutations(IntegerValue n, IntegerValue k) {
    if (n.isNegative || k.isNegative) {
      return const MathFailure(
        DomainError(
          message: 'Permutations P(n, k) requires non-negative arguments.',
          functionName: 'permutations',
        ),
      );
    }

    if (k.value > n.value) {
      return const MathFailure(
        DomainError(
          message: 'Cannot choose k > n items in permutations P(n, k).',
          functionName: 'permutations',
        ),
      );
    }

    if (k.isZero) {
      return MathSuccess(IntegerValue.one, metadata: CalculationMetadata.exact);
    }

    var result = BigInt.one;
    final limit = n.value - k.value;
    var current = n.value;
    while (current > limit) {
      result *= current;
      current -= BigInt.one;
    }

    return MathSuccess(
      IntegerValue(result),
      metadata: CalculationMetadata.exact,
    );
  }

  /// Computes the number of combinations `C(n, k) = n! / (k! * (n - k)!)`.
  ///
  /// Domain: `n >= 0`, `k >= 0`, and `k <= n`.
  static MathResult<IntegerValue> combinations(IntegerValue n, IntegerValue k) {
    if (n.isNegative || k.isNegative) {
      return const MathFailure(
        DomainError(
          message: 'Combinations C(n, k) requires non-negative arguments.',
          functionName: 'combinations',
        ),
      );
    }

    if (k.value > n.value) {
      return const MathFailure(
        DomainError(
          message: 'Cannot choose k > n items in combinations C(n, k).',
          functionName: 'combinations',
        ),
      );
    }

    if (k.isZero || k.value == n.value) {
      return MathSuccess(IntegerValue.one, metadata: CalculationMetadata.exact);
    }

    // Optimization: C(n, k) == C(n, n - k)
    var effectiveK = k.value;
    final nMinusK = n.value - k.value;
    if (effectiveK > nMinusK) {
      effectiveK = nMinusK;
    }

    var result = BigInt.one;
    for (var i = BigInt.one; i <= effectiveK; i += BigInt.one) {
      result = (result * (n.value - i + BigInt.one)) ~/ i;
    }

    return MathSuccess(
      IntegerValue(result),
      metadata: CalculationMetadata.exact,
    );
  }
}
