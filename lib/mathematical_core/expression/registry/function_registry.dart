import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/angle_mode.dart';
import 'package:nexa_math/mathematical_core/common/math_context.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/expression/registry/math_function.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/decimal_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/primitives/combinatorics.dart';
import 'package:nexa_math/mathematical_core/numeric/primitives/number_theory.dart';
import 'package:nexa_math/mathematical_core/numeric/promotion/numeric_promoter.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Registry interface for resolving and registering mathematical functions.
abstract interface class FunctionRegistry {
  /// Resolves a function by [name], or returns null if not found.
  MathFunction? resolve(String name);

  /// Registers a new or custom [function].
  void register(MathFunction function);

  /// Checks if a function with [name] is registered.
  bool contains(String name);
}

/// Production implementation of [FunctionRegistry] pre-populated with all standard functions.
final class DefaultFunctionRegistry implements FunctionRegistry {
  final Map<String, MathFunction> _functions = {};

  DefaultFunctionRegistry() {
    _registerBuiltIns();
  }

  @override
  MathFunction? resolve(String name) => _functions[name.toLowerCase()];

  @override
  void register(MathFunction function) {
    _functions[function.name.toLowerCase()] = function;
  }

  @override
  bool contains(String name) => _functions.containsKey(name.toLowerCase());

  void _registerBuiltIns() {
    // --- Trigonometric (Respects AngleMode) ---
    register(_TrigFunction('sin', math.sin, isInverse: false));
    register(_TrigFunction('cos', math.cos, isInverse: false));
    register(_TrigFunction('tan', math.tan, isInverse: false));
    register(_TrigFunction('asin', math.asin, isInverse: true));
    register(_TrigFunction('acos', math.acos, isInverse: true));
    register(_TrigFunction('atan', math.atan, isInverse: true));

    // --- Hyperbolic ---
    register(
      _DoubleUnaryFunction('sinh', (x) => (math.exp(x) - math.exp(-x)) / 2),
    );
    register(
      _DoubleUnaryFunction('cosh', (x) => (math.exp(x) + math.exp(-x)) / 2),
    );
    register(
      _DoubleUnaryFunction('tanh', (x) {
        final e2x = math.exp(2 * x);
        return (e2x - 1) / (e2x + 1);
      }),
    );

    // --- Square root and Powers ---
    register(_SqrtFunction());
    register(
      _DoubleUnaryFunction(
        'cbrt',
        (x) => x < 0
            ? -math.pow(-x, 1 / 3).toDouble()
            : math.pow(x, 1 / 3).toDouble(),
      ),
    );

    // --- Exponential & Logarithm ---
    register(_DoubleUnaryFunction('exp', math.exp));
    register(
      _DoubleUnaryFunction('ln', (x) {
        if (x <= 0) {
          throw const DomainError(
            message: 'ln domain is x > 0',
            functionName: 'ln',
          );
        }
        return math.log(x);
      }),
    );
    register(
      _DoubleUnaryFunction('log', (x) {
        if (x <= 0) {
          throw const DomainError(
            message: 'log domain is x > 0',
            functionName: 'log',
          );
        }
        return math.log(x) / math.ln10;
      }),
    );
    register(
      _DoubleUnaryFunction('log10', (x) {
        if (x <= 0) {
          throw const DomainError(
            message: 'log10 domain is x > 0',
            functionName: 'log10',
          );
        }
        return math.log(x) / math.ln10;
      }),
    );
    register(
      _DoubleUnaryFunction('log2', (x) {
        if (x <= 0) {
          throw const DomainError(
            message: 'log2 domain is x > 0',
            functionName: 'log2',
          );
        }
        return math.log(x) / math.ln2;
      }),
    );

    // --- Rounding & Absolute Value ---
    register(_AbsFunction());
    register(_FloorFunction());
    register(_CeilFunction());
    register(_RoundFunction());

    // --- Number Theory & Combinatorics ---
    register(_GcdFunction());
    register(_LcmFunction());
    register(_FactorialFunction());
    register(_PermutationsFunction());
    register(_CombinationsFunction());

    // --- Min & Max ---
    register(_MinFunction());
    register(_MaxFunction());
  }
}

// ============================================================================
// Built-in Function Implementations
// ============================================================================

