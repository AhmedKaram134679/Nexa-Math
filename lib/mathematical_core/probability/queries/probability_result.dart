import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/probability/queries/probability_query.dart';

/// Structured outcome of evaluating a [ProbabilityQuery].
///
/// Encapsulates the evaluated probability [value] (as a canonical [ScalarValue])
/// and the original [query] definition.
final class ProbabilityResult {
  /// The evaluated probability value, bounded in $[0.0, 1.0]$.
  final ScalarValue value;

  /// The original structured query evaluated.
  final ProbabilityQuery query;

  const ProbabilityResult({required this.value, required this.query});

  @override
  String toString() => 'ProbabilityResult(value: $value, query: $query)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProbabilityResult &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          query == other.query;

  @override
  int get hashCode => Object.hash(value, query);
}
