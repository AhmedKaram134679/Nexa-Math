# NexaMath — Phase 9: Statistics & Regression Specification

**Document Type:** Architectural & Mathematical Engineering Specification\
**Status:** Authoritative Implementation Contract (Final Hardened Pass)\
**Author:** Senior Mathematical Software Architect & Numerical Methods Engineer\
**Date:** September 23, 2026\
**Target Engine:** `lib/mathematical_core/statistics/`\
**Host Framework:** Flutter / Pure Dart Mathematical Core\
**Target Platforms:** Windows & Android

---

## 1. Executive Summary

This document establishes the final authoritative mathematical, algorithmic,
architectural, and error contract for **Phase 9 — Statistics & Regression** of
the NexaMath computing platform.

In strict adherence to the project's engineering principles:

- **No production code is implemented during this specification pass.** The
  repository remains production-clean.
- **Phases 0 through 8 remain completely sealed, protected, and unmodified.**
  (Verified baseline: 374/374 unit tests passing, `flutter analyze` 0 issues).
- Phase 9 is designed as an autonomous, 100% pure Dart mathematical subsystem
  residing within `lib/mathematical_core/statistics/`.
- Exact mathematical results (sums, integer counts, rational sample means,
  rational variances, rational standard deviations) are preserved through
  `IntegerValue` and `FractionValue` when all input scalars are exact
  (`isExact: true`).
- Regression modeling is defined with explicit exactness semantics: regression
  fitting is numerical/approximate by design, emitting `DecimalValue`
  coefficients, original-space residuals and $R^2$, accompanied by
  `CalculationMetadata(isExact: false, approximation: ...)`.
- All statistical and regression algorithms are formulated with bounded
  engineering language: algorithms are designed to mitigate documented
  numerical-stability risks (such as catastrophic cancellation and loss of
  significance) for the supported numeric representations, without making
  unsupported universal claims.
- All error types and non-fatal warnings map strictly to existing Phase 1 core
  contracts (`lib/core/errors/math_error.dart` and
  `lib/core/result/math_warning.dart`). No new unverified diagnostic classes are
  introduced.

---

## 2. Authoritative Requirements, Scope & Non-Goals

Per `NEXAMATH_IMPLEMENTATION_ROADMAP.md` §14,
`NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §36–37, and
`NEXAMATH_IMPLEMENTATION_BLUEPRINT.md` §44–47, Phase 9 encompasses three
cohesive capabilities:

```text
Phase 9: Statistics & Regression
 ├── 1. Descriptive Statistics (Univariate Dataset analysis)
 ├── 2. Bivariate Statistics (PairedDataset covariance, correlation, R²)
 └── 3. Regression Analysis (Model fitting, equation AST, residuals, and predictions)
