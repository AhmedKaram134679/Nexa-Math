import 'dart:math' as math;

import 'package:nexa_math/core/errors/math_error.dart';
import 'package:nexa_math/core/result/calculation_metadata.dart';
import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/complex/complex_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/numeric_engine.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/complex_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/operations/decimal_operations.dart';
import 'package:nexa_math/mathematical_core/numeric/values/complex_number.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/fraction_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';

/// Canonical production implementation of [ComplexEngine].
final class DefaultComplexEngine implements ComplexEngine {
  final NumericEngine numericEngine;
  @override
  final PrecisionContext context;

  DefaultComplexEngine({
    NumericEngine? numericEngine,
    this.context = PrecisionContext.standard,
  }) : numericEngine = numericEngine ?? NumericEngine(context: context);

  @override
  MathResult<ComplexNumber> add(ComplexNumber left, ComplexNumber right) =>
      ComplexOperations.add(left, right);

  @override
  MathResult<ComplexNumber> subtract(ComplexNumber left, ComplexNumber right) =>
      ComplexOperations.subtract(left, right);

  @override
  MathResult<ComplexNumber> multiply(ComplexNumber left, ComplexNumber right) =>
      ComplexOperations.multiply(left, right);

  @override
  MathResult<ComplexNumber> divide(ComplexNumber left, ComplexNumber right) =>
      ComplexOperations.divide(left, right, context: context);

  @override
  MathResult<ComplexNumber> negate(ComplexNumber z) =>
      ComplexOperations.negate(z);

  @override
  MathResult<ComplexNumber> conjugate(ComplexNumber z) =>
      ComplexOperations.conjugate(z);

  @override
  MathResult<ComplexNumber> reciprocal(ComplexNumber z) =>
      divide(ComplexNumber.one, z);

  @override
  MathResult<DecimalValue> magnitudeSquared(ComplexNumber z) {
    // a^2 + b^2
    final a2 = DecimalOperations.multiply(z.real, z.real).valueOrNull!;
    final b2 = DecimalOperations.multiply(
      z.imaginary,
      z.imaginary,
    ).valueOrNull!;
    return DecimalOperations.add(a2, b2);
  }

  @override
  MathResult<DecimalValue> magnitude(ComplexNumber z) {
    final magSqRes = magnitudeSquared(z);
    if (magSqRes.isFailure) return MathFailure(magSqRes.errorOrNull!);
    return DecimalOperations.sqrt(magSqRes.valueOrNull!, context: context);
  }

