/// Authoritative top-level abstraction for all mathematical values in NexaMath.
///
/// Expression evaluation in NexaMath is not restricted to scalar numbers.
/// Values may encompass scalars, vectors, matrices, quantities, polynomials,
/// and symbolic forms.
abstract class MathValue {
  const MathValue();
}

/// Abstract contract for all scalar numerical values (Integer, Decimal, Fraction, Complex).
abstract class ScalarValue extends MathValue {
  const ScalarValue();
}