```

### Explicit Non-Goals for Phase 9

- **No Probability Distributions:** Normal, Binomial, Poisson, Student's t,
  Chi-squared, F-distribution, and PDF/CDF/inverse CDF belong strictly to
  **Phase 10 (Probability & Distributions)**.
- **No Physical Units:** Dimensional quantity tracking belongs to **Phase 11
  (Units & Dimensional Analysis)**.
- **No UI / Charting / Visualization:** Histograms, scatter plots, and box plots
  belong to **Phase 13 (Graphing Engine)** and **Phase 18 (Flutter
  Presentation)**.
- **No External Dependencies:** No external third-party statistical or linear
  algebra packages (e.g. no SciDart, no external C-FFI). Everything runs on the
  established NexaMath Pure Dart Core (`NumericEngine`, `MatrixEngine`,
  `ExpressionNode`). External tools (such as NumPy or R) serve strictly as
  development-time verification reference oracles.

---

## 3. Dataset Domain Models & Equality Contracts

### 3.1 `Dataset` (Univariate Series)

- **Definition:** An immutable 1D ordered collection of scalar observations:
  $$\mathcal{D} = (x_1, x_2, \dots, x_N), \quad x_i \in \text{ScalarValue}$$
- **Immutability:** Backed by an unmodifiable `List<ScalarValue>`. Input
  collections are defensively copied upon construction.
- **Ordering:** Preserves insertion order. Sorting operations return sorted
  copies and do not mutate the dataset container.
- **Scalar Type Support:** Accepts `IntegerValue`, `FractionValue`, and
  `DecimalValue`. Complex numbers ($x_i \in \mathbb{C} \setminus \mathbb{R}$)
  are rejected at validation with
  `DomainError(functionName: 'Dataset', message: 'Complex numbers are not supported in real statistical datasets.')`.
- **Equality & HashCode:** Reuses Phase 2 scalar mathematical value equality
  semantics. Two scalar values representing the same mathematical number compare
  equal (e.g., `DecimalValue.parse("1.5") == FractionValue.fromInts(3, 2)`
  evaluates to true under established Phase 2 equality / canonical value
  comparison). Duplicate detection, frequency counting for mode, and container
  equality must strictly reuse this established Phase 2 equality contract rather
  than inventing statistics-specific equality logic.
- **Empty Dataset:** `values.isEmpty` is valid for the model container
  ($N = 0$). Operations requiring $N \ge 1$ (such as mean, median, mode,
  variance) return a typed
  `MathFailure(InvalidArgumentError(argumentName: 'dataset', reason: 'Dataset must not be empty.'))`.

### 3.2 `PairedDataset` (Bivariate Series)

- **Definition:** An ordered collection of coordinate pairs representing paired
  observations:
  $$\mathcal{P} = \big((x_1, y_1), (x_2, y_2), \dots, (x_N, y_N)\big)$$
- **Invariant:** Lengths must match exactly: $|X| = |Y| = N$.
- **Validation:** If `x.length != y.length`, construction or evaluation fails
  with
  `DimensionMismatchError(expectedDimension: '${x.length}', actualDimension: '${y.length}')`.
- **Empty State:** Permitted as a data container ($N = 0$). Operations requiring
  $N \ge 2$ (sample covariance, correlation, regression) return typed failures
  (`InvalidArgumentError`).
- **Duplicate Observations:** Duplicate coordinate pairs
  $(x_i, y_i) = (x_j, y_j)$ for $i \ne j$, as well as repeated $x$ values with
  differing $y$ values, are completely valid bivariate observations. Duplicate
  pairs contribute multiple distinct weighted residual terms to least-squares
  fitting and are never treated as automatically singular; singularity is
  determined strictly by the rank of the design matrix.

---

## 4. Descriptive Statistics Mathematical Specifications

| Metric              | Mathematical Definition                                 | Minimum $N$ | Degenerate Condition        | Exactness Rule                                                                  | Failure Condition                  |
| :------------------ | :------------------------------------------------------ | :---------- | :-------------------------- | :------------------------------------------------------------------------------ | :--------------------------------- |
| **Count**           | $N = \|\mathcal{D}\|$                                   | $0$         | $N = 0 \to 0$               | Always exact (`IntegerValue`)                                                   | None (returns 0 on empty)          |
| **Sum**             | $S = \sum_{i=1}^N x_i$                                  | $0$         | $N = 0 \to 0$               | Exact if all elements exact (`isExact: true`)                                   | Overflow in fixed representation   |
| **Mean**            | $\bar{x} = \frac{1}{N} \sum_{i=1}^N x_i$                | $1$         | $N = 1 \to x_1$             | Exact rational (`FractionValue`) if all $x_i$ exact (`isExact: true`)           | $N = 0 \to$ `InvalidArgumentError` |
| **Median**          | Value splitting ordered data                            | $1$         | $N = 1 \to x_1$             | Exact if inputs exact (`isExact: true`)                                         | $N = 0 \to$ `InvalidArgumentError` |
| **Mode**            | $\arg\max_v \text{freq}(v)$                             | $1$         | See §4.2 Contract           | Exact list of `ScalarValue`                                                     | $N = 0 \to$ `InvalidArgumentError` |
| **Min / Max**       | $\min(x_i), \max(x_i)$                                  | $1$         | $N = 1 \to x_1$             | Exact if inputs exact (`isExact: true`)                                         | $N = 0 \to$ `InvalidArgumentError` |
| **Range**           | $\max(x_i) - \min(x_i)$                                 | $1$         | $N = 1 \to 0$               | Exact if inputs exact (`isExact: true`)                                         | $N = 0 \to$ `InvalidArgumentError` |
| **Pop. Variance**   | $\sigma^2 = \frac{1}{N} \sum_{i=1}^N (x_i - \bar{x})^2$ | $1$         | $N = 1 \to 0$               | Exact rational (`FractionValue`) if all $x_i$ exact                             | $N = 0 \to$ `InvalidArgumentError` |
| **Sample Variance** | $s^2 = \frac{1}{N-1} \sum_{i=1}^N (x_i - \bar{x})^2$    | $2$         | All $x_i$ identical $\to 0$ | Exact rational (`FractionValue`) if all $x_i$ exact                             | $N < 2 \to$ `InvalidArgumentError` |
| **Pop. Std Dev**    | $\sigma = \sqrt{\sigma^2}$                              | $1$         | $\sigma^2 = 0 \to 0$        | Exact if $\sigma^2$ is an exact rational square (see §4.4), else `DecimalValue` | $N = 0 \to$ `InvalidArgumentError` |
| **Sample Std Dev**  | $s = \sqrt{s^2}$                                        | $2$         | $s^2 = 0 \to 0$             | Exact if $s^2$ is an exact rational square (see §4.4), else `DecimalValue`      | $N < 2 \to$ `InvalidArgumentError` |

---

### 4.1 Numerical Variance & Standard Deviation Algorithms

The naive single-pass textbook shortcut: $$\sum x_i^2 - \frac{(\sum x_i)^2}{N}$$

is notorious for catastrophic subtractive cancellation when data values have a
large mean relative to their variance.

To protect numerical stability, NexaMath mandates the following algorithmic
strategy:

1. **Exact Path (All $x_i$ exact):**
   - When all $x_i \in \mathcal{D}$ have `isExact == true` (`IntegerValue`,
     `FractionValue`, or exact `DecimalValue`), calculations are performed in
     exact rational arithmetic via `FractionValue` using arbitrary-precision
     `BigInt`.
   - The sample mean $\bar{x} \in \mathbb{Q}$ is computed exactly.
   - Sum of squared deviations $\sum_{i=1}^N (x_i - \bar{x})^2$ is accumulated
     exactly as a rational number, completely avoiding floating-point
     cancellation.
   - Population variance $\sigma^2$ and sample variance $s^2$ are returned as
     exact canonical `FractionValue` instances with `CalculationMetadata.exact`.
2. **Approximate / Floating-Point Path (Any $x_i$ approximate):**
   - When approximate numbers are present, a **stable two-pass variance
     algorithm** or **Welford's algorithm** is employed:
     - **Two-Pass Algorithm:** Pass 1 computes $\bar{x} = \frac{1}{N} \sum x_i$.
       Pass 2 computes $M_2 = \sum_{i=1}^N (x_i - \bar{x})^2$.
     - **Welford's Algorithm:** Online single-pass update
       $M_{2, k} = M_{2, k-1} + (x_k - \bar{x}_{k-1})(x_k - \bar{x}_k)$.
   - _Stability Guarantee Boundary:_ The selected algorithms are designed to
     mitigate documented numerical-stability risks (such as catastrophic
     cancellation) for the supported numeric representations. They do not claim
     universal immunity to severe ill-conditioning or extreme dynamic ranges
     exceeding the configured `PrecisionContext`.
   - Result is returned as `DecimalValue` with
     `CalculationMetadata(isExact: false, approximation: ApproximationMetadata(method: 'twoPassVariance', precision: context.precisionDigits))`.

---

### 4.2 Mode Semantics Contract (NexaMath Mode Convention)

The mode contract must be mathematically and internally consistent across all
edge cases. Because statistical conventions for ties and singletons vary widely
across software packages, NexaMath explicitly standardizes on the following
deterministic convention:

1. **$N = 0$ (Empty Dataset):**
   - Returns typed failure
     `MathFailure(InvalidArgumentError(argumentName: 'dataset', reason: 'Mode is undefined for an empty dataset.'))`.
2. **$N = 1$ (Singleton Dataset $\{x_1\}$):**
   - The single value is the unique mode: `modes = [x_1]`.
3. **$N > 1$ and Maximum Frequency $f_{\max} = 1$ (All values unique):**
   - For example, $\{1, 2, 3, 4\}$: no value occurs more frequently than any
     other. By NexaMath statistical convention, the dataset has **no mode**:
     `modes = []` (an empty list inside a successful result).
4. **$N > 1$ and All Values Identical ($N$ occurrences of a single unique
   value):**
   - For example, $\{5, 5, 5, 5\}$: there is a single unique value with
     frequency $f_{\max} = 4 > 1$. By definition, this single value is the
     unique mode: `modes = [5]`.
5. **$N > 1$ and Multiple Distinct Values Share Identical Frequency $f > 1$
   Across the Entire Dataset:**
   - For example, $\{1, 1, 2, 2, 3, 3\}$: because all observed unique values
     share the identical frequency with no predominant peak, there is **no
     mode**: `modes = []`.
6. **Unique Maximum Frequency $f_{\max} > 1$ with Other Lower-Frequency Elements
   (Unimodal):**
   - For example, $\{1, 2, 2, 3\}$: returns a single-element list `modes = [2]`.
7. **Multiple Values Sharing Maximum Frequency $f_{\max} > 1$ with Other
   Lower-Frequency Elements (Multimodal):**
   - For example, $\{1, 1, 2, 3, 3, 4\}$: returns all $k$ modes sorted in
     strictly ascending numerical order according to Phase 2 scalar comparison:
     `modes = [1, 3]`.

---

### 4.3 Mean Exactness Contract

The mean is: $$\bar{x} = \frac{1}{N} \sum_{i=1}^N x_i$$

- **Exactness Dependency:** The mean is exact (`isExact: true`) if and only if
  **every** underlying value in the dataset has `isExact == true`.
- **Type Semantics:**
  - If all elements are `IntegerValue` or `FractionValue`, or `DecimalValue`
    with `isExact: true`, their sum is exact, and division by the exact integer
    $N$ yields an exact `FractionValue` (or `IntegerValue` if the fraction
    simplifies to an integer).
  - If any element has `isExact: false` (such as a precision-limited decimal
    approximation), the mean is returned as a `DecimalValue` with
    `isExact: false` and appropriate `ApproximationMetadata`.

---

### 4.4 Exact Standard Deviation & Rational Square Roots

The standard deviation is $\sqrt{\text{Variance}}$.

- Rational square roots can be represented **exactly** as `FractionValue`
  whenever both the numerator and denominator of the canonical reduced fraction
  are perfect integer squares:
  $$\sqrt{\frac{p}{q}} = \frac{\sqrt{p}}{\sqrt{q}} \in \mathbb{Q} \quad (\text{for } p, q \in \mathbb{Z}^+, \, \sqrt{p}, \sqrt{q} \in \mathbb{Z})$$
  _Examples of exact standard deviations:_
  - $\sigma^2 = \frac{1}{4} \implies \sigma = \frac{1}{2}$
    (`FractionValue(1, 2)`, exact).
  - $\sigma^2 = \frac{9}{16} \implies \sigma = \frac{3}{4}$
    (`FractionValue(3, 4)`, exact).
  - $\sigma^2 = 4 \implies \sigma = 2$ (`IntegerValue(2)`, exact).
- **Exactness Determination Procedure:**
  1. If variance $V$ is exact (`FractionValue(num, den)` in reduced form):
     - If both `num` and `den` are perfect integer squares (verifiable via
       integer square root trial $r^2 == n$), return exact
       `FractionValue(sqrtNum, sqrtDen)` (or `IntegerValue` if `sqrtDen == 1`)
       with `CalculationMetadata.exact`.
  2. If $V$ is not a perfect rational square, or if $V$ is an approximate
     `DecimalValue`:
     - Fall back to numerical square root via
       `DecimalOperations.sqrt(v, context: context)`.
     - Return approximate `DecimalValue` with
       `CalculationMetadata(isExact: false, approximation: ApproximationMetadata(method: 'newtonRaphsonSqrt', precision: context.precisionDigits))`.
- No statistics-specific numeric types are created; standard deviation uses
  existing `IntegerValue`, `FractionValue`, and `DecimalValue`.

---

## 5. Quantiles, Quartiles & Percentiles Specification

### 5.1 Attribution & Method Selection: Hyndman–Fan Type 7

Percentiles in NexaMath are defined using the **Hyndman–Fan Type 7** linear
interpolation method (Hyndman and Fan, 1996, _Sample Quantiles in Statistical
Packages_, The American Statistician).

- **Cross-Platform Compatibility:** Type 7 is the default quantile method in:
  - R (`quantile(..., type = 7)`)
  - Python NumPy / SciPy / Pandas (`method='linear'`)
  - Microsoft Excel `PERCENTILE.INC` (inclusive percentile)
- **Attribution Corrections:**
  - Type 7 must NOT be attributed to Excel `PERCENTILE.EXC` (which uses
    Hyndman–Fan Type 6: $h = (N + 1)p$).
  - Type 7 must NOT be claimed as a NIST standard definition (NIST Handbook
    §1.3.5.18 documents Type 6).

### 5.2 Mathematical Formulation & Parameter Representation (Type 7)

Given sorted sample observations $x_{(1)} \le x_{(2)} \le \dots \le x_{(N)}$:

1. **Percentile Parameter Representation:**
   - The authoritative public API accepts `p` as a `ScalarValue`:
     `MathResult<PercentileResult> percentile(Dataset dataset, ScalarValue percentile)`
     (convenience overloads taking Dart `num` immediately promote to `ScalarValue`
     via `IntegerValue` for integer inputs or canonical `DecimalValue` for floating-point inputs).
   - Valid Domain: $0 \le p \le 100$. If $p < 0$ or $p > 100$, evaluation fails with
     `MathFailure(DomainError(functionName: 'percentile', argument: 'p', message: 'Percentile must be between 0 and 100 inclusive.'))`.
   - The normalized quantile fraction is $q = \frac{p}{100}$:
     - When `p` is an `IntegerValue` or `FractionValue`, or a `DecimalValue` with `isExact == true`,
       $q$ is converted to an exact rational `FractionValue(num, den)`.
     - When `p` is a `DecimalValue` with `isExact == false`, $q$ remains an approximate `DecimalValue`.
2. **Rank Index Formulation:** $$h = (N - 1) q + 1 = (N - 1) \frac{p}{100} + 1$$
3. Let $k = \lfloor h \rfloor \in \{1, 2, \dots, N\}$ and fractional part
   $f = h - k \in [0, 1)$.
4. **Boundary and Interpolation Behavior:**
   - If $k = N$ (which occurs when $p = 100$),
     $P_{100} = x_{(N)} \equiv \max(\mathcal{D})$.
   - If $p = 0$,
     $h = 1 \implies k = 1, f = 0 \implies P_0 = x_{(1)} \equiv \min(\mathcal{D})$.
   - Otherwise, for $1 \le k < N$:
     $$P_p = x_{(k)} + f \cdot \big(x_{(k+1)} - x_{(k)}\big) = (1 - f) x_{(k)} + f x_{(k+1)}$$
5. **Exactness Semantics:**
   - **Exact Rational Path:** When ALL $x_i \in \mathcal{D}$ have `isExact == true`
     AND parameter `p` has `isExact == true` (e.g. `IntegerValue` or `FractionValue`),
     both $h$ and $f$ are represented as exact rational numbers (`FractionValue`), and
     $P_p$ is evaluated strictly in exact rational arithmetic, returning `FractionValue`
     (or `IntegerValue` if the fraction simplifies to an integer) with
     `CalculationMetadata.exact`.
   - **Approximate Decimal Path:** When ANY $x_i \in \mathcal{D}$ has `isExact == false`
     OR parameter `p` has `isExact == false`, the rank $h$, fractional part $f$, and
     interpolation $P_p$ are computed using `DecimalValue` arithmetic under the
     active `PrecisionContext`, returning an approximate `DecimalValue` with
     `CalculationMetadata(isExact: false, approximation: ...)`.
   - Exact percentile interpolation is strictly guaranteed if and only if both the dataset
     and the percentile parameter `p` are exact representations.
6. **Sample Size Edge Cases:**
   - $N = 0$: Returns
     `MathFailure(InvalidArgumentError(argumentName: 'dataset', reason: 'Percentile is undefined for empty dataset.'))`.
   - $N = 1$: For any $p \in [0, 100]$,
     $h = (0)q + 1 = 1 \implies k = 1, f = 0 \implies P_p = x_1$ (preserves the exactness of $x_1$).
7. **Internal Sorting:** The input `Dataset` preserves insertion order
   externally, but the percentile calculator sorts a local copy internally
   before computing real ranks.

### 5.3 Quartiles & Invariants

- First Quartile ($Q_1$): $p = 25$ ($q = 1/4$, exact)
- Second Quartile ($Q_2$): $p = 50$ ($q = 1/2$, exact). Under Type 7, $Q_2$ is
  mathematically identical to the sample median.
- Third Quartile ($Q_3$): $p = 75$ ($q = 3/4$, exact)
- Interquartile Range ($\text{IQR}$): $\text{IQR} = Q_3 - Q_1$
- Invariant: $P_0 \le Q_1 \le Q_2 \le Q_3 \le P_{100}$ for all non-empty
  datasets.

---

## 6. Bivariate Statistics Contracts

### 6.1 Covariance Edge Cases & Invariants

- **Population Covariance ($N \ge 1$):**
  $$\operatorname{Cov}_{\text{pop}}(X, Y) = \frac{1}{N} \sum_{i=1}^N (x_i - \bar{x})(y_i - \bar{y})$$
  - Edge Case $N = 1$: When $N = 1$, $x_1 - \bar{x} = 0$ and
    $y_1 - \bar{y} = 0$. Population covariance for a singleton paired dataset is
    mathematically well-defined and equals **0** (exact `IntegerValue.zero` or
    `FractionValue.zero`).
  - Edge Case $N = 0$: Returns
    `MathFailure(InvalidArgumentError(argumentName: 'dataset', reason: 'Population covariance requires N >= 1.'))`.
- **Sample Covariance ($N \ge 2$):**
  $$\operatorname{Cov}_{\text{sample}}(X, Y) = \frac{1}{N - 1} \sum_{i=1}^N (x_i - \bar{x})(y_i - \bar{y})$$
  - Edge Case $N = 1$: Denominator $N - 1 = 0$. Sample covariance is
    mathematically undefined for $N < 2$. Returns
    `MathFailure(InvalidArgumentError(argumentName: 'dataset', reason: 'Sample covariance requires N >= 2.'))`.
  - Consistency: This mirrors the exact degree-of-freedom boundary established
    for population variance ($N \ge 1$) versus sample variance ($N \ge 2$).
- **Exactness:** If both $X$ and $Y$ contain exact values (`isExact: true`),
  covariance is computed as an exact `FractionValue`.

### 6.2 Pearson Correlation Coefficient ($r$)

$$r = \frac{\sum_{i=1}^N (x_i - \bar{x})(y_i - \bar{y})}{\sqrt{\sum_{i=1}^N (x_i - \bar{x})^2} \sqrt{\sum_{i=1}^N (y_i - \bar{y})^2}} = \frac{\operatorname{Cov}_{\text{sample}}(X, Y)}{s_X s_Y}$$

- **Domain:** Defined for $N \ge 2$.
- **Zero Variance Condition:** If either $s_X = 0$ (all $x_i$ identical) or
  $s_Y = 0$ (all $y_i$ identical), Pearson $r$ is mathematically undefined.
- **Failure Contract:** Returns
  `MathFailure(DomainError(functionName: 'pearsonCorrelation', message: 'Pearson correlation is undefined when variance of X or Y is zero.'))`.
- **Clamping Policy:**
  - Mathematically, $-1 \le r \le 1$.
  - In numerical floating-point evaluation, tiny round-off errors may cause
    $|r|$ to slightly exceed 1.0 (e.g., $1.0000000000000002$).
  - **Bounded Clamping Rule:** Only clamp values within the authoritative
    numerical zero tolerance $\epsilon_{\text{clamp}} = \text{PrecisionContext.standard.zeroTolerance} = 10^{-15}$.
    If $1.0 < r \le 1.0 + \epsilon_{\text{clamp}}$, clamp to $1.0$.
    If $-1.0 - \epsilon_{\text{clamp}} \le r < -1.0$, clamp to $-1.0$.
  - If $|r| > 1.0 + \epsilon_{\text{clamp}}$, this indicates severe numerical instability or
    invalid computation; return
    `MathFailure(PrecisionLossError(message: 'Correlation coefficient exceeded valid mathematical bounds due to severe numerical error.'))`.
    Do NOT blindly clamp gross errors like $1.2 \to 1.0$.

### 6.3 Unified Coefficient of Determination ($R^2$) Contract

The general definition of $R^2$ across all regression models in NexaMath is:
$$R^2 = 1 - \frac{\text{SSE}}{\text{SST}} = 1 - \frac{\sum_{i=1}^N (y_i - \hat{y}_i)^2}{\sum_{i=1}^N (y_i - \bar{y})^2}$$

#### 6.3.1 Negative $R^2$ Policy

- **Negative Values Permitted:** In non-linear models, models without an
  intercept, or models evaluated out-of-sample or in original space after
  non-linear transformation, $\text{SSE}$ can exceed $\text{SST}$
  ($\text{SSE} > \text{SST}$), yielding $R^2 < 0$.
- **No Clamping:** $R^2$ MUST NOT be artificially clamped to $[0, 1]$. Negative
  $R^2$ accurately indicates that the fitted model performs worse than a simple
  horizontal mean line $\hat{y} = \bar{y}$.

#### 6.3.2 Linear Regression $R^2$ Implementation

- In ordinary linear regression ($y = ax + b$) with an intercept,
  $R^2 = 1 - \frac{\text{SSE}}{\text{SST}}$ is algebraically equivalent to $r^2$
  (Pearson correlation squared).
- To ensure architectural consistency, the regression engine uses the unified
  formula $R^2 = 1 - \frac{\text{SSE}}{\text{SST}}$ across all regression
  models. Pearson $r^2$ is documented only as an analytical property for linear
  regression.

#### 6.3.3 Exhaustive Matrix of $R^2$ Behavior across $\text{SST}$ and $\text{SSE}$

To ensure consistent behavior across all regression models and eliminate undefined operations, NexaMath establishes an exhaustive specification for the four possible permutations of $\text{SST}$ and $\text{SSE}$:

```text
┌──────────────┬──────────────┬────────────────────────┬────────────────────────────────────────────────────────┐
│ Total Var.   │ Residual Var.│ Resulting rSquared     │ Warning / Semantic Contract                            │
├──────────────┼──────────────┼────────────────────────┼────────────────────────────────────────────────────────┤
│ 1. SST == 0  │ SSE == 0     │ DecimalValue(1.0)      │ NearZeroWarning('...constant response perfectly fitted')│
│ 2. SST == 0  │ SSE > 0      │ DecimalValue(0.0)      │ NearZeroWarning('...model residuals are non-zero')     │
│ 3. SST > 0   │ SSE == 0     │ DecimalValue(1.0)      │ Standard fit; no warning. Perfect interpolation.       │
│ 4. SST > 0   │ SSE > 0      │ DecimalValue(1-SSE/SST)│ Standard fit; may be negative if SSE > SST (no clamp). │
└──────────────┴──────────────┴────────────────────────┴────────────────────────────────────────────────────────┘
```

1. **Case 1 ($\text{SST} = 0$ and $\text{SSE} = 0$ — Perfect Constant Fit):**
   - Occurs when response observations are constant ($y_i = c$ for all $i$) and the fitted model reproduces the constant value identically ($\hat{y}_i = c$, e.g. linear regression with zero slope and intercept $c$).
   - The classical formula $\frac{\text{SSE}}{\text{SST}} = \frac{0}{0}$ is algebraically indeterminate.
   - **Contract:** By NexaMath convention, the model explains 100% of the degenerate variation. Return `rSquared = DecimalValue(1.0)` accompanied by `NearZeroWarning(message: 'Total sum of squares (SST) is zero; constant response perfectly fitted.')`.
2. **Case 2 ($\text{SST} = 0$ and $\text{SSE} > 0$ — Non-Fitting Model on Constant Data):**
   - Occurs when response observations are constant ($y_i = c$) but the model produces non-constant predictions ($\hat{y}_i \ne c$, e.g. constrained non-linear models or forced zero-intercept).
   - The classical ratio $\frac{\text{SSE}}{0} \to +\infty$ is undefined.
   - **Contract:** By NexaMath convention, the model fails to explain the constant data. Return `rSquared = DecimalValue(0.0)` accompanied by `NearZeroWarning(message: 'Total sum of squares (SST) is zero; model residuals are non-zero.')`.
3. **Case 3 ($\text{SST} > 0$ and $\text{SSE} = 0$ — Exact Interpolation with Variation):**
   - Occurs when response observations vary and the model interpolates all points perfectly (e.g. exactly determined polynomial regression with distinct $x$).
   - **Contract:** Evaluated via standard formula: $R^2 = 1 - \frac{0}{\text{SST}} = 1.0$. Return `rSquared = DecimalValue(1.0)` with no warning.
4. **Case 4 ($\text{SST} > 0$ and $\text{SSE} > 0$ — General Regression Fit):**
   - Standard least-squares fitting on arbitrary paired data.
   - **Contract:** Evaluated via standard unified formula $R^2 = 1 - \frac{\text{SSE}}{\text{SST}}$.
   - If $\text{SSE} > \text{SST}$ (which occurs in non-linear transformed models on mismatched data or out-of-sample evaluations), $R^2 < 0$. Negative values are preserved as valid diagnostics and NEVER clamped to zero.

---

## 7. Regression Models & Numerical Formulation

All regression models fit a relationship $y = f(x; \boldsymbol{\theta})$ to
paired data $\mathcal{P} = \{(x_i, y_i)\}_{i=1}^N$.

```text
┌──────────────┬────────────────────────┬───────────┬─────────────────────┬────────────────────────────────────┐
│ Model        │ Mathematical Form      │ Min Pairs │ Domain Restrictions │ Fitting Strategy                   │
│              │                        │ (N)       │                     │                                    │
├──────────────┼────────────────────────┼───────────┼─────────────────────┼────────────────────────────────────┤
│ Linear       │ y = a x + b            │ N >= 2    │ At least 2 distinct │ Analytic Ordinary Least Squares    │
│              │                        │           │ x values            │ (Covariance / Variance formulation)│
│ Quadratic    │ y = a x² + b x + c     │ N >= 3    │ At least 3 distinct │ Least-Squares Normal Equations     │
│              │                        │           │ x values (rank 3)   │ via MatrixEngine.inverse           │
│ Cubic        │ y = a x³ + b x² + cx+d │ N >= 4    │ At least 4 distinct │ Least-Squares Normal Equations     │
│              │                        │           │ x values (rank 4)   │ via MatrixEngine.inverse           │
│ Logarithmic  │ y = a + b ln(x)        │ N >= 2    │ x_i > 0 for all i;  │ Semi-log OLS on (ln(x), y)         │
│              │                        │           │ >= 2 distinct x     │ (Transformation-based fitting)     │
│ Exponential  │ y = a * e^(b x)        │ N >= 2    │ y_i > 0 for all i;  │ Log-linear OLS on (x, ln(y));      │
│              │                        │           │ >= 2 distinct x     │ a = exp(alpha) > 0                 │
│ Power        │ y = a * x^b            │ N >= 2    │ x_i > 0, y_i > 0;   │ Log-log OLS on (ln(x), ln(y));     │
│              │                        │           │ >= 2 distinct x     │ a = exp(alpha) > 0                 │
└──────────────┴────────────────────────┴───────────┴─────────────────────┴────────────────────────────────────┘
```

---

### 7.1 Linear Regression ($y = ax + b$)

- Slope:
  $$a = \frac{\sum_{i=1}^N (x_i - \bar{x})(y_i - \bar{y})}{\sum_{i=1}^N (x_i - \bar{x})^2} = \frac{\operatorname{Cov}(X, Y)}{\operatorname{Var}(X)}$$
- Intercept: $$b = \bar{y} - a \bar{x}$$
- **Rank & Distinct $X$ Requirement:** Requires $N \ge 2$ and at least 2
  distinct $x$ coordinates. If all $x_i$ are identical
  ($\operatorname{Var}(X) = 0$, vertical line), returns
  `MathFailure(SingularMatrixError(message: 'Cannot fit linear regression: zero variance in predictor variable X (vertical line).'))`.

---

### 7.2 Polynomial Regression: Least-Squares Formulation & Authoritative Numerical Strategy

#### 7.2.1 Architectural Scope & Determinacy Classification

In strict alignment with the project's foundational architecture:
- `NEXAMATH_IMPLEMENTATION_ROADMAP.md` §14.3 explicitly defines the approved polynomial regression models as **quadratic** and **cubic**.
- `NEXAMATH_IMPLEMENTATION_BLUEPRINT.md` §22, §47 establishes `quadratic_regression.dart` and `cubic_regression.dart`.
- `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §37 explicitly specifies `MathResult<RegressionResult> quadratic(PairedDataset dataset)` and `MathResult<RegressionResult> cubic(PairedDataset dataset)` on `RegressionEngine`.
- Therefore, Phase 9 polynomial regression scope is authoritatively defined as **degree $d = 2$ (Quadratic)** and **degree $d = 3$ (Cubic)**. (No general unconstrained degree-$d$ polynomial solver was originally scoped or approved for Phase 9).

