# NexaMath — Phase 6 Final Domain-Safety Sign-Off Report

**Document Status:** OFFICIAL PRODUCTION MATHEMATICAL SIGN-OFF  
**Audit Date:** 2026-09-21  
**Target Function:** `SymbolicSimplifier._combinePowersOfSameBase` (`lib/mathematical_core/symbolic/simplification/symbolic_simplifier.dart`)  
**Auditor:** Senior Mathematical Software Engineer & Formal Correctness Reviewer  
**Final Decision:** PHASE 6 — MATHEMATICALLY VERIFIED AND READY FOR PHASE 7  

---

## 1. Executive Summary

This final narrow acceptance audit resolves the mathematical domain-safety semantics of the symbolic simplification rule:
$$\text{base}^a \times \text{base}^b \longrightarrow \text{base}^{a+b}$$
specifically evaluating whether **arbitrary symbolic exponents** (such as $x^a \times x^b$, $x^a \times x^2$, or $x^a \times x^{-a}$) can be safely combined when no symbolic assumption engine exists to prove that the exponents are non-negative or that the base is non-zero.

### Key Finding
Because NexaMath does not currently possess an assumption subsystem proving $x \ne 0$ or $a \ge 0$, an unrestricted symbolic exponent $a$ can evaluate to a negative value (e.g. $a = -1, b = 2$). If $x^a \times x^b$ were reduced to $x^{a+b}$ ($x^1 = x$), the expression would become defined at $x = 0$, whereas the original product $x^{-1} \times x^2$ is undefined at $x = 0$.

### Core Resolution
The implementation was corrected to enforce **Option B**:
- For an **unproven base** (such as a variable $x$), exponents are combined **ONLY if both exponents are proven non-negative numbers** (`_isProvenNonNegative`).
- Unrestricted symbolic exponents on variable bases ($x^a \times x^b$, $x^a \times x^2$, $x^a \times x^{-a}$) are **conservatively preserved** without reduction.
- Proven non-zero scalar bases ($2^a \times 2^b \to 2^{a+b}$ and $2^4 \times 2^{-2} \to 4$) and safe non-negative integer powers on variable bases ($x^2 \times x^3 \to x^5$) **remain fully supported**.

---

## 2. Answers to Required Source-Level Questions

### Question 1: Does NexaMath Phase 6 have an assumptions mechanism proving arbitrary symbolic exponents are domain-safe?
**Answer: `NO`**
*Source Evidence:* `lib/mathematical_core/symbolic/` implements immutable AST wrappers (`SymbolicExpression`), rewrite rules (`SymbolicSimplifier`), and exact differentiation (`SymbolicDifferentiator`). No domain assumption or predicate engine exists to infer that a variable $a$ satisfies $a \ge 0$ or that $x \ne 0$.

### Question 2: Can $x^a \times x^b$ currently be safely rewritten to $x^{a+b}$ for unrestricted symbolic $a$ and $b$?
**Answer: `NO`**
*Mathematical Justification:* Without assumptions on $a$ and $b$, assigning $a = -1, b = 2$ turns $x^a \times x^b$ into $x^{-1} \times x^2$, which is undefined at $x = 0$ ($0^{-1} = \frac{1}{0}$ is undefined). Combining it into $x^{(-1+2)} = x^1$ yields a polynomial term defined at $x = 0$. This changes the mathematical domain.

### Question 3: What happens to specific symbolic exponent cases?
- **$x^a \times x^b$:** **PRESERVED** without reduction.
- **$x^a \times x^{-a}$:** **PRESERVED** without reduction (prevents false reduction to $1$ at $x = 0$).
- **$x^a \times x^2$ / $x^2 \times x^a$:** **PRESERVED** without reduction.

### Question 4: What happens to safe numeric cases?
- **$x^2 \times x^3$:** **COMBINED** to $x^5$ (both exponents are proven non-negative integers $\ge 0$).
- **$x \times x^{-1}$:** **PRESERVED** without reduction (negative exponent on unproven base).
- **$x^4 \times x^{-2}$:** **PRESERVED** without reduction (negative exponent on unproven base).
- **$2^4 \times 2^{-2}$:** **COMBINED** to $2^2$ and constant-folded to $4$ (base literal $2 \ne 0$ is proven non-zero).

---

## 3. Actual Source-Level Guard: Before and After

### Before (Allowed Arbitrary Symbolic Exponents)
```dart
    if (baseL == baseR) {
      final baseIsProvenNonZero = _isProvenNonZero(baseL);
      if (!baseIsProvenNonZero) {
        if (_hasNegativeExponent(expL) || _hasNegativeExponent(expR)) {
          return null;
        }
      }
      // Allowed x^a * x^b because 'a' was not syntactically a negative literal!
      ...
    }
```

