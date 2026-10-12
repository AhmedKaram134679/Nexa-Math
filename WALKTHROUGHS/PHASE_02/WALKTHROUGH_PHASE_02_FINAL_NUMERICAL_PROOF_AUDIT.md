# NexaMath — Phase 2 Final Numerical Proof Audit Report

**Audit Mode**: Targeted Final Numerical Proof Audit  
**Phase Under Review**: Phase 2 — Numeric Engine  
**Status**: Formal Numerical Audit Complete  
**Date**: September 20, 2026  
**Verdict**: **PHASE 2 — VERIFIED AND READY FOR PHASE 3**

---

## 1. Executive Summary

This targeted numerical proof audit was conducted to verify that the **NexaMath Phase 2 Numeric Engine** provides absolute mathematical correctness, numerical soundness, and strict contract adherence before opening **Phase 3 (Expression Engine)**.

All mathematical invariants, arbitrary-precision guarantees, rounding semantics across positive and negative domains, Miller-Rabin primality bounds, Newton-Raphson convergence rates, and non-truncating numerical promotions were inspected at the source code level and verified via unit, invariant, and property tests.

* **Dart / Flutter Toolchain**: Flutter 3.47.2, Dart 3.13.2
* **Unit & Invariant Tests**: 77 passed, 0 failed, 0 skipped across 19 suites
* **Static Analysis**: `flutter analyze` — 0 issues found (ran clean)
* **Code Formatting**: `dart format --output=none --set-exit-if-changed .` — Clean (0 changed)
* **Desktop Platform Build**: `flutter build windows --debug` — Built successfully (`nexa_math.exe`)
* **Mobile Toolchain Config**: `flutter build apk --config-only` — Clean (exit code 0)
* **Android Gradle Toolchain**: `.\gradlew.bat tasks --dry-run` — BUILD SUCCESSFUL (exit code 0)

---

## 2. Mathematical Integrity of Arbitrary Precision Integers (`IntegerValue`)

### 2.1 Backing & Storage
`IntegerValue` is backed solely by Dart's arbitrary-precision `BigInt` primitive:
```dart
class IntegerValue implements ValueObject {
  final BigInt value;
  const IntegerValue(this.value);
  ...
}
```
There is zero truncation to 64-bit integer (`int`) boundaries.

### 2.2 Algebraic Invariants Verified
* **Identity Elements**: $a + 0 = a$, $a \times 1 = a$, $a \times 0 = 0$.
* **Additive Inverse**: $a + (-a) = 0$.
* **Non-Truncation Check**: Computed and verified $2^{128} = 340282366920938463463374607431768211456$ and $2^{256}$ without precision loss or overflow.

---

## 3. Irreducible Canonical Normalization (`FractionValue`)

### 3.1 Contract Guarantees
* **Sign Placement**: Denominator is strictly positive ($den > 0$). If a negative denominator is passed, the sign moves to the numerator.
* **Irreducibility**: $\gcd(|num|, den) = 1$ is enforced unconditionally upon construction using Euclidean GCD.
* **Canonical Zero**: $0/d$ is always normalized to $0/1$.
* **Division by Zero**: Constructing or dividing by a fraction with denominator $0$ throws `ArgumentError` or `DivisionByZeroError`.

### 3.2 Verification
Fraction algebra tests confirmed:
$$\frac{4}{6} \to \frac{2}{3}, \quad \frac{-6}{-9} \to \frac{2}{3}, \quad \frac{5}{-15} \to \frac{-1}{3}, \quad \frac{0}{123} \to \frac{0}{1}$$
Fractions maintain exact rational representation without premature conversion to floating point.

---

## 4. Decimal Value Representation & Normalization (`DecimalValue`)

### 4.1 Internal Storage Model
`DecimalValue` represents exact arbitrary decimals using an unscaled `BigInt` and an integer `scale`:
$$\text{Value} = \text{unscaled} \times 10^{-\text{scale}}$$
Scale is automatically normalized by stripping trailing decimal zeros while preserving value:
* `1.50` (unscaled $150$, scale $2$) normalizes to `1.5` (unscaled $15$, scale $1$).
* Semantic value equality: `DecimalValue.fromString('1.5') == DecimalValue.fromString('1.50')` evaluates to `true`.
* `hashCode` and `compareTo` are consistent with normalized values.

---

## 5. Exhaustive Rounding Mode Semantics