For a polynomial model of degree $d \in \{2, 3\}$:
$$y = c_0 + c_1 x + c_2 x^2 + \dots + c_d x^d$$

we classify datasets by observation count $N$ and degree $d$:

1. **Under-determined ($N < d + 1$):**
   - The number of data points is strictly less than the number of model
     parameters ($d + 1$).
   - Returns typed failure:
     `MathFailure(InvalidArgumentError(argumentName: 'dataset', reason: 'Polynomial regression of degree $d$ requires at least ${d+1}$ observations.'))`.
2. **Exactly Determined ($N = d + 1$):**
   - When $N = d + 1$ and all $N$ observations have **distinct $x$-values**, the
     polynomial uniquely interpolates every point.
   - _Mathematical Invariants:_
     - When response variance exists ($\text{SST} > 0$): Mathematical $\text{SSE} = 0$ and $R^2 = 1.0$.
     - When response is constant ($\text{SST} = 0$, so $y_i = c$ for all $i$):
       The unique polynomial of degree $d \ge 1$ interpolating constant points is the constant horizontal line $y = c$,
       yielding mathematical $\text{SSE} = 0$. Because $\frac{\text{SSE}}{\text{SST}} = \frac{0}{0}$ is undefined,
       the system strictly applies the **NexaMath Constant-Response Convention (§6.3.3 Case A)**:
       $R^2 = 1.0$ accompanied by `NearZeroWarning(message: 'Total sum of squares (SST) is zero; constant response perfectly fitted.')`.
       Under no circumstances is division by zero attempted.
   - _Numerical Implementation Expectation:_ Because regression is approximate by design
     (see §7.4), polynomial normal equations, matrix inversion, and coefficient reconstruction are evaluated via
     finite-precision decimal/floating arithmetic.
     - While mathematical interpolation yields zero error, finite-precision evaluation and coefficient reconstruction
       introduce round-off that depends on the dynamic range and coordinate spread of $x$.
     - Under well-conditioned coordinate scales (such as unit intervals or after predictor centering $u_i = x_i - \bar{x}$),
       computed residuals and error sums satisfy the scale-aware comparison tolerance (§7.3.3):
       $$\text{SSE}_{\text{computed}} \le \text{atol} + \text{rtol} \cdot \text{SST}$$
       and when $\text{SST} > 0$:
       $$|1 - R^2_{\text{computed}}| \le \epsilon_{\text{comp}} = 10^{-12}$$
     - No universal fixed error bound is promised for arbitrarily ill-conditioned coordinate spreads;
       in cases of severe ill-conditioning, the relative pivot monitor emits `PrecisionLossWarning`.
   - The test contract explicitly distinguishes the mathematical invariant ($\text{SSE} = 0, R^2 = 1.0$)
     from tolerance-based numerical validation, and does NOT require raw floating-point equality (`SSE == 0.0`)
     unless explicitly normalized.