### After (Strictly Domain-Safe)
In `lib/mathematical_core/symbolic/simplification/symbolic_simplifier.dart`:
```dart
    if (baseL == baseR) {
      // Domain Safety Check:
      // If the base is not a proven non-zero literal, combining exponents changes
      // the mathematical domain unless both exponents are proven non-negative.
      // E.g., x^a * x^b can have a = -1, b = 2 where x^-1 * x^2 is undefined at x = 0,
      // but x^1 is defined at x = 0. Likewise, x * x^-1 is undefined at x = 0.
      final baseIsProvenNonZero = _isProvenNonZero(baseL);
      if (!baseIsProvenNonZero) {
        if (!_isProvenNonNegative(expL) || !_isProvenNonNegative(expR)) {
          return null; // Refuse domain-changing reduction for unrestricted/negative exponents
        }
      }

      final sumExp = BinaryOpNode(
        position: pos,
        operator: BinaryOperator.add,
        left: expL,
        right: expR,
      );
      final simplifiedExp = simplify(sumExp).valueOrNull ?? sumExp;
      return BinaryOpNode(
        position: pos,
        operator: BinaryOperator.power,
        left: baseL,
        right: simplifiedExp,
      );
    }
    return null;
```
Supporting predicate:
```dart
  bool _isProvenNonNegative(ExpressionNode node) {
    if (node is NumberLiteralNode) {
      final val = node.value;
      if (val is IntegerValue) return !val.isNegative;
      if (val is FractionValue) return !val.isNegative;
    }
    return false;
  }
```

---

## 4. Test Matrix & Executable Evidence

All cases verified in `test/mathematical_core/symbolic/symbolic_simplification_test.dart`:

| Category | Input Expression | Target Behavior | Actual Result | Mathematical Reason |
|---|---|---|---|---|
| **Safe numeric** | `x^2 * x^3` | Combine to `x^5` | `x^5` | Proven non-negative exponents $\ge 0$ |
| **Safe numeric** | `x^3 * x^2` | Combine to `x^5` | `x^5` | Proven non-negative exponents $\ge 0$ |
| **Safe numeric** | `x^0 * x^3` | Combine to `x^3` | `x^3` | Exponent addition $0 + 3 = 3$ |
| **Unsafe symbolic** | `x^a * x^b` | Preserve as `x^a * x^b` | `x^a * x^b` | Exponents $a, b$ could be negative |
| **Unsafe symbolic** | `x^a * x^2` | Preserve as `x^a * x^2` | `x^a * x^2` | Exponent $a$ could be negative |
| **Unsafe symbolic** | `x^a * x^-a` | Preserve as `x^a * x^-a` | `x^a * x^-a` | Protects singularity at $x = 0$ |
| **Unsafe numeric** | `x * x^-1` | Preserve as `x * x^-1` | `x * x^-1` | Protects singularity at $x = 0$ |
| **Unsafe numeric** | `x^4 * x^-2` | Preserve as `x^4 * x^-2` | `x^4 * x^-2` | Protects singularity at $x = 0$ |
| **Proven base** | `2^a * 2^b` | Combine to `2^(a+b)` | `2^(a + b)` | Base $2 \ne 0$ is proven non-zero |
| **Proven base** | `2^4 * 2^-2` | Combine to `4` | `4` | Base $2 \ne 0$ is proven non-zero |
| **Different base** | `x^2 * y^3` | Preserve | `x^2 * y^3` | `baseL != baseR` |

---

## 5. Production Code Changes

Exclusively in `lib/mathematical_core/symbolic/simplification/symbolic_simplifier.dart`:
- Replaced negative-check logic in `_combinePowersOfSameBase` with `!_isProvenNonNegative(expL) || !_isProvenNonNegative(expR)`.
- Replaced `_hasNegativeExponent` with `_isProvenNonNegative`.
- Zero changes to AST, parser, evaluator, or Phase 0–5 subsystems.

---

## 6. Verification Results

- **Test Suite:** **301 / 301 passed (100%)** (0 failures, 0 regressions across Phases 0–6).
- **Static Analysis:** `flutter analyze` passed with 0 issues.
- **Code Formatting:** `dart format` passed with 0 changes across 118 files.
- **Windows Verification:** `flutter build windows --debug` succeeded in 9.0s (`nexa_math.exe` built).
- **Android Configuration Verification:** `flutter build apk --config-only` succeeded with exit code 0.

---

## 7. Final Acceptance Decision

```text
PHASE 6 — MATHEMATICALLY VERIFIED AND READY FOR PHASE 7
```