final class _SqrtFunction implements MathFunction {
  @override
  String get name => 'sqrt';
  @override
  int? get minimumArguments => 1;
  @override
  int? get maximumArguments => 1;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 1) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: 'sqrt requires 1 argument',
        ),
      );
    }
    final dec = NumericPromoter.toDecimal(arguments.first);
    return DecimalOperations.sqrt(dec, context: context.precision);
  }
}

final class _AbsFunction implements MathFunction {
  @override
  String get name => 'abs';
  @override
  int? get minimumArguments => 1;
  @override
  int? get maximumArguments => 1;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 1) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: 'abs requires 1 argument',
        ),
      );
    }
    return engine.absolute(arguments.first);
  }
}

final class _FloorFunction implements MathFunction {
  @override
  String get name => 'floor';
  @override
  int? get minimumArguments => 1;
  @override
  int? get maximumArguments => 1;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    final dec = NumericPromoter.toDecimal(arguments.first);
    final dbl = dec.toDouble().floor();
    return MathSuccess(
      IntegerValue.fromInt(dbl),
      metadata: CalculationMetadata.exact,
    );
  }
}

final class _CeilFunction implements MathFunction {
  @override
  String get name => 'ceil';
  @override
  int? get minimumArguments => 1;
  @override
  int? get maximumArguments => 1;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    final dec = NumericPromoter.toDecimal(arguments.first);
    final dbl = dec.toDouble().ceil();
    return MathSuccess(
      IntegerValue.fromInt(dbl),
      metadata: CalculationMetadata.exact,
    );
  }
}

final class _RoundFunction implements MathFunction {
  @override
  String get name => 'round';
  @override
  int? get minimumArguments => 1;
  @override
  int? get maximumArguments => 1;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    final dec = NumericPromoter.toDecimal(arguments.first);
    final dbl = dec.toDouble().round();
    return MathSuccess(
      IntegerValue.fromInt(dbl),
      metadata: CalculationMetadata.exact,
    );
  }
}

final class _GcdFunction implements MathFunction {
  @override
  String get name => 'gcd';
  @override
  int? get minimumArguments => 2;
  @override
  int? get maximumArguments => 2;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 2) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: 'gcd requires 2 arguments',
        ),
      );
    }
    final a = arguments[0];
    final b = arguments[1];
    if (a is! IntegerValue || b is! IntegerValue) {
      return const MathFailure(
        DomainError(
          message: 'gcd requires integer arguments.',
          functionName: 'gcd',
        ),
      );
    }
    return MathSuccess(
      NumberTheory.gcd(a, b),
      metadata: CalculationMetadata.exact,
    );
  }
}

final class _LcmFunction implements MathFunction {
  @override
  String get name => 'lcm';
  @override
  int? get minimumArguments => 2;
  @override
  int? get maximumArguments => 2;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 2) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: 'lcm requires 2 arguments',
        ),
      );
    }
    final a = arguments[0];
    final b = arguments[1];
    if (a is! IntegerValue || b is! IntegerValue) {
      return const MathFailure(
        DomainError(
          message: 'lcm requires integer arguments.',
          functionName: 'lcm',
        ),
      );
    }
    return MathSuccess(
      NumberTheory.lcm(a, b),
      metadata: CalculationMetadata.exact,
    );
  }
}

final class _FactorialFunction implements MathFunction {
  @override
  String get name => 'factorial';
  @override
  int? get minimumArguments => 1;
  @override
  int? get maximumArguments => 1;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 1) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: 'factorial requires 1 argument',
        ),
      );
    }
    final a = arguments.first;
    if (a is! IntegerValue) {
      return const MathFailure(
        DomainError(
          message: 'factorial requires integer argument.',
          functionName: 'factorial',
        ),
      );
    }
    return Combinatorics.factorial(a);
  }
}

final class _PermutationsFunction implements MathFunction {
  @override
  String get name => 'npr';
  @override
  int? get minimumArguments => 2;
  @override
  int? get maximumArguments => 2;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 2) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: 'nPr requires 2 arguments',
        ),
      );
    }
    final n = arguments[0];
    final k = arguments[1];
    if (n is! IntegerValue || k is! IntegerValue) {
      return const MathFailure(
        DomainError(
          message: 'nPr requires integer arguments.',
          functionName: 'nPr',
        ),
      );
    }
    return Combinatorics.permutations(n, k);
  }
}

