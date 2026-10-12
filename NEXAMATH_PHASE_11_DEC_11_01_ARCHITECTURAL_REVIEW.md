# NexaMath Phase 11 — Architectural Decision Review: DEC-11-01
## Dimensional Exponent Representation — Analysis and Decision Preparation Report

**Document Version:** 1.4.0  
**Date:** October 9, 2026  
**Auditor / Reviewer:** Senior Mathematical Software Architect, Numerical Computing Engineer & Dart/Flutter Architecture Reviewer  
**Target Topic:** `DEC-11-01 — Dimensional Exponent Representation`  
**Authoritative Specification Target:** [`NEXAMATH_PHASE_11_UNITS_DIMENSIONAL_ANALYSIS_SPECIFICATION.md`](file:///d:/Programming%20projects/nexa_math/NEXAMATH_PHASE_11_UNITS_DIMENSIONAL_ANALYSIS_SPECIFICATION.md), Revision 5  
**Architectural Decision Status:** `DEC-11-01 ARCHITECTURAL DIRECTION: OPTION C APPROVED BY OWNER`  
**Resource Bound Status:** `1024-BIT ENFORCEMENT POLICY: OPEN — PENDING FOCUSED REVIEW`  
**Execution Context:** Architectural Decision Record & Analysis (Phase 11 Implementation Not Authorized)  

---

## 1. Executive Summary

This report documents the architectural review and owner decision record for **DEC-11-01 (Dimensional Exponent Representation)** under Revision 5 of the Phase 11 specification.

The central inquiry of DEC-11-01 is how physical dimension exponents across the 7 international base dimensions (ISQ / ISO 80000-1: Length $L$, Mass $M$, Time $T$, Electric Current $I$, Thermodynamic Temperature $\Theta$, Amount of Substance $N$, and Luminous Intensity $J$) should be represented in the upcoming `DimensionVector` model.

### Key Architectural Findings & Owner Resolution:
1. **Integer Exponents (Option A) are insufficient** for the explicit mathematical requirements of Revision 5, which mandates rational roots of dimensional quantities (e.g., $m^{1/2}$, $s^{-1/2}$, kinematic relationships, and rational power acceptance tests such as $(-8\text{ m}^3)^{1/3}$). While Dart `BigInt` could prevent platform integer overflow, integer storage inherently cannot represent rational fractions.
2. **Direct Reuse of `FractionValue` (Option B)** aligns with the specification's proposed data model, leveraging existing canonical rational reduction ($\gcd(|p|, q) == 1$) and `BigInt` backing. However, `FractionValue` is a general `ScalarValue` without physical domain typing, and does not natively enforce resource bounds or vector-level dimensional invariants.
3. **Dedicated Wrapper Type around `FractionValue` (Option C) — APPROVED BY OWNER:**
   - **Architectural Decision:** The project owner has approved **Option C** as the canonical architectural direction for DEC-11-01.
   - **Domain Typing:** A domain-specific immutable type (such as `DimensionalExponent`) serves as the dedicated representation for physical dimension exponents, providing a clear domain boundary and strong type safety separating exponents from general numerical scalars.
   - **Composition & Reuse:** `DimensionalExponent` internally composes and reuses the repository's existing `FractionValue` representation and its underlying canonical reduction ($\gcd(|p|, q) == 1, q \ge 1$), avoiding redundant reimplementation of rational arithmetic.
   - **Comprehensive Enforcement Requirement:** Constructor-only validation is explicitly recognized as insufficient. All construction and arithmetic paths (addition, subtraction, rational power scaling) must eventually enforce dimensional-exponent invariants and resource limits.
4. **Fully Independent Rational Type (Option D)** reimplements rational arithmetic from scratch, incurring high code duplication, dual-maintenance liability, and type conversion friction when evaluating general powers $q^r$.
5. **Outstanding Technical Issue — 1,024-Bit Bound Enforcement Policy:**
   - The owner has **not yet approved the detailed enforcement strategy** for the 1,024-bit limit.
   - While the specification mandates that absolute numerator and denominator bit lengths of reduced exponents respect the 1,024-bit bound and fail with `OverflowError` (with intermediate arithmetic checked and no fallback to `DecimalValue` or `PrecisionLossWarning`), the precise algorithmic points and scope for intermediate arithmetic checks (e.g., unreduced cross-products vs. canonical reduction boundaries vs. compound chaining) remain an **open issue pending a subsequent focused review**.

---

## 2. Canonical Decision Record

- **Decision ID:** `DEC-11-01`
- **Canonical Title:** **Dimensional Exponent Representation**
- **Specification Baseline (Revision 5, §18, Line 864):**
  > `FractionValue` (BigInt-backed) with canonical reduction $\gcd(|p|, q) == 1, q \ge 1$. Eliminates 64-bit platform limitations of native Dart int; enforces 1,024-bit limits on Windows & Android; components $> 1024$ bits fail with `OverflowError`.
- **Owner Decision (October 9, 2026):**
  - **Selected Direction:** **Option C — Dedicated Wrapper Type (`DimensionalExponent`) Composing `FractionValue`**.
  - **Scope of Approval:** Establishes `DimensionalExponent` as the domain-specific exponent abstraction composing `FractionValue` with domain type separation and reuse of existing canonical reduction.
  - **Open Reservation:** The detailed algorithmic enforcement strategy for the 1,024-bit intermediate-arithmetic bound is **not finalized** and is reserved for separate focused review.
- **Decision Status:** `DEC-11-01 ARCHITECTURAL DIRECTION: OPTION C APPROVED BY OWNER`
- **Resource Bound Policy:** `1024-BIT ENFORCEMENT POLICY: OPEN — PENDING FOCUSED REVIEW`
- **Implementation Gate:** `PHASE 11 IMPLEMENTATION STATUS: NOT AUTHORIZED`

---

## 3. Inspected Source Files and Specification Sections

### 3.1 Workspace Source Code Inspected
- [`lib/mathematical_core/numeric/values/fraction_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/fraction_value.dart) (Lines 1–157)
- [`lib/mathematical_core/numeric/values/integer_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/integer_value.dart) (Lines 1–85)
- [`lib/mathematical_core/numeric/values/decimal_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/decimal_value.dart) (Lines 1–306)
- [`lib/mathematical_core/common/math_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/common/math_value.dart) (Lines 1–14)
- [`lib/mathematical_core/numeric/operations/fraction_operations.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/operations/fraction_operations.dart) (Lines 1–135)
- [`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) (Lines 45–52)

### 3.2 Authoritative Specification Sections Inspected
- [`NEXAMATH_PHASE_11_UNITS_DIMENSIONAL_ANALYSIS_SPECIFICATION.md`](file:///d:/Programming%20projects/nexa_math/NEXAMATH_PHASE_11_UNITS_DIMENSIONAL_ANALYSIS_SPECIFICATION.md) (Revision 5):
  - Section 4.1: Base Dimensions (ISO 80000-1)
  - Section 4.2: Rational Exponent Representation & Target Runtime Compatibility
  - Section 4.3: `DimensionVector` Enforceable Construction Contract
  - Section 8.4: Powers ($q^r$) & Rational-Power Real Branch Rules
  - Section 17.1: Dimension Invariants
  - Section 18: Decision Register (DEC-11-01)
- Supporting Audit Baseline: [`NEXAMATH_PHASE_11_FINAL_SOURCE_OF_TRUTH_RECONCILIATION.md`](file:///d:/Programming%20projects/nexa_math/NEXAMATH_PHASE_11_FINAL_SOURCE_OF_TRUTH_RECONCILIATION.md) (Version 1.1.1).

---

## 4. Current Repository Architecture Analysis

Inspection of the actual codebase establishes the following architectural facts:

1. **`MathValue` and `ScalarValue` Hierarchy:**
   [`MathValue`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/common/math_value.dart#L6) is an unsealed abstract class serving as the root for all mathematical objects. [`ScalarValue`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/common/math_value.dart#L11) directly subclasses `MathValue`.
2. **`FractionValue` Structure & Invariants:**
   - In [`fraction_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/fraction_value.dart#L10), `FractionValue` directly extends `ScalarValue` and implements `Comparable<FractionValue>`.
   - Backed by two `BigInt` fields: `final BigInt numerator;` and `final BigInt denominator;`.
   - Enforces canonical invariants in its factory constructor: `denominator > 0`, `gcd(|numerator|, denominator) == 1`, and zero is uniquely normalized to `0/1`.
   - Structural equality (`operator ==`) and `hashCode` are defined based on `numerator` and `denominator`. Because instances are uniquely reduced, structural equality corresponds identically to mathematical equality.
3. **Resource Bound Status in Existing Code:**
   - **`FractionValue` does NOT enforce a 1,024-bit limit:** Inspection of lines 24–53 confirms that `FractionValue` accepts arbitrary `BigInt` values without any length or bit-width validation.
   - **`FractionOperations` does NOT enforce a 1,024-bit limit on rational addition, subtraction, multiplication, or division:** It performs unbounded `BigInt` arithmetic. Only the `power` method caps integral exponents at $100,000$.
   - **The 1,024-bit limit is a NEW Phase 11 requirement:** It exists solely as an architectural specification in Revision 5 §4.2 and must be implemented as part of Phase 11 dimensional contracts.
4. **Separation of Arithmetic Operations:**
   - `FractionValue` does **not** declare operator overloads (`+`, `-`, `*`, `/`) directly on its value class.
   - Arithmetic operations are externalized in [`FractionOperations`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/operations/fraction_operations.dart), which wraps outputs in `MathResult<FractionValue>` with `CalculationMetadata.exact`.
5. **Platform Integer Characteristics:**
   Native Dart `int` is a signed 64-bit integer on Windows and Android (VM runtime), with fixed bit-length limits ($[-2^{63}, 2^{63}-1]$). Conversely, `BigInt` represents arbitrary-precision integers, subject only to system memory.

---

## 5. Requirements Imposed by Revision 5

Revision 5 mandates the following concrete requirements for dimensional exponents:

1. **Rational Dimension Support:**
   The specification explicitly requires representing fractional dimensions resulting from roots and fractional powers (e.g., $m^{1/2}$, $L^{1/2}$, $(kg \cdot m^2 / s^2)^{1/2}$, and real branch powers in §8.4).
2. **Abelian Group Structure under Addition/Subtraction:**
   - Multiplication of quantities adds dimension exponents: $D(u_1 \times u_2) = D(u_1) + D(u_2)$.
   - Division subtracts exponents: $D(u_1 / u_2) = D(u_1) - D(u_2)$.
   - Power scales exponents: $D(u^r) = D(u) \times r$.
3. **Exact Canonical Reduction:**
   Exponents must always be in irreducible form ($\gcd(|p|, q) == 1, q \ge 1$). Equivalent exponents (e.g. $2/4$ and $1/2$) must have identical canonical representations to ensure deterministic equality and hashing.
4. **Deterministic 1,024-Bit Resource Bound:**
   Revision 5 §4.2 states verbatim:
   > *"Scope: Applies independently to the absolute numerator (`numerator.abs().bitLength`) and denominator (`denominator.bitLength`) of the canonicalized reduced rational exponent.*  
   > *Evaluation Timing: Checked after reduction and during intermediate arithmetic.*  
   > *Deterministic Failure: If any intermediate or canonicalized component exceeds 1,024 bits, the dimensional operation aborts deterministically with `OverflowError` (`lib/core/errors/math_error.dart`). It does not convert to `DecimalValue`, and does not emit `PrecisionLossWarning`. Dimensional invariants must remain exact."*
5. **Zero Indication & Dimensionless Cancellation:**
   A dimension vector where all seven exponents are $0/1$ represents a dimensionless scalar. Division of like units must collapse to `dimensionless` and reduce the quantity to a pure `ScalarValue` (§8.3).

---

## 6. Detailed Analysis of the 1,024-Bit Resource-Bound Contract

### 6.1 Explicit Mandate vs. Algorithmic Underspecification
The Revision 5 specification (§4.2) sets down a clear, mandatory policy:
- **Mandatory Policy:** The 1,024-bit bound is **not optional**. It explicitly applies to both canonicalized reduced rational components (`numerator.abs().bitLength` and `denominator.bitLength`) and intermediate arithmetic, requiring deterministic failure via `OverflowError` rather than approximation or precision warnings.
- **The Core Ambiguity Requiring Project-Owner Review:** While the mandate to check both intermediate arithmetic and canonicalized reduced components is explicit, Revision 5 does **not** define the exact scope of intermediate values and the precise algorithmic points at which they must be evaluated. This unresolved issue is not merely a binary choice between "unreduced vs. reduced", but spans multiple distinct algorithmic granularities:
  1. *Sub-Operation Algebraic Cross-Terms:* In rational addition/subtraction $\frac{a}{b} \pm \frac{c}{d} = \frac{a \cdot d \pm b \cdot c}{b \cdot d}$, are individual cross-products ($a \cdot d$, $b \cdot c$) checked during multiplication, or is the intermediate unreduced numerator ($a \cdot d \pm b \cdot c$) and denominator ($b \cdot d$) checked immediately before the GCD calculation?
  2. *Canonical Reduction Boundary:* Are canonical rational components verified immediately after Euclidean GCD reduction and normalization ($\gcd(|p|, q) == 1, q \ge 1$), prior to returning the resultant exponent?
  3. *Multi-Operand Accumulation Chains:* In compound expressions involving chained operations (such as multi-factor unit multiplications $u_1 \cdot u_2 \cdot u_3$ or repeated division), are intermediate component vectors checked at each pairwise operation step, or only at overall subexpression boundaries?
  4. *Rational Power Scaling:* When scaling exponents by a rational power $r = p_r / q_r$, are intermediate products $(p \cdot p_r, q \cdot q_r)$ checked before reduction, or does the check apply strictly to the canonical exponent?

### 6.2 Impact on Behavior and Necessary Owner Action
The precise definition of intermediate check scope directly impacts algorithmic behavior and failure boundaries:
- If intermediate checks evaluate unreduced cross-products before reduction, an operation whose canonical result has small bit-length could fail prematurely simply because intermediate cross-products temporarily grew beyond 1,024 bits before simplification.
- Conversely, if checks occur exclusively on canonicalized components after GCD reduction, intermediate cross-products could momentarily expand beyond 1,024 bits during calculation without triggering `OverflowError`.
- If chained operations evaluate intermediate vectors pairwise, associativity or evaluation order could alter whether a resource bound is tripped during intermediate steps.
- **Conclusion:** Because this distinction directly alters execution boundaries and error conditions, it represents a **specification ambiguity that requires project-owner review and formal clarification**. The authoritative specification must not be amended unilaterally during this architectural review.

---

## 7. Comparative Evaluation of Candidate Options

### Option A — Integer Exponents
- **Concept:** Store each dimension exponent as a single integer (either native 64-bit `int` or arbitrary-precision `BigInt`).
- **Analysis:**
  - *Native `int`:* Fixed platform limits (63-bit on VM, 53-bit on JS); cannot represent rational fractions.
  - *`BigInt`:* Eliminates bit overflow, but represents only integers ($\mathbb{Z}$), completely incapable of representing rational fractions ($\mathbb{Q}$).
- **Compatibility with Revision 5:** **INCOMPATIBLE**.
  - Revision 5 explicitly mandates fractional dimensions (e.g. `m^(1/2)` in EBNF grammar §10.2, and rational power tests §17.3). Neither `int` nor `BigInt` can represent $L^{1/2}$ or $M^{1/3}$.
- **Verdict on Option A:** Rejected due to mathematical inability to represent rational exponents.

### Option B — Direct Reuse of Existing `FractionValue`
- **Concept:** Store each base dimension exponent directly as an instance of `FractionValue`.
- **Compatibility with Revision 5:** **PARTIALLY SPECIFIED / REQUIRES ADAPTER DESIGN**.
  - Aligns with the data model proposed in Revision 5 §4.2, §4.3, and §18.
  - Reuses existing canonical reduction, GCD calculation, and immutable `BigInt` backing.
- **Implementation Realities:**
  - *1,024-Bit Contract:* Because `FractionValue` itself does not enforce this bound, `DimensionVector` must implement boundary validation in its constructors and vector arithmetic methods.
  - *Arithmetic API:* `FractionOperations.add` and `subtract` return `MathResult<FractionValue>`. Reusing them directly requires handling `MathResult` across 7 dimensions or wrapping them in a vector-level adapter.
  - *Domain Separation:* `FractionValue` is a `ScalarValue`. It does not provide compile-time distinction between dimension exponents and general numeric scalars.

### Option C — Dedicated Wrapper Type around `FractionValue` (`DimensionalExponent`)
- **Concept:** Introduce an immutable domain type (e.g. `final class DimensionalExponent`) that internally composes `FractionValue`.
- **Compatibility with Revision 5:** **HIGHLY COMPATIBLE (SUBJECT TO ARITHMETIC DESIGN)**.
- **Detailed Invariant Analysis & Necessary Conditions:**
  A wrapper type provides genuine type separation, but **only guarantees correctness if the following conditions are met across all code paths**:
  1. *Constructor Boundary Validation:* The wrapper constructor must validate `frac.numerator.abs().bitLength <= 1024` and `frac.denominator.bitLength <= 1024`, throwing `OverflowError` if breached.
  2. *Arithmetic Pipeline Validation:* Because `FractionOperations` does not enforce the 1,024-bit bound, every arithmetic method on the wrapper (`+`, `-`, `*`) must actively inspect components and enforce the resource policy, rather than assuming output validity.
  3. *Immutability:* The wrapped `FractionValue` must remain `final`, guaranteeing that validly constructed instances cannot be mutated into an invalid state.
  Without these active checks on arithmetic paths, the wrapper alone cannot guarantee bounded intermediate or resulting computation.

### Option D — Fully Independent Rational Type (`RationalExponent`)
- **Concept:** Reimplement a rational number class from scratch, completely detached from `FractionValue`.
- **Compatibility with Revision 5:** **CONDITIONALLY COMPATIBLE**.
- **Disadvantages:**
  - Duplicates GCD algorithms, reduction routines, and parsing already verified in `FractionValue`.
  - Violates DRY principles and creates parallel maintenance liability.
  - Friction when physical quantities are raised to powers $q^r$, requiring conversion between `FractionValue` and `RationalExponent`.
- **Verdict on Option D:** Inferior to Option C.

---

## 8. Precise Technical Evaluation of Arithmetic Integration Strategies

When performing dimensional arithmetic ($D_1 \pm D_2$, $D \times r$), three integration strategies are evaluated neutrally:

### Strategy 1: Reusing Existing `FractionOperations` with `MathResult` Handling
- **What is Reused:** Reuses existing `FractionOperations.add`, `subtract`, and `multiply` algorithms, full GCD reduction logic, and canonical `FractionValue` normalization.
- **What is Newly Implemented:** Mapping/unwrapping logic in `DimensionVector` to unpack `MathResult<FractionValue>` for each of the 7 base dimensions, plus an explicit post-arithmetic 1,024-bit bitLength check.
- **Canonical Reduction:** Handled automatically by `FractionValue` construction within `FractionOperations`.
- **Error Propagation:** Existing `MathFailure` results (e.g. `DivisionByZeroError`) are preserved and propagated directly through `MathResult`. `OverflowError` must be synthesized if the resulting components exceed 1,024 bits.
- **Maintainability & Duplication:** **Zero rational arithmetic duplication**. High maintainability, though error-handling boilerplate is required across vector components.
- **Allocation Impact (Estimate):** Generates intermediate `MathSuccess` and `CalculationMetadata` wrapper objects per component operation (an estimated 7 to 14 transient allocations per vector binary operation).

### Strategy 2: Introducing an Internal Arithmetic/Validation Adapter
- **What is Reused:** Reuses `FractionValue` constructor invariants ($\gcd(|p|, q) == 1$, sign normalization, zero representation) and `BigInt` multiplication/addition primitives.
- **What is Newly Implemented:** An internal helper (e.g. `_addExponents(FractionValue a, FractionValue b)`) that executes cross-multiplication, performs the mandatory 1,024-bit check, and directly returns `FractionValue` (or throws `OverflowError`).
- **Canonical Reduction:** Reuses `FractionValue(num, den)` factory, which executes GCD reduction.
- **Error Propagation:** Direct fail-fast model via throwing `OverflowError` and `DivisionByZeroError`, matching the `DimensionVector` contract in Revision 5 §4.3.
- **Maintainability & Duplication:** Duplicates basic rational addition formulas ($a \cdot d \pm b \cdot c, b \cdot d$), but avoids duplicating GCD logic.
- **Allocation Impact (Estimate):** Avoids `MathResult` and `CalculationMetadata` object allocations.

### Strategy 3: Independent Rational Arithmetic inside the Wrapper/Vector
- **What is Reused:** Reuses only primitive `BigInt` types.
- **What is Newly Implemented:** Full rational arithmetic, custom Euclidean GCD algorithm, custom sign normalization, custom zero normalization, and custom bitLength checking.
- **Canonical Reduction:** Newly implemented custom reduction.
- **Error Propagation:** Fully custom exception handling.
- **Maintainability & Duplication:** **High duplication**. Creates a second, divergent rational number engine in the codebase.
- **Verdict:** Reimplementation is mathematically and architecturally unjustified.

*Trade-off Assessment:* Correctness, deterministic resource enforcement, and error-contract consistency take absolute priority over speculative allocation savings. Strategy 1 and Strategy 2 are both technically viable; Strategy 2 provides a cleaner internal vector contract, while Strategy 1 maximizes reuse of existing core operations.

---

## 9. Comprehensive Comparison Matrix

| Evaluation Criterion | Option A: Integer Exponents | Option B: Direct `FractionValue` Reuse | Option C: Wrapper around `FractionValue` | Option D: Independent Rational Type |
| :--- | :--- | :--- | :--- | :--- |
| **Supports Fractional Exponents ($L^{1/2}$)** | **NO** (Violates Spec) | **YES** | **YES** | **YES** |
| **Exact Rational Arithmetic** | N/A | **YES** (Existing `FractionValue`) | **YES** (Via composed `FractionValue`) | **YES** (Reimplemented) |
| **Enforces 1,024-Bit Bound** | N/A | Requires check in vector methods | Requires check in wrapper arithmetic | Enforced in custom methods |
| **Code Duplication** | Low | **None** | Minimal (Composes `FractionValue`) | **High** (Duplicates GCD & reduction) |
| **Domain Type Safety** | Low | Low (`FractionValue` is general scalar) | **High** (Dedicated exponent type) | High (Dedicated exponent type) |
| **Arithmetic Integration** | Simple integer ops | Adapter or `MathResult` handling needed | Domain operators with bound checks | Custom operators with bound checks |
| **Interoperability with $q^r$** | N/A | **Direct** ($r$ is `FractionValue`) | **Direct** (Exposes `.value`) | Requires conversion layer |
| **Allocation Overhead (Estimated)** | Lowest | Moderate (Component allocations) | Moderate (Wrapper indirection) | Moderate (Custom objects) |

---

## 10. Mathematical Associativity vs. Bounded Execution Behavior
 
When multiplying physical quantities ($q_1 \times q_2 \times q_3$), the corresponding dimension vectors are combined by vector addition of exponents: $D(q_1 \times q_2) = D(q_1) + D(q_2)$.
 
In pure mathematics, dimension-vector addition over $\mathbb{Q}^7$ is strictly associative:
$$(D_1 + D_2) + D_3 = D_1 + (D_2 + D_3)$$

However, under a **finite resource bound** (such as the 1,024-bit ceiling), operational associativity can diverge between mathematically identical groupings if intermediate values or intermediate vectors grow before canonical reduction:
- If intermediate unreduced numerators $a \cdot d \pm b \cdot c$ or denominators $b \cdot d$ are checked *before* reduction, an intermediate component in $(D_1 + D_2)$ might temporarily exceed 1,024 bits and trigger an `OverflowError`, whereas reassociating as $D_1 + (D_2 + D_3)$ might keep intermediate values under 1,024 bits.
- Conversely, if checks occur exclusively *after* canonical reduction ($\gcd(|p|, q)$), any intermediate cross-products that collapse back into small canonical fractions will succeed regardless of grouping, unless the canonical components themselves exceed 1,024 bits.
- **Classification:** While the mathematical equality of the final canonical rational dimension vectors is guaranteed, operational success or failure under bounded intermediate execution depends on the exact scoping and timing of checks. This boundary remains an **unresolved question requiring project-owner review**.

---

## 11. Owner Architectural Direction Record

```
════════════════════════════════════════════════════════════════════════════════
  DEC-11-01 ARCHITECTURAL DIRECTION:
  OPTION C — DEDICATED WRAPPER TYPE (DimensionalExponent) COMPOSING FractionValue
  (APPROVED BY OWNER)
════════════════════════════════════════════════════════════════════════════════
```

### Basis of Approved Direction:
- **Option C (`DimensionalExponent`)** is approved by the project owner because it provides clean domain type separation (distinguishing physical dimensions from numerical scalars) while reusing the repository's verified GCD canonicalization in `FractionValue`.
- **Underlying Composition:** `FractionValue` remains the underlying rational-number representation. Existing fraction reduction and rational arithmetic capabilities are reused where appropriate rather than duplicated unnecessarily.
- **Enforcement Scope:** Constructor-only validation is explicitly recognized as insufficient. All construction and arithmetic paths must eventually enforce dimensional-exponent constraints and resource bounds.
- **Alternative Considered:** **Option B (Direct Reuse)** was evaluated as a viable alternative; however, Option C was selected to achieve stronger domain boundary protection and compile-time type safety.

---

## 12. Unresolved Owner Decisions vs. Specification Amendments vs. Implementation Details

To ensure clear decision boundaries, issues are categorized into three distinct levels:

### 12.1 Status of Architectural Representation (DEC-11-01)
1. **Architectural Representation Selection:** **RESOLVED BY OWNER** — The owner has approved **Option C (`DimensionalExponent` composing `FractionValue`)**.
2. **Public API Surface:** Reserved for finalization during Phase 11 design review (e.g., whether `DimensionVector` exposes exponents as `DimensionalExponent`, convenience integer getters, or raw values).

### 12.2 Outstanding Issue: 1,024-Bit Resource Bound Enforcement Policy (OPEN — PENDING FOCUSED REVIEW)
The owner has **not yet approved the detailed enforcement strategy** for the 1,024-bit limit. This remains an open issue reserved for a subsequent focused review.
The authoritative specification (§4.2) requires:
- The absolute numerator (`numerator.abs().bitLength`) and denominator (`denominator.bitLength`) of the canonicalized reduced rational exponent must each respect the 1,024-bit bound.
- Checks must account for intermediate arithmetic, not merely the final reduced result.
- If a bound is exceeded, the operation must abort deterministically with `OverflowError` (`lib/core/errors/math_error.dart`).
- No fallback to `DecimalValue` and no `PrecisionLossWarning` is permitted.

**Unresolved Scope and Algorithmic Checkpoints:**
The exact algorithmic points and scope for intermediate arithmetic checks remain open:
- *Sub-operation cross-products:* Whether intermediate unreduced cross-products ($a \cdot d \pm b \cdot c, b \cdot d$) or power products are checked before GCD reduction.
- *Canonical reduction checkpoints:* Verification of reduced components immediately following GCD normalization.
- *Compound chaining checkpoints:* Whether pairwise intermediate vectors in multi-factor expressions are checked at each step or only at subexpression boundaries.
- *Error propagation model:* How resource bounds integrate with `FractionOperations` and `MathResult` error propagation.

*(Note: No enforcement algorithm is finalized here; this issue remains open for a dedicated architectural review.)*

### 12.3 Implementation Design Details (Deferred to Implementation Phase)
- Selection between Integration Strategy 1 (reusing `FractionOperations` via `MathResult`) and Strategy 2 (internal vector adapter helper).
- Specific internal helper method naming, visibility, and parameter ordering.
- Singleton caching of common derived dimension vectors.

---

## 13. Proposed Acceptance Checklist for Future Implementation

When implementation is authorized, the delivered code must verify:
- [ ] Exponent representations support arbitrary rational fractions ($p/q$).
- [ ] Canonical reduction ($\gcd(|p|, q) == 1, q \ge 1$) is enforced on all exponents.
- [ ] Components exceeding 1,024 bits throw `OverflowError`.
- [ ] `DimensionVector.dimensionless` has all 7 exponents equal to $0/1$.
- [ ] Vector multiplication, division, and rational powers operate without floating-point error.
- [ ] Zero modifications to pre-existing Phase 10 or numeric core files.

---

## 14. Source Traceability Table

| Claim / Subject | Physical Source / Spec Section | Authoritative Classification |
| :--- | :--- | :--- |
| `FractionValue` BigInt backing & GCD reduction | [`lib/mathematical_core/numeric/values/fraction_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/fraction_value.dart) L10–53 | **VERIFIED AGAINST CURRENT SOURCE FILES** |
| `FractionValue` lacks 1,024-bit check | [`lib/mathematical_core/numeric/values/fraction_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/fraction_value.dart) L24–53 | **VERIFIED AGAINST CURRENT SOURCE FILES** |
| `FractionOperations` returns `MathResult` | [`lib/mathematical_core/numeric/operations/fraction_operations.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/operations/fraction_operations.dart) L14–54 | **VERIFIED AGAINST CURRENT SOURCE FILES** |
| `OverflowError` contract & code | [`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) L46–52 | **VERIFIED AGAINST CURRENT SOURCE FILES** |
| `DimensionVector` 7-base rational exponent proposal | Revision 5 §4.1–4.3 | **VERIFIED AGAINST AUTHORITATIVE SPECIFICATION** |
| 1,024-bit deterministic resource limit requirement | Revision 5 §4.2 | **VERIFIED AGAINST AUTHORITATIVE SPECIFICATION** |
| Option A integer insufficiency for fractional powers | Mathematical derivation from Revision 5 §8.4 | **VERIFIED BY DIRECT MATHEMATICAL DERIVATION** |
| Intermediate vs post-reduction overflow timing ambiguity | Revision 5 §4.2 text analysis | **AMBIGUITY REQUIRING SPECIFICATION AMENDMENT** |
| Memory and allocation overhead figures | Architectural analysis | **ARCHITECTURAL INFERENCE (ESTIMATED)** |

---

## 15. Final Approval Gate

```
════════════════════════════════════════════════════════════════════════════════
  DEC-11-01 ARCHITECTURAL DIRECTION: OPTION C APPROVED BY OWNER
  1024-BIT ENFORCEMENT POLICY: OPEN — PENDING FOCUSED REVIEW
  PHASE 11 IMPLEMENTATION STATUS: NOT AUTHORIZED
════════════════════════════════════════════════════════════════════════════════
```

*This review documents the owner's architectural choice of Option C for DEC-11-01. The detailed 1,024-bit intermediate-arithmetic enforcement policy remains an open issue pending focused review. No implementation is authorized, no tests were executed, and no production code has been modified.*
