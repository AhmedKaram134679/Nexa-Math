import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';

/// Registry interface for resolving mathematical constants.
abstract interface class ConstantRegistry {
  /// Resolves a constant by [name], or returns null if not recognized.
  ScalarValue? resolve(String name);

  /// Checks whether a constant with [name] is present.
  bool contains(String name);
}

/// Production implementation of [ConstantRegistry] providing standard mathematical constants.
final class DefaultConstantRegistry implements ConstantRegistry {
  const DefaultConstantRegistry();

  /// 64-digit approximation of Archimedes' constant π.
  static final DecimalValue pi = DecimalValue.parse(
    '3.1415926535897932384626433832795028841971693993751058209749445923',
    isExact: false,
  );

  /// 64-digit approximation of Euler's number e.
  static final DecimalValue e = DecimalValue.parse(
    '2.7182818284590452353602874713526624977572470936999595749669676277',
    isExact: false,
  );

  /// 64-digit approximation of the Golden Ratio ϕ = (1 + √5)/2.
  static final DecimalValue phi = DecimalValue.parse(
    '1.6180339887498948482045868343656381177203091798057628621354486227',
    isExact: false,
  );

  @override
  ScalarValue? resolve(String name) {
    switch (name.toLowerCase()) {
      case 'pi':
      case 'π':
        return pi;
      case 'e':
        return e;
      case 'phi':
      case 'ϕ':
      case 'φ':
      case 'Φ':
        return phi;
      default:
        return null;
    }
  }

  @override
  bool contains(String name) => resolve(name) != null;
}
