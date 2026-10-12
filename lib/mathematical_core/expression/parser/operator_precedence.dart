/// Precedence and associativity definitions for NexaMath expression operators.
library;

/// Operator associativity direction.
enum Associativity { left, right }

/// Precedence definitions used by the Pratt parser.
final class OperatorPrecedence {
  const OperatorPrecedence._();

  static const int none = 0;
  static const int addition = 10; // +, -
  static const int multiplication = 20; // *, /, %
  static const int implicitMultiplication =
      25; // 2x, 3(4) (binds tighter than explicit div/mult)
  static const int prefixUnary = 30; // +x, -x
  static const int power = 40; // ^ (right associative)
  static const int postfix = 50; // !
}