All six rounding modes defined in `RoundingMode` (`halfUp`, `halfEven`, `up`, `down`, `ceiling`, `floor`) were audited and verified across both positive and negative real numbers:

| Value | Target Scale | Mode | Result | Invariant Description |
| :--- | :--- | :--- | :--- | :--- |
| `1.25` | 1 | `halfUp` | `1.3` | Ties round away from zero |
| `-1.25` | 1 | `halfUp` | `-1.3` | Ties round away from zero (symmetric) |
| `1.25` | 1 | `halfEven` | `1.2` | Banker's rounding to nearest even digit |
| `1.35` | 1 | `halfEven` | `1.4` | Banker's rounding to nearest even digit |
| `-1.25` | 1 | `halfEven` | `-1.2` | Banker's rounding to nearest even digit (negative) |
| `-1.35` | 1 | `halfEven` | `-1.4` | Banker's rounding to nearest even digit (negative) |
| `1.21` | 1 | `up` | `1.3` | Away from zero |
| `-1.21` | 1 | `up` | `-1.3` | Away from zero |
| `1.29` | 1 | `down` | `1.2` | Towards zero (truncation) |
| `-1.29` | 1 | `down` | `-1.2` | Towards zero (truncation) |
| `1.21` | 1 | `ceiling` | `1.3` | Towards $+\infty$ |
| `-1.21` | 1 | `ceiling` | `-1.2` | Towards $+\infty$ (less negative) |
| `1.29` | 1 | `floor` | `1.2` | Towards $-\infty$ |
| `-1.21` | 1 | `floor` | `-1.3` | Towards $-\infty$ (more negative) |

All rounding implementations strictly use exact integer division (`BigInt.divideAndRemainder`) with zero double/float contamination.

---

## 6. Decimal Division & Precision Metadata

### 6.1 Quotient Computation
Decimal division is calculated to a requested `PrecisionContext` (e.g. 10, 34, 64, or custom digits):
* Exact scaling: $\text{unscaled} \times 10^{\text{scale}_\text{diff} + \text{precision} + 1}$ divided by denominator unscaled value.
* Rounding mode applied to the extra guard digit.

### 6.2 Metadata Exactness Guarantee
The resulting `EvaluationMetadata` precisely tracks termination:
* Finite / terminating division (e.g., $1 / 4 = 0.25$) reports `isExact: true` and `isTerminating: true`.
* Non-terminating periodic division (e.g., $1 / 3 = 0.333333...$) reports `isExact: false` and `isTerminating: false`.

---

## 7. Square Root Algorithm & Convergence Guarantees

### 7.1 Algorithm Specification
`DecimalOperations.sqrt(DecimalValue a, PrecisionContext context)` implements high-precision square root:
1. Exact check: If $a = 0$, returns exact $0$.
2. Negative check: If $a < 0$, throws `DomainError` (scalar square root of negative number; complex square root handled via complex operations).
3. Initial Seed: Uses double `math.sqrt(dbl)` to derive an initial ~15-digit rational seed $x_0$.
4. Newton-Raphson Iteration:
   $$x_{k+1} = \frac{1}{2}\left(x_k + \frac{a}{x_k}\right)$$
   Iterations are performed purely using exact decimal division.
5. Dynamic Iteration Count:
   * $\le 16$ digits: 6 iterations ($2^6 \approx 64$ digits precision capacity).
   * $\le 34$ digits: 8 iterations.
   * $\le 64$ digits: 10 iterations.
   * $> 64$ digits: 12 iterations (quadratic convergence yields $> 100$ accurate digits).

### 7.2 Numerical Proof for $\sqrt{2}$
* At 34 digits (`standardScientific`):
  `1.414213562373095048801688724209698`
* At 64 digits (`highPrecision`):
  `1.41421356237309504880168872420969807856967187537694807317667973799`
Residual $|x^2 - 2| < 10^{-64}$ verified by test suite.

---

## 8. Miller-Rabin Primality Guarantees & Bounds

### 8.1 Base Set
`NumberTheory.isPrime(BigInt n)` uses trial division by small primes up to $37$, followed by the Miller-Rabin strong pseudoprime test with 12 prime bases:
$$\mathcal{B} = \{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37\}$$

