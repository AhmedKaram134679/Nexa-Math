# NexaMath — Phase 10: Probability & Distributions Specification

**Document Type:** Architectural, Mathematical & Engineering Specification  
**Document Status:** Authoritative Implementation Specification (REVISION 6 — FINAL TECHNICAL CORRECTION CANDIDATE — PENDING OWNER APPROVAL)  
**Author:** Senior Numerical Software Engineer, Scientific Computing Specialist & Mathematical Software Architect  
**Initial Draft Date:** October 3, 2026  
**Revision 1 Date:** October 3, 2026  
**Revision 2 Date:** October 3, 2026  
**Revision 3 Date:** October 3, 2026  
**Revision 4 Date:** October 3, 2026  
**Revision 5 Date:** October 4, 2026  
**Revision 6 Date:** October 4, 2026  
**Target Engine:** `lib/mathematical_core/probability/`  
**Host Framework:** Flutter / Pure Dart Mathematical Core  
**Target Platforms:** Windows & Android  

---

## 1. Document Control & Revision History

### 1.1 Revision History
| Revision | Date | Author | Summary of Changes | Status |
|---|---|---|---|---|
| **Draft 0** | October 3, 2026 | Senior Mathematical Architect | Initial draft synthesizing Roadmap §15, Engine Contracts §38, and Blueprint §4. | Superseded |
| **Revision 1** | October 3, 2026 | Senior Numerical Software Engineer | Initial hardening pass: decision classification, PRNG Option B, open-interval concept, initial quantile endpoints, Poisson exactness correction. | Superseded |
| **Revision 2** | October 3, 2026 | Senior Numerical Software Engineer & Mathematical Architect | Targeted hardening: generalized inverse quantile, degenerate distributions, incomplete function identities, discrete boundaries, representation exactness, distribution-specific stability. | Superseded |
| **Revision 3** | October 3, 2026 | Senior Numerical Software Engineer & Mathematical Architect | Targeted Mathematical & Contractual Closure: formalized generalized inverse vs API endpoints, discrete queries, Beta/Gamma boundary isolation, exactness layers, RandomSource audit, error mapping. | Superseded |
| **Revision 4** | October 3, 2026 | Senior Numerical Software Engineer & Mathematical Architect | Final Contract Closure: repository API audit, RandomSource boundary, exactness/resource separation, underflow semantics, observable numerical acceptance, discrete quantile closure, sampling shape validation. | Superseded |
| **Revision 5** | October 4, 2026 | Senior Numerical Software Engineer & Mathematical Architect | Final Implementation Gate & Micro-Closure: RandomSource reproducibility boundary clarified, Geometric domain corrected ($0 < p \le 1$), underflow safety lock, quantile bracket invariant, sampling moment consistency. | Superseded |
| **Revision 6** | October 4, 2026 | Senior Numerical Software Engineer & Mathematical Architect | **Pre-Implementation Audit Integration, Resource Policy & Micro-Correction Pass:**<br>1) Incorporated findings from Repository Pre-Implementation Audit (applicable existing repository prerequisites verified where present; documented RandomSource limitations unchanged; Phase 10 target path clean);<br>2) §20.1: Proposed deterministic 1,024-bit representation resource threshold as an explicit engineering policy with predictive growth checks where feasible, pending Owner Approval;<br>3) §20.2: Proposed underflow policy relative to the actual evaluation representation used without assuming binary64 floats universally; positive tail underflow yields representational zero (`DecimalValue.zero` [verified] or `0.0`) with non-exact metadata and verified parameterless `NearZeroWarning`; fatal `UnderflowError` strictly reserved for unrecoverable computational/structural failures;<br>4) Clarified structural exact zeros vs transcendental approximations;<br>5) Refined numerical acceptance criteria to be distribution-aware (z-scale for Normal, $\lambda x$ for Exponential, support-relative for Uniform);<br>6) Formulated Normal symmetry as a tolerance-based numerical identity;<br>7) Separated empirical 100k sampling test from open-interval invariant contract;<br>8) Status: Candidate prepared for Owner Review. | **CANDIDATE PENDING OWNER APPROVAL** |

### 1.2 Document Metadata
- **Document Title:** NexaMath Phase 10 — Probability & Distributions Specification
- **Phase:** Phase 10 — Probability & Distributions
- **Authority:** Authoritative Implementation Specification for Phase 10
- **Current Implementation Status:** READY FOR OWNER REVIEW (Pre-Implementation Audit passed for existing dependencies; zero open architectural blockers)
- **Implementation Authorization:** PENDING OWNER APPROVAL (Awaiting explicit human owner authorization)
- **Production Code Modified:** NO
- **Test Code Modified:** NO

### 1.3 Supersession & Document Hierarchy
Per `NEXAMATH_IMPLEMENTATION_ROADMAP.md` §1:
1. `CALCULATOR_MASTER_SPECIFICATION.md` defines what NexaMath must become.
2. `NEXAMATH_IMPLEMENTATION_BLUEPRINT.md` defines the structural architecture.
3. `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` defines public engine APIs, models, and boundaries.
4. `NEXAMATH_IMPLEMENTATION_ROADMAP.md` defines the execution sequence.
5. `NEXAMATH_PHASE_10_PROBABILITY_DISTRIBUTIONS_SPECIFICATION.md` (this document) establishes the final contractual and mathematical rules for Phase 10 implementation.

---

## 2. Decision Classification & Origin Traceability

To maintain complete architectural and evidentiary honesty, every material policy in Revision 6 is classified into one of the following distinct categories:
- **`[SOURCE-DERIVED]`**: Explicitly mandated or directly constrained by existing authoritative project documents (`CALCULATOR_MASTER_SPECIFICATION.md`, `NEXAMATH_IMPLEMENTATION_ROADMAP.md`, `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md`, `NEXAMATH_IMPLEMENTATION_BLUEPRINT.md`, or existing source files in `lib/core/`). *Note: Mathematical standardness or consistency with another phase is rationale, not source authority.*
- **`[NEW PHASE 10 DECISION]`**: Established specifically in this Phase 10 specification to resolve mathematical, numerical, or boundary ambiguities where authoritative documents were silent.
- **`[IMPLEMENTATION CHOICE]`**: Left to the discretion of the implementation engineer, provided the observable contract and acceptance criteria are satisfied.
- **`[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]`**: Policy choices rigorously resolved from an engineering and numerical analysis standpoint, submitted to the project owner for formal review and authorization.