3. **Overdetermined ($N > d + 1$):**
   - When $N > d + 1$, the system is an overdetermined **linear least-squares
     problem**:
     $$\min_{\boldsymbol{\theta}} \|\mathbf{y} - \mathbf{X} \boldsymbol{\theta}\|_2^2$$
   - The system MUST NOT be described or implemented as solving a square
     Vandermonde system. It is formulated via the normal equations:
     $$(\mathbf{X}^T \mathbf{X}) \boldsymbol{\theta} = \mathbf{X}^T \mathbf{y}$$
     where $\mathbf{X}^T \mathbf{X} \in \mathbb{R}^{(d+1) \times (d+1)}$ is
     symmetric positive semi-definite and
     $\mathbf{X}^T \mathbf{y} \in \mathbb{R}^{(d+1)}$.

#### 7.2.2 Rank Requirements & Distinction from Duplicate Points

- For the specific polynomial Vandermonde design matrix
  $\mathbf{X} \in \mathbb{R}^{N \times (d+1)}$:
  $$\mathbf{X} = \begin{bmatrix} 1 & x_1 & x_1^2 & \dots & x_1^d \\ \vdots & \vdots & \vdots & \ddots & \vdots \\ 1 & x_N & x_N^2 & \dots & x_N^d \end{bmatrix}$$
  the matrix $\mathbf{X}$ has full column rank $d + 1$ if and only if there are
  at least **$d + 1$ distinct $x$ coordinates** in the dataset:
  - Quadratic ($d=2$): requires at least 3 distinct $x$ values.
  - Cubic ($d=3$): requires at least 4 distinct $x$ values.
- **Duplicate Observations:** Duplicate coordinate pairs
  $(x_i, y_i) = (x_j, y_j)$ are completely valid observations that weight the
  least-squares error. Duplicates alone do NOT cause singularity. Singularity
  occurs if and only if the count of _distinct_ $x$ values is strictly less than
  $d + 1$.
- If distinct $x$ count $< d + 1$, $\mathbf{X}^T \mathbf{X}$ is mathematically
  rank-deficient and singular. Returns:
  `MathFailure(SingularMatrixError(message: 'Polynomial regression of degree $d$ requires at least ${d+1}$ distinct x coordinates for full column rank.'))`.

#### 7.2.3 Authoritative Numerical Strategy & Centering Transformation

1. **Authoritative Linear System Solve:** The production solver sets up the
   $(d+1) \times (d+1)$ moment matrix $\mathbf{M} = \mathbf{X}^T \mathbf{X}$ and
   vector $\mathbf{v} = \mathbf{X}^T \mathbf{y}$, and solves for
   $\boldsymbol{\theta}$ using the existing Phase 5 `MatrixEngine.inverse`:
   $$\boldsymbol{\theta} = \mathbf{M}^{-1} \mathbf{v}$$
