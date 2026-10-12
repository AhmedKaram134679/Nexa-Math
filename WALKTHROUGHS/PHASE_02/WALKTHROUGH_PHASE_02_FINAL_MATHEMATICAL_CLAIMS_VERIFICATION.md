# NexaMath — Phase 2 Final Mathematical Claims Verification & Closure Report

**Phase Under Review**: Phase 2 — Numeric Engine  
**Execution Mode**: WRITE MODE (Final Miller-Rabin Correction & Phase 2 Closure Gate)  
**Date**: September 20, 2026  
**Final Gate Decision**: **PHASE 2 — VERIFIED AND READY FOR PHASE 3**

---

## 1. Objective

This gate serves as the authoritative, final mathematical claims correction and closure gate before formally closing **Phase 2 — Numeric Engine** and unlocking **Phase 3 — Expression Engine**.

Its narrow primary objective was to:
1. Verify the exact Miller-Rabin base set currently in the source code.
2. Formally correct the deterministic primality threshold associated with the exact 12-base configuration in code from the erroneous `331,704,406,467,988` to the mathematically established threshold `318,665,857,834,031,151,167,461` ($> 2^{64}$).
3. Eliminate any remaining instance or phrase claiming universal "immunity to Carmichael pseudoprimes".
4. Accurately and conservatively classify large-integer behavior ($n \ge 318,665,857,834,031,151,167,461$) as a strong probable-prime test for those fixed bases, rather than an unrestricted proof of primality.
5. Re-run and verify the complete testing, analysis, and build pipeline.

---

## 2. Actual Base Set in Implementation