### 2.1 Revision 6 Decisions Origin Matrix
| Decision / Contract Element | Classification | Source / Rationale | Status |
|---|---|---|---|
| **Public Façade Interface (`ProbabilityEngine`)** | `[SOURCE-DERIVED]` | `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §38 | Locked |
| **Initial 6 Distributions Scope** | `[SOURCE-DERIVED]` | `NEXAMATH_IMPLEMENTATION_ROADMAP.md` §15.3 | Locked |
| **Query Sealed Hierarchy** | `[SOURCE-DERIVED]` | `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §38 | Locked |
| **Complex Input Rejection Policy** | `[NEW PHASE 10 DECISION]` | Rejects non-real scalars with `DomainError`; verified `ComplexNumber.isReal` and `imaginary.isZero`. | Locked |
| **Geometric Convention 1 (Trials $k \ge 1$)** | `[NEW PHASE 10 DECISION]` | Standard discrete modeling convention; matches $E[X]=1/p$ and scientific calculator norms. | Locked |
| **Geometric Success Probability Domain ($0 < p \le 1$)** | `[NEW PHASE 10 DECISION]` | Enforces $p > 0$ strictly for Geometric; $p = 0$ is rejected with `InvalidDistributionParameterError`. | Locked |
| **Quantile Generalized Inverse vs Endpoint Convention** | `[NEW PHASE 10 DECISION]` | Formalized $Q(p) = \inf\{x \in \mathbb{R} : F(x) \ge p\}$ for $p \in (0, 1)$; explicit API convention for $p \in \{0, 1\}$. | Locked |
| **Degenerate Quantiles ($n=0, p=0, p=1$)** | `[NEW PHASE 10 DECISION]` | Formally resolved via generalized inverse on discrete support. | Locked |
| **Poisson Exactness Limitation** | `[NEW PHASE 10 DECISION]` | Recognizes $e^{-\lambda}$ is transcendental; Poisson PMF/CDF emitted as approximate `DecimalValue`. | Locked |
| **Exact Rational Representation Resource Policy** | `[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]` | Deterministic engineering limit (1,024-bit numerator/denominator threshold) with predictive growth checks where feasible; fallback to `DecimalValue` with `PrecisionLossWarning`. | Pending Owner Approval |
| **Representation-Relative Underflow Policy** | `[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]` | Underflow behavior is relative to active evaluation representation; positive tail underflow clamped to representational zero with verified `NearZeroWarning` (`isExact: false`). | Pending Owner Approval |
| **Underflow vs Positive Probability Invariant** | `[NEW PHASE 10 DECISION]` | Underflowed positive probabilities must not be returned as exact `IntegerValue.zero`. | Locked |
| **PRNG Cross-Platform Contract (Option B)** | `[NEW PHASE 10 DECISION]` | Repeatability guaranteed per PRNG instance; cross-platform validation via statistical tests. | Locked |
| **Public `RandomSource` Interface Boundary** | `[SOURCE-DERIVED]` | `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §71 defines `nextDouble()` and `nextInt(int max)`. | Locked |
| **Open-Unit Variate Generation Mechanism** | `[IMPLEMENTATION CHOICE]` | Implementation selects transformation or rejection preserving distribution without endpoint bias. | Locked |
| **PRNG Resampling Retry Limit & Failure Policy** | `[IMPLEMENTATION CHOICE]` | Finite retry limit (e.g. 100) aborts with `ConvergenceFailureError` to prevent infinite loops. | Locked |
| **Discrete Quantile Predicate Invariant** | `[NEW PHASE 10 DECISION]` | Invariant adoption: $F(Q(p)) \ge p$ and $F(Q(p) - 1) < p$ with $F = 0$ outside support. | Locked |
| **Continuous Quantile Inversion Bracket Invariant** | `[NEW PHASE 10 DECISION]` | Mandates bracket $F(\text{lo}) \le p \le F(\text{hi})$ and bidirectional consistency. | Locked |
| **Special Functions Numerical Implementation** | `[IMPLEMENTATION CHOICE]` | Specific algorithms (Cody, Lentz, Halley, etc.) flexible provided acceptance criteria are met. | Locked |
| **Stable Tail / Interval Calculation Strategy** | `[IMPLEMENTATION CHOICE]` | Implementation selects CDF difference, survival difference, or log transform per distribution. | Locked |

---

## 3. Phase Objective


`[SOURCE-DERIVED]` Phase 10 delivers a production-grade, numerically robust probability and distribution calculation engine for NexaMath.

The core objectives are:
1. **Distribution Abstraction:** Implement an immutable, strongly typed distribution hierarchy supporting both continuous and discrete univariate distributions.
2. **Distribution Set:** Provide complete, mathematically verified implementations of six core distributions:
   - *Continuous:* Normal Distribution, Uniform Distribution, Exponential Distribution.
   - *Discrete:* Binomial Distribution, Poisson Distribution, Geometric Distribution.
3. **Core Density & Distribution Operations:** Implement Probability Density Functions (PDF) / Probability Mass Functions (PMF), Cumulative Distribution Functions (CDF), and Quantile / Inverse CDF functions ($Q(p) = F^{-1}(p)$).
4. **Structured Probability Queries:** Provide a declarative query engine evaluating Point, Interval, Lower-Tail, and Upper-Tail probabilities with rigorous boundary semantics.
5. **Deterministic Sampling:** Provide pseudo-random sampling capabilities backed by an injectable `RandomSource` abstraction producing canonical `Dataset` containers.
6. **Numerical Rigor:** Ensure bounded numerical stability across finite-precision evaluations, active numerical representations, extreme tails, asymptotic expansions, and combinatorial evaluations without catastrophic cancellation or unhandled overflow/underflow.
7. **Strict Typed Diagnostics:** Map all mathematical domain violations, parameter boundaries, and convergence failures strictly to established Phase 1 `MathError` and `MathWarning` contracts.

---

## 4. Explicit Scope & Non-Goals

### 4.1 Scope Matrix `[SOURCE-DERIVED]`
| Capability | Phase 10 Scope | Later Phase Scope | Out of Scope |
|---|:---:|:---:|:---:|
| Core Distributions (Normal, Uniform, Exponential) | **In Scope** | — | — |
| Core Distributions (Binomial, Poisson, Geometric) | **In Scope** | — | — |
| Additional Distributions (Student's t, Chi-squared, F, Beta, Gamma) | Out of Scope | Post-Phase 10 Extension | — |
| PDF / PMF Evaluation | **In Scope** | — | — |
| CDF Evaluation | **In Scope** | — | — |
| Inverse CDF / Quantile Evaluation | **In Scope** | — | — |
| Probability Queries (`Point`, `Interval`, `LowerTail`, `UpperTail`) | **In Scope** | — | — |
| Pseudo-Random Sampling (`Dataset`) | **In Scope** | — | — |
| Combinatorial Primitives (`Combinatorics`) integration | **In Scope** | — | — |
| Internal Special Functions (`erf`, `erfc`, `logGamma`, `regularizedGammaP`, `regularizedBeta`) | **In Scope (Internal Helpers)** | — | — |
| Physical Units on Probability Quantities | Out of Scope | Phase 11 (Units) | — |
| Built-in Probability Formulas in Catalog | Out of Scope | Phase 12 (Formulas) | — |
| Probability Density & CDF Plotting / Visualization | Out of Scope | Phase 13 (Graphing) & Phase 18 (UI) | — |
| Probability Functions in Spreadsheet Cells | Out of Scope | Phase 16 (Spreadsheet) | — |
| High-level Application Use Cases & ViewModels | Out of Scope | Phase 15 (Application) | — |
| External Native / C-FFI / Third-Party Math Libraries | Out of Scope | — | **Strictly Prohibited** |

### 4.2 Non-Goals
1. **No Advanced / Extended Distributions:** Student's t, Snedecor's F, Pearson's Chi-squared, Weibull, Beta, Gamma, Log-Normal, Hypergeometric, and Negative Binomial distributions belong to later phases or post-Phase 10 extensions.
2. **No Physical Units:** Quantities with dimensional units (e.g., seconds, meters) are not accepted or emitted; all parameters and results are unitless scalars. Dimensional tracking belongs strictly to **Phase 11 (Units & Dimensional Analysis)**.
3. **No UI / Charting / Visualization:** Density curves, shaded areas under curves, histogram overlays, and interactive sliders belong to **Phase 13 (Graphing Engine)** and **Phase 18 (Flutter Presentation)**.
4. **No Spreadsheet Grid Evaluation:** Matrix/table evaluation of probabilities belongs to **Phase 16 (Spreadsheet Engine)**.
5. **No Third-Party Dependencies:** No external math packages (e.g., SciDart, petitparser extensions, or C-FFI binaries). Everything runs on pure Dart within NexaMath.

---

## 5. Architectural Position & Invariants

```text
Presentation Layer (Phase 18)
    ↓
Application Layer (Phase 15 - Use Cases, Orchestration)
    ↓
Mathematical Core (Autonomous Pure Dart)
    ├── Expression Engine (AST, Parsing, Evaluation)
    ├── Numeric Engine (IntegerValue, FractionValue, DecimalValue)
    ├── Statistics Subsystem (Dataset, Descriptive, Regression)
    └── Probability Subsystem [PHASE 10]
          ├── ProbabilityEngine (Façade interface)
          ├── ProbabilityDistribution (Hierarchy & Concrete Distributions)
          ├── ProbabilityQuery & ProbabilityResult
          ├── Sampling (RandomSource)
          └── Numerical / Special Functions (erf, gamma, beta helpers)
    ↓
