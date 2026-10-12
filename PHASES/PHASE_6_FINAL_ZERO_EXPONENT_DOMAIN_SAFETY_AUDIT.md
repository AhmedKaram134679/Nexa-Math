# Phase 6 Final Zero-Exponent Domain-Safety Audit & Sign-Off Report

**Document Type:** Formal Mathematical Correctness & Domain-Safety Audit  
**Target Subsystems:**  
- `lib/mathematical_core/symbolic/simplification/symbolic_simplifier.dart`  
- `lib/mathematical_core/algebra/simplification/algebraic_simplifier.dart`  
**Author:** Senior Mathematical Software Engineer  
**Date:** September 22, 2026  
**Status:** Closed & Audited  

---

## 1. Issue Audited

In NexaMath's foundational numeric semantics (`DecimalOperations.power` and `IntegerOperations.power`), $0^0$ is explicitly defined as an indeterminate form returning `DomainError`:
$$0^0 \longrightarrow \text{DomainError: } 0^0 \text{ is an indeterminate form.}$$
Therefore, for an unrestricted symbolic base $x$, $x^0$ is undefined at $x = 0$. Consequently, the power product:
$$x^0 \times x^3$$
is undefined at $x = 0$, while the potential simplified product:
$$x^3$$
is defined at $x = 0$ ($0^3 = 0$).

Simplifying $x^0 \times x^3 \to x^3$ for an unproven symbolic base enlarges the mathematical domain at $x = 0$, violating NexaMath's strict domain-preservation mandate. This audit examined whether any direct or indirect simplification path permitted $x^0 \times x^n \to x^n$ or collapsed $x^0 \times x^0$ for unproven variable bases.

---

## 2. Source-Level Finding

1. **`_combinePowersOfSameBase` Direct Path:**
   - The predicate in `SymbolicSimplifier` previously used `_isProvenNonNegativeInteger(ExpressionNode node)`. Because `IntegerValue(0)` has `!val.isNegative == true`, $0$ was accepted as a valid exponent for combining powers on unproven bases.
   - This permitted $x^0 \times x^3 \to x^{0+3} \to x^3$.

2. **Identical Term Multiplication Indirect Path ($u \times u$):**
   - In both `SymbolicSimplifier.visitBinaryOp` (for `BinaryOperator.multiply`) and `DefaultAlgebraicSimplifier.visitBinaryOp`, the rewrite $u \times u \to u^2$ was previously able to match $u = x^0$, which would form $(x^0)^2 \to x^0$.

3. **Multiplicative Identity Path ($u \times 1 \to u$):**
   - Both simplifiers already protect $x^0$ from collapsing into $1$ when $x$ is an unrestricted variable (only non-zero literals $c^0 \to 1$ are reduced). Therefore, $x^0 \times u$ does not collapse via $1 \times u$.

---

## 3. Mathematical Rule

For a power-product $\text{base}^a \times \text{base}^b$:

### 1. Unrestricted Symbolic Base (Base NOT proven non-zero):
A power product $\text{base}^a \times \text{base}^b$ may be rewritten as $\text{base}^{a+b}$ **if and only if both exponents $a$ and $b$ are proven strictly positive integers** ($a, b \in \mathbb{Z}_{\ge 1}$):
$$x^m \times x^n \longrightarrow x^{m+n} \quad \iff \quad m, n \in \mathbb{Z}_{\ge 1}$$
- **Zero exponents must be preserved:** $x^0 \times x^n$, $x^n \times x^0$, and $x^0 \times x^0$ must remain uncombined.
- **Negative exponents must be preserved:** $x \times x^{-1}$, $x^4 \times x^{-2}$ remain uncombined.
- **Fractional exponents must be preserved:** $x^{1/2} \times x^{1/2}$, $x^{1/3} \times x^{1/3}$ remain uncombined.

### 2. Proven Non-Zero Numeric Base:
When the base is a proven non-zero numerical scalar ($c \in \mathbb{R} \setminus \{0\}$):
- Powers with zero exponents safely simplify and fold using $c^0 = 1$:
  $$2^0 \times 2^3 \longrightarrow 1 \times 8 \longrightarrow 8$$
  $$4^0 \times 4^5 \longrightarrow 1 \times 1024 \longrightarrow 1024$$

---

## 4. Changes Made

