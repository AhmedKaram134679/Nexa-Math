/// Source code position tracking for diagnostics and syntax error reporting.
library;

/// Represents an immutable 1-based character position in a source expression.
final class SourcePosition {
  /// 0-based character offset from the start of the source string.
  final int offset;

  /// 1-based line number.
  final int line;

  /// 1-based column number within the line.
  final int column;

  const SourcePosition({
    required this.offset,
    required this.line,
    required this.column,
  });

  /// The start of a source input (offset 0, line 1, column 1).
  static const SourcePosition start = SourcePosition(
    offset: 0,
    line: 1,
    column: 1,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourcePosition &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          line == other.line &&
          column == other.column;

  @override
  int get hashCode => Object.hash(offset, line, column);

  @override
  String toString() => '$line:$column (offset $offset)';
}