final class _CombinationsFunction implements MathFunction {
  @override
  String get name => 'ncr';
  @override
  int? get minimumArguments => 2;
  @override
  int? get maximumArguments => 2;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 2) {
      return const MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: 'nCr requires 2 arguments',
        ),
      );
    }
    final n = arguments[0];
    final k = arguments[1];
    if (n is! IntegerValue || k is! IntegerValue) {
      return const MathFailure(
        DomainError(
          message: 'nCr requires integer arguments.',
          functionName: 'nCr',
        ),
      );
    }
    return Combinatorics.combinations(n, k);
  }
}

final class _MinFunction implements MathFunction {
  @override
  String get name => 'min';
  @override
  int? get minimumArguments => 2;
  @override
  int? get maximumArguments => 2;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    final aDec = NumericPromoter.toDecimal(arguments[0]);
    final bDec = NumericPromoter.toDecimal(arguments[1]);
    return MathSuccess(aDec.compareTo(bDec) <= 0 ? arguments[0] : arguments[1]);
  }
}

final class _MaxFunction implements MathFunction {
  @override
  String get name => 'max';
  @override
  int? get minimumArguments => 2;
  @override
  int? get maximumArguments => 2;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    final aDec = NumericPromoter.toDecimal(arguments[0]);
    final bDec = NumericPromoter.toDecimal(arguments[1]);
    return MathSuccess(aDec.compareTo(bDec) >= 0 ? arguments[0] : arguments[1]);
  }
}

final class _TrigFunction implements MathFunction {
  @override
  final String name;
  final double Function(double) fn;
  final bool isInverse;

  _TrigFunction(this.name, this.fn, {required this.isInverse});

  @override
  int? get minimumArguments => 1;
  @override
  int? get maximumArguments => 1;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 1) {
      return MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: '$name requires 1 argument',
        ),
      );
    }

    var input = NumericPromoter.toDecimal(arguments.first).toDouble();

    if (!isInverse) {
      // Convert angle to radians based on active AngleMode
      switch (context.angleMode) {
        case AngleMode.degrees:
          input = input * (math.pi / 180.0);
          break;
        case AngleMode.gradians:
          input = input * (math.pi / 200.0);
          break;
        case AngleMode.radians:
          break;
      }
    }

    final rawRes = fn(input);

    var resDbl = rawRes;
    if (isInverse) {
      // Inverse trig returns radians; convert output to active AngleMode
      switch (context.angleMode) {
        case AngleMode.degrees:
          resDbl = resDbl * (180.0 / math.pi);
          break;
        case AngleMode.gradians:
          resDbl = resDbl * (200.0 / math.pi);
          break;
        case AngleMode.radians:
          break;
      }
    }

    if (resDbl.isNaN) {
      return MathFailure(
        DomainError(
          message: 'Trigonometric operation $name evaluated to NaN.',
          functionName: name,
        ),
      );
    }

    // Convert to DecimalValue with active precision
    final dec = DecimalValue.parse(
      resDbl.toString(),
      isExact: false,
    ).roundToPrecision(context.precision);
    return MathSuccess(
      dec,
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precision.precisionDigits,
          method: 'trigonometric',
          converged: true,
        ),
      ),
    );
  }
}

final class _DoubleUnaryFunction implements MathFunction {
  @override
  final String name;
  final double Function(double) fn;

  _DoubleUnaryFunction(this.name, this.fn);

  @override
  int? get minimumArguments => 1;
  @override
  int? get maximumArguments => 1;

  @override
  MathResult<ScalarValue> invoke(
    List<ScalarValue> arguments,
    EvaluationContext context,
    NumericEngine engine,
  ) {
    if (arguments.length != 1) {
      return MathFailure(
        InvalidArgumentError(
          argumentName: 'arguments',
          reason: '$name requires 1 argument',
        ),
      );
    }
    final input = NumericPromoter.toDecimal(arguments.first).toDouble();
    try {
      final resDbl = fn(input);
      if (resDbl.isNaN) {
        return MathFailure(
          DomainError(
            message: 'Operation $name evaluated to NaN.',
            functionName: name,
          ),
        );
      }
      final dec = DecimalValue.parse(
        resDbl.toString(),
        isExact: false,
      ).roundToPrecision(context.precision);
      return MathSuccess(
        dec,
        metadata: CalculationMetadata(
          isExact: false,
          approximation: ApproximationMetadata(
            precision: context.precision.precisionDigits,
            method: name,
            converged: true,
          ),
        ),
      );
    } catch (e) {
      if (e is MathError) return MathFailure(e);
      return MathFailure(GenericMathError(message: e.toString()));
    }
  }
}
