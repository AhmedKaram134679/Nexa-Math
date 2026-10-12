# NexaMath — Phase 7: Calculus Engine Implementation & Verification Walkthrough

## 1. Executive Summary

**Phase 7 — Calculus Engine** for NexaMath has been designed, implemented, and fully verified in strict production implementation mode.
The Calculus Engine delivers analytical and high-precision numerical calculus capabilities in pure, platform-independent Dart with zero Flutter dependencies, conforming to Clean Architecture and Clean Code principles.

All existing Phase 0–6 capabilities and regressions remain 100% green and preserved. The verification suite expanded from **312 to 336 tests** (24 new comprehensive Phase 7 calculus tests), with 100% passing results, zero analyzer warnings, zero formatting violations, and clean Windows/Android build configurations.

---

## 2. Scope Implemented

The authoritative Phase 7 scope has been implemented completely without placeholders, mock data, or shortcuts:

### 2.1 Numerical Differentiation
1. **Forward Difference**: First-order forward finite-difference quotient `(f(x + h) - f(x)) / h`.
2. **Backward Difference**: First-order backward finite-difference quotient `(f(x) - f(x - h)) / h`.
3. **Central Difference**: Second-order central difference quotient `(f(x + h) - f(x - h)) / (2h)`.
4. **Richardson Extrapolation**: High-order Romberg-like extrapolation tableau over central differences with geometric step halving (`h_{k+1} = h_k / 2`), achieving high numerical accuracy and rigorous convergence monitoring.
5. **Adaptive Step Selection**: Controlled scale-aware initial step selection using optimal machine epsilon scaling $h \sim \epsilon^{1/3} \max(1, |x|)$ combined with Richardson extrapolation.

### 2.2 Numerical Integration (Quadrature)
1. **Composite Trapezoidal Rule**: Composite integration over $n$ subdivisions.
2. **Composite Simpson's 1/3 Rule**: Composite integration enforcing that $n$ is even ($n \ge 2$, $n \equiv 0 \pmod 2$). Invalid subdivision counts yield typed `InvalidArgumentError`.
3. **Composite Simpson's 3/8 Rule**: Composite integration enforcing $n \ge 3$ and $n \equiv 0 \pmod 3$. Invalid subdivision counts yield typed `InvalidArgumentError`.
4. **Gauss-Legendre Quadrature**: High-order numerical quadrature supporting orders $n \in \{2, 3, 4, 5\}$ with exact affine coordinate mapping $x = \frac{b-a}{2} t + \frac{a+b}{2}$. Verified exact on polynomials up to degree $2n - 1$.
5. **Adaptive Simpson Quadrature**: Recursive local error-control strategy monitoring $|S_{\text{left}} + S_{\text{right}} - S_{\text{whole}}| \le 15 \cdot \text{tol}$ with subdivision bisection, Richardson error correction ($+ \Delta / 15$), and strict maximum recursion depth guards returning `ConvergenceFailureError` on non-convergence.

### 2.3 Boundary and Singularity Handling
* **Equal boundaries ($a = b$)**: Directly produces exact `0` (`DecimalValue.zero`, `metadata: CalculationMetadata.exact`).
* **Reversed intervals ($a > b$)**: Automatically evaluates $-\int_b^a f(x) dx$ via negation of the transposed integral.
* **Domain / Singularity Handling**: Detects and propagates `DomainError`, `DivisionByZeroError`, and non-finite results (NaN, $\pm\infty$) immediately as typed `MathFailure` without silent corrupt approximations.

### 2.4 Symbolic Differentiation Integration
* Reuses Phase 6 `SymbolicDifferentiator` without duplication or second AST implementations.
* Supports arbitrary positive integer differentiation orders ($d^n/dx^n$) with typed validation ($n \ge 1$).
* Provides expression-level bridging: `numericalDerivativeOfExpression` and `definiteIntegralOfExpression` allowing continuous AST evaluation across points and intervals.