Core Infrastructure (Phase 1 - MathResult, MathError, MathWarning)
```

### Architectural Invariants:
- The probability subsystem **never imports Flutter** (`flutter/material.dart`, etc.).
- The subsystem depends only on `lib/core/` and sibling core modules (`lib/mathematical_core/numeric/`, `lib/mathematical_core/statistics/models/dataset.dart`).
- Sibling engines (Calculus, Equation Solver, Expression) do not depend on Probability.

---

## 6. Package and Module Decomposition

The package layout maps structural requirements to directory organization:

```text
lib/mathematical_core/probability/
├── probability.dart                                 # Subsystem barrel export [IMPLEMENTATION CHOICE]
├── probability_engine.dart                          # Public ProbabilityEngine contract [SOURCE-DERIVED]
├── default_probability_engine.dart                  # Production implementation of engine [IMPLEMENTATION CHOICE]
├── distribution.dart                                # Abstract ProbabilityDistribution base contract [SOURCE-DERIVED]
├── models/                                          # Internal & public data models
│   ├── probability_query.dart                       # Query sealed class hierarchy [SOURCE-DERIVED]
│   ├── probability_result.dart                      # Result container with metadata [SOURCE-DERIVED]
│   └── distribution_type.dart                       # Enumeration of supported distributions [NEW PHASE 10 DECISION]
├── distributions/
│   ├── continuous/
│   │   ├── continuous_distribution.dart             # Continuous base contract [NEW PHASE 10 DECISION]
│   │   ├── normal_distribution.dart                 # Normal(mu, sigma) [SOURCE-DERIVED]
│   │   ├── uniform_distribution.dart                # Uniform(a, b) [SOURCE-DERIVED]
│   │   └── exponential_distribution.dart            # Exponential(lambda) [SOURCE-DERIVED]
│   └── discrete/
│   │   ├── discrete_distribution.dart               # Discrete base contract [NEW PHASE 10 DECISION]
│   │   ├── binomial_distribution.dart               # Binomial(n, p) [SOURCE-DERIVED]
│   │   ├── poisson_distribution.dart                # Poisson(lambda) [SOURCE-DERIVED]
│   │   └── geometric_distribution.dart              # Geometric(p) [SOURCE-DERIVED]
├── sampling/
│   ├── random_source.dart                           # Abstract pseudo-random source contract [SOURCE-DERIVED]
│   └── standard_random_source.dart                  # Injectable PRNG wrapper implementation [IMPLEMENTATION CHOICE]
└── special_functions/                               # Internal numerical evaluation helpers [IMPLEMENTATION CHOICE]
    ├── error_function.dart                          # erf, erfc, inverse erf
    ├── gamma_functions.dart                         # logGamma, regularized incomplete gamma P, Q
    └── beta_functions.dart                          # logBeta, regularized incomplete beta I_x(a,b)
```

*Traceability Note:* The parent package `lib/mathematical_core/probability/`, the engine contract `ProbabilityEngine`, the query models, and the 6 concrete distribution names are `[SOURCE-DERIVED]` from `NEXAMATH_IMPLEMENTATION_BLUEPRINT.md` §4 and `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §38. Specific internal file decomposition, helper classes, and private methods are `[IMPLEMENTATION CHOICE]`.

---

## 7. ProbabilityDistribution Contract

### 7.1 Distribution Base Abstraction `[NEW PHASE 10 DECISION]`
```dart
/// Abstract contract for all univariate probability distributions.
abstract interface class ProbabilityDistribution {
  /// Unique machine-readable name of the distribution.
  String get name;

  /// Classification of the distribution (continuous vs discrete).
  DistributionType get type;

  /// Whether this distribution is discrete (integer/count support).
  bool get isDiscrete;

  /// Whether this distribution is continuous (real interval support).
  bool get isContinuous;

  /// Theoretical expected value E[X].
  /// Returns MathFailure(DomainError) if mean is undefined or infinite.
  MathResult<ScalarValue> get mean;

  /// Theoretical variance Var(X).
  /// Returns MathFailure(DomainError) if variance is undefined or infinite.
  MathResult<ScalarValue> get variance;

  /// Theoretical standard deviation sqrt(Var(X)).
  MathResult<ScalarValue> get standardDeviation;

  /// Evaluates the probability density function (for continuous) or
  /// probability mass function (for discrete) at point [x].
  MathResult<ScalarValue> pdf(ScalarValue x);

  /// Evaluates the cumulative distribution function F(x) = P(X <= x).
  MathResult<ScalarValue> cdf(ScalarValue x);

  /// Evaluates the quantile function Q(p) for p in [0, 1].
  MathResult<ScalarValue> inverseCdf(ScalarValue probability);

  /// Generates a single pseudo-random variate using [source].
  MathResult<ScalarValue> sampleOne(RandomSource source);
}
```

### 7.2 Discrete vs Continuous Specialization
1. `ContinuousDistribution extends ProbabilityDistribution`:
   - `isContinuous => true`, `isDiscrete => false`.
   - `pdf(x)` represents true probability density $f(x) \ge 0$ (density may exceed $1.0$).
2. `DiscreteDistribution extends ProbabilityDistribution`:
   - `isContinuous => false`, `isDiscrete => true`.
   - `pdf(x)` evaluates the Probability Mass Function (PMF) $P(X = x) \in [0, 1]$.
   - Explicit typed helper `pmf(IntegerValue k)` evaluates integer mass.

---

## 8. ProbabilityEngine Contract

### 8.1 Authoritative Public Interface `[SOURCE-DERIVED]`
Preserved verbatim from `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §38:

```dart
abstract interface class ProbabilityEngine {
  /// Evaluates a structured probability query against a distribution.
  MathResult<ProbabilityResult> probability(
    ProbabilityDistribution distribution,
    ProbabilityQuery query,
  );

  /// Evaluates PDF (continuous) or PMF (discrete) at [x].
  MathResult<ScalarValue> pdf(
    ProbabilityDistribution distribution,
    ScalarValue x,
  );

  /// Evaluates Cumulative Distribution Function F(x) = P(X <= x).
  MathResult<ScalarValue> cdf(
    ProbabilityDistribution distribution,
    ScalarValue x,
  );

  /// Evaluates Quantile / Inverse CDF Q(p) for p in [0, 1].
  MathResult<ScalarValue> inverseCdf(
    ProbabilityDistribution distribution,
    ScalarValue probability,
  );

  /// Generates a dataset of [count] pseudo-random observations.
  MathResult<Dataset> sample(
    ProbabilityDistribution distribution,
    int count,
    RandomSource randomSource,
  );
}
```

---

## 9. Complex Input Rejection Policy

`[NEW PHASE 10 DECISION]` Consistent with real probability domain definitions:
1. Probability distributions in Phase 10 are defined strictly over the real numbers $\mathbb{R}$ (or non-negative integers $\mathbb{Z}_{\ge 0}$).
2. Any `ScalarValue` argument that is an instance of `ComplexNumber` with a non-zero imaginary component (`!complex.imaginary.isZero` or `!complex.isReal`) **MUST be immediately rejected**.
3. **Contract Failure:** Returns typed `MathFailure` with:
   ```dart
   DomainError(
     functionName: 'ProbabilityDistribution',
     argument: 'x',
     message: 'Complex numbers are not supported in real probability distributions.',
   )
   ```
4. If a `ComplexNumber` has an identically zero imaginary component (`complex.isReal`), it is canonically unboxed to its real `DecimalValue` component before evaluation.

---

## 10. Discrete Boundary Semantics & Query Invariants

### 10.1 Query Hierarchy `[SOURCE-DERIVED]`
```dart
sealed class ProbabilityQuery {
  const ProbabilityQuery();
}

final class PointProbabilityQuery extends ProbabilityQuery {
  final ScalarValue point;
  const PointProbabilityQuery(this.point);
}

final class IntervalProbabilityQuery extends ProbabilityQuery {
  final ScalarValue lower;
  final ScalarValue upper;
  final bool includeLower;
  final bool includeUpper;

  const IntervalProbabilityQuery({
    required this.lower,
    required this.upper,
    this.includeLower = true,
    this.includeUpper = true,
  });
}

final class LowerTailQuery extends ProbabilityQuery {
  final ScalarValue value;
  final bool inclusive;

  const LowerTailQuery(this.value, {this.inclusive = true});
}

final class UpperTailQuery extends ProbabilityQuery {
  final ScalarValue value;
  final bool inclusive;