  @override
  MathResult<DecimalValue> phase(ComplexNumber z) {
    if (z.isZero) {
      return const MathFailure(
        DomainError(
          message: 'Argument / phase is undefined for complex zero.',
          functionName: 'phase',
        ),
      );
    }
    final rDbl = z.real.toDouble();
    final iDbl = z.imaginary.toDouble();
    final phi = math.atan2(iDbl, rDbl);
    return MathSuccess(
      DecimalValue.parse(phi.toString(), isExact: false),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'atan2',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<ComplexNumber> sqrt(ComplexNumber z) {
    if (z.isZero) {
      return MathSuccess(
        ComplexNumber.zero,
        metadata: CalculationMetadata.exact,
      );
    }
    if (z.isReal) {
      if (!z.real.isNegative) {
        final realSqrt = DecimalOperations.sqrt(
          z.real,
          context: context,
        ).valueOrNull!;
        return MathSuccess(ComplexNumber.realOnly(realSqrt));
      } else {
        final imagSqrt = DecimalOperations.sqrt(
          z.real.abs(),
          context: context,
        ).valueOrNull!;
        return MathSuccess(ComplexNumber.imaginaryOnly(imagSqrt));
      }
    }

    // Formula: sqrt(a + bi) = u + iv
    // where u = sqrt((|z| + a) / 2)
    // and v = sign(b) * sqrt((|z| - a) / 2)
    final modRes = magnitude(z);
    if (modRes.isFailure) return MathFailure(modRes.errorOrNull!);
    final mod = modRes.valueOrNull!;

    final two = DecimalValue.fromInt(2);
    final modPlusA = DecimalOperations.add(mod, z.real).valueOrNull!;
    final uSq = DecimalOperations.divide(
      modPlusA,
      two,
      context: context,
    ).valueOrNull!;
    final u = DecimalOperations.sqrt(uSq, context: context).valueOrNull!;

    final modMinusA = DecimalOperations.subtract(mod, z.real).valueOrNull!;
    final vSq = DecimalOperations.divide(
      modMinusA,
      two,
      context: context,
    ).valueOrNull!;
    final vAbs = DecimalOperations.sqrt(vSq, context: context).valueOrNull!;
    final v = z.imaginary.isNegative ? -vAbs : vAbs;

    return MathSuccess(
      ComplexNumber(real: u, imaginary: v),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'complexSqrt',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<ComplexNumber> exp(ComplexNumber z) {
    // e^(a + bi) = e^a * (cos(b) + i * sin(b))
    final aDbl = z.real.toDouble();
    final bDbl = z.imaginary.toDouble();

    final expA = math.exp(aDbl);
    final cosB = math.cos(bDbl);
    final sinB = math.sin(bDbl);

    final realPart = expA * cosB;
    final imagPart = expA * sinB;

    return MathSuccess(
      ComplexNumber(
        real: DecimalValue.parse(realPart.toString(), isExact: false),
        imaginary: DecimalValue.parse(imagPart.toString(), isExact: false),
      ),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'complexExp',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<ComplexNumber> ln(ComplexNumber z) {
    if (z.isZero) {
      return const MathFailure(
        DomainError(
          message: 'Complex logarithm is undefined for zero.',
          functionName: 'ln',
        ),
      );
    }
    // ln(z) = ln|z| + i * arg(z)
    final rDbl = z.real.toDouble();
    final iDbl = z.imaginary.toDouble();
    final mod = math.sqrt(rDbl * rDbl + iDbl * iDbl);
    final phi = math.atan2(iDbl, rDbl);

    final lnMod = math.log(mod);

    return MathSuccess(
      ComplexNumber(
        real: DecimalValue.parse(lnMod.toString(), isExact: false),
        imaginary: DecimalValue.parse(phi.toString(), isExact: false),
      ),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'complexLn',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<ComplexNumber> power(ComplexNumber base, ScalarValue exponent) {
    if (base.isZero) {
      if (exponent is IntegerValue && exponent.isZero) {
        return const MathFailure(
          DomainError(
            message: '0^0 is an indeterminate form.',
            functionName: 'power',
          ),
        );
      }
      return MathSuccess(ComplexNumber.zero);
    }

    if (exponent is IntegerValue) {
      final expVal = exponent.value;
      if (expVal == BigInt.zero) {
        return MathSuccess(ComplexNumber.one);
      }
      if (expVal > BigInt.zero) {
        var result = ComplexNumber.one;
        var currentBase = base;
        var e = expVal;
        while (e > BigInt.zero) {
          if (e.isOdd) {
            result = multiply(result, currentBase).valueOrNull!;
          }
          if (e > BigInt.one) {
            currentBase = multiply(currentBase, currentBase).valueOrNull!;
          }
          e ~/= BigInt.two;
        }
        return MathSuccess(result);
      } else {
        // Negative integer power: 1 / (base ^ |exp|)
        final posPow = power(base, IntegerValue(-expVal)).valueOrNull!;
        return divide(ComplexNumber.one, posPow);
      }
    }

    // General power: base ^ exp = e^(exp * ln(base))
    ComplexNumber expComplex;
    if (exponent is ComplexNumber) {
      expComplex = exponent;
    } else if (exponent is DecimalValue) {
      expComplex = ComplexNumber.realOnly(exponent);
    } else if (exponent is FractionValue) {
      final div = DecimalOperations.divide(
        DecimalValue(exponent.numerator, 0),
        DecimalValue(exponent.denominator, 0),
        context: context,
      ).valueOrNull!;
      expComplex = ComplexNumber.realOnly(div);
    } else {
      expComplex = ComplexNumber.realOnly(
        DecimalValue.parse(exponent.toString()),
      );
    }

    final lnBaseRes = ln(base);
    if (lnBaseRes.isFailure) return MathFailure(lnBaseRes.errorOrNull!);
    final lnBase = lnBaseRes.valueOrNull!;

    final prodRes = multiply(expComplex, lnBase);
    if (prodRes.isFailure) return MathFailure(prodRes.errorOrNull!);

    return exp(prodRes.valueOrNull!);
  }

  @override
  MathResult<ComplexNumber> sin(ComplexNumber z) {
    // sin(a + bi) = sin(a)*cosh(b) + i*cos(a)*sinh(b)
    final aDbl = z.real.toDouble();
    final bDbl = z.imaginary.toDouble();

    final r = math.sin(aDbl) * _cosh(bDbl);
    final i = math.cos(aDbl) * _sinh(bDbl);

    return MathSuccess(
      ComplexNumber(
        real: DecimalValue.parse(r.toString(), isExact: false),
        imaginary: DecimalValue.parse(i.toString(), isExact: false),
      ),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'complexSin',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<ComplexNumber> cos(ComplexNumber z) {
    // cos(a + bi) = cos(a)*cosh(b) - i*sin(a)*sinh(b)
    final aDbl = z.real.toDouble();
    final bDbl = z.imaginary.toDouble();

    final r = math.cos(aDbl) * _cosh(bDbl);
    final i = -math.sin(aDbl) * _sinh(bDbl);

    return MathSuccess(
      ComplexNumber(
        real: DecimalValue.parse(r.toString(), isExact: false),
        imaginary: DecimalValue.parse(i.toString(), isExact: false),
      ),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'complexCos',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<ComplexNumber> tan(ComplexNumber z) {
    final s = sin(z).valueOrNull!;
    final c = cos(z).valueOrNull!;
    return divide(s, c);
  }

  @override
  MathResult<ComplexNumber> sinh(ComplexNumber z) {
    // sinh(a + bi) = sinh(a)*cos(b) + i*cosh(a)*sin(b)
    final aDbl = z.real.toDouble();
    final bDbl = z.imaginary.toDouble();

    final r = _sinh(aDbl) * math.cos(bDbl);
    final i = _cosh(aDbl) * math.sin(bDbl);

    return MathSuccess(
      ComplexNumber(
        real: DecimalValue.parse(r.toString(), isExact: false),
        imaginary: DecimalValue.parse(i.toString(), isExact: false),
      ),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'complexSinh',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<ComplexNumber> cosh(ComplexNumber z) {
    // cosh(a + bi) = cosh(a)*cos(b) + i*sinh(a)*sin(b)
    final aDbl = z.real.toDouble();
    final bDbl = z.imaginary.toDouble();

    final r = _cosh(aDbl) * math.cos(bDbl);
    final i = _sinh(aDbl) * math.sin(bDbl);

    return MathSuccess(
      ComplexNumber(
        real: DecimalValue.parse(r.toString(), isExact: false),
        imaginary: DecimalValue.parse(i.toString(), isExact: false),
      ),
      metadata: CalculationMetadata(
        isExact: false,
        approximation: ApproximationMetadata(
          precision: context.precisionDigits,
          method: 'complexCosh',
          converged: true,
        ),
      ),
    );
  }

  @override
  MathResult<ComplexNumber> tanh(ComplexNumber z) {
    final s = sinh(z).valueOrNull!;
    final c = cosh(z).valueOrNull!;
    return divide(s, c);
  }

  double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2.0;
  double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2.0;
}
