import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/source_position.dart';
import 'package:nexa_math/mathematical_core/expression/tokens/token_type.dart';

/// An immutable token produced by lexical scanning of a mathematical expression.
final class Token {
  /// The specific lexical classification of this token.
  final TokenType type;

  /// The raw character substring representing this token in the source expression.
  final String lexeme;

  /// The starting source position of this token.
  final SourcePosition position;

  /// Optional pre-parsed scalar literal representation (e.g. [IntegerValue] or [DecimalValue]).
  ///
  /// Set only for number tokens to preserve exact numerical representation without floating point drift.
  final ScalarValue? literalValue;

  const Token({
    required this.type,
    required this.lexeme,
    required this.position,
    this.literalValue,
  });

  /// Factory helper for creating an end-of-input token at a given position.
  factory Token.eof(SourcePosition position) =>
      Token(type: TokenType.endOfInput, lexeme: '', position: position);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          lexeme == other.lexeme &&
          position == other.position &&
          literalValue == other.literalValue;

  @override
  int get hashCode => Object.hash(type, lexeme, position, literalValue);

  @override
  String toString() =>
      'Token($type, "$lexeme", $position${literalValue != null ? ", value: $literalValue" : ""})';
}