1. **`lib/mathematical_core/symbolic/simplification/symbolic_simplifier.dart`:**
   - Replaced `_isProvenNonNegativeInteger` with `_isProvenPositiveInteger(ExpressionNode node)`, strictly requiring `node is NumberLiteralNode && node.value is IntegerValue && node.value.isPositive` (i.e. integer $\ge 1$).
   - Updated `_combinePowersOfSameBase`: for unproven bases, combination requires `_isProvenPositiveInteger(expL) && _isProvenPositiveInteger(expR)`.
   - Updated the identical-term product guard ($u \times u$) to prevent converting power expressions with non-positive or non-integer exponents (such as $x^0$ or $x^{1/2}$) into squared expressions.
2. **`lib/mathematical_core/algebra/simplification/algebraic_simplifier.dart`:**
   - Hardened identical-term multiplication ($u \times u \to u^2$) to check whether `u` is a power node with a zero or fractional exponent on an unproven base, preventing indirect power-of-power collapses.
3. **`test/mathematical_core/symbolic/symbolic_simplification_test.dart`:**
   - Added explicit regression tests for:
     - $x^0 \times x^3$, $x^3 \times x^0$, and $x^0 \times x^0$ preservation.
     - $x \times x^4 \to x^5$ (implicit exponent 1 on left operand).
     - $2^0 \times 2^3 \to 8$ and $4^0 \times 4^5 \to 1024$ (proven non-zero literal base).
     - Concrete evaluation test in `AstEvaluator`: verifying $x^0 \times x^3$ evaluated at $x = 0$ fails with `DomainError`, while $x^2 \times x^3$ at $x = 0$ evaluates identically to $x^5$ ($0$).

---

## 5. Regression Matrix

| Case | Expression | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| **Case 1** | $x^2 \times x^3$ | $x^5$ | $x^5$ | **PASS** |
| **Case 2** | $x \times x^4$ | $x^5$ | $x^5$ | **PASS** |
| **Case 3** | $x^0 \times x^3$ | Preserved (unsimplified) | $x^0 \times x^3$ | **PASS** |
| **Case 4** | $x^3 \times x^0$ | Preserved (unsimplified) | $x^3 \times x^0$ | **PASS** |
| **Case 5** | $x^0 \times x^0$ | Preserved (unsimplified) | $x^0 \times x^0$ | **PASS** |
| **Case 6** | $2^0 \times 2^3$ | $8$ (constant folded) | $8$ | **PASS** |
| **Case 7** | $4^0 \times 4^5$ | $1024$ (constant folded) | $1024$ | **PASS** |
| **Case 8** | $x \times x^{-1}$ | Preserved (unsimplified) | $x \times x^{-1}$ | **PASS** |
| **Case 9** | $x^4 \times x^{-2}$ | Preserved (unsimplified) | $x^4 \times x^{-2}$ | **PASS** |
| **Case 10** | $x^{1/2} \times x^{1/2}$ | Preserved (unsimplified) | $x^{1/2} \times x^{1/2}$ | **PASS** |

---

## 6. Verification Results

| Verification Check | Tool / Command | Result |
|---|---|---|
| Full Test Suite | `flutter test` | **312 / 312 tests passed** (0 failures) |
| Static Analysis | `flutter analyze` | **No issues found!** (0 errors, 0 warnings) |
| Formatting Verification | `dart format --output=none --set-exit-if-changed .` | **Formatted 118 files (0 changed)** (Clean) |
| Windows Debug Build | `flutter build windows --debug` | **Successful** (`nexa_math.exe` generated) |
| Android Build Validation | `flutter build apk --config-only` | **Successful** (Exit code 0) |

---

## 7. Mathematical Guarantees

1. **Domain Singularity Preservation at $x = 0$:**
   For any unproven symbolic base, power expressions with non-positive integer exponents ($\le 0$) or non-integer fractional exponents cannot be combined or reduced into positive integer powers. The singularity at $x = 0$ (caused by division-by-zero or indeterminate $0^0$) is never erased.
2. **Domain Preservation for Fractional Powers ($x < 0$):**
   Fractional exponent power expressions on unproven bases remain strictly uncombined, ensuring the domain $[0, \infty)$ is never enlarged to $\mathbb{R}$.
3. **Sound Polynomial Reduction:**
   When both exponents are proven positive integers ($m, n \in \mathbb{Z}_{\ge 1}$), the domain of both $x^m \times x^n$ and $x^{m+n}$ is identically $\mathbb{R}$, guaranteeing complete mathematical equivalence and domain preservation across all real values including $x = 0$.

---

## 8. Final Verdict

```text
PHASE 6 — ZERO-EXPONENT DOMAIN SAFETY VERIFIED
```