2. **Predictor Centering Optimization:**
   - The moment matrix $\mathbf{M}$ has condition number
     $\kappa(\mathbf{M}) = [\kappa(\mathbf{X})]^2$. For large uncentered $x$
     (e.g. calendar years $x \in [2000, 2025]$), $\mathbf{M}$ becomes
     ill-conditioned.
   - _Centering Policy:_ To mitigate shift-induced cancellation across typical
     datasets, predictor centering is a **mandatory implementation requirement**
     during matrix setup: $$u_i = x_i - \bar{x}$$
     The implementation constructs $\tilde{\mathbf{X}}$ with columns $u_i^k$, and
     solves for centered coefficients
     $\tilde{\boldsymbol{\theta}} = [\tilde{c}_0, \tilde{c}_1, \dots, \tilde{c}_d]^T$
     via $(\tilde{\mathbf{X}}^T \tilde{\mathbf{X}})^{-1} (\tilde{\mathbf{X}}^T \mathbf{y})$
     using `MatrixEngine.inverse` (which uses Gauss-Jordan elimination under the
     project's numerical zero/pivot policy).
   - _Conditioning Boundary:_ While centering mitigates origin-shift cancellation,
     normal equations inherently square condition numbers ($\kappa(\mathbf{M}) = [\kappa(\mathbf{X})]^2$),
     and centering does not guarantee universal stability under extreme dynamic
     ranges or high degrees. For Phase 9, stability is guarded by bounding polynomial
     degrees to $d \in \{2, 3\}$ and emitting `PrecisionLossWarning` when ill-conditioning
     is detected.
   - _Algebraic Reconstruction to Canonical Coefficients:_ The model is
     algebraically transformed back into the canonical variable $x$:
     - For Quadratic ($d=2$):
       $y = \tilde{c}_0 + \tilde{c}_1(x - \bar{x}) + \tilde{c}_2(x - \bar{x})^2$:
       $$c_2 = \tilde{c}_2, \quad c_1 = \tilde{c}_1 - 2\tilde{c}_2\bar{x}, \quad c_0 = \tilde{c}_0 - \tilde{c}_1\bar{x} + \tilde{c}_2\bar{x}^2$$
     - For Cubic ($d=3$):
       $y = \tilde{c}_0 + \tilde{c}_1(x - \bar{x}) + \tilde{c}_2(x - \bar{x})^2 + \tilde{c}_3(x - \bar{x})^3$:
       $$c_3 = \tilde{c}_3, \quad c_2 = \tilde{c}_2 - 3\tilde{c}_3\bar{x}, \quad c_1 = \tilde{c}_1 - 2\tilde{c}_2\bar{x} + 3\tilde{c}_3\bar{x}^2, \quad c_0 = \tilde{c}_0 - \tilde{c}_1\bar{x} + \tilde{c}_2\bar{x}^2 - \tilde{c}_3\bar{x}^3$$
   - _Invariance:_ All public `RegressionResult` outputs, coefficients, AST
     expressions, predictions, residuals, and $R^2$ are expressed strictly in
     terms of the original variable $x$. Centering is purely an internal
     numerical safeguard.

### 7.3 Numerical Policies: Zero Tolerance, Near-Singularity Heuristic & Regression Comparison

Phase 9 strictly distinguishes three independent numerical concepts. They must NEVER be conflated:

```text
┌──────────────────────────────────────┬─────────────┬────────────────────────────────────────────────────────┐
│ Policy / Semantic Concept            │ Threshold   │ Semantic Purpose & Application Scope                   │
├──────────────────────────────────────┼─────────────┼────────────────────────────────────────────────────────┤
│ A. Zero Tolerance (context.zeroTol)  │ 1e-15       │ True numerical zero detection, singular pivot checks   │
│                                      │ (standard)  │ in MatrixEngine, Pearson correlation bounds clamp.     │
├──────────────────────────────────────┼─────────────┼────────────────────────────────────────────────────────┤
│ B. Near-Singularity Heuristic        │ 1e-15       │ Scale-aware engineering risk check for pivot decay;    │
│    (heuristicThreshold)              │ (reused)    │ emits non-fatal PrecisionLossWarning. NOT a zero test. │
├──────────────────────────────────────┼─────────────┼────────────────────────────────────────────────────────┤
│ C. Regression Comparison Tolerance   │ 1e-12       │ Assertion tolerance for approximate regression outputs:│
│    (regressionComparisonTolerance)   │ (Phase 9)   │ coefficients, predictions, residuals, SSE, SST, R², r. │
└──────────────────────────────────────┴─────────────┴────────────────────────────────────────────────────────┘
```

#### 7.3.1 Zero Tolerance Policy ($\epsilon_{\text{zero}} = 10^{-15}$)
- Defined by `PrecisionContext.standard.zeroTolerance = 1e-15`.
- **Scope of Use:**
  - True numerical zero decisions across all scalar operations.
  - Zero-pivot identification during Gauss-Jordan elimination in `MatrixEngine.inverse` (`_isZero(pivot)`).
  - Mathematical singularity detection (returns `MathFailure(SingularMatrixError())`).
  - Pearson correlation clamping threshold ($|r| \le 1.0 + \epsilon_{\text{zero}}$).

#### 7.3.2 Near-Singularity Numerical-Risk Heuristic ($\epsilon_{\text{heuristic}} = 10^{-15}$)
- **Algorithmic Context & Evaluation:**
  - Evaluated on the moment matrix $\mathbf{M} = \tilde{\mathbf{X}}^T \tilde{\mathbf{X}}$ during or immediately prior to the Gauss-Jordan elimination pass in `MatrixEngine.inverse`.
  - The pivot sequence $p_1, p_2, \dots, p_{d+1}$ represents the unnormalized diagonal pivot elements selected at each column step $k \in \{0, \dots, d\}$ (after row pivoting / swapping, but before dividing the pivot row by $p_k$).
  - **Zero Denominator Handling:** If $\max_k |p_k| == 0$ (or $< \epsilon_{\text{zero}}$), the matrix is mathematically singular and triggers `SingularMatrixError` via the zero-tolerance policy (§7.3.1) before any heuristic ratio is computed.
  - **Engineering Risk Ratio:** When $\max_k |p_k| > 0$, the relative pivot decay is evaluated:
    $$\rho = \frac{\min_k |p_k|}{\max_k |p_k|}$$
  - **Behavior & Warning Emission:**
    - If $\rho < \epsilon_{\text{heuristic}} = 10^{-15}$, the system is flagged with elevated numerical risk of significance loss.
    - The matrix solve completes without raising an error, returning `MathSuccess`, but attaches a non-fatal warning to result metadata:
      `CalculationMetadata(warnings: [PrecisionLossWarning(message: 'Design matrix is ill-conditioned; regression coefficients may suffer precision loss.')])`.
  - **Explicit Semantic Boundary:**
    - This ratio $\rho$ is strictly an engineering heuristic tied to the elimination trajectory.
    - It is **NOT** a matrix condition number $\kappa(\mathbf{M}) = \|\mathbf{M}\| \|\mathbf{M}^{-1}\|$.
    - It is **NOT** a Singular Value Decomposition (SVD) ratio $\sigma_{\min}/\sigma_{\max}$.
    - It is **NOT** mathematical proof of singularity.
    - It cannot guarantee detection of all forms of ill-conditioning, nor does $\rho \ge 10^{-15}$ guarantee infinite precision. It serves solely as a scale-aware risk monitor during elimination.

#### 7.3.3 Scale-Aware Approximate Regression Comparison Policy
- **Authoritative Comparison Formula:**
  Comparing an approximate computed quantity $v_{\text{calc}}$ against reference oracle value $v_{\text{ref}}$ employs a **combined absolute-and-relative comparison tolerance**:
  $$|v_{\text{calc}} - v_{\text{ref}}| \le \text{atol} + \text{rtol} \cdot |v_{\text{ref}}|$$
  where:
  - Base comparison tolerance $\epsilon_{\text{comp}} = 10^{-12}$.
  - $\text{atol} = 10^{-12}$ (governs when reference is zero or near zero, preventing division-by-zero or false rejections).
  - $\text{rtol} = 10^{-12}$ (provides scale invariance when reference magnitudes exceed $1.0$).
- **Application Across Regression Outputs:**
  1. **Coefficients ($\boldsymbol{\theta}$):** For each coefficient $c_k$, $|c_{k, \text{calc}} - c_{k, \text{ref}}| \le 10^{-12} + 10^{-12} \cdot |c_{k, \text{ref}}|$.
  2. **Predictions ($\hat{y}_i$):** For each point $i$, $|\hat{y}_{i, \text{calc}} - \hat{y}_{i, \text{ref}}| \le 10^{-12} + 10^{-12} \cdot |\hat{y}_{i, \text{ref}}|$.
  3. **Residuals ($e_i$):** For each point $i$, $|e_{i, \text{calc}} - e_{i, \text{ref}}| \le 10^{-12} + 10^{-12} \cdot |e_{i, \text{ref}}|$. When $e_{i, \text{ref}} = 0$ (such as in interpolation), the bound simplifies strictly to $\text{atol} = 10^{-12}$.
  4. **Sum of Squared Errors (SSE):** $|\text{SSE}_{\text{calc}} - \text{SSE}_{\text{ref}}| \le 10^{-12} + 10^{-12} \cdot |\text{SSE}_{\text{ref}}|$. When $\text{SSE}_{\text{ref}} = 0$, simplifies to $\le 10^{-12}$.
  5. **Total Sum of Squares (SST):** $|\text{SST}_{\text{calc}} - \text{SST}_{\text{ref}}| \le 10^{-12} + 10^{-12} \cdot |\text{SST}_{\text{ref}}|$.
  6. **Coefficient of Determination ($R^2$):** Because $R^2$ is a normalized dimensionless statistic, $|R^2_{\text{calc}} - R^2_{\text{ref}}| \le 10^{-12}$ (pure absolute comparison).
  7. **Pearson Correlation ($r$):** Dimensionless on $[-1, 1]$, compared via $|r_{\text{calc}} - r_{\text{ref}}| \le 10^{-12}$.

---

### 7.4 Regression Exactness & Numerical Representation Contract

- **Regression Fitting is Approximate by Design:**
  - Unlike univariate descriptive statistics (mean, variance) which maintain
    exact rational arithmetic via `FractionValue`, regression analysis involves
    linear system solving, matrix inversion, square roots (in correlation), and
    transcendental functions ($\ln$, $\exp$).
  - Therefore, all regression models (linear, polynomial, logarithmic,
    exponential, power) return numerical results using `DecimalValue`
    coefficients with
    `CalculationMetadata(isExact: false, approximation: ApproximationMetadata(method: 'olsRegression', precision: context.precisionDigits))`.
  - Predictions $\hat{y}_i$, residuals $e_i$, and $R^2$ are represented as
    `DecimalValue`.
  - Exact input preservation is maintained at the `Dataset` and `PairedDataset`
    storage level, but regression results are explicitly approximate to avoid
    explosive rational fraction degrees during matrix inversion.

---

### 7.5 `RegressionResult` Contract: Model Coefficients, Residuals & Correlation Semantics

#### 7.5.1 Authoritative `RegressionResult` Class Structure

```dart
final class RegressionResult {
  final RegressionType type;
  final List<DecimalValue> coefficients; // Deterministic model-specific ordering
  final ExpressionNode equation;
  final DecimalValue? correlation; // Populated ONLY for linear regression; null for all others
  final DecimalValue rSquared;
  final List<DecimalValue> predictions;
  final List<DecimalValue> residuals; // e_i = y_i - y_hat_i (observed minus predicted)
  final CalculationMetadata metadata;

  const RegressionResult({
    required this.type,
    required this.coefficients,
    required this.equation,
    this.correlation,
    required this.rSquared,
    required this.predictions,
    required this.residuals,
    required this.metadata,
  });
}
```

#### 7.5.2 Exhaustive Coefficient Mapping for Every Supported Model

Every regression model defines a strictly deterministic coefficient list `coefficients`:

```text
┌──────────────┬────────────────────────┬──────────────────────────────────────────┬──────────────────────────────┐
│ Model Type   │ Mathematical Form      │ Canonical Public Coefficients            │ Index & Semantic Meaning     │
├──────────────┼────────────────────────┼──────────────────────────────────────────┼──────────────────────────────┤
│ Linear       │ y = a*x + b            │ [b, a]                                   │ coefficients[0] = intercept b│
│              │                        │ (Ascending power: b*x^0 + a*x^1)         │ coefficients[1] = slope a    │
├──────────────┼────────────────────────┼──────────────────────────────────────────┼──────────────────────────────┤
│ Quadratic    │ y = a*x² + b*x + c     │ [c, b, a]                                │ coefficients[0] = constant c │
│              │                        │ (Ascending power: c*x^0 + b*x^1 + a*x^2) │ coefficients[1] = linear b   │
│              │                        │                                          │ coefficients[2] = quadratic a│
├──────────────┼────────────────────────┼──────────────────────────────────────────┼──────────────────────────────┤
│ Cubic        │ y = a*x³ + b*x² + cx+d │ [d, c, b, a]                             │ coefficients[0] = constant d │
│              │                        │ (Ascending power: d + c*x + b*x² + a*x³) │ coefficients[1] = linear c   │
│              │                        │                                          │ coefficients[2] = quadratic b│
│              │                        │                                          │ coefficients[3] = cubic a    │
├──────────────┼────────────────────────┼──────────────────────────────────────────┼──────────────────────────────┤
│ Logarithmic  │ y = a + b*ln(x)        │ [a, b]                                   │ coefficients[0] = constant a │
│              │                        │                                          │ coefficients[1] = scale b    │
├──────────────┼────────────────────────┼──────────────────────────────────────────┼──────────────────────────────┤
│ Exponential  │ y = a*exp(b*x)         │ [a, b]                                   │ coefficients[0] = scale a > 0│
│              │                        │ (a = exp(alpha), canonical form)         │ coefficients[1] = growth b   │
├──────────────┼────────────────────────┼──────────────────────────────────────────┼──────────────────────────────┤
│ Power        │ y = a*x^b              │ [a, b]                                   │ coefficients[0] = scale a > 0│
│              │                        │ (a = exp(alpha), canonical form)         │ coefficients[1] = power b    │
└──────────────┴────────────────────────┴──────────────────────────────────────────┴──────────────────────────────┘
```

#### 7.5.3 Exhaustive `correlation` Semantics for Every Supported Model

The `correlation` property represents the sample Pearson correlation coefficient $r$:

1. **Linear Regression (`type == RegressionType.linear`):**
   - **Populated:** `correlation` is computed as the standard Pearson correlation between $X$ and $Y$:
     $$r = \frac{\operatorname{Cov}(X, Y)}{s_X s_Y}$$
   - Returns a non-null `DecimalValue`.
   - **Relationship to $R^2$:** In linear regression with an intercept, $r^2 \equiv R^2$.
2. **Polynomial Regressions (Quadratic & Cubic):**
   - **Strictly `null`:** Pearson correlation $r$ is a bivariate measure of linear association; it does not measure curvilinear or polynomial dependence.
   - For Quadratic and Cubic regressions, `correlation == null`. Model quality is measured exclusively by original response-space $R^2$.
3. **Transformed Regressions (Logarithmic, Exponential, Power):**
   - **Strictly `null`:** In transformed models, a linear correlation $r_{\text{trans}}$ exists in transformed coordinate space (e.g. between $x$ and $\ln y$), but user-facing public diagnostics are strictly defined in the physical response space of $y$.
   - Because $r_{\text{trans}}^2 \ne R_{\text{orig}}^2$, exposing $r_{\text{trans}}$ on the top-level result would mislead users into confusing transformed correlation with physical prediction fidelity.
   - Therefore, `correlation == null` for all transformed regressions. Goodness-of-fit is reported strictly via `rSquared` in original response space.

#### 7.5.4 Residual & Diagnostic Semantics
- **Residual Convention:** Uniformly defined across all models as **observed minus predicted**:
  $$e_i = y_i - \hat{y}_i$$
- **Sum of Squared Errors (SSE):**
  $$\text{SSE} = \sum_{i=1}^N e_i^2 = \sum_{i=1}^N (y_i - \hat{y}_i)^2$$
- **Total Sum of Squares (SST):**
  $$\text{SST} = \sum_{i=1}^N (y_i - \bar{y})^2$$
- **Unified Coefficient of Determination ($R^2$):**
  $$R^2 = 1 - \frac{\text{SSE}}{\text{SST}} = 1 - \frac{\sum (y_i - \hat{y}_i)^2}{\sum (y_i - \bar{y})^2}$$
  Computed strictly in the physical units of the dependent variable $y$. Never clamped to zero when $\text{SSE} > \text{SST}$.

---

### 7.6 Non-Linear Transformation Models (Logarithmic, Exponential, Power)

Transformation-based regression converts non-linear relationships into linear
models via logarithmic mappings.

#### 7.6.1 Parameter Separation: Internal vs. Public

For transformed regressions, we strictly distinguish internal transformed
parameters from public model coefficients:

- **Logarithmic ($y = a + b \ln(x)$):**
  - Linear fit on $(u_i, y_i)$ where $u_i = \ln(x_i)$.
  - Public coefficients: `[a, b]` (`coefficients[0] = a`,
    `coefficients[1] = b`).
- **Exponential ($y = a e^{bx}$):**
  - Linear fit on $(x_i, v_i)$ where $v_i = \ln(y_i) = \alpha + b x_i$.
  - Internal parameter: $\alpha = \ln(a)$.
  - Public canonical coefficients: `[a, b]` where $a = e^\alpha > 0$. The
    internal parameter $\alpha$ is never exposed as a public coefficient.
- **Power ($y = a x^b$):**
  - Linear fit on $(u_i, v_i)$ where $u_i = \ln(x_i)$ and
    $v_i = \ln(y_i) = \alpha + b u_i$.
  - Internal parameter: $\alpha = \ln(a)$.
  - Public canonical coefficients: `[a, b]` where $a = e^\alpha > 0$.

#### 7.6.2 Domain Restrictions & Errors

- **Logarithmic:** Requires $x_i > 0$ for all $i$. If any $x_i \le 0$, returns:
  `MathFailure(DomainError(functionName: 'logarithmicRegression', message: 'Logarithmic regression requires strictly positive x values (x > 0).'))`.
- **Exponential:** Requires $y_i > 0$ for all $i$. If any $y_i \le 0$, returns:
  `MathFailure(DomainError(functionName: 'exponentialRegression', message: 'Exponential regression via log-linear transformation requires strictly positive y values (y > 0).'))`.
- **Power:** Requires $x_i > 0$ and $y_i > 0$ for all $i$. If any $x_i \le 0$ or
  $y_i \le 0$, returns:
  `MathFailure(DomainError(functionName: 'powerRegression', message: 'Power regression requires strictly positive x and y values (x > 0, y > 0).'))`.

#### 7.6.3 Defensible Precision Loss, Overflow & Underflow Taxonomy

Rather than relying on vague notions of "catastrophic cancellation", NexaMath categorizes numerical breakdown conditions into four strictly defined, concrete operational states:

```text
┌──────────────────────────────────────┬─────────────────────────────┬────────────────────────────────────────────────────────┐
│ State Category                       │ Concrete Detectable Trigger │ Runtime Action & Contract Return                       │
├──────────────────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ A. Detectable Overflow               │ Magnitude exceeds finite    │ Return typed failure: MathFailure(OverflowError)       │
│                                      │ limit (> 10^308 or context) │                                                        │
├──────────────────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ B. Detectable Underflow              │ Non-zero positive parameter │ Return typed failure: MathFailure(UnderflowError)       │
│                                      │ collapses to 0.0 (a <= 0)   │                                                        │
├──────────────────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ C. Numerical Precision Risk          │ Relative pivot decay in     │ Return success with warning: MathSuccess +             │
│                                      │ moment matrix: rho < 1e-15  │ PrecisionLossWarning(message: 'Design matrix is...')   │
├──────────────────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ D. Unacceptable Precision Loss       │ Concrete sanity failure:    │ Return typed failure: MathFailure(PrecisionLossError)  │
│                                      │ |r| > 1 + 1e-15, NaN,       │ (Cannot return valid mathematical representation)      │
│                                      │ or non-convergent root      │                                                        │
└──────────────────────────────────────┴─────────────────────────────┴────────────────────────────────────────────────────────┘
```

1. **Category A — Detectable Overflow (`OverflowError`):**
   - **Trigger:** A computed floating-point/decimal quantity exceeds the maximum representable finite bound (e.g. IEEE 754 float magnitude $> 1.7976931348623157 \times 10^{308}$ or exceeding configured `PrecisionContext.precisionDigits` exponent limit).
   - **Occurs In:**
     - Parameter reconstruction: $a = e^\alpha$ for steep positive $\alpha$ (e.g. $\alpha > 709.78$).
     - Predictions: $\hat{y}_i = a e^{b x_i}$ or $\hat{y}_i = a x_i^b$ exceeding finite bounds.
     - Residual squaring: $e_i^2$ or $\text{SSE} = \sum e_i^2$ overflowing finite representation.
   - **Action:** Operation returns typed failure:
     `MathFailure(OverflowError(message: 'Numerical calculation overflowed maximum representable finite bound.'))`.
2. **Category B — Detectable Underflow (`UnderflowError`):**
   - **Trigger:** A mathematically non-zero positive parameter falls below the minimum representable positive floating/decimal magnitude and truncates to zero, violating structural model invariants.
   - **Occurs In:**
     - Exponential or Power parameter reconstruction: $a = e^\alpha \le 0$ (for large negative $\alpha < -745$), violating the strict domain requirement $a > 0$.
   - **Action:** Operation returns typed failure:
     `MathFailure(UnderflowError(message: 'Scale parameter underflowed below minimum representable positive bound.'))`.
   - _Note on Residuals/Predictions:_ If an individual prediction $\hat{y}_i$ underflows below minimum magnitude while mathematically non-negative, it gracefully flattens to `0.0` under standard IEEE 754 denormal semantics rather than failing, provided model domain invariants are not violated.
3. **Category C — Numerical Precision Risk (`PrecisionLossWarning`):**
   - **Trigger:** An engineering condition-risk monitor detects severe dynamic range loss, but the calculation remains numerically well-defined and completes without violating mathematical domain invariants.
   - **Occurs In:**
     - Relative pivot decay during Gauss-Jordan elimination on moment matrix $\tilde{\mathbf{X}}^T \tilde{\mathbf{X}}$ satisfies $\rho = \frac{\min |p|}{\max |p|} < 10^{-15}$.
   - **Action:** Operation succeeds with `MathSuccess`, but attaches a non-fatal warning:
     `CalculationMetadata(warnings: [PrecisionLossWarning(message: 'Design matrix is ill-conditioned; regression coefficients may suffer precision loss.')])`.
4. **Category D — Unacceptable Precision Loss (`PrecisionLossError`):**
   - **Trigger:** A concrete, objectively verifiable violation of mathematical axioms caused by cumulative finite-precision round-off error, rendering the computed result unrepresentable as a valid mathematical object.
   - **Occurs In:**
     - Pearson correlation coefficient computed value exceeds mathematical bound by more than zero tolerance: $|r| > 1.0 + 10^{-15}$.
   - **Non-Finite Results (`NaN` / `Infinity`):**
     - Non-finite numbers are NOT automatically classified as `PrecisionLossError`.
     - Overflow beyond representable range $\to$ `OverflowError`.
     - Division by zero $\to$ `DivisionByZeroError`.
     - Evaluation outside domain $\to$ `DomainError`.
     - `PrecisionLossError` is reserved strictly for operations that fail due to demonstrable loss of numerical precision where domain and finite inputs were valid.
   - **Action:** Operation returns typed failure:
     `MathFailure(PrecisionLossError(message: 'Catastrophic precision loss occurred: computed values violate mathematical bounds.'))`.
   - _Boundary Principle:_ NexaMath does NOT claim arbitrary cancellation in arbitrary intermediate steps is universally detectable; `PrecisionLossError` is emitted exclusively when an explicit verifiable invariant breach occurs.

#### 7.6.4 Warning Selection, Prioritization & Coexistence Contract

In accordance with `CalculationMetadata(warnings: List<MathWarning>)` from Phase 1, multiple non-fatal warnings can legitimately coexist in a single computation result. To ensure fully deterministic behavior across implementations, the following selection and prioritization rules apply:

```text
┌──────────────────────────────────────┬────────────────────────────────────────────────────────┐
│ Numerical Condition                  │ Emitted Warning Instance                               │
├──────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ 1. SST == 0 (Constant Response)      │ NearZeroWarning(message: 'Total sum of squares (SST)...')│
│ 2. Moment matrix relative pivot decay│ PrecisionLossWarning(message: 'Design matrix is...')   │
│ 3. Both conditions occur together    │ BOTH warnings included: [NearZeroWarning,              │
│                                      │  PrecisionLossWarning] in deterministic order.         │
└──────────────────────────────────────┴────────────────────────────────────────────────────────┘
```

1. **Independent Triggers:**
   - A warning is emitted **if and only if** its specific condition trigger is satisfied. One warning is never emitted as a side-effect or proxy for another.
2. **Deterministic Warning Ordering:**
   - When multiple warnings are applicable to a single regression result, they are ordered deterministically in `metadata.warnings`:
     1. Domain/scale structural warnings (e.g. `NearZeroWarning` for $\text{SST} = 0$).
     2. Solver conditioning warnings (e.g. `PrecisionLossWarning` for $\rho < 10^{-15}$).
     3. Approximation metadata warnings (e.g. `NumericalApproximationWarning` if applicable).
3. **No Warning Suppression:**
   - Neither warning suppresses the other. For example, if a constant response dataset ($\text{SST} = 0$) also produces an ill-conditioned moment matrix ($\rho < 10^{-15}$), the result carries both `NearZeroWarning` and `PrecisionLossWarning`.
4. **Compatibility:**
   - Uses only existing Phase 1 warning classes ([lib/core/result/math_warning.dart](file:///d:/Programming%20projects/nexa_math/lib/core/result/math_warning.dart)). No new warning types or ad-hoc diagnostic strings are introduced.

---

### 7.7 Transformed Regression $R^2$, Prediction, and Residual Semantics

To prevent semantic divergence between linear and transformed regressions,
NexaMath establishes the following mandatory contract:

- **All predictions $\hat{y}_i$, residuals $e_i$, and user-facing $R^2$ are
  computed strictly in the ORIGINAL RESPONSE SPACE ($y$-space):**
  1. **Predictions:**
     - Logarithmic: $\hat{y}_i = a + b \ln(x_i)$
     - Exponential: $\hat{y}_i = a e^{b x_i}$
     - Power: $\hat{y}_i = a x_i^b$
  2. **Residuals:**
     $$e_i = y_i - \hat{y}_i \quad (\text{measured in the physical scale of } y)$$
  3. **Coefficient of Determination ($R^2$):**
     $$R^2 = 1 - \frac{\sum_{i=1}^N (y_i - \hat{y}_i)^2}{\sum_{i=1}^N (y_i - \bar{y})^2}$$
     calculated directly on original observations $y_i$ and reconstructed
     predictions $\hat{y}_i$.
  4. **Important Guardrail:** User-facing $R^2$ for transformed regressions is
     **NOT** equal to the square of Pearson correlation computed in the
     transformed log-space ($R^2 \ne r_{\text{transformed}}^2$). Computing $R^2$
     in transformed log-space ($\ln(y)$) distorts the error metric and misleads
     users regarding actual prediction accuracy in physical units.

---

## 8. Expression AST Integration Contract

Every fitted regression model produces a corresponding canonical
`ExpressionNode` AST representing the continuous function $f(x)$ for downstream
evaluation, plotting, and symbolic differentiation.

### 8.1 Semantic AST Generation Requirements

- **Strict Alignment with Phase 3 AST API:**
  - `NumberLiteralNode(position: SourcePosition.start, value: DecimalValue(...))`
  - `VariableNode(position: SourcePosition.start, name: 'x')`
  - `BinaryOpNode(position: SourcePosition.start, operator: BinaryOperator.add / multiply / power, left: ..., right: ...)`
  - `FunctionCallNode(position: SourcePosition.start, name: 'ln' / 'exp', arguments: [...])`
  - _(Verified: `SourcePosition.start` is the canonical position constant in
    Phase 3; `FunctionRegistry` built-ins provide registered functions `'ln'`
    and `'exp'`)_.
- **Canonical Expressions Produced:**
  - **Linear:** $a \cdot x + b$
  - **Quadratic:** $a \cdot x^2 + b \cdot x + c$
  - **Cubic:** $a \cdot x^3 + b \cdot x^2 + c \cdot x + d$
  - **Logarithmic:** $a + b \cdot \ln(x)$ (uses
    `FunctionCallNode(position: SourcePosition.start, name: 'ln', arguments: [VariableNode(position: SourcePosition.start, name: 'x')])`)
  - **Exponential:** $a \cdot \exp(b \cdot x)$
  - **Power:** $a \cdot x^b$
- **Prediction Evaluator:** Point predictions $\hat{y} = f(x_0)$ can be
  generated either directly via compiled arithmetic functions or by passing the
  AST and `EvaluationContext(variables: {'x': x0})` to the Phase 3
  `AstEvaluator`.

---

## 9. Error and Warning Semantics Verification

All Phase 9 error and warning returns map 1-to-1 with existing Phase 1 core
contracts. No new exception classes or ad-hoc strings are introduced.

```text
┌────────────────────────────────────────┬─────────────────────────────┬────────────────────────────────────────────────────────┐
│ Scenario                               │ Result Type                 │ Verified Existing Class / Constructor                  │
├────────────────────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Empty dataset for mean, var, std, etc. │ MathFailure                 │ InvalidArgumentError(argumentName: 'dataset', ...)     │
│ Sample variance with N < 2             │ MathFailure                 │ InvalidArgumentError(argumentName: 'dataset', ...)     │
│ Sample covariance with N < 2           │ MathFailure                 │ InvalidArgumentError(argumentName: 'dataset', ...)     │
│ PairedDataset with |X| != |Y|          │ MathFailure                 │ DimensionMismatchError(expected: ..., actual: ...)     │
│ Percentile p < 0 or p > 100            │ MathFailure                 │ DomainError(functionName: 'percentile', ...)           │
│ Zero variance in Pearson correlation   │ MathFailure                 │ DomainError(functionName: 'pearsonCorrelation', ...)   │
│ Extreme Pearson round-off (|r| > 1+eps)│ MathFailure                 │ PrecisionLossError(message: ...)                       │
│ Logarithmic regression with x <= 0     │ MathFailure                 │ DomainError(functionName: 'logarithmicRegression', ...)│
│ Exponential regression with y <= 0     │ MathFailure                 │ DomainError(functionName: 'exponentialRegression', ...)│
│ Power regression with x <= 0 or y <= 0 │ MathFailure                 │ DomainError(functionName: 'powerRegression', ...)      │
│ Parameter exp(alpha) overflow          │ MathFailure                 │ OverflowError(message: ...)                            │
│ Parameter exp(alpha) underflow         │ MathFailure                 │ UnderflowError(message: ...)                           │
│ Singular regression matrix             │ MathFailure                 │ SingularMatrixError(message: ...)                      │
│ Insufficient distinct x values         │ MathFailure                 │ SingularMatrixError(message: ...)                      │
│ Polynomial regression with N < d + 1   │ MathFailure                 │ InvalidArgumentError(argumentName: 'dataset', ...)     │
│ Near-singular design matrix            │ MathSuccess + Warning       │ PrecisionLossWarning / NearZeroWarning                 │
│ SST = 0 in regression R²               │ MathSuccess + Warning       │ NearZeroWarning(message: ...)                          │
│ Approximated numerical result          │ MathSuccess + Metadata      │ CalculationMetadata(isExact: false, approximation: ...)│
└────────────────────────────────────────┴─────────────────────────────┴────────────────────────────────────────────────────────┘
```

---

## 10. Computational Complexity & Performance Contract

Expected asymptotic time and space complexity for all Phase 9 operations:

| Operation                   | Time Complexity                     | Space Complexity   | Notes                                                           |
| :-------------------------- | :---------------------------------- | :----------------- | :-------------------------------------------------------------- |
| **Count, Sum, Mean**        | $O(N)$                              | $O(1)$ auxiliary   | Single or two-pass iteration                                    |
| **Min, Max, Range**         | $O(N)$                              | $O(1)$ auxiliary   | Single pass extremum search                                     |
| **Median, Quantiles, IQR**  | $O(N \log N)$                       | $O(N)$ auxiliary   | Requires sorted copy of observations                            |
| **Mode**                    | $O(N)$ average, $O(N \log N)$ worst | $O(N)$ auxiliary   | Hash-map frequency counting + sort of modes                     |
| **Variance, Std Dev**       | $O(N)$                              | $O(1)$ auxiliary   | Two-pass or Welford algorithm                                   |
| **Covariance, Correlation** | $O(N)$                              | $O(1)$ auxiliary   | Two-pass paired accumulation                                    |
| **Linear Regression**       | $O(N)$                              | $O(1)$ auxiliary   | Analytic OLS sums                                               |
| **Polynomial Regression**   | $O(N \cdot d + d^3)$                | $O(d^2)$ auxiliary | Moment accumulation $O(N \cdot d)$ + $(d+1) \times (d+1)$ solve |
| **Transformed Regression**  | $O(N)$                              | $O(N)$ auxiliary   | Log transform pass + analytic OLS                               |

---

## 11. Architectural Package Map & Component Boundaries

The physical code layout for Phase 9 implementation will reside exclusively
within:

```text
lib/mathematical_core/statistics/
├── models/
│   ├── dataset.dart                     # Immutable 1D scalar dataset
│   ├── paired_dataset.dart              # Immutable coordinate dataset (X, Y)
│   ├── descriptive_statistics.dart      # Immutable container for all descriptive metrics
│   └── regression_result.dart           # Immutable container for regression output, R², AST
├── descriptive/
│   ├── descriptive_calculator.dart      # Mean, median, mode, variance, std dev
│   └── quantile_calculator.dart         # Hyndman-Fan Type 7 percentile and quartile algorithms
├── regression/
│   ├── regression_model.dart            # Base contract for regression estimators
│   ├── linear_regression.dart           # OLS linear regression
│   ├── polynomial_regression.dart       # Quadratic and cubic regression solvers
│   └── transformed_regression.dart      # Logarithmic, exponential, and power estimators
├── statistics_engine.dart               # Public abstract interface
├── default_statistics_engine.dart       # Production coordinator implementation
└── statistics.dart                      # Public barrel export
```

### Architectural Dependency Hierarchy

```text
Statistics & Regression Subsystem
 ├── depends on: lib/core/ (MathResult, MathError, MathWarning, CalculationMetadata)
 ├── depends on: lib/mathematical_core/common/ (ScalarValue, MathValue, PrecisionContext)
 ├── depends on: lib/mathematical_core/numeric/ (IntegerValue, DecimalValue, FractionValue)
 ├── depends on: lib/mathematical_core/expression/ (ExpressionNode AST generation)
 └── depends on: lib/mathematical_core/matrix/ (Matrix & MatrixEngine for polynomial regression)
```

- **Strict Isolation:** No dependencies on Flutter UI, Phase 7 Calculus, Phase 8
  Equation Solver, or external third-party packages.

---

## 12. Expanded Test Strategy & Deterministic Reference Test Suite

When Phase 9 is authorized for implementation, the test suite
(`test/mathematical_core/statistics/`) will comprehensively validate:

### 12.1 Descriptive Statistics Test Matrix

- Empty dataset ($N = 0 \to$ `InvalidArgumentError`).
- Singleton dataset ($N = 1 \to$ count=1, sum=$x_1$, mean=$x_1$, median=$x_1$,
  mode=$[x_1]$, pop_var=0, sample_var=`InvalidArgumentError`).
- All identical values (e.g. $\{5, 5, 5, 5\} \to$ count=4, range=0, variance=0,
  **mode=$[5]$**).
- All unique values (e.g. $\{1, 2, 3, 4\} \to$ mode=`[]`).
- Multi-element identical-frequency tie across all values (e.g.
  $\{1, 1, 2, 2, 3, 3\} \to$ mode=`[]`).
- Bimodal / Multimodal datasets (e.g. $\{1, 1, 2, 3, 3\} \to$ modes=$[1, 3]$ in
  ascending order).
- Mixed scalar types ($1.5$ and $3/2$ treated as identical values in frequency
  table).
- Exact rational sample mean (e.g., $\{1, 2\} \to \text{FractionValue}(3, 2)$).
- Exact rational variance and standard deviation
  ($\sigma^2 = 1/4 \to \sigma = 1/2$, $\sigma^2 = 9/16 \to \sigma = 3/4$).
- Non-perfect square standard deviation
  ($\sigma^2 = 2 \to \text{DecimalValue}(1.4142...)$ with `isExact: false`).
- Negative and zero-centered values ($\{-10, 0, 10\} \to \text{mean}=0$).
- Immutability: External list modifications do not mutate `Dataset`.

### 12.2 Quantiles & Quartiles Test Matrix

- $N = 1$ dataset ($P_p = x_1$ for all $p \in [0, 100]$).
- Boundary invariants: $P_0 = \min(\mathcal{D})$ and
  $P_{100} = \max(\mathcal{D})$.
- Known reference Type 7 cases (validated against R `type=7` and NumPy
  `linear`):
  - Dataset $\mathcal{D} = \{1, 2, 3, 4, 5\}$: $P_{25} = 2.0$, $P_{50} = 3.0$,
    $P_{75} = 4.0$.
  - Dataset $\mathcal{D} = \{10, 20, 30, 40\}$:
    $h(25) = (3)(0.25) + 1 = 1.75 \implies P_{25} = 10 + 0.75(10) = 17.5$ (exact
    `FractionValue(35, 2)`).
- Median invariant: $Q_2 \equiv \text{Median}$ across odd and even sample sizes.
- Domain errors: $p = -0.1$ and $p = 100.1$ return `DomainError`.

### 12.3 Bivariate & Correlation Test Matrix

- Length mismatch ($|X| \ne |Y| \to$ `DimensionMismatchError`).
- Singleton paired dataset ($N = 1 \to \operatorname{Cov}_{\text{pop}} = 0$,
  $\operatorname{Cov}_{\text{sample}} \to$ `InvalidArgumentError`).
- Perfect positive ($r = 1.0$) and negative ($r = -1.0$) correlation.
- Zero correlation (orthogonal data:
  $X = \{-1, 0, 1\}, Y = \{1, 0, 1\} \implies r = 0$).
- Zero variance in $X$ or $Y \to$ `DomainError`.
- Bounded round-off clamping ($r = 1.0000000000000002 \to 1.0$).
- Catastrophic round-off rejection ($r = 1.05 \to$ `PrecisionLossError`).

### 12.4 Linear & Polynomial Regression Test Matrix

All approximate numerical regression test assertions apply the **scale-aware comparison policy** (§7.3.3):
$$|v_{\text{calc}} - v_{\text{ref}}| \le 10^{-12} + 10^{-12} \cdot |v_{\text{ref}}|$$

- $N = 2$ exact linear fit ($y = 2x + 1$):
  - Invariants: slope $a = 2$, intercept $b = 1$, correlation $r = 1.0$, $R^2 = 1.0$.
  - Numerical assertions: $|a - 2| \le 10^{-12} + 10^{-12}\cdot 2$, $|b - 1| \le 10^{-12} + 10^{-12}\cdot 1$, $|r - 1.0| \le 10^{-12}$, $|1 - R^2| \le 10^{-12}$, $\text{SSE} \le 10^{-12}$.
- Vertical line ($x_1 = x_2 \to$ `SingularMatrixError`).
- Exactly Determined Quadratic ($N = 3$, 3 distinct $x$ values):
  - When $\text{SST} > 0$: Mathematical invariant $\text{SSE} = 0, R^2 = 1.0$.
    - Numerical assertion: $\text{SSE} \le 10^{-12}$, $|1 - R^2| \le 10^{-12}$, $|e_i| \le 10^{-12}$, and coefficients satisfy $|c_k - c_{k, \text{expected}}| \le 10^{-12} + 10^{-12}\cdot |c_{k, \text{expected}}|$.
  - When $\text{SST} = 0$ (constant $y_i = c$):
    - Conforms to §6.3.3 Case 1: $R^2 = 1.0$ accompanied by `NearZeroWarning`. No division by zero.
- Exactly Determined Cubic ($N = 4$, 4 distinct $x$ values):
  - Mathematical invariant: $\text{SSE} = 0, R^2 = 1.0$ (for $\text{SST} > 0$).
  - Numerical assertion: $\text{SSE} \le 10^{-12}$, $|1 - R^2| \le 10^{-12}$, $|e_i| \le 10^{-12}$, and coefficients evaluated via scale-aware comparison.
- Overdetermined Quadratic ($N > 3$) and Cubic ($N > 4$) least-squares fitting:
  - Assertions evaluate coefficients, predictions, residuals, SSE, and $R^2$ within scale-aware tolerance ($\text{atol}=10^{-12}, \text{rtol}=10^{-12}$).
- Under-determined inputs ($N < d + 1 \to$ `InvalidArgumentError`).
- Duplicate $X$ coordinate handling: valid observations with distinct $Y$ values
  do NOT fail unless distinct $X$ count $< d + 1$.
- Insufficient distinct $x$ values (e.g. degree 2 with only 2 distinct $x$
  values $\to$ `SingularMatrixError`).
- Ill-conditioned design matrix warnings (`PrecisionLossWarning` emitted when
  relative pivot decay ratio $\rho < 10^{-15}$).
- Centered predictor invariant: verify that shifted data (e.g.
  $x \in \{2000, 2001, 2002\}$) recovers identical canonical coefficients as
  unshifted coordinates within scale-aware tolerance.

### 12.5 Transformed Regression, Overflow & Deterministic $R^2$ Tests

#### 12.5.1 Deterministic Negative $R^2$ Test

- **Objective:** Prove that $R^2 < 0$ is legitimately produced and not clamped
  when $\text{SSE} > \text{SST}$.
- **Dataset:** $\mathcal{P} = \{(1, 100), (2, 50), (3, 10)\}$.
- **Model:** Power regression $y = a x^b$.
  - Transformed log-linear fit on $(\ln x, \ln y)$:
    $\ln(1)=0, \ln(100)\approx 4.605$;
    $\ln(2)\approx 0.693, \ln(50)\approx 3.912$;
    $\ln(3)\approx 1.098, \ln(10)\approx 2.302$.
  - Linear slope on logs: $b \approx -2.096$, intercept
    $\alpha \approx 4.887 \implies a = e^\alpha \approx 132.55$.
  - Reconstructed original-space predictions: $\hat{y}_1 \approx 132.55$,
    $\hat{y}_2 \approx 30.98$, $\hat{y}_3 \approx 13.23$.
  - Reconstructed original residuals: $e_1 = 100 - 132.55 = -32.55$;
    $e_2 = 50 - 30.98 = 19.02$; $e_3 = 10 - 13.23 = -3.23$.
  - $\text{SSE} = (-32.55)^2 + (19.02)^2 + (-3.23)^2 \approx 1059.5 + 361.8 + 10.4 = 1431.7$.
  - Response mean: $\bar{y} = (100 + 50 + 10) / 3 = 53.333$.
  - $\text{SST} = (100 - 53.333)^2 + (50 - 53.333)^2 + (10 - 53.333)^2 \approx 2177.8 + 11.1 + 1877.8 = 4066.7$.
- Now consider an unconstrained exponential fit on mismatched concave/convex
  data, e.g. $\mathcal{P} = \{(1, 10), (2, 1), (3, 10)\}$:
  - $\bar{y} = 7.0 \implies \text{SST} = (10-7)^2 + (1-7)^2 + (10-7)^2 = 9 + 36 + 9 = 54$.
  - Fitted log-linear exponential model $y = a e^{bx}$: taking logs
    $\ln(10)\approx 2.302, \ln(1)=0, \ln(10)\approx 2.302$.
  - Symmetric data forces transformed slope
    $b = 0 \implies \hat{\alpha} = \frac{2.302 + 0 + 2.302}{3} = 1.535 \implies a = e^{1.535} \approx 4.64$.
  - Original predictions: $\hat{y}_i \approx 4.64$ for all $i$.
  - $\text{SSE} = (10 - 4.64)^2 + (1 - 4.64)^2 + (10 - 4.64)^2 = 28.73 + 13.25 + 28.73 = 70.71$.
  - Because $\text{SSE} (70.71) > \text{SST} (54.0)$, the unified formula
    yields: $$R^2 = 1 - \frac{70.71}{54.0} \approx 1 - 1.309 = -0.309 < 0$$
- **Expected Result:** $R^2 \approx -0.31 \pm 0.02$. The test asserts $R^2 < 0$,
  verifying that negative $R^2$ is preserved and NEVER clamped to $0$.

#### 12.5.2 Deterministic Transformed-Space $r^2$ vs. Original-Space $R^2$ Distinction Test

- **Objective:** Prove that user-facing $R^2$ is evaluated in original $y$-space
  and is NOT equal to transformed-space $r^2$.
- **Dataset:** Exponential model on $\mathcal{P} = \{(1, 1), (2, 2), (3, 9)\}$.
  - Transformed coordinates: $(x, \ln y) = (1, 0), (2, 0.6931), (3, 2.1972)$.
  - Transformed Pearson correlation
    $r_{\text{trans}} \approx 0.963 \implies r_{\text{trans}}^2 \approx 0.927$.
  - Fitted exponential model: $y \approx 0.323 \cdot e^{1.0986 x}$.
  - Predictions in original space: $\hat{y}_1 \approx 0.97$,
    $\hat{y}_2 \approx 2.91$, $\hat{y}_3 \approx 8.73$.
  - Residuals in original space: $e_1 = 1 - 0.97 = 0.03$,
    $e_2 = 2 - 2.91 = -0.91$, $e_3 = 9 - 8.73 = 0.27$.
  - $\text{SSE} = (0.03)^2 + (-0.91)^2 + (0.27)^2 \approx 0.0009 + 0.8281 + 0.0729 = 0.9019$.
  - $\bar{y} = (1 + 2 + 9)/3 = 4.0 \implies \text{SST} = (1-4)^2 + (2-4)^2 + (9-4)^2 = 9 + 4 + 25 = 38.0$.
  - Original response-space $R^2$:
    $$R_{\text{orig}}^2 = 1 - \frac{0.9019}{38.0} \approx 1 - 0.0237 = 0.9763$$
- **Assertion:** The test explicitly verifies that:
  $$|R_{\text{orig}}^2 - r_{\text{trans}}^2| = |0.9763 - 0.9274| \approx 0.0489 > 0.01$$
  confirming that $R^2$ represents original response-space variance reduction,
  not transformed-space correlation squared.

#### 12.5.3 Degenerate Constant Response $\text{SST} = 0$ Tests

- **Test 1 ($\text{SST} = 0, \text{SSE} = 0$ — Public API Reachable):**
  - Horizontal dataset $\mathcal{P} = \{(1, 5), (2, 5), (3, 5)\}$.
  - Ordinary least-squares linear or polynomial fit unconstrained produces
    $y = 0x + 5 \implies \hat{y}_i = 5 \implies \text{SSE} = 0$.
  - Returns $R^2 = 1.0$ accompanied by `NearZeroWarning`.
- **Test 2 ($\text{SST} = 0, \text{SSE} > 0$ — Internal Model Diagnostic Test):**
  - **API Reachability Analysis:** In unconstrained OLS linear and polynomial regression with an intercept, the optimal least-squares solution for constant response $y_i = c$ is always the constant line $\hat{y} = c$, resulting in $\text{SSE} = 0$. Therefore, $\text{SSE} > 0$ with $\text{SST} = 0$ cannot be reached through the standard unconstrained linear/polynomial public fit.
  - **Test Classification & Execution:** This scenario is tested as an **internal unit test on the diagnostic evaluation engine** (`RegressionDiagnosticCalculator.calculateRSquared` or evaluating a candidate model with non-constant predictions against constant observations, e.g. $\mathbf{y} = [5, 5, 5]^T$ with pre-fitted $\hat{\mathbf{y}} = [4, 5, 6]^T \implies \text{SSE} = 2 > 0$).
  - **Verification:** The diagnostic calculator returns $R^2 = 0.0$ accompanied by `NearZeroWarning(message: 'Total sum of squares (SST) is zero; model residuals are non-zero.')`. No public constrained-parameter API is invented.

#### 12.5.4 Parameter Overflow / Underflow Tests

- Exponential fit on steep coordinates yielding $\alpha > 710$ (such that
  $a = e^\alpha > 10^{308}$ in double or exceeding `PrecisionContext` bound):
  - Expected Failure: `MathFailure(OverflowError(code: 'OVERFLOW', message: ...))`.
- Exponential fit yielding $\alpha < -750$ (such that $e^\alpha$ underflows to zero, violating $a > 0$):
  - Expected Failure: `MathFailure(UnderflowError(code: 'UNDERFLOW', message: ...))`.
- Prediction evaluation overflow: $\hat{y} = a e^{b x_0}$ where $b x_0$ forces magnitude $> 10^{308}$:
  - Expected Failure: `MathFailure(OverflowError(code: 'OVERFLOW', message: ...))`.

---

## 13. Step-by-Step Implementation Sequence

When authorized, Phase 9 implementation will proceed in the following ordered
dependency sequence:

1. **Step 1: Core Models & Validation Contracts**\
   Implement `Dataset` and `PairedDataset` with immutability, defensive copies,
   Phase 2 value equality, and scalar domain checks.
2. **Step 2: Descriptive Calculator (Univariate)**\
   Implement count, sum, mean, median, min, max, range, and mode according to
   the exactness and edge-case contracts.
3. **Step 3: Stable Variance & Standard Deviation**\
   Implement two-pass/Welford variance and rational square root exactness
   detection.
4. **Step 4: Quantile & Quartile Calculator**\
   Implement Hyndman-Fan Type 7 interpolation with exact/approximate parameter
   handling, quartiles, and IQR.
5. **Step 5: Bivariate Calculator**\
   Implement population/sample covariance (including $N=1$ population covariance
   = 0), Pearson correlation with bounded clamping, and SST=0 contract.
6. **Step 6: Regression Result Model & AST Generator**\
   Implement `RegressionResult` with ascending power coefficient ordering
   `[c0, c1, ...]`, original-space prediction evaluator, residual extractor, and
   Phase 3 `ExpressionNode` AST builder using verified `SourcePosition.start`.
7. **Step 7: Linear Regression Model**\
   Implement analytic OLS linear regression with vertical-line singularity
   detection.
8. **Step 8: Polynomial Regression Model**\
   Implement quadratic and cubic least-squares regression with Vandermonde
   normal equations, distinct $X$ count validation, predictor centering
   optimization with algebraic reconstruction to canonical coefficients, and
   `MatrixEngine.inverse` integration.
9. **Step 9: Transformed Regression Models**\
   Implement Logarithmic, Exponential, and Power regressions with strict domain
   pre-checks, overflow/underflow safeguards, and original-space residual/$R^2$
   reconstruction.
10. **Step 10: Statistics Engine Public Façade**\
    Implement `StatisticsEngine` and `DefaultStatisticsEngine` dispatching all
    operations through `MathResult`.
11. **Step 11: Unit & Integration Test Suite**\
    Implement comprehensive test suite in `test/mathematical_core/statistics/`
    covering all deterministic test matrices and invariants.
12. **Step 12: Analyzer, Linter & Formatter Verification**\
    Verify `flutter analyze`, `dart format`, and zero regressions across Phases
    0–8.

---

## 14. Verification & Acceptance Criteria for Future Implementation

Phase 9 implementation will be deemed complete only when:

- [ ] 100% of methods in `StatisticsEngine` are implemented and verified.
- [ ] All descriptive metrics match reference hand calculations and oracle
      benchmarks.
- [ ] Quantiles follow the Hyndman-Fan Type 7 specification without deviation.
- [ ] Rational variance and perfect-square standard deviations preserve exact
      representation (`FractionValue` / `IntegerValue`).
- [ ] Mode conforms to the deterministic contract across empty, singleton,
      all-unique, identical-value, and multimodal sets.
- [ ] Polynomial regressions enforce distinct $X$ rank requirements and
      distinguish under-determined, exactly determined, and overdetermined
      cases.
- [ ] Transformed regressions compute residuals, predictions, and $R^2$ in
      original response space without clamping negative $R^2$.
- [ ] Deterministic tests for negative $R^2$ and transformed $R^2 \ne r^2$ pass.
- [ ] All error cases return typed `MathResult.failure` using verified existing
      Phase 1 error classes.
- [ ] `flutter analyze` reports 0 issues.
- [ ] All 374 baseline tests plus all new Phase 9 tests pass.
- [ ] Native Windows and Android configurations remain intact.

---

## 15. Official Planning Sign-Off

> ### **PHASE 9 — MATHEMATICAL SPECIFICATION & ARCHITECTURE PLANNING — HARDENED AND ACCEPTED**
>
> ### **PHASE 9 IMPLEMENTATION — NOT YET STARTED**
>
> All identified mathematical ambiguities, percentile parameter exactness, mode
> semantics, exact standard deviation rules, polynomial least-squares solve
> strategy, centering and algebraic reconstruction formulas, relative pivot
> numerical-risk indicators, regression exactness policies, ascending
> coefficient ordering, transformed regression parameter separation,
> overflow/underflow behavior, and deterministic test cases have been resolved,
> hardened, and verified against the NexaMath Pure Dart Core architecture.
>
> The specification is 100% authoritative and implementation-ready.
