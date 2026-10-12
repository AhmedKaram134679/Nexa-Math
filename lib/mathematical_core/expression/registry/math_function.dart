import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';

/// Contract representing a mathematical function callable within an expression.
abstract interface class MathFunction {
  /// The canonical name of this function (e.g. `sin`, `sqrt`, `gcd`).
  String get name;

  /// The minimum required arguments, or null if unrestricted.
  int? get minimumArguments;

  /// The maximum allowed arguments, or null if unrestricted.
  int? get maximumArguments;

  /// Evaluates this function with the evaluated [arguments] under [context] and [engine].
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  );
}