  const UpperTailQuery(this.value, {this.inclusive = true});
}
```

### 10.2 Parameter Domains & Boundaries for Discrete Distributions `[NEW PHASE 10 DECISION]`
Parameter boundaries are strictly enforced during distribution construction:
1. **Binomial Distribution ($\text{Bin}(n, p)$):**
   - $n \in \mathbb{Z}_{\ge 0}$ (number of trials). If $n < 0$ or non-integer $\implies$ fails with `InvalidDistributionParameterError(parameterName: 'n', reason: 'Number of trials must be a non-negative integer.')`.
   - $p \in [0, 1]$ (success probability). If $p < 0$ or $p > 1 \implies$ fails with `InvalidDistributionParameterError(parameterName: 'p', reason: 'Probability must be in [0, 1].')`.
   - Boundary values $p = 0.0$ and $p = 1.0$ are mathematically valid degenerate distributions.
2. **Geometric Distribution ($\text{Geom}(p)$):**
   - Defined under Convention 1: $X \in \{1, 2, 3, \dots\}$ (number of Bernoulli trials until the first success).
   - $p \in (0, 1]$ (success probability).
   - **Boundary Exclusion:** $p = 0$ is **strictly invalid** for Geometric under this convention (expected value $E[X] = 1/p$ diverges to $\infty$; the first success never occurs).
   - If $p \le 0$ or $p > 1 \implies$ fails with `InvalidDistributionParameterError(parameterName: 'p', reason: 'Geometric success probability must satisfy 0 < p <= 1.')`.
   - Boundary value $p = 1.0$ is a mathematically valid degenerate distribution ($P(X = 1) = 1.0$).
3. **Poisson Distribution ($\text{Pois}(\lambda)$):**
   - $\lambda > 0$ (rate parameter). If $\lambda \le 0 \implies$ fails with `InvalidDistributionParameterError(parameterName: 'lambda', reason: 'Rate parameter must be positive.')`.

### 10.3 Mathematical Event Semantics for Discrete Query Evaluation `[NEW PHASE 10 DECISION]`
For all discrete distributions, events are defined over the discrete integer support. Non-integer queries behave as follows:

1. **Point Query ($P(X = x)$):**
   - Represents the mathematical event $\{X = x\}$.
   - If $x$ is an exact integer $k \in \text{Support}$: evaluates and returns $\text{PMF}(k)$.
   - If $x$ is non-integer (e.g. $x = 2.5$) or outside support: the event $\{X = 2.5\} = \emptyset$; **MUST return exact `IntegerValue.zero`** with `CalculationMetadata.exact`.
2. **Lower Tail Query:**
   - **Inclusive ($P(X \le x)$):** Represents event $\{k \in \text{Support} : k \le x\}$.
     - Let $k_{\text{floor}} = \lfloor x \rfloor$. Returns $F(k_{\text{floor}})$.
     - Example: $P(X \le 2.5) = P(X \le 2) = F(2)$.
     - If $x < \min(\text{Support})$: returns exact `IntegerValue.zero` with `CalculationMetadata.exact`.
     - If $x \ge \max(\text{Support})$: returns exact `IntegerValue.one` (or $1.0$).
   - **Strict / Exclusive ($P(X < x)$):** Represents event $\{k \in \text{Support} : k < x\}$.
     - If $x \in \mathbb{Z}$: returns $F(x - 1)$. (e.g. $P(X < 3) = F(2)$).
     - If $x \notin \mathbb{Z}$: returns $F(\lfloor x \rfloor)$. (e.g. $P(X < 2.5) = P(X \le 2) = F(2)$).
3. **Upper Tail Query:**
   - **Inclusive ($P(X \ge x)$):** Represents event $\{k \in \text{Support} : k \ge x\}$.
     - If $x \in \mathbb{Z}$: returns $S(x - 1) = 1 - F(x - 1)$. (e.g. $P(X \ge 3) = 1 - F(2)$).
     - If $x \notin \mathbb{Z}$: returns $S(\lfloor x \rfloor) = 1 - F(\lfloor x \rfloor)$. (e.g. $P(X \ge 2.5) = P(X \ge 3) = 1 - F(2)$).
   - **Strict / Exclusive ($P(X > x)$):** Represents event $\{k \in \text{Support} : k > x\}$.
     - Returns $S(\lfloor x \rfloor) = 1 - F(\lfloor x \rfloor)$. (e.g. $P(X > 2) = 1 - F(2)$; $P(X > 2.5) = 1 - F(2)$).
4. **Interval Query ($P(a \le X \le b)$):**
   - If $a > b$: fails with `InvalidArgumentError(argumentName: 'upper', reason: 'Upper bound must be >= lower bound.')`.
   - Effective integer index bounds:
     - $k_{\text{min}} = \text{includeLower} ? \lceil a \rceil : ((a \in \mathbb{Z}) ? a + 1 : \lceil a \rceil)$
     - $k_{\text{max}} = \text{includeUpper} ? \lfloor b \rfloor : ((b \in \mathbb{Z}) ? b - 1 : \lfloor b \rfloor)$
   - If $k_{\text{min}} > k_{\text{max}}$: the integer event is empty; **MUST return exact `IntegerValue.zero`** with `CalculationMetadata.exact`.
   - Otherwise: returns $F(k_{\text{max}}) - F(k_{\text{min}} - 1)$ or direct PMF sum.

---

## 11. Quantile Contracts: Mathematical Generalized Inverse vs API Endpoints

### 11.1 Mathematical Generalized Inverse for $p \in (0, 1)$ `[NEW PHASE 10 DECISION]`
For interior probabilities $p \in (0, 1)$, the mathematical quantile is defined as the left-continuous generalized inverse:
$$Q(p) = \inf \{x \in \mathbb{R} : F(x) \ge p\}$$

- **Continuous Distributions:** $Q(p)$ is the unique root $x$ satisfying $F(x) = p$.
- **Discrete Distributions:** $Q(p)$ is the smallest integer $k \in \text{Support}$ such that $F(k) \ge p$.

### 11.2 NexaMath API Endpoint Convention for $p \in \{0, 1\}$ `[NEW PHASE 10 DECISION]`
The generalized inverse definition does not automatically specify finite representable scalar returns at the boundaries $p = 0.0$ and $p = 1.0$. NexaMath establishes an **explicit API convention**:
1. If the mathematical domain is bounded at the endpoint, return the finite scalar boundary value.
2. If the mathematical domain is unbounded (diverges to $\pm\infty$), **MUST return typed failure `DomainError`** because `ScalarValue` represents finite numbers and does not contain an infinity representation.

### 11.3 Degenerate Distribution Quantile Semantics `[NEW PHASE 10 DECISION]`
1. **Binomial $n = 0$ (Support $k \in \{0\}$, $P(X = 0) = 1.0$):**
   - $F(0) = 1.0 \ge p$ for all $p \in [0, 1]$.
   - **Contract:** $Q(p) = \text{IntegerValue.zero}$ for all $p \in [0, 1]$.
2. **Binomial $p = 0$ ($n \ge 1$, Support $k \in \{0, \dots, n\}$, $P(X = 0) = 1.0$):**
   - $F(0) = 1.0 \ge p$ for all $p \in [0, 1]$.
   - **Contract:** $Q(p) = \text{IntegerValue.zero}$ for all $p \in [0, 1]$.
3. **Binomial $p = 1$ ($n \ge 1$, Support $k \in \{0, \dots, n\}$, $P(X = n) = 1.0$):**
   - $F(k) = 0$ for $k < n$, and $F(n) = 1.0$.
   - **Contract:** For $p = 0.0 \implies \text{IntegerValue.zero}$; for $p \in (0, 1] \implies \text{IntegerValue(n)}$.
4. **Geometric $p = 1$ (Support $k \in \{1, 2, \dots\}$, $P(X = 1) = 1.0$):**
   - $F(1) = 1.0 \ge p$ for all $p \in [0, 1]$.
   - **Contract:** $Q(p) = \text{IntegerValue.one}$ for all $p \in [0, 1]$.

### 11.4 Definitive Quantile Policy Table
| Distribution | $p = 0.0$ API Contract | $p = 1.0$ API Contract | $p \in (0, 1)$ Mathematical Contract |
|---|---|---|---|
| **Normal** | `MathFailure(DomainError(message: 'Quantile diverges to -Infinity at p=0.'))` | `MathFailure(DomainError(message: 'Quantile diverges to +Infinity at p=1.'))` | Unique finite $x \in \mathbb{R}$ |
| **Uniform** | Finite Scalar: $a$ | Finite Scalar: $b$ | Finite scalar: $a + p(b - a)$ |
| **Exponential** | Finite Scalar: $0.0$ | `MathFailure(DomainError(message: 'Quantile diverges to +Infinity at p=1.'))` | Finite scalar: $-\frac{\ln(1 - p)}{\lambda}$ |
| **Binomial ($p \in (0, 1)$)** | Finite Scalar: $0$ | Finite Scalar: $n$ | Smallest integer $k \in \{0, \dots, n\}$ such that $F(k) \ge p$ |
| **Binomial ($n=0$ or $p=0$)** | Finite Scalar: $0$ | Finite Scalar: $0$ | Finite Scalar: $0$ |
| **Binomial ($p=1$)** | Finite Scalar: $0$ | Finite Scalar: $n$ | Finite Scalar: $n$ |
| **Poisson** | Finite Scalar: $0$ | `MathFailure(DomainError(message: 'Poisson quantile diverges to +Infinity at p=1.'))` | Smallest integer $k \ge 0$ such that $F(k) \ge p$ |
| **Geometric ($p \in (0, 1)$)** | Finite Scalar: $1$ | `MathFailure(DomainError(message: 'Geometric quantile diverges to +Infinity at p=1.'))` | Smallest integer $k \ge 1$ such that $F(k) \ge p$ |
| **Geometric ($p=1$)** | Finite Scalar: $1$ | Finite Scalar: $1$ | Finite Scalar: $1$ |

---

## 12. Special Function Identities & Mathematical Conventions

### 12.1 Regularized Incomplete Function Conventions `[NEW PHASE 10 DECISION]`
1. **Regularized Incomplete Beta Function $I_x(a, b)$:**
   $$I_x(a, b) = \frac{\text{B}(x; a, b)}{\text{B}(a, b)} = \frac{1}{\text{B}(a, b)} \int_0^x t^{a - 1} (1 - t)^{b - 1} dt$$
   - Invariants: $I_0(a, b) = 0$, $I_1(a, b) = 1$, $I_x(a, b) = 1 - I_{1 - x}(b, a)$.
2. **Regularized Lower Incomplete Gamma Function $P(a, x)$:**
   $$P(a, x) = \frac{\gamma(a, x)}{\Gamma(a)} = \frac{1}{\Gamma(a)} \int_0^x t^{a - 1} e^{-t} dt$$
3. **Regularized Upper Incomplete Gamma Function $Q(a, x)$:**
   $$Q(a, x) = \frac{\Gamma(a, x)}{\Gamma(a)} = \frac{1}{\Gamma(a)} \int_x^\infty t^{a - 1} e^{-t} dt = 1 - P(a, x)$$

### 12.2 Binomial CDF / Beta Identity & Boundary Isolation `[NEW PHASE 10 DECISION]`
For $X \sim \text{Bin}(n, p)$, the mathematical identity relates the CDF to the regularized incomplete beta function:
$$F(k) = P(X \le k) = I_{1 - p}(n - k, k + 1)$$
**Mandatory Boundary Isolation:** The incomplete beta identity is valid for $0 \le k < n$ and $0 < p < 1$. Boundary cases MUST be isolated directly to prevent division-by-zero or non-positive beta arguments:
- If $k < 0$: $F(k) = 0.0$ (direct).
- If $k \ge n$: $F(k) = 1.0$ (direct).
- If $p = 0$: $F(k) = 1.0$ for $k \ge 0$ (direct).
- If $p = 1$: $F(k) = 0.0$ for $k < n$, $F(n) = 1.0$ (direct).
- If $n = 0$: $F(k) = 1.0$ for $k \ge 0$ (direct).

### 12.3 Poisson CDF / Gamma Identity & Boundary Isolation `[NEW PHASE 10 DECISION]`
For $X \sim \text{Pois}(\lambda)$, the mathematical identity relates the CDF to the regularized upper incomplete gamma function:
$$F(k) = P(X \le k) = Q(k + 1, \lambda) = 1 - P(k + 1, \lambda)$$
**Mandatory Boundary Isolation:**
- If $k < 0$: $F(k) = 0.0$ (direct).
- If $k = 0$: $F(0)$ MUST equal $e^{-\lambda}$ mathematically and MUST be evaluated using a numerically valid method `[IMPLEMENTATION CHOICE]`.
- For $k \ge 1$: evaluated via $Q(k + 1, \lambda)$ or a numerically stable recurrence relation `[IMPLEMENTATION CHOICE]`.

---

## 13. Exactness Contract & Underflow Representation

### 13.1 Exactness Layers in NexaMath `[NEW PHASE 10 DECISION]`
1. **Mathematical Exactness:** Whether the result mathematically belongs to the rational numbers $\mathbb{Q}$.
2. **Representational Exactness:** Whether NexaMath's `IntegerValue` or `FractionValue` (backed by `BigInt`) can represent the number.
3. **Evaluation Mode:** Whether the algorithm maintains exact rational arithmetic or switches to high-precision floating-point/decimal approximation.
4. **Resource Policy:** Formal project boundary governing maximum bit/digit growth in exact rational representations.

### 13.2 Distribution-Specific Exactness & Resource Policy `[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]`
1. **Scope of Exact Rational Evaluation:**
   - Binomial, Geometric, and Uniform probabilities with exact rational inputs are evaluated in exact rational arithmetic via `FractionValue`, provided resource limits are satisfied.
2. **Resource Boundary (1,024-Bit Threshold as Deterministic Engineering Policy `[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]`):**
   - The 1,024-bit (~308 decimal digits) threshold on numerator/denominator bit length is established as a **deterministic engineering and memory resource guard**, not as a universal mathematical law.
   - **Predictive Guarding vs Post-Operation Detection:** Implementations should avoid intentionally constructing unbounded, pathological intermediate fractions when exponential representation growth can be determined or bounded in advance (e.g. evaluating large combinatorial terms or large powers with coprime components). If advance bounding indicates representation size will exceed the threshold, or if an intermediate/final numerator or denominator exceeds 1,024 bits in length:
     - The calculation safely switches from exact rational evaluation to an approximate numerical evaluation path.
     - The result is emitted using `DecimalValue` (which represents arbitrary-precision decimal values with explicit scale and an `isExact` flag) with `isExact: false`.
     - The result metadata MUST be marked with `CalculationMetadata(isExact: false, warnings: [PrecisionLossWarning()])` to signify that exact rational representation was curtailed due to resource boundaries.
     - The implementation MUST NOT claim exactness (`isExact: true`) once approximation is introduced.
3. **Geometric Distribution:**
   - If $p \in \mathbb{Q}$, then for integer $k \ge 1$, $P(X = k) = (1-p)^{k-1}p \in \mathbb{Q}$ and $F(k) = 1 - (1-p)^k \in \mathbb{Q}$.
   - Emitted as exact `FractionValue` with `CalculationMetadata.exact` when within the resource limit; otherwise falls back to approximate `DecimalValue` with `CalculationMetadata(isExact: false, warnings: [PrecisionLossWarning()])`.
   - Structural boundary $p = 1$: $P(X = 1) = 1$, $P(X > 1) = 0$ are emitted as exact `IntegerValue`.
4. **Poisson Distribution:**
   - For general rational $\lambda > 0$, $e^{-\lambda}$ is transcendental; general interior PMF/CDF values are evaluated numerically and emitted as approximate `DecimalValue` with `CalculationMetadata(isExact: false)`.
   - Structurally exact boundary cases (e.g. $k < 0 \implies P(X = k) = 0$ and $F(k) = 0$) are mathematically exact zero and emitted as exact `IntegerValue.zero` with `CalculationMetadata.exact`.
5. **Uniform Distribution:**
   - For exact rational bounds $a, b \in \mathbb{Q}$, interval probabilities and quantiles within support are mathematically rational. They are emitted as exact `FractionValue` within the 1,024-bit threshold.
   - If inputs are non-exact decimals or if bounds/queries require floating-point evaluation, results are emitted as approximate `DecimalValue`.
   - Outside support ($x < a$ or $x > b$), CDF/PDF cases produce exact structural zeros or ones ($0$ or $1$) emitted as exact `IntegerValue`.
6. **Normal & Exponential Distributions:**
   - General interior evaluations involve transcendental functions ($\pi, e, \text{erf}$) and are emitted as approximate `DecimalValue` with `CalculationMetadata(isExact: false)`.
   - Structural exact results (e.g. Exponential $x < 0 \implies F(x) = 0$ or $f(x) = 0$) are mathematically determined to be zero and emitted as exact `IntegerValue.zero` with `CalculationMetadata.exact`.

### 13.3 Underflow & Very-Small Probabilities Representation Policy `[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]`
1. **Mathematical Zero vs Underflow Zero:**
   - A mathematically determined zero occurs whenever the definition of the distribution or function structurally produces zero. This includes:
     - Events outside distribution support (e.g. $k < 0$ or $k > n$ for Binomial, $k < 1$ for Geometric, $x < 0$ for Exponential, $x < a$ for Uniform).
     - Empty query events (e.g. discrete interval $(2, 3)$ with non-inclusive bounds).
     - Structural boundary behavior.
   - All such mathematically determined zero results MUST be emitted as exact `IntegerValue.zero` with `CalculationMetadata.exact`.
2. **Representation-Relative Underflow Policy (Observable Clamping with Warning `[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]`):**
   - Underflow behavior is defined strictly relative to the finite-precision numerical representation or intermediate evaluation path actually used by the implementation:
     - For a binary64 floating-point evaluation path (e.g. standard IEEE-754 `double`), the implementation may use the binary64 representational limits as the applicable underflow boundary for that path. The value $2^{-1074} \approx 4.9 \times 10^{-324}$ (the smallest representable positive subnormal float) is therefore an IEEE-754 binary64-specific example, not a universal NexaMath underflow threshold.
     - For arbitrary-precision decimal representations (`DecimalValue`), values are parameterized by an unscaled `BigInt` and integer `scale`; the repository does not impose a fixed minimum positive limit, but finite evaluation paths or precision contexts can produce effective underflow when intermediate scale limits or conversions collapse positive probabilities to zero.
     - **Observable Rule:** Whenever a probability query mathematically satisfies $P > 0$ on the distribution's support, but the numerical evaluation path collapses the value to zero because the finite-precision representation or intermediate algorithm cannot preserve its positive magnitude:
       - The query MUST NOT fail with a fatal `UnderflowError`.
       - The query MUST NOT return exact `IntegerValue.zero` (which would falsely imply an impossible event or support exclusion).
       - The query MUST return representational zero (`DecimalValue.zero` [verified repository static constant] or numerical `0.0`) wrapped in `MathSuccess`.
       - The result metadata MUST be marked with `CalculationMetadata(isExact: false, warnings: [NearZeroWarning()])`.
     - *Verified Repository API:* In `lib/core/result/math_warning.dart`, `NearZeroWarning` is declared with a default parameterless constructor emitting default code `'NEAR_ZERO_WARNING'` and message `'Operand is near zero, which may cause instability or loss of significance.'`. The contract requires instantiating the verified class `const NearZeroWarning()` without assuming custom message overrides.
3. **Fatal UnderflowError Invariant:**
   - In accordance with `lib/core/errors/math_error.dart`, `UnderflowError` represents a fatal calculation failure where numerical underflow prevents completing a required calculation or where continuing would violate an internal mathematical or algorithmic invariant (e.g. when an underflowed intermediate divisor causes an unrecoverable division-by-zero or loss of model definition).
   - Fatal `UnderflowError` MUST NOT be thrown on benign tail probability queries where clamping to representational zero with `NearZeroWarning` accurately preserves observable continuity.

---

## 14. RandomSource & Sampling Contract

### 14.1 Determinism vs Cross-Platform Repeatability `[NEW PHASE 10 DECISION]`
1. **Deterministic Repeatability per Instance:** Deterministic reproducibility with a fixed seed is a testing and internal capability of a concrete deterministic random source implementation. Calling sampling methods on a concrete deterministic PRNG instance with a fixed seed yields an identical sequence on that specific runtime platform. It is not an exposed public method of the abstract `ProbabilityEngine` or `RandomSource` interface.
2. **Cross-Platform Parity Limitation:** Bit-for-bit identical PRNG sequences across Windows and Android are **not** guaranteed when wrapping system PRNGs (`dart:math Random`). Cross-platform correctness is validated through **statistical acceptance criteria** and distribution support compliance.
3. **Public API Status:** The repository's authoritative engine contracts do NOT define a public seeding method or seed constructor on `RandomSource`. Deterministic seeding is an internal implementation concern unless a public seed contract is approved.

### 14.2 RandomSource API Boundary `[SOURCE-DERIVED]`
Per `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` §71, the public `RandomSource` contract defines strictly:
```dart
abstract interface class RandomSource {
  double nextDouble();
  int nextInt(int max);
}
```
*Repository Fact:* `nextOpenDouble()` and seed constructors do NOT exist in the authoritative engine contracts or repository source code. They MUST NOT be exposed as public API methods in Phase 10 without project-level approval.

### 14.3 Open Unit Interval Contract ($0 < U < 1$)
Inverse-transform sampling algorithms evaluate logarithmic expressions like $\ln(U)$. If $U = 0.0$, $\ln(0)$ diverges to $-\infty$.
1. **Observable Contract `[SOURCE-DERIVED]`:** The random value supplied to inverse-transform operations requiring an open interval MUST satisfy:
   $$0 < U < 1$$
2. **Implementation Choice `[IMPLEMENTATION CHOICE]`:** The implementation may use a suitable transformation, rejection/resampling strategy, or bit-level mantissa generation. The chosen mechanism **MUST preserve the intended sampling distribution and MUST NOT introduce systematic endpoint bias** that violates the sampling acceptance criteria.
3. **Retry Guard `[IMPLEMENTATION CHOICE]`:** To prevent unbounded retry loops when interacting with custom or degenerate random sources:
   - The sampling implementation must fail deterministically after a finite limit (e.g. an implementation-selected threshold such as 100 consecutive invalid draws).
   - Upon exceeding this limit, it must return a typed `MathFailure(ConvergenceFailureError(method: 'RandomSource.sample', iterations: maxRetries))` reporting the actual retry limit reached.
   - The specific retry limit is an engineering policy classified as `[IMPLEMENTATION CHOICE]`, not a mathematical constant or public API requirement.

### 14.4 Degenerate Sampling Cases `[NEW PHASE 10 DECISION]`
1. **Geometric Distribution with $p = 1$:** MUST bypass $\ln(1 - p) = \ln(0)$ and deterministically return exact `IntegerValue.one`.
2. **Binomial Distribution with $p = 0$ or $n = 0$:** Deterministically return `IntegerValue.zero`.
3. **Binomial Distribution with $p = 1$:** Deterministically return `IntegerValue(n)`.

---

## 15. Numerical Stability & Strategy

### 15.1 Numerical Strategies as Implementation Choices `[IMPLEMENTATION CHOICE]`
The specification mandates that implementations MUST avoid catastrophic cancellation. Specific algorithmic paths are implementation choices:
1. **Normal Distribution:** Upper tail queries evaluate survival function $S(x) = \frac{1}{2}\text{erfc}\left(\frac{x - \mu}{\sigma \sqrt{2}}\right)$ directly. Extreme tails use continued fractions or asymptotic expansions for $\text{erfc}(z)$.
2. **Exponential Distribution:** CDF evaluates via $\text{expm1}(-\lambda x)$ to prevent subtractive cancellation when $\lambda x \ll 1$. Upper tail evaluates $S(x) = e^{-\lambda x}$ directly. Quantile near $p=1$ evaluates $-\frac{\text{log1p}(-p)}{\lambda}$.
3. **Interval Probabilities:** Implementations choose stable formulations (e.g. $S(a) - S(b)$ in upper tail, $F(b) - F(a)$ in lower tail).

---

## 16. Error & Warning Contracts

### 16.1 Error Contract `[SOURCE-DERIVED]`
All errors must strictly instantiate existing Phase 1 error classes from `lib/core/errors/math_error.dart`:

| Failure Scenario | Typed MathError Class | Invariant Constructor Arguments |
|---|---|---|
| Complex input with imaginary component | `DomainError` | `functionName: 'ProbabilityDistribution', argument: 'x', message: '...'` |
| Invalid distribution parameter ($\sigma \le 0, \lambda \le 0, a \ge b, n < 0$) | `InvalidDistributionParameterError` | `parameterName: '...', reason: '...'` |
| Geometric parameter $p \le 0$ or $p > 1$ | `InvalidDistributionParameterError` | `parameterName: 'p', reason: 'Geometric success probability must satisfy 0 < p <= 1.'` |
| Parameter probability $p \notin [0, 1]$ (Binomial) | `InvalidDistributionParameterError` | `parameterName: 'p', reason: 'Probability must be in [0, 1].'` |
| Inverse CDF probability $p \notin [0, 1]$ | `InvalidProbabilityError` | `value: p` |
| Negative sample count ($N < 0$) | `InvalidArgumentError` | `argumentName: 'count', reason: 'Sample count must be non-negative.'` |
| Inverted query interval ($a > b$) | `InvalidArgumentError` | `argumentName: 'upper', reason: 'Upper bound must be >= lower bound.'` |
| Infinite quantile endpoint ($p=0$ or $p=1$ unbounded) | `DomainError` | `functionName: 'inverseCdf', message: 'Quantile diverges to Infinity.'` |
| Pathological PRNG or iteration limit exceeded | `ConvergenceFailureError` | `iterations: actualRetries, method: '...'` |
| Calculation overflows finite representable bound | `OverflowError` | `message: '...'` |
| Numerical underflow prevents completing required calculation or breaks invariant | `UnderflowError` | `message: '...'` |

### 16.2 Warning Contract `[NEW PHASE 10 DECISION]`
Mapped strictly to existing classes in `lib/core/result/math_warning.dart`:
1. **`NearZeroWarning`:**
   - **Allowed:** Emitted when floating-point underflow causes an intermediate calculation to lose significant digits, when a positive probability rounds to non-exact zero underflow, or when negative floating-point jitter ($-\epsilon_{\text{clamp}} \le p < 0$) is clamped to $0.0$.
   - **Prohibited:** Must **NOT** be emitted merely because a mathematically valid event has a tiny probability that is accurately computed.
2. **`PrecisionLossWarning`:**
   - Emitted when floating-point jitter clamps $1.0 < p \le 1.0 + \epsilon_{\text{clamp}}$ to $1.0$, or when an exact rational calculation transitions to approximate `DecimalValue` because of the deterministic 1,024-bit resource policy.
   - *Role Clarification:* Its emission during resource-policy fallback indicates that the result has transitioned from an exact rational representation path to an approximate decimal representation path to prevent unbounded integer growth, not that the underlying approximate numerical algorithm suffered numerical instability or divergence.
3. **`NumericalApproximationWarning`:**
   - Emitted when an analytical formula is replaced by an asymptotic expansion.
   - **Prohibited:** Must **NOT** be emitted for standard iterative root-finding that converges cleanly within required tolerance.

---

## 17. Numerical Acceptance Criteria

The acceptance contract specifies observable mathematical and numerical invariants rather than mandating specific numerical algorithms:

### 17.1 Universal Invariants
1. **Range Bounds:** For any query, PDF (discrete PMF), CDF, survival function, and interval probability:
   - PMF and CDF values MUST satisfy $0.0 \le P \le 1.0$.
   - Continuous PDF MUST satisfy $f(x) \ge 0.0$ on the entire support.
   - Interval probabilities MUST satisfy $0.0 \le P(a \le X \le b) \le 1.0$.
2. **Monotonicity:**
   - CDF $F(x)$ MUST be monotonically non-decreasing: $x_1 < x_2 \implies F(x_1) \le F(x_2)$.
   - Survival Function $S(x)$ MUST be monotonically non-increasing: $x_1 < x_2 \implies S(x_1) \ge S(x_2)$.
   - Quantile Function $Q(p)$ MUST be monotonically non-decreasing: $p_1 < p_2 \implies Q(p_1) \le Q(p_2)$.
3. **Complement Consistency:**
   - Complement relation $|(F(x) + S(x)) - 1.0| \le 10^{-15}$ across bounded central support where $10^{-15} \le F(x) \le 1 - 10^{-15}$.
   - Direct survival evaluation MUST be used in upper tails to prevent catastrophic cancellation.
4. **Finite Robustness:**
   - No avoidable `NaN` or `Infinity` may be emitted for any finite input within the supported domain.

### 17.2 Quantile Bracket & Inversion Invariant `[NEW PHASE 10 DECISION]`
For continuous distributions, a valid quantile result $x = Q(p)$ for $p \in (0, 1)$ must satisfy:
1. **Finite Result:** $x \in \mathbb{R}$ is finite.
2. **Numerical Bracket Certificate:** The implementation must maintain or establish a valid bracket $[\text{lo}, \text{hi}]$ such that $F(\text{lo}) \le p \le F(\text{hi})$ within numerical precision.
3. **Bidirectional Consistency:**
   - Forward-Inverse Parity: $|F(Q(p)) - p| \le 10^{-11} \cdot \max(p, 1 - p)$ across $p \in [10^{-9}, 1 - 10^{-9}]$.
   - Inverse-Forward Parity: $|Q(F(x)) - x| \le 10^{-11} \cdot \max(1.0, |x|)$ across the central domain.
4. **Monotonic Step Invariant for Discrete Distributions:**
   - Smallest integer $k \in \text{Support}$ such that:
     $$F(k) \ge p \quad \text{and} \quad F(k - 1) < p$$
     (with $F(k - 1) = 0.0$ if $k = \min(\text{Support})$).

### 17.3 Domain-Specific Acceptance Criteria Table
| Operation / Area | Comparison Metric | Acceptance Criterion | Domain of Applicability |
|---|---|---|---|
| **Rational Discrete Calculations** | Exact Identity | Exact (`isExact: true`) | Binomial, Geometric, Uniform with exact inputs within resource limit |
| **Continuous PDF / CDF Central Domain** | Relative Error $|\frac{\text{actual} - \text{ref}}{\text{ref}}|$ | $\le 10^{-12}$ | Central domain: **Normal** standardized $|z| = |\frac{x - \mu}{\sigma}| \le 5$ (where $P \ge 10^{-7}$); **Exponential** $\lambda x \in [10^{-6}, 10]$; **Uniform** interior support $x \in [a + \delta, b - \delta]$. |
| **Continuous CDF / SF Intermediate Tails** | Relative Error $|\frac{\text{actual} - \text{ref}}{\text{ref}}|$ | $\le 10^{-9}$ | Intermediate tail: **Normal** $5 < |z| \le 10$ down to $10^{-50}$; **Exponential** $\lambda x \in (10, 100)$. *(Uniform does not exhibit infinite asymptotic tails; support boundaries are evaluated directly).* |
| **Extreme Tail Probabilities** | Scale-Aware / Log-Space Error $|\ln(P) - \ln(P_{\text{ref}})|$ | $\le 10^{-6}$ | Extreme tail probabilities: **Normal** $|z| > 10$ down to representable subnormals; **Exponential** $\lambda x > 100$ down to representable subnormals. |
| **Continuous Quantile Inversion** | Residual & Bracket Invariant | $|F(Q(p)) - p| \le 10^{-11} \cdot \max(p, 1-p)$ | Tested across $p \in [10^{-9}, 1 - 10^{-9}]$ across continuous distributions |
| **Discrete Quantile Step Invariant** | Invariant Inequality | $F(k) \ge p$ and $F(k - 1) < p$ | All valid $p \in (0, 1)$ across discrete distributions |
| **Floating-Point Jitter Clamping** | Absolute Tolerance $\epsilon_{\text{clamp}}$ | $\le 10^{-15}$ | Jitter clamp threshold at $0.0$ and $1.0$ |

---

## 18. Comprehensive Test Matrix

### 18.1 Edge-Case & Boundary Tests
1. **Normal Distribution:**
   - Standard $\mathcal{N}(0, 1)$, shifted $\mathcal{N}(100, 15^2)$, narrow $\mathcal{N}(0, 0.01^2)$.
   - Symmetry: $|f(\mu - x) - f(\mu + x)| \le 10^{-14} \cdot \max(1.0, f(\mu))$ and $|F(\mu - x) + F(\mu + x) - 1.0| \le 10^{-14}$ across test domain.
   - Tails: $z \in \{\pm 5, \pm 8, \pm 10, \pm 30\}$.
   - Inversion parity: $Q(F(x)) \approx x$ for $x \in [-5, 5]$.
   - Quantile endpoints: $p = 0.0$ and $p = 1.0$ return typed `DomainError`.
2. **Uniform Distribution:**
   - Bounds: positive $[2, 6]$, negative $[-10, -2]$, spanning zero $[-5, 5]$, unit $[0, 1]$.
   - Validation: $a \ge b$ rejected with `InvalidDistributionParameterError`.
   - Finite endpoints: $Q(0) = a$, $Q(1) = b$.
3. **Exponential Distribution:**
   - Boundary $x = 0$: $f(0) = \lambda$, $F(0) = 0$.
   - Negative $x < 0$: $f(x) = 0$, $F(x) = 0$.
   - Small $\lambda x = 10^{-12}$: evaluates without subtractive cancellation.
   - Endpoints: $Q(0) = 0.0$, $Q(1)$ returns `DomainError`.
4. **Binomial Distribution:**
   - Degenerate cases: $n = 0$; $p = 0$; $p = 1$.
   - Quantile degenerate verification: $n=0 \implies Q(p)=0$; $p=1 \implies Q(p)=n$ for $p>0$.
   - Support boundaries: $k < 0 \implies 0$; $k > n \implies 0$.
   - Non-integer points: $k = 2.5 \implies \text{pdf} = 0$.
   - Beta function identity check across $n \in \{5, 10, 50\}$ with boundary isolation.
5. **Poisson Distribution:**
   - Parameter extremes: small $\lambda = 0.01$, large $\lambda = 500.0$.
   - Numerical Stability: Poisson PMF/CDF evaluation for large parameter or count values must avoid avoidable intermediate overflow, underflow-related loss of numerical validity, or other preventable numerical failure `[IMPLEMENTATION CHOICE]`.
   - Gamma function identity check: $F(k) = Q(k + 1, \lambda)$ with $k=0$ boundary isolation ($F(0) = e^{-\lambda}$).
   - Endpoints: $Q(0) = 0$, $Q(1)$ returns `DomainError`.
6. **Geometric Distribution:**
   - Parameter validation: $p \le 0$ or $p > 1$ rejected with `InvalidDistributionParameterError`.
   - Trials convention check: $P(X = 0) = 0$, $P(X = 1) = p$.
   - Degenerate case $p = 1$: $P(X = 1) = 1.0$, $Q(p) = 1$.
   - Sampling degenerate check: $p = 1$ returns $1$ without evaluating $\ln(0)$.
   - Endpoints: $Q(0) = 1$, $Q(1)$ returns `DomainError`.

### 18.2 Sampling Verification Suite
1. **Support Compliance:** 100% of samples satisfy $X \in \text{Support}$.
2. **Open-Interval Empirical Test:** In an empirical test of 100,000 variate draws, 100% of values supplied to the internal inverse transform satisfy $0.0 < U < 1.0$, verifying the implementation's compliance with the open-interval variate invariant.
3. **Degenerate Sampling:** Binomial $n=0 \implies 0$, $p=0 \implies 0$, $p=1 \implies n$; Geometric $p=1 \implies 1$.
4. **Moment Consistency Check:** For sample size $N$ (e.g. $N = 10,000$), empirical sample mean and empirical sample variance must be statistically consistent with theoretical $E[X]$ and $\text{Var}(X)$ within standard sample confidence boundaries.
5. **Distribution-Shape Validation `[NEW PHASE 10 DECISION]`:**
   - In addition to moment checks, the sampler must validate empirical distribution shape:
     - **Discrete Distributions (Binomial, Poisson, Geometric):** Empirical frequency counts across representative support bins must be statistically consistent with theoretical PMF probabilities. For Geometric, verify support strictly starts at $k = 1$.
     - **Continuous Distributions (Normal, Uniform, Exponential):** Empirical cumulative distribution function must be statistically consistent with theoretical CDF $F(x)$ across representative quantiles.
   - The implementation/test engineer may select a mathematically appropriate statistical goodness-of-fit methodology `[IMPLEMENTATION CHOICE]`.

---

## 19. Implementation Boundaries for Future Agents

### Future Implementation Agent MAY:
- Choose private class decomposition and internal helper method naming.
- Select specific approximation algorithms (Cody, Lanczos, Lentz, Halley, asymptotic expansions) provided numerical acceptance criteria are satisfied.
- Choose open-interval generation technique (resampling, affine scaling) satisfying $U \in (0, 1)$ without endpoint bias.
- Define internal PRNG retry limit to guard against infinite loops.

### Future Implementation Agent MAY NOT:
- Alter public method signatures of `ProbabilityEngine` or `ProbabilityDistribution`.
- Add `nextOpenDouble()` to the public `RandomSource` contract.
- Expand distribution scope beyond the initial 6 distributions.
- Alter the Geometric distribution convention from Trials ($k \ge 1$) to Failures.
- Allow Geometric distribution parameter $p = 0$.
- Claim exact rational representation for Poisson distributions.
- Return underflowed positive probabilities as exact `IntegerValue.zero`.
- Exceed the 1,024-bit rational evaluation threshold without transitioning to `DecimalValue`.
- Throw fatal `UnderflowError` on standard tail probability queries where clamping with `NearZeroWarning` is mandated.
- Suppress typed `MathError` failures or emit unverified error classes.
- Introduce external third-party dependencies or Flutter imports.

---

## 20. Resolution of Architectural Decisions & Repository Audit Findings

Following the formal **Repository Pre-Implementation Audit** and architectural decision analysis, technical proposals have been formulated for the two remaining policy decisions, subject to owner authorization:

1. **Exact Rational Representation Resource Policy `[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]` (§20.1):**
   - *Resolution:* Proposed policy: establish a **1,024-bit (~308 decimal digits)** deterministic engineering resource threshold on the numerator and denominator bit lengths of rational computations in Binomial, Geometric, and Uniform distributions, subject to Owner Approval. Implementations should apply predictive growth estimation to avoid intentionally constructing unbounded pathological intermediates.
   - *Behavior on Threshold:* When the bit length threshold is exceeded (or predicted to be exceeded), computation transitions gracefully to an approximate numerical evaluation path emitted as `DecimalValue` (with `isExact: false`) marked with `CalculationMetadata(isExact: false, warnings: [PrecisionLossWarning()])`.
   - *Status:* **PROPOSED — PENDING OWNER APPROVAL**.
2. **Representation-Relative Underflow Policy `[PROPOSED FINAL TECHNICAL POLICY — PENDING OWNER APPROVAL]` (§20.2):**
   - *Resolution:* Proposed policy: adopt **Observable Clamping with Warning** relative to the actual evaluation representation used, subject to Owner Approval. When a mathematically positive tail probability drops below the minimum representable positive non-zero bound of the evaluation representation, the engine returns **representational zero (`DecimalValue.zero` [verified repository static constant] or numerical `0.0`) wrapped in `MathSuccess` accompanied by `CalculationMetadata(isExact: false, warnings: [NearZeroWarning()])`** using the verified parameterless `NearZeroWarning` API.
   - *Fatal Error Boundary:* `UnderflowError` is strictly reserved for computational or structural failures where underflow prevents completion of a required calculation or violates a mathematical invariant.
   - *Status:* **PROPOSED — PENDING OWNER APPROVAL**.
3. **Repository Pre-Implementation Audit Summary:**
   - *Infrastructure Verification:* All applicable existing repository infrastructure required by Phase 10 was verified where present and applicable; the previously documented RandomSource limitations (contract-only interface verified; concrete implementation, public seeding, and `nextOpenDouble()` intentionally absent) remain unchanged.
   - *Existing API Mismatch Count:* **0**.
   - *Repository Blockers:* **0**.
   - *Phase 10 Target Path State:* Completely clean (`lib/mathematical_core/probability/` does not exist; no premature or conflicting code).

---

## 21. Final Specification Status

```text
NexaMath Phase 10 — Probability & Distributions

Specification:
REVISION 6 — FINAL TECHNICAL CORRECTION COMPLETED

Production Code:
NOT IMPLEMENTED

Test Code:
NOT IMPLEMENTED

Pre-Implementation Audit:
COMPLETED

Existing Repository Prerequisites:
VERIFIED WHERE APPLICABLE

Phase 10 Repository Implementation:
NOT YET PRESENT

Open Technical Owner Decisions:
2 — Pending Owner Approval

Implementation Authorization:
PENDING OWNER APPROVAL

Final Owner Approval:
PENDING
```

