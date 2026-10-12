/// Lexical token types recognized by the NexaMath Expression Lexer.
library;

/// Enumerates all lexical token types in the NexaMath expression grammar.
enum TokenType {
  // --- Literals ---
  /// Exact integer literal without decimal point (e.g. `42`, `100000000000000000000`).
  integer,

  /// Decimal literal with explicit fractional part (e.g. `3.14159`, `.5`).
  decimal,

  /// Number literal in scientific notation (e.g. `1.23e-4`, `6.022E23`).
  scientificNumber,

  // --- Identifiers ---
  /// Alphanumeric name identifying a variable, constant, or function (e.g. `x`, `sin`, `pi`).
  identifier,

  // --- Arithmetic Operators ---
  /// Addition operator (`+`).
  plus,

  /// Subtraction / unary negation operator (`-`).
  minus,

  /// Explicit multiplication operator (`*`, `×`, `·`).
  multiply,

  /// Explicit division operator (`/`, `÷`).
  divide,

  /// Modulo operator (`%`).
  modulo,

  /// Exponentiation operator (`^`).
  power,

  /// Postfix factorial operator (`!`).
  factorial,

  // --- Delimiters & Grouping ---
  /// Opening left parenthesis (`(`).
  leftParen,

  /// Closing right parenthesis (`)`).
  rightParen,

  /// Comma separator for function arguments (`,`).
  comma,

  // --- Structural ---
  /// Signifies end of input string.
  endOfInput,
}
