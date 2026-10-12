# NexaMath — Phase 7: Mathematical Correctness & Numerical Stability Acceptance Audit Report

## 1. Executive Summary

This document establishes the authoritative mathematical correctness, numerical stability, boundary preservation, and architecture acceptance audit for **NexaMath — Phase 7: Calculus Engine**.

The audit examined every implemented algorithm, theoretical truncation error, Richardson extrapolation tableau construction, adaptive step-size heuristic, quadrature weighting scheme, boundary symmetry property, error propagation path, and symbolic integration bridge.

### Final Verification Numbers:
* **Baseline Tests (Phases 0–6)**: 312 tests
* **Phase 7 Calculus Tests**: 31 tests (24 baseline calculus + 7 advanced counterexamples and stability tests)
* **Total Tests Passed**: **343 / 343 tests passed (100%)**
* **Static Analysis**: `flutter analyze` → 0 issues found (0 errors, 0 warnings, 0 lints)
* **Formatting**: `dart format --output=none --set-exit-if-changed .` → Clean (0 changed files)
* **Windows Debug Build**: `flutter build windows --debug` → Successful (`runner\Debug\nexa_math.exe` built)
* **Android Configuration Check**: `flutter build apk --config-only` → Successful (exit code 0)
* **Production Code Modifications**: Minimal, targeted numerical stability hardening (scale-relative tolerance thresholding in Richardson extrapolation, removal of artificial $h \le 0.1$ clamping for macro-scale evaluations, canonical default subdivision alignment to 1200, and factory constructor added to `CalculusEngine`).

---

## 2. Audit Scope & Authoritative Phase 7 Requirements

The audit verified adherence to:
1. `CALCULATOR_MASTER_SPECIFICATION.md`
2. `NEXAMATH_IMPLEMENTATION_BLUEPRINT.md`
3. `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` (Section 32)
4. `NEXAMATH_IMPLEMENTATION_ROADMAP.md` (Phase 7 Scope)
5. `PHASE_7_IMPLEMENTATION_WALKTHROUGH.md`

All audited features were verified to remain strictly within the mathematical core (`lib/mathematical_core/calculus/`) without importing Flutter, `dart:ui`, or any platform UI packages.

---

## 3. Source Files Inspected

* `lib/mathematical_core/calculus/calculus.dart`
* `lib/mathematical_core/calculus/calculus_engine.dart`
* `lib/mathematical_core/calculus/default_calculus_engine.dart`
* `lib/mathematical_core/calculus/differentiation/numerical_differentiator.dart`
* `lib/mathematical_core/calculus/integration/quadrature_rules.dart`
* `lib/mathematical_core/calculus/models/calculus_options.dart`
* `lib/mathematical_core/calculus/models/calculus_trace.dart`
* `lib/mathematical_core/calculus/models/numeric_derivative.dart`
* `lib/mathematical_core/expression/evaluator/ast_evaluator.dart`
* `lib/mathematical_core/symbolic/differentiation/symbolic_differentiator.dart`
* `test/mathematical_core/calculus/calculus_engine_test.dart`

---

## 4. Numerical Differentiation Audit

### 4.1 Forward, Backward, and Central Difference Schemes
* **Forward Difference**: $f'(x) \approx \frac{f(x+h) - f(x)}{h}$. Truncation error is $O(h)$. Verified against linear, quadratic, cubic, exponential, and trigonometric functions.
* **Backward Difference**: $f'(x) \approx \frac{f(x) - f(x-h)}{h}$. Truncation error is $O(h)$.
* **Central Difference**: $f'(x) \approx \frac{f(x+h) - f(x-h)}{2h}$. Truncation error is $O(h^2)$.
* **Input Validation**: $x \in \{\text{NaN}, \pm\infty\}$ and $h \le 0$ are explicitly checked and return a typed `InvalidArgumentError`.
* **Error Propagation**: Any domain violation during node evaluation (such as $\ln(0)$ or $\sqrt{-1}$) immediately short-circuits and propagates as a typed `MathFailure` (`DomainError`).

---

## 5. Richardson Extrapolation & Adaptive Step Audit