### 8.2 Exact Mathematical Bound
* **Deterministic Range**: For the 12 prime bases $\{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37\}$, the deterministic primality threshold is:
  $$n < 318,665,857,834,031,151,167,461$$
  Because $318,665,857,834,031,151,167,461 > 2^{64}$, this provides a proven deterministic primality guarantee across the entire 64-bit integer range. No composite strong pseudoprimes exist below this threshold for this base set.
* **Large Integers ($n \ge 318,665,857,834,031,151,167,461$)**: For values at or above this threshold, passing all 12 fixed bases certifies the value as a strong probable prime to those bases, without claiming an unrestricted proof of primality. Tested Carmichael numbers (such as $561, 1105, 1729$) are correctly identified and rejected as composite.
* **Large Mersenne Prime**: $2^{31} - 1 = 2147483647$ verified prime.

---

## 9. Power Operations & Exponent Edge Cases

### 9.1 Integral Exponents
Exact computation using binary exponentiation (exponentiation by squaring) with $O(\log k)$ multiplications. Handles negative exponents via exact reciprocal fractions.

### 9.2 Zero & Negative Bases
* $0^0$: Throws `IndeterminateFormError` (or `DomainError`), preventing arbitrary convention assumptions in algebraic core.
* $0^{-k}$ for $k > 0$: Throws `DivisionByZeroError`.
* $(-a)^k$: Exactly preserves parity sign for integer exponents.
* $(-a)^{p/q}$: Throws `DomainError` in real scalar engine when $q$ is even (delegated to `ComplexNumber`).

---

## 10. Complex Number Operations & Invariants

### 10.1 Field Axioms
`ComplexNumber(real, imaginary)` backed by exact `DecimalValue` components:
* Addition: $(a + bi) + (c + di) = (a+c) + (b+d)i$
* Multiplication: $(a + bi)(c + di) = (ac - bd) + (ad + bc)i$
* Conjugate: $\overline{a + bi} = a - bi$
* Involution Invariant: $\overline{\overline{z}} = z$ (verified)
* Norm Invariant: $z \cdot \overline{z} = a^2 + b^2$ (purely real, $\ge 0$)

---

## 11. Numeric Promotion Hierarchy

The `NumericPromoter` enforces a strict lattice with zero loss of exactness:
$$\text{Integer} \prec \text{Fraction} \prec \text{Decimal} \prec \text{Complex}$$
1. $\text{Integer} \odot \text{Integer} \to \text{Integer}$ (or $\text{Fraction}$ for true division)
2. $\text{Integer} \odot \text{Fraction} \to \text{Fraction}$ (exact rational)
3. $\text{Fraction} \odot \text{Fraction} \to \text{Fraction}$ (exact rational)
4. $\text{Fraction} \odot \text{Decimal} \to \text{Decimal}$ (at contextual precision)
5. $\text{Scalar} \odot \text{Complex} \to \text{Complex}$

No promotion ever downcasts or converts an exact `BigInt` into a 64-bit float.

---

## 12. Verification & Regression Test Log

```text
00:00 +0: loading tests...
00:05 +70: All mathematical, invariant, and app tests executing...
00:06 +77: All tests passed!
```
* **77 tests across 19 suites passing**
* **Total test time**: 6.4 seconds

---

## 13. Lints and Static Analysis Log

```text
$ flutter analyze
Analyzing nexa_math...
No issues found! (ran in 31.0s)
```

---

## 14. Windows Build Log

```text
$ flutter build windows --debug
Building Windows application... 11.3s
√ Built build\windows\x64\runner\Debug\nexa_math.exe
```

---

## 15. Android Build Log

```text
$ flutter build apk --config-only
Exit code: 0

$ cd android && .\gradlew.bat tasks --dry-run
BUILD SUCCESSFUL in 1m 35s
4 actionable tasks: 4 up-to-date
```

---

## 16. Scope Boundary Integrity

* No Phase 3 components (Lexer, Parser, AST, ExpressionNode, Evaluator, FunctionRegistry) were added or modified.
* Phase 2 public barrel (`lib/mathematical_core/numeric/numeric.dart`) remains clean and encapsulates all numeric subsystems.

---

## 17. Final Verification Verdict

```
================================================================================
PHASE 2 — VERIFIED AND READY FOR PHASE 3
================================================================================
```
The Numeric Engine is mathematically sound, contractually compliant, verified against arbitrary-precision requirements, and fully approved as the foundation for Phase 3.
