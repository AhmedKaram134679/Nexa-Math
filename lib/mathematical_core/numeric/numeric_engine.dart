import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/default_numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';

/// Primary public façade interface for the NexaMath Numeric Engine.
///
/// Dispatches and coordinates arithmetic, elementary functions, precision handling,
/// and type conversions across scalar numerical types ([IntegerValue], [FractionValue],
/// [DecimalValue], [ComplexNumber]).
abstract interface class NumericEngine {
  /// Default factory constructor returning the canonical production implementation.
  factory NumericEngine({PrecisionContext context}) = DefaultNumericEngine;

  /// Active precision context governing precision digits and rounding behavior.
  PrecisionContext get context;

  /// Adds two scalar values: `left + right`.
  MathResult<ScalarValue> add(ScalarValue left, ScalarValue right);

  /// Subtracts two scalar values: `left - right`.
  MathResult<ScalarValue> subtract(ScalarValue left, ScalarValue right);

  /// Multiplies two scalar values: `left * right`.
  MathResult<ScalarValue> multiply(ScalarValue left, ScalarValue right);

  /// Divides two scalar values: `left / right`.
  MathResult<ScalarValue> divide(ScalarValue left, ScalarValue right);

  /// Exponentiation: `base ^ exponent`.
  MathResult<ScalarValue> power(ScalarValue base, ScalarValue exponent);

  /// Negation of a scalar value: `-value`.
  MathResult<ScalarValue> negate(ScalarValue value);

  /// Absolute value (or magnitude for complex) of a scalar value: `|value|`.
  MathResult<ScalarValue> absolute(ScalarValue value);

  /// Factorial: `value!`. Valid for non-negative integers.
  MathResult<ScalarValue> factorial(ScalarValue value);

  /// Explicit conversion between numeric types/kinds.
  MathResult<ScalarValue> convert(ScalarValue value, NumericType targetType);
}