### 5.1 Richardson Extrapolation
* **Base Scheme**: Central difference quotient $D(h) = \frac{f(x+h) - f(x-h)}{2h}$, possessing an asymptotic expansion with even powers: $D(h) = f'(x) + c_1 h^2 + c_2 h^4 + c_3 h^6 + \dots$
* **Tableau Formulation**:
  $$D_{i, 0} = \frac{f(x + h_i) - f(x - h_i)}{2h_i}, \quad h_i = \frac{h_0}{2^i}$$
  $$D_{i, j} = D_{i, j-1} + \frac{D_{i, j-1} - D_{i-1, j-1}}{4^j - 1}$$
* **Mathematical Correctness of the Factor**: Because truncation error decreases in powers of $h^2$, halving $h$ reduces error by $2^2 = 4$. Thus, the cancellation factor is $4^j - 1$. The factor 4.0 used in the implementation is exact.
* **Convergence & Stopping Criterion**: The error estimate is the diagonal difference $|D_{i, i} - D_{i-1, i-1}|$. During the audit, the stopping criterion was hardened to use a scale-relative threshold:
  $$\text{errorEst} \le \max(\text{absoluteTolerance}, \text{tolerance} \cdot \max(1.0, |D_{i, i}|))$$
  preventing false non-convergence flags on macro-scale derivatives (e.g. $f'(10^8) = 2 \cdot 10^8$).
* **Non-Convergence Guard**: If the maximum iteration limit is reached without meeting the tolerance threshold, the method returns `ConvergenceFailureError` rather than claiming unverified convergence.

### 5.2 Adaptive Step-Size Selection
* **Heuristic**: Uses the standard floating-point scale-aware initial step heuristic $h_0 \sim \epsilon^{1/3} \max(1.0, |x|)$, where $\epsilon \approx 2.22 \times 10^{-16}$.
* **Documentation Honesty**: The implementation uses this scale-aware initial step heuristic followed by iterative Richardson extrapolation. It does not perform a multi-interval domain partitioning.

---

## 6. Numerical Integration Audit

### 6.1 Composite Trapezoidal Rule
* Formula: $T_n = h \left[ \frac{f(a) + f(b)}{2} + \sum_{i=1}^{n-1} f(a + ih) \right]$.
* Truncation error: $O(h^2)$.
* Validated against polynomials, exponential, and trigonometric functions.

### 6.2 Composite Simpson's 1/3 Rule
* Formula: $S_n = \frac{h}{3} \left[ f(a) + 4 \sum_{\text{odd}} f(x_i) + 2 \sum_{\text{even}} f(x_i) + f(b) \right]$.
* Truncation error: $O(h^4)$.
* Subdivision Constraint: Strictly enforces $n \ge 2$ and $n \equiv 0 \pmod 2$. An odd $n$ returns `InvalidArgumentError`.

### 6.3 Composite Simpson's 3/8 Rule
* Formula: $S_{3/8} = \frac{3h}{8} \left[ f(a) + 3 f(x_1) + 3 f(x_2) + 2 f(x_3) + \dots + f(b) \right]$.
* Truncation error: $O(h^4)$.
* Subdivision Constraint: Strictly enforces $n \ge 3$ and $n \equiv 0 \pmod 3$. Any violation returns `InvalidArgumentError`.
* Canonical Configuration: Default subdivisions in `NumericalCalculusOptions` set to $1200 = \text{lcm}(2, 3) \times 200$, ensuring seamless out-of-the-box compatibility with both Simpson rules.

### 6.4 Gauss-Legendre Quadrature
* Supports orders $n \in \{2, 3, 4, 5\}$.
* Exact affine coordinate transformation from $[-1, 1]$ to $[a, b]$:
  $$x_i = \frac{b-a}{2} t_i + \frac{a+b}{2}, \quad w'_i = \frac{b-a}{2} w_i$$
* **Node & Weight Precision**: Audited against NIST/Abramowitz & Stegun tables. All nodes and weights are symmetric and recorded to full double precision (18 decimal places).
* **Polynomial Exactness**: Verified exact within machine precision for all polynomials up to degree $2n - 1$ (e.g. order 2 is exact on cubics $x^3 + 2x^2 - x + 1$).

### 6.5 Adaptive Simpson Quadrature
* Recursively refines intervals using the adaptive Simpson local error estimator:
  $$|S_{\text{left}} + S_{\text{right}} - S_{\text{whole}}| \le 15 \cdot \text{tol}$$
* When local error estimate satisfies the threshold, applies Richardson error correction:
  $$I \approx S_{\text{left}} + S_{\text{right}} + \frac{S_{\text{left}} + S_{\text{right}} - S_{\text{whole}}}{15}$$
* Tolerance splitting: recursively assigns $\text{tol} / 2$ to subintervals, subject to the numerical assumptions of the method and the configured recursion-depth limit.
* Recursion guard: bounded by `maxRecursionDepth` (default 50), preventing stack overflow and returning `ConvergenceFailureError` if tolerance cannot be achieved.

---

## 7. Boundary and Singularity Audit

* **Equal Boundaries ($a = b$)**: Directly yields `DecimalValue.zero` with `CalculationMetadata.exact` without evaluating $f(x)$.
* **Reversed Boundaries ($a > b$)**: Computes $\int_a^b f(x) dx = -\int_b^a f(x) dx$ with exact negation preserving metadata.
* **Interior & Endpoint Singularities**: The engine intercepts non-finite evaluations (NaN, $\pm\infty$) and typed failures (`DivisionByZeroError`, `DomainError`) across all quadrature rules and aborts with a typed `MathFailure`.
* **Honest Singularity Boundary**: The engine detects singularities when a quadrature node evaluates inside an undefined or non-finite region. It does not claim formal analytical residue or Cauchy principal value detection for un-sampled points.

---

## 8. Symbolic Differentiation Integration Audit

* **AST & Engine Reuse**: Directly coordinates with Phase 6 `SymbolicDifferentiator` without creating parallel AST nodes or parser engines.
* **Higher-Order Analytical Differentiation**: Iteratively applies the differentiator for orders $n \ge 1$. Rejects $n < 1$ with `InvalidArgumentError`.
* **Expression Bridging**: `numericalDerivativeOfExpression` and `definiteIntegralOfExpression` evaluate AST nodes across points by substituting variable values in `EvaluationContext`, evaluating via `AstEvaluator`, and converting scalars to `double` via `NumericPromoter.toDecimal(scalar).toDouble()`.

---

## 9. Precision & Floating-Point Bridge Audit

* **Node-Level Precision**: Sampling node evaluation in numerical calculus is performed in 64-bit IEEE 754 floating point (`double`), offering 53 bits of significand precision ($\approx 15\text{--}17$ decimal digits).
* **Decimal Wrapping**: Output values are wrapped into `DecimalValue.parse(approx.toString(), isExact: false)`.
* **Metadata Honesty**: Output `CalculationMetadata` sets `isExact = false` and attaches `ApproximationMetadata` with the method name, converged status, and error bound. It never masquerades a numerical approximation as an exact integer or fraction.

---

## 10. Counterexample Testing Matrix

| Test Case | Method | Expected Mathematical Behavior | Observed Engine Behavior | Verdict |
| :--- | :--- | :--- | :--- | :--- |
| $\frac{d}{dx}[x^2]$ at $x = 3$ | Central Difference | $6.0$ | $6.0 \pm 10^{-5}$ | **PASS** |
| $\frac{d}{dx}[x^3]$ at $x = 2$ | Forward Difference | $12.0$ | $12.0 \pm 10^{-4}$ | **PASS** |
| $\frac{d}{dx}[x^3]$ at $x = 2$ | Backward Difference | $12.0$ | $12.0 \pm 10^{-4}$ | **PASS** |
| $\frac{d}{dx}[\sin(x)]$ at $x = 0$ | Richardson Extrapolation | $1.0$ | $1.0 \pm 10^{-7}$ | **PASS** |
| $\frac{d}{dx}[\exp(x)]$ at $x = 1$ | Adaptive Step | $e \approx 2.7182818$ | $e \pm 10^{-6}$ | **PASS** |
| $\frac{d}{dx}[\ln(x)]$ at $x = 2$ | Richardson Extrapolation | $0.5$ | $0.5 \pm 10^{-7}$ | **PASS** |
| $\frac{d}{dx}[x^2]$ at $x = 10^8$ | Adaptive / Richardson | $2 \cdot 10^8$ | $2 \cdot 10^8 \pm 10^2$ acceptance window (actual error $\approx 3.6 \times 10^{-3}$, rel. err $\approx 1.8 \times 10^{-11}$) | **PASS** |
| $\frac{d}{dx}[\sin(1/x)]$ at $x = 10^{-4}$ | Richardson | Finite derivative ($-10^8 \cos(10^4) \approx 95,215,536.83$), rapid local oscillation | Deterministic `MathResult` (bounded approx $\approx 95,215,536.81$ / failure) | **PASS** |
| $\frac{d}{dx}[\ln(x)]$ at $x \le 0$ | Central Difference | Outside domain | Returns `DomainError` | **PASS** |
| $\int_0^1 x^2 dx$ | Trapezoidal | $1/3$ | $0.3333 \dots \pm 10^{-4}$ | **PASS** |
| $\int_0^1 x^3 dx$ | Simpson 1/3 ($n=100$) | $1/4$ | $0.25 \pm 10^{-7}$ | **PASS** |
| Simpson 1/3 ($n=101$) | Simpson 1/3 | Invalid subdivision | Returns `InvalidArgumentError` | **PASS** |
| $\int_0^1 x^3 dx$ | Simpson 3/8 ($n=99$) | $1/4$ | $0.25 \pm 10^{-7}$ | **PASS** |
| Simpson 3/8 ($n=100$) | Simpson 3/8 | Invalid subdivision | Returns `InvalidArgumentError` | **PASS** |
| $\int_0^\pi \sin(x) dx$ | Gauss-Legendre (order 5) | $2.0$ | $2.0 \pm 10^{-4}$ | **PASS** |
| $\int_{-1}^2 (x^3 + 2x^2 - x + 1) dx$ | Gauss-Legendre (order 2) | $11.25$ | $11.25 \pm 10^{-6}$ | **PASS** |
| $\int_0^1 \exp(x) dx$ | Adaptive Simpson | $e - 1 \approx 1.71828$ | $e - 1 \pm 10^{-6}$ | **PASS** |
| $\int_4^4 x^2 dx$ | Any | Exact $0$ | `DecimalValue.zero`, exact metadata | **PASS** |
| $\int_2^0 x^2 dx$ | Adaptive Simpson | $-8/3 \approx -2.66667$ | $-8/3 \pm 10^{-7}$ | **PASS** |
| $\int_{-1}^1 \frac{1}{x} dx$ | Trapezoidal | Undefined / singularity | Returns `DivisionByZeroError` | **PASS** |
| $\int_1^{1.00001} \exp(x) dx$ | Adaptive Simpson | $e \cdot 10^{-5} \approx 2.718 \cdot 10^{-5}$ | $e \cdot 10^{-5} \pm 10^{-9}$ | **PASS** |
| $\frac{d}{dx}[x^3]$ (Symbolic) | Phase 6 Engine | $3x^2$ | Differentiated AST tree | **PASS** |
| $\frac{d^2}{dx^2}[x^3]$ (Symbolic) | Phase 6 Engine | $6x$ | Higher-order AST tree | **PASS** |
| $\frac{d}{dx}[x^3]$ at $x=2$ | Expression Bridge | $12.0$ | $12.0 \pm 10^{-5}$ | **PASS** |
| $\int_0^3 x^2 dx$ | Expression Bridge | $9.0$ | $9.0 \pm 10^{-5}$ | **PASS** |

---

## 11. Minimal Production Changes Made During Audit

1. **`lib/mathematical_core/calculus/differentiation/numerical_differentiator.dart`**:
   - Replaced absolute-only convergence check in Richardson extrapolation with scale-relative threshold: $\max(\text{absoluteTolerance}, \text{tolerance} \cdot \max(1.0, |\text{approx}|))$, ensuring numerical stability when evaluating macro-scale derivatives.
   - Removed artificial clamping of step size $h \le 0.1$ when user or adaptive options request larger scale-appropriate initial steps.
2. **`lib/mathematical_core/calculus/models/calculus_options.dart`**:
   - Adjusted default `subdivisions` from $1000$ to $1200$ ($\text{lcm}(2, 3) \times 200$), making the default configuration simultaneously compatible with Simpson's 1/3 and Simpson's 3/8 rules.
3. **`lib/mathematical_core/calculus/calculus_engine.dart`**:
   - Added canonical factory constructor `factory CalculusEngine(...) = DefaultCalculusEngine;` matching the architecture of `SymbolicEngine`, `ExpressionEngine`, and `MatrixEngine`.
   - Standardized imports to use package URI notation (`package:nexa_math/...`).

---

## 12. Final Acceptance Decision

Every Phase 7 acceptance criterion has been validated with mathematical rigor, independent counterexamples, clean code verification, and zero regression across Phases 0–6.

```text
PHASE 7 — VERIFIED AND READY FOR PHASE 8
```

Production Changes: MINIMAL, TARGETED CORRECTIONS ONLY
