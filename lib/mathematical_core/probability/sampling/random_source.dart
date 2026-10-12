/// Abstract interface defining a random number source for probability sampling.
///
/// Pure Dart contract matching `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §71.
abstract interface class RandomSource {
  /// Generates a pseudo-random floating-point value uniformly distributed in `[0.0, 1.0)`.
  double nextDouble();

  /// Generates a pseudo-random integer uniformly distributed in `[0, max)`.
  int nextInt(int max);
}