### 2.5 Structured Tracing & Honest Metadata
* `CalculusTrace` and `CalculusStep`: Pure mathematical audit trace recording method name, parameters, iteration numbers, intermediate values, estimated errors, and function evaluation counts.
* Integration with `CalculationMetadata` and `ApproximationMetadata`: Never claims approximations are exact; preserves distinction between analytical exactness and numerical approximations.

---

## 3. Package Architecture & File Structure

All Phase 7 code resides inside `lib/mathematical_core/calculus/` with zero Flutter dependencies:

```text
lib/mathematical_core/calculus/
├── differentiation/
│   └── numerical_differentiator.dart
├── integration/
│   └── quadrature_rules.dart
├── models/
│   ├── calculus_options.dart
│   ├── calculus_trace.dart
│   └── numeric_derivative.dart
├── calculus.dart
├── calculus_engine.dart
└── default_calculus_engine.dart
```

### Export Integration
* `lib/mathematical_core/mathematical_core.dart`: Added `export 'calculus/calculus.dart';`.

---

## 4. Test & Verification Gate Summary

### 4.1 Automated Test Results
* **Test Command**: `flutter test`
* **Baseline Test Count (Phase 6)**: 312 tests
* **New Phase 7 Tests**: 24 tests
* **Total Passing Tests**: **336 / 336 tests passed (100%)**
* **Failures**: 0

### 4.2 Static Analysis
* **Command**: `flutter analyze`
* **Result**: `No issues found!` (0 errors, 0 warnings, 0 lints)

### 4.3 Code Formatting
* **Command**: `dart format --output=none --set-exit-if-changed .`
* **Result**: Clean (0 changed files, exit code 0)

### 4.4 Windows Debug Build
* **Command**: `flutter build windows --debug`
* **Result**: `Built build\windows\x64\runner\Debug\nexa_math.exe` (Successful, 0 errors)

### 4.5 Android Configuration Verification
* **Command**: `flutter build apk --config-only`
* **Result**: Successful (exit code 0)

---

## 5. Mathematical Limitations & Known Boundaries

1. **Floating-point Evaluator Bridge**: Numerical differentiation and quadrature evaluate expressions using IEEE 754 `double` arithmetic at the sampling node level before wrapping into `DecimalValue`. This is numerically honest and documented; rounding errors near machine epsilon $\epsilon \approx 2.22 \times 10^{-16}$ are controlled by Richardson extrapolation and adaptive step sizing.
2. **Order Constraints on Simpson Rules**: Simpson's 1/3 requires even $n$ ($n \ge 2$); Simpson's 3/8 requires $n \ge 3$ and $n \equiv 0 \pmod 3$. Any violation is rejected with a typed `InvalidArgumentError`.
3. **Adaptive Recursion Limit**: Default maximum depth is 50. Pathologically oscillatory functions (e.g. $\sin(1/x)$ near 0) will exhaust recursion depth and return a typed `ConvergenceFailureError` rather than crashing or infinite looping.

---

## 6. Files Created and Modified

### Files Created:
1. `lib/mathematical_core/calculus/models/calculus_options.dart`
2. `lib/mathematical_core/calculus/models/calculus_trace.dart`
3. `lib/mathematical_core/calculus/models/numeric_derivative.dart`
4. `lib/mathematical_core/calculus/differentiation/numerical_differentiator.dart`
5. `lib/mathematical_core/calculus/integration/quadrature_rules.dart`
6. `lib/mathematical_core/calculus/calculus_engine.dart`
7. `lib/mathematical_core/calculus/default_calculus_engine.dart`
8. `lib/mathematical_core/calculus/calculus.dart`
9. `test/mathematical_core/calculus/calculus_engine_test.dart`

### Files Modified:
1. `lib/mathematical_core/mathematical_core.dart` (added export for calculus module)

---

## 7. Status Declaration

Every single Phase 7 acceptance criterion has been implemented, validated against rigorous mathematical edge cases, and verified via automated test suites and compiler builds.

```text
PHASE 7 — VERIFIED AND READY FOR PHASE 8
```