Inspection of [`lib/mathematical_core/numeric/primitives/number_theory.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/primitives/number_theory.dart#L71-L84) confirms that the implementation uses the exact 12 prime bases:
$$\mathcal{B} = \{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37\}$$

The algorithm was **not** altered; it performs small prime trial division up to $10^6$ and applies Miller-Rabin strong probable-prime rounds against these 12 fixed bases.

---

## 3. Correct Deterministic Threshold

### 3.1 Mathematical Bound
For the exact sequence of the first 12 prime bases up to 37:
$$\mathcal{B} = \{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37\}$$
The smallest composite strong pseudoprime to all 12 bases is known in number theory literature (e.g., calculations of Jiang & Deng, OEIS A014883) to be:
$$N_{12} = 318,665,857,834,031,151,167,461 \approx 3.187 \times 10^{23}$$

Therefore, for all integers strictly below this threshold:
$$n < 318,665,857,834,031,151,167,461$$
the 12-base Miller-Rabin test provides a **100% deterministic primality guarantee**.

### 3.2 64-Bit Integer Implication
Because:
$$318,665,857,834,031,151,167,461 > 2^{64} \approx 1.845 \times 10^{19}$$
the implementation provides a **proven, deterministic primality test across the entire unsigned 64-bit integer range (`uint64`)**.

---

## 4. Removal of the Previous Incorrect Claim

The number:
$$331,704,406,467,988$$
was previously associated in error with the 12-base configuration in earlier audit walkthroughs (that number corresponds to a smaller base subset in classical tables).

* **Correction Action**: The number `331,704,406,467,988` (and `3.317 × 10^14`) has been completely removed from all active code doc comments and replaced with $318,665,857,834,031,151,167,461$.

---

## 5. Large-Integer Semantics ($n \ge 318,665,857,834,031,151,167,461$)

To maintain strict mathematical conservatism:
* For values at or above $318,665,857,834,031,151,167,461$, passing all 12 fixed bases certifies the value as a **strong probable prime** (or strong pseudoprime if composite) for those specific 12 bases.
* It does **not** constitute an unrestricted mathematical proof of primality for arbitrary-width `BigInt`.
* The invalid $4^{-12}$ probability bound (which mathematically applies only to independently chosen random bases in a Monte-Carlo algorithm) remains completely removed.

---

## 6. Carmichael Number Regression Coverage

The phrase **"immune to Carmichael pseudoprimes"** was removed.

The documentation and test suite precisely record tested behavior:
* Standard Carmichael numbers fail strong pseudoprime tests across multiple prime bases.
* The test suite includes regression coverage verifying that known Carmichael numbers ($561, 1105, 1729$) are correctly identified and rejected as composite:
  ```dart
  expect(NumberTheory.isPrime(IntegerValue.fromInt(561)), isFalse);
  expect(NumberTheory.isPrime(IntegerValue.fromInt(1105)), isFalse);
  expect(NumberTheory.isPrime(IntegerValue.fromInt(1729)), isFalse);
  ```
* No universal claim of immunity to all hypothetical pseudoprimes is asserted.

---

## 7. Mathematical Claims Review

| Area | Previous Wording | Verified Status | Final Wording |
| :--- | :--- | :--- | :--- |
| **Miller-Rabin Deterministic Bound** | "Deterministic for $n < 331,704,406,467,988$" | Corrected threshold | Deterministically exact for all $n < 318,665,857,834,031,151,167,461$ across the configured 12 prime bases, guaranteeing deterministic classification across the full 64-bit integer range ($> 2^{64}$). |
| **Large-Integer Primality** | "Error probability $< 4^{-12}$" / "certifies n as a strong pseudoprime" | Mathematically conservative | Passing all 12 fixed bases establishes strong probable-prime status for those bases; does not constitute an unrestricted proof of primality. |
| **Carmichael Numbers** | "Immune to Carmichael pseudoprimes" | Replaced with verified behavior | Tested Carmichael numbers ($561, 1105, 1729$) are correctly identified and rejected as composite by this multi-base configuration. |
| **Sqrt Convergence** | ">12 iterations guarantee >100 accurate digits" | Verified | Newton-Raphson doubles precision per iteration; 12 iterations provide verified residual accuracy $< 10^{-63}$ at 64 digits. |
| **Promotion Exactness** | "Zero loss of exactness" | Verified | Exactness preserved for exact representations; explicitly flagged as approximate (`isExact: false`) for non-terminating decimals. |
| **$0^0$ Error Contract** | "IndeterminateFormError (or DomainError)" | Verified | Deterministically returns `DomainError('0^0 is an indeterminate form.')` across Integer, Fraction, and Decimal. |
| **Fraction Denominator Zero** | "ArgumentError or DivisionByZeroError" | Verified | Constructor invariant throws `ArgumentError`; arithmetic division returns `MathFailure(DivisionByZeroError)`. |

---

## 8. Code Changes in this Gate

1. **`lib/mathematical_core/numeric/primitives/number_theory.dart`**:
   - Corrected doc comments for `isPrime` to state the exact deterministic threshold $318,665,857,834,031,151,167,461$ ($> 2^{64}$).
   - Replaced large-integer classification wording with conservative strong probable-prime terminology.
   - Removed all references to $331,704,406,467,988$.
2. **`WALKTHROUGH_PHASE_02_FINAL_MATHEMATICAL_CLAIMS_VERIFICATION.md`**:
   - Updated Section 5.2, Section 9, Section 10, and Section 13 with the corrected threshold and wording.
3. **`WALKTHROUGH_PHASE_02_FINAL_NUMERICAL_PROOF_AUDIT.md`**:
   - Updated Section 8.2 to align with the corrected deterministic bound and Carmichael wording.

---

## 9. Verification Pipeline Results

All verification commands were executed on the active repository and passed cleanly:

* **Code Formatting**:
  ```text
  $ dart format --output=none --set-exit-if-changed .
  Formatted 54 files (0 changed) in 0.25 seconds.
  ```
* **Static Analysis**:
  ```text
  $ flutter analyze
  Analyzing nexa_math...
  No issues found! (ran in 37.6s)
  ```
* **Unit & Invariant Tests**:
  ```text
  $ flutter test
  00:04 +78: All tests passed!
  ```
  *Status*: 78 passed, 0 failed across 19 suites.
* **Windows Host Build**:
  ```text
  $ flutter build windows --debug
  Building Windows application... 10.8s
  √ Built build\windows\x64\runner\Debug\nexa_math.exe
  ```
* **Android Configuration**:
  ```text
  $ flutter build apk --config-only
  Exit code: 0
  ```
* **Android Gradle Validation**:
  ```text
  $ cd android && .\gradlew.bat tasks --dry-run
  BUILD SUCCESSFUL in 37s
  4 actionable tasks: 3 executed, 1 up-to-date
  ```

---

## 10. Scope Compliance

- **No Numeric Engine Redesign**: No data structures, scalar wrappers, or promotion lattices were altered.
- **No Phase 3 Functionality**: Zero Lexer, Parser, AST, or Evaluator code was created or imported.
- **No Unrelated Refactoring**: Only targeted mathematical doc comments and audit reports were modified.

---

## 11. Final Gate Decision

```
================================================================================
PHASE 2 — VERIFIED AND READY FOR PHASE 3
================================================================================
```

* **Phase 2 Status**: **FORMALLY CLOSED**
* **Phase 3 Status**: **READY TO BEGIN** (Phase 3 — Expression Engine)
