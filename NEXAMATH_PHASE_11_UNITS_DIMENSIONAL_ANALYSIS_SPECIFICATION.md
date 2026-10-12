# NexaMath — Phase 11: Units & Dimensional Analysis Specification

**Document Type:** Authoritative Architectural & Engineering Specification  
**Document Status:** REVISION 5 — READY FOR OWNER ARCHITECTURAL REVIEW (IMPLEMENTATION NOT AUTHORIZED)  
**Author:** Senior Software Architect, Dart/Flutter Engineer, Mathematical Computing Specialist & Technical Specification Auditor  
**Date:** October 9, 2026  
**Target Subsystem:** `lib/mathematical_core/units/`  
**Host Framework:** Flutter / Pure Dart Mathematical Core  
**Target Platforms:** Windows & Android  

---

## 1. Document Control & Historical Integrity

### 1.1 Revision History
| Revision | Date | Author | Summary of Changes | Status |
|---|---|---|---|---|
| **Revision 1** | October 8, 2026 | Senior Mathematical Software Architect | Initial draft synthesizing Roadmap §16, Engine Contracts §39 & §57, Blueprint §48–49, and Core Value Contracts. Formulated DimensionVector (rational 7-tuple exponent model), Unit, Quantity (MathValue subtype), UnitEngine contract, affine offset temperature models, parsing grammar, and open decisions register. | SUPERSEDED |
| **Revision 2** | October 8, 2026 | Senior Mathematical Software Architect | Comprehensive architectural correction & hardening pass: formalized rational DimensionVector semantics, affine temperature conversion equation, QuantityKind enum, standardized unit catalog, SI-prefix precedence, angle model, real rational power branches, whitespace parsing separation, and Decision Register (DEC-11-01 through DEC-11-09). | SUPERSEDED |
| **Revision 3** | October 8, 2026 | Senior Mathematical Software Architect | Mathematical consistency & contract verification pass: reconciled repository API contracts against actual code inspection (`MathValue`, `ScalarValue`, `MathResult<T>`, `MathError`, `MathWarning`, `PrecisionContext`); formalized affine conversion pipeline; formulated real-branch rational powers; prohibited affine compound units; clarified derived-unit canonicalization vs semantic meaning. | SUPERSEDED |
| **Revision 4** | October 9, 2026 | Senior Mathematical Software Architect | Focused contract corrections: replaced `(int, int)` with `FractionValue` / `BigInt` backing for 1024-bit safety; audited BTU conventions ($1055.056\text{ J}$ rounded vs $1055.05585262\text{ J}$ exact ISO); corrected EBNF grammar for `m^(1/2)`; reconciled temperature scalar arithmetic; separated dimensional vs numeric vs semantic equality; narrowed round-trip guarantees; read-only repository audit. | SUPERSEDED |
| **Revision 5** | October 9, 2026 | Senior Software Architect & Spec Auditor | Focused contract corrections & rigorous consistency pass: (1) Formalized rational representation using repository `FractionValue` with BigInt backing, defining 1,024-bit limits and deterministic `OverflowError` failure; (2) Enforced `DimensionVector` construction invariants via private constructor and validated factory; (3) Audited BTU International Table definitions, distinguishing ISO 31-4 exact standard from rounded conventional values under DEC-11-07; (4) Formalized complete EBNF grammar with parenthesized rational exponents, signed integers, and whitespace tokenization; (5) Reconciled temperature arithmetic, strictly prohibiting scalar multiplication/division of absolute states; (6) Formalized absolute vs interval conversions with cross-scale offset isolation; (7) Distinctly defined dimensional compatibility, numeric equality, and semantic equality (preserving Energy vs Torque distinctions); (8) Reconciled unit factors, irrational $\pi$ angle conversions, and precision tracking; (9) Narrowed round-trip identity guarantees to linear rational conversions within limits; (10) Enforced unit immutability (`Set.unmodifiable`) and derived `isAffine`; (11) Audited SI prefix coverage ($10^{-24}$ to $10^{24}$ bounded subset) and documented 2022 CGPM extreme prefixes ($10^{\pm 27}, 10^{\pm 30}$) as deferred; (12) Defined declared-unit basis for `floor`/`ceil`/`round`; (13) Enforced `Quantity` construction validation rejecting ordinary/interval kind on affine units; (14) Defined base-normalized arithmetic with compound unit assignment; (15) Audited repository exactness metadata contracts (`CalculationMetadata`, `isExact`, warnings); (16) Conducted exhaustive read-only repository audit with line numbers and source locations; (17) Resolved all cross-section contradictions; (18) Formulated comprehensive acceptance test suites; (19) Preserved DEC-11-01 through DEC-11-09 as `PROPOSED — PENDING OWNER APPROVAL`. | **READY FOR OWNER ARCHITECTURAL REVIEW (IMPLEMENTATION NOT AUTHORIZED)** |

### 1.2 Historical Baseline & Protection of Closed Phases
The repository workspace maintains a strictly verified baseline:
* **Phases 0–9 Core Modules**: Formally completed, sealed, and protected.
* **Phase 10 — Probability & Distributions**: Officially **VERIFIED — CLOSED** (48/48 Phase 10 tests, 483/483 total tests passing, `flutter analyze` clean, `dart format` clean, [PHASE_10_CLOSURE.md](file:///d:/Programming%20projects/nexa_math/PHASES/PHASE_10_CLOSURE.md) recorded).
* **Absolute Non-Modification Rule**: Phase 11 specification authoring does **not** alter, reopen, or refactor any completed phase, nor does it create or modify any production Dart code, test files, dependencies, or build configurations.

---

## 2. Requirements Hierarchy & Source Traceability

Every architectural choice, model property, and mathematical rule in this specification is categorized according to its authoritative origin:

* **`[SOURCE-DERIVED]`**: Directly mandated or constrained by existing authoritative project documents:
  * [`CALCULATOR_MASTER_SPECIFICATION.md`](file:///d:/Programming%20projects/nexa_math/CALCULATOR_MASTER_SPECIFICATION.md)
  * [`NEXAMATH_IMPLEMENTATION_ROADMAP.md`](file:///d:/Programming%20projects/nexa_math/NEXAMATH_IMPLEMENTATION_ROADMAP.md) §16
  * [`NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md`](file:///d:/Programming%20projects/nexa_math/NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md) §39, §57
  * [`NEXAMATH_IMPLEMENTATION_BLUEPRINT.md`](file:///d:/Programming%20projects/nexa_math/NEXAMATH_IMPLEMENTATION_BLUEPRINT.md) §48–49
  * [`lib/mathematical_core/common/math_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/common/math_value.dart) *(Verified)*
  * [`lib/mathematical_core/numeric/values/fraction_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/fraction_value.dart) *(Verified)*
  * [`lib/mathematical_core/numeric/values/integer_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/integer_value.dart) *(Verified)*
  * [`lib/mathematical_core/numeric/values/decimal_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/decimal_value.dart) *(Verified)*
  * [`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) *(Verified)*
  * [`lib/core/result/math_warning.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/result/math_warning.dart) *(Verified)*
  * [`lib/core/result/math_result.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/result/math_result.dart) *(Verified)*
  * [`lib/mathematical_core/common/precision_context.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/common/precision_context.dart) *(Verified)*
* **`[NEW PHASE 11 DECISION]`**: Concrete mathematical, numerical, or boundary rule formulated in this specification to resolve ambiguities where prior documents were high-level.
* **`[IMPLEMENTATION CHOICE]`**: Implementation details left to the discretion of the future implementation engineer, subject to passing acceptance criteria.
* **`[OWNER DECISION REQUIRED]`**: Core architectural choices submitted explicitly to the project owner for binding resolution before code implementation begins.

---

## 3. Scope Boundary

### 3.1 In Scope for Phase 11
1. **Physical Dimension System**:
   * Representation of physical dimensions across the 7 international base dimensions (SI / ISO 80000-1): Length ($L$), Mass ($M$), Time ($T$), Electric Current ($I$), Thermodynamic Temperature ($\Theta$), Amount of Substance ($N$), and Luminous Intensity ($J$).
   * Dimensionless quantities ($1 = L^0 M^0 T^0 I^0 \Theta^0 N^0 J^0$).
   * Canonical rational dimension vector arithmetic: addition of exponents for multiplication, subtraction for division, rational scaling for powers.
   * Exact 1,024-bit bit-length resource guard on dimensional exponents with deterministic `OverflowError` failure.
2. **Unit Model & Registry**:
   * Immutable `Unit` definition parameterized by canonical symbol, primary name, dimension vector, exact rational/decimal scale, offset, and quantity kind.
   * Standard unit catalog (SI base units, coherent SI derived units, common Imperial/US Customary units, angles, percentages).
   * SI decimal prefix system ($10^{-24}$ to $10^{24}$) with deterministic longest-prefix resolution and ambiguity avoidance.
   * Case-sensitive unit symbol and alias registry with immutable collections.
3. **Physical Quantity Model**:
   * Immutable `Quantity` container subtyping top-level `MathValue` directly, binding `ScalarValue magnitude`, `Unit unit`, and `QuantityKind kind`.
   * Semantic kinds distinguishing ordinary physical quantities, absolute thermodynamic temperatures, and temperature intervals.
   * Quantity arithmetic: dimensionally checked addition and subtraction, compound multiplication, division with dimensionless collapse, and real rational powers.
   * Mixed quantity-scalar operations: $q \times s$, $s \times q$, $q / s$, $s / q$.
4. **Unit Conversion & Normalization**:
   * Exact linear conversion between dimensionally compatible units using reduced rational `FractionValue`s.
   * Rigorous affine offset conversion using $v_{\text{base}} = v \times \text{scale} + \text{offset}$ and its exact inverse, guaranteeing single application of offsets.
   * Base normalization to coherent SI units.
   * Narrowly defined round-trip identity preservation for rational linear conversions within 1024-bit limits.
5. **Unit Expression Parsing**:
   * Two-tier parsing architecture: dedicated unit symbol/alias resolution followed by composite expression parsing.
   * Deterministic EBNF grammar accepting parenthesized exponents `m^(1/2)`, `m^(-2)`, signed integers, and parenthesized compound expressions.
   * Whitespace tokenization separating implicit juxtaposition multiplication from multiword unit names and explicit operators.
6. **Mathematical Functions Interaction**:
   * Strict dimensional preconditions for trigonometric, transcendental, and algebraic functions.
   * Real branch rational-power evaluation for quantities with negative bases and odd denominators after canonical reduction.
7. **Engine Façade & Diagnostics**:
   * Authoritative `UnitEngine` abstract contract.
   * Strict diagnostic reporting through existing `MathResult<T>`, verified `MathError` subclasses (`DimensionMismatchError`, `InvalidUnitError`, `DomainError`, `DivisionByZeroError`, `OverflowError`, `SyntaxError`), and verified `MathWarning` subclasses (`PrecisionLossWarning`, `UnitConversionWarning`, `NumericalApproximationWarning`).

### 3.2 Out of Scope for Phase 11 (Non-Goals)
* **No UI / Flutter Presentation**: Unit pickers, UI dropdowns, localized string formatting, and widget layouts belong to Phase 18 (`presentation/units/`).
* **No Dynamic Currency Conversion**: Currencies (USD, EUR, GBP) fluctuate in real-time, require internet feeds, and are non-physical; currency conversion belongs to application-level plugins or online finance services.
* **No Calendar / Time Zone Systems**: Date/time arithmetic (leap seconds, calendar months, time zones) belongs to standard platform libraries or dedicated date utilities, not dimensional physical analysis.
* **No Online External Unit APIs**: The core must remain pure Dart, deterministic, zero-dependency, and offline.
* **No Binary Prefixes (kibi, mebi, gibi)**: Binary prefixes (`Ki`, `Mi`, `Gi`) apply to information quantities (bytes, bits) and are deferred to a specialized computing units extension.
* **No Unbounded User-Defined Unit Scripting**: Custom persistent user formulas/units belong to Phase 12 (`formulas/`).

---

## 4. Dimensional Analysis Architecture & Rational Exponent Representation

### 4.1 Base Dimensions (ISO 80000-1)
`[SOURCE-DERIVED]` The physical dimension system is grounded in the 7 independent physical dimensions of the International System of Quantities (ISQ):

```dart
enum BaseDimension {
  length,                 // L (meter)
  mass,                   // M (kilogram)
  time,                   // T (second)
  electricCurrent,        // I (ampere)
  temperature,            // Θ (kelvin)
  amountOfSubstance,      // N (mole)
  luminousIntensity,      // J (candela)
}
```

### 4.2 Rational Exponent Representation & Target Runtime Compatibility
`[NEW PHASE 11 DECISION — DEC-11-01 & REVISION 5 AUDIT]`  
In Dart on 64-bit platforms (Windows and 64-bit Android), the primitive `int` type is a signed 64-bit two's complement integer with maximum bit-length 63 ($[-2^{63}, 2^{63}-1]$). On the web (JavaScript compilation), `int` is represented as double-precision floating point (53-bit mantissa).  
Therefore, a tuple of native Dart ints `(int, int)` **cannot** represent integers exceeding 63 bits and cannot satisfy an arbitrary 1,024-bit bound.

#### Architectural Resolution:
1. **Reuse Existing Repository Abstraction**: The repository already provides an authoritative arbitrary-precision canonical rational value type:
   [`FractionValue`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/fraction_value.dart).
   `FractionValue` is backed internally by Dart `BigInt` (both numerator and denominator), enforces $\text{denominator} > 0$, canonical reduction via $\gcd(|p|, q)$, and unique zero representation ($0/1$).
2. **Dimension Exponent Type**:
   Each base dimension exponent in `DimensionVector` is represented as an immutable canonical `FractionValue`.
   Integer dimensions are created via `FractionValue.fromInts(p, 1)`.
3. **Deterministic 1,024-Bit Resource Policy Definition**:
   * **Scope**: Applies independently to the absolute numerator (`numerator.abs().bitLength`) and denominator (`denominator.bitLength`) of the canonicalized reduced rational exponent.
   * **Evaluation Timing**: Checked after reduction and during intermediate arithmetic.
   * **Deterministic Failure**: If any intermediate or canonicalized component exceeds 1,024 bits, the dimensional operation **aborts deterministically with `OverflowError`** (`lib/core/errors/math_error.dart`). It does **not** convert to `DecimalValue`, and does **not** emit `PrecisionLossWarning`. Dimensional invariants must remain exact.
   * **Zero and Negative Values**: $0$ is canonicalized to $0/1$ (bit-length 0 and 1). Negative exponents have positive denominators with negative numerators (e.g. $-2/1$ has numerator bit-length 2).

### 4.3 `DimensionVector` Enforceable Construction Contract
To guarantee that invalid or non-canonical dimension vectors can never exist at runtime, the public contract prohibits direct unchecked instantiation:

```dart
final class DimensionVector {
  /// Canonical reduced rational exponents for [L, M, T, I, Θ, N, J].
  /// Guaranteed invariants:
  /// 1. Backed by FractionValue (BigInt numerator & strictly positive denominator).
  /// 2. Reduced to lowest terms: gcd(|num|, den) == 1.
  /// 3. Zero is uniquely 0/1.
  /// 4. bitLength <= 1024 for all numerators and denominators.
  final FractionValue length;
  final FractionValue mass;
  final FractionValue time;
  final FractionValue current;
  final FractionValue temperature;
  final FractionValue amount;
  final FractionValue luminousIntensity;

  /// Private canonical constructor enforcing internal immutability.
  const DimensionVector._({
    required this.length,
    required this.mass,
    required this.time,
    required this.current,
    required this.temperature,
    required this.amount,
    required this.luminousIntensity,
  });

  /// Validated public factory enforcing canonicalization and resource limits.
  /// Throws [ArgumentError] if denominator is zero.
  /// Throws [OverflowError] if bit-length exceeds 1024 bits.
  factory DimensionVector({
    FractionValue? length,
    FractionValue? mass,
    FractionValue? time,
    FractionValue? current,
    FractionValue? temperature,
    FractionValue? amount,
    FractionValue? luminousIntensity,
  }) {
    final l = length ?? FractionValue.zero;
    final m = mass ?? FractionValue.zero;
    final t = time ?? FractionValue.zero;
    final i = current ?? FractionValue.zero;
    final th = temperature ?? FractionValue.zero;
    final n = amount ?? FractionValue.zero;
    final j = luminousIntensity ?? FractionValue.zero;

    _assertBitLength(l);
    _assertBitLength(m);
    _assertBitLength(t);
    _assertBitLength(i);
    _assertBitLength(th);
    _assertBitLength(n);
    _assertBitLength(j);

    return DimensionVector._(
      length: l,
      mass: m,
      time: t,
      current: i,
      temperature: th,
      amount: n,
      luminousIntensity: j,
    );
  }

  /// Convenience factory for integer base dimensions.
  factory DimensionVector.fromInts({
    int length = 0,
    int mass = 0,
    int time = 0,
    int current = 0,
    int temperature = 0,
    int amount = 0,
    int luminousIntensity = 0,
  }) => DimensionVector(
    length: length == 0 ? FractionValue.zero : FractionValue.fromInts(length, 1),
    mass: mass == 0 ? FractionValue.zero : FractionValue.fromInts(mass, 1),
    time: time == 0 ? FractionValue.zero : FractionValue.fromInts(time, 1),
    current: current == 0 ? FractionValue.zero : FractionValue.fromInts(current, 1),
    temperature: temperature == 0 ? FractionValue.zero : FractionValue.fromInts(temperature, 1),
    amount: amount == 0 ? FractionValue.zero : FractionValue.fromInts(amount, 1),
    luminousIntensity: luminousIntensity == 0 ? FractionValue.zero : FractionValue.fromInts(luminousIntensity, 1),
  );

  /// Canonical dimensionless vector: L^0 M^0 T^0 I^0 Θ^0 N^0 J^0.
  static final DimensionVector dimensionless = DimensionVector._(
    length: FractionValue.zero,
    mass: FractionValue.zero,
    time: FractionValue.zero,
    current: FractionValue.zero,
    temperature: FractionValue.zero,
    amount: FractionValue.zero,
    luminousIntensity: FractionValue.zero,
  );

  /// True if all 7 base exponents are zero.
  bool get isDimensionless =>
      length.isZero &&
      mass.isZero &&
      time.isZero &&
      current.isZero &&
      temperature.isZero &&
      amount.isZero &&
      luminousIntensity.isZero;

  /// Dimensional multiplication: rational exponents add.
  DimensionVector multiply(DimensionVector other);

  /// Dimensional division: rational exponents subtract.
  DimensionVector divide(DimensionVector other);

  /// Dimensional power: rational exponents multiplied by scalar rational exponent.
  DimensionVector pow(FractionValue rationalExponent);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DimensionVector &&
          runtimeType == other.runtimeType &&
          length == other.length &&
          mass == other.mass &&
          time == other.time &&
          current == other.current &&
          temperature == other.temperature &&
          amount == other.amount &&
          luminousIntensity == other.luminousIntensity;

  @override
  int get hashCode => Object.hash(
    length,
    mass,
    time,
    current,
    temperature,
    amount,
    luminousIntensity,
  );

  /// Deterministic symbolic string representation (e.g. "L*M*T^-2" or "M*L^(-1/2)*T^-2").
  String toSymbolicString();

  static void _assertBitLength(FractionValue f) {
    if (f.numerator.bitLength > 1024 || f.denominator.bitLength > 1024) {
      throw const OverflowError(
        message: 'Dimensional exponent bit-length exceeded 1024-bit deterministic resource limit.',
      );
    }
  }
}
```

---

## 5. Unit Model, Registry & Exactness Audit

### 5.1 Formal Affine Conversion Equation & Single-Offset Invariant
`[NEW PHASE 11 DECISION — DEC-11-05]`  
Every unit defines its relationship to the coherent SI base or derived unit through an exact affine transformation parameterized by a multiplicative `scale` and an additive `offset`:

#### 1. Canonical Conversion Formula
Throughout NexaMath, affine unit transformation uses the standard canonical equation:
$$v_{\text{base}} = v \times \text{scale} + \text{offset}$$

#### 2. Inverse Conversion from Coherent Base Unit:
$$v = \frac{v_{\text{base}} - \text{offset}}{\text{scale}} = (v_{\text{base}} - \text{offset}) \times \frac{1}{\text{scale}}$$

#### 3. Single-Offset Application Invariant:
When converting between two units $u_1 \to u_2$ within the conversion pipeline:
$$v_2 = \frac{(v_1 \times \text{scale}_1 + \text{offset}_1) - \text{offset}_2}{\text{scale}_2}$$
* The forward offset $\text{offset}_1$ is applied **exactly once** during the reduction to base units.
* The inverse offset $\text{offset}_2$ is subtracted **exactly once** during the projection from base units to the target unit.
* Units are immutable value descriptors; conversions are orchestrated exclusively by `UnitConverter`.

#### 4. Absolute Temperature Parameters:
* **Celsius** (`degC`):
  * $\text{scale} = 1$
  * $\text{offset} = \frac{5463}{20} = 273.15\text{ K}$ (exact rational)
  * $T(\text{K}) = T(^\circ\text{C}) \times 1 + \frac{5463}{20}$
  * $T(^\circ\text{C}) = T(\text{K}) - \frac{5463}{20}$
* **Fahrenheit** (`degF`):
  * Standard definition: $T(^\circ\text{F}) = (T(\text{K}) - 273.15) \times \frac{9}{5} + 32$.
  * Canonical form $T(\text{K}) = T(^\circ\text{F}) \times \text{scale} + \text{offset}$:
    $$T(\text{K}) = (T(^\circ\text{F}) - 32) \times \frac{5}{9} + 273.15 = T(^\circ\text{F}) \times \frac{5}{9} + \left(273.15 - \frac{160}{9}\right)$$
    $$273.15 - \frac{160}{9} = \frac{5463}{20} - \frac{160}{9} = \frac{49167 - 3200}{180} = \frac{45967}{180}\text{ K}$$
  * Exact rational scale: $\text{scale} = \text{FractionValue.fromInts}(5, 9)$
  * Exact rational offset: $\text{offset} = \text{FractionValue.fromInts}(45967, 180) = 255.372\overline{2}\text{ K}$
  * Decimal approximation (for diagnostics/display only): $\approx 255.37222222222222\text{ K}$
  * Inversion to Fahrenheit:
    $$T(^\circ\text{F}) = \left(T(\text{K}) - \frac{45967}{180}\right) \times \frac{9}{5}$$

#### 5. Temperature Intervals vs. Absolute States:
For temperature intervals ($\Delta^\circ\text{C}$, $\Delta^\circ\text{F}$, $\Delta\text{K}$), the additive offset is identically zero ($\text{offset} = 0$):
$$\Delta T(\text{K}) = \Delta T(^\circ\text{C}) = \Delta T(^\circ\text{F}) \times \frac{5}{9}$$

### 5.2 Unit Model & Immutability Invariant
`[REVISION 5 AUDIT]`
To ensure deep immutability and prevent contradictory states:
1. `aliases` is wrapped as an unmodifiable collection: `Set.unmodifiable(aliases)`.
2. `isAffine` is strictly defined as `offset != IntegerValue.zero && !offset.isZero`, eliminating any potential contradiction between the flag and the offset value.

```dart
final class Unit {
  final String symbol;
  final String name;
  final DimensionVector dimension;
  final ScalarValue scale;
  final ScalarValue offset;
  final bool isAffine;
  final Set<String> aliases;

  Unit({
    required this.symbol,
    required this.name,
    required this.dimension,
    required this.scale,
    this.offset = IntegerValue.zero,
    Set<String> aliases = const {},
  }) : isAffine = offset != IntegerValue.zero && (offset is! FractionValue || !offset.isZero),
       aliases = Set.unmodifiable(aliases);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          dimension == other.dimension &&
          scale == other.scale &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(symbol, dimension, scale, offset);

  @override
  String toString() => symbol;
}
```

### 5.3 SI Decimal Prefix System & Bounded Scope
`[REVISION 5 AUDIT — 4.11]`  
Phase 11 implements a **bounded subset** of the SI decimal prefix system spanning from $10^{-24}$ to $10^{24}$:

| Prefix | Symbol | Exponent $n$ | Exact Multiplier $10^n$ |
|---|---|---|---|
| yotta | Y | $+24$ | $\text{IntegerValue}(10^{24})$ |
| zetta | Z | $+21$ | $\text{IntegerValue}(10^{21})$ |
| exa | E | $+18$ | $\text{IntegerValue}(10^{18})$ |
| peta | P | $+15$ | $\text{IntegerValue}(10^{15})$ |
| tera | T | $+12$ | $\text{IntegerValue}(10^{12})$ |
| giga | G | $+9$ | $\text{IntegerValue}(10^9)$ |
| mega | M | $+6$ | $\text{IntegerValue}(10^6)$ |
| kilo | k | $+3$ | $\text{IntegerValue}(10^3)$ |
| hecto | h | $+2$ | $\text{IntegerValue}(100)$ |
| deka | da | $+1$ | $\text{IntegerValue}(10)$ |
| deci | d | $-1$ | $\text{FractionValue.fromInts}(1, 10)$ |
| centi | c | $-2$ | $\text{FractionValue.fromInts}(1, 100)$ |
| milli | m | $-3$ | $\text{FractionValue.fromInts}(1, 1000)$ |
| micro | $\mu$ / u | $-6$ | $\text{FractionValue.fromInts}(1, 10^6)$ |
| nano | n | $-9$ | $\text{FractionValue.fromInts}(1, 10^9)$ |
| pico | p | $-12$ | $\text{FractionValue.fromInts}(1, 10^{12})$ |
| femto | f | $-15$ | $\text{FractionValue.fromInts}(1, 10^{15})$ |
| atto | a | $-18$ | $\text{FractionValue.fromInts}(1, 10^{18})$ |
| zepto | z | $-21$ | $\text{FractionValue.fromInts}(1, 10^{21})$ |
| yocto | y | $-24$ | $\text{FractionValue.fromInts}(1, 10^{24})$ |

* **Scope Rationale & 2022 CGPM Status**: In 2022, the 27th CGPM introduced extreme prefixes: ronna ($R, 10^{27}$), quetta ($Q, 10^{30}$), ronto ($r, 10^{-27}$), and quecto ($q, 10^{-30}$). To maintain deterministic prefix decomposition and prevent symbol collisions in standard engineering calculations, Phase 11 bounds prefix support to $10^{-24} \dots 10^{24}$. Extension to the 2022 extreme prefixes is explicitly **deferred** to a future phase.

### 5.4 Authoritative Unit Catalog & Exactness Audit
`[REVISION 5 CORRECTION — DEC-11-07 AUDIT]`  
Every unit factor is categorized as either a **definitionally exact standard** or a **conventional approximation**:

1. **SI Base Units**:
   * Meter (`m`), Kilogram (`kg`), Second (`s`), Ampere (`A`), Kelvin (`K`), Mole (`mol`), Candela (`cd`): All exact base units ($\text{scale} = 1, \text{offset} = 0$).
   * Gram (`g`): $\frac{1}{1000}\text{ kg}$ (exact rational).
   * Minute (`min` $= 60\text{ s}$), Hour (`h` $= 3600\text{ s}$), Day (`d` $= 86400\text{ s}$): Exact integer multiples.
2. **Coherent SI Derived Units**:
   * `Hz`, `N`, `Pa`, `J`, `W`, `C`, `V`, `F`, `Ω`, `S`, `Wb`, `T`, `H`, `lm`, `lx`: All coherent with $\text{scale} = 1$ (exact).
3. **Imperial & US Customary Units (Definitionally Exact)**:
   * **Length (International Yard Agreement 1959)**:
     * `in` $\equiv \frac{127}{5000}\text{ m} = 0.0254\text{ m}$ (exact rational).
     * `ft` $\equiv 12\text{ in} = \frac{381}{1250}\text{ m} = 0.3048\text{ m}$ (exact rational).
     * `yd` $\equiv 3\text{ ft} = \frac{1143}{1250}\text{ m} = 0.9144\text{ m}$ (exact rational).
     * `mi` $\equiv 5280\text{ ft} = \frac{201168}{125}\text{ m} = 1609.344\text{ m}$ (exact rational).
   * **Mass (International Avoirdupois Pound 1959)**:
     * `lb` / `lbm` $\equiv \frac{45359237}{100000000}\text{ kg} = 0.45359237\text{ kg}$ (exact rational).
     * `oz` $\equiv \frac{1}{16}\text{ lb} = \frac{45359237}{1600000000}\text{ kg}$ (exact rational).
   * **Force & Pressure**:
     * Standard acceleration of gravity: $g_0 \equiv \frac{196133}{20000}\text{ m/s}^2 = 9.80665\text{ m/s}^2$ (exact standard).
     * `lbf` $\equiv \text{lbm} \times g_0$ (exact rational).
     * `psi` $\equiv \text{lbf}/\text{in}^2 = \frac{45359237 \times 196133 \times 5000^2}{100000000 \times 20000 \times 127^2}\text{ Pa}$ (exact rational).
     * `bar` $\equiv 10^5\text{ Pa}$ (exact integer).
     * `atm` $\equiv 101325\text{ Pa}$ (exact integer).
   * **Power & Volume**:
     * `hp` $\equiv 550\text{ ft}\cdot\text{lbf}/\text{s} = 745.69987158227022\text{ W}$ (exact rational).
     * `L` $\equiv \frac{1}{1000}\text{ m}^3$ (exact rational).
     * `gal` (US liquid) $\equiv 231\text{ in}^3 = \frac{473176473}{125000000000}\text{ m}^3 = 3.785411784\text{ L}$ (exact rational).
4. **Energy Units & BTU Audit**:
   * `cal` $\equiv$ **Thermochemical calorie** $\equiv 4.184\text{ J} = \frac{523}{125}\text{ J}$ (exact rational by definition).
   * **BTU Conventions Audit**:
     * *Convention A (International Steam Table / 5th International Conference 1956)*: $1\text{ BTU}_{\text{IT}} \equiv 1055.05585262\text{ J}$ (exact by international convention based on $1\text{ lb} \times 1^\circ\text{F}$ under $2.326\text{ J/g}$).
     * *Convention B (Conventional Rounded Value)*: $1055.056\text{ J} = \frac{131882}{125}\text{ J}$. This terminating decimal is a rounded engineering approximation, **not** an exact physical standard.
     * *Convention C (Thermochemical BTU)*: $1\text{ BTU}_{\text{th}} \approx 1054.350\text{ J}$.
     * **Phase 11 Resolution**: The standard catalog adopts **ISO 31-4 / IT BTU** with exact terminating definition:
       $$\text{scale} = \text{DecimalValue.parse}("1055.05585262") \text{ or exact rational equivalent}$$
       If rational approximation is used, it must be accompanied by `CalculationMetadata` indicating approximation. Owner approval required under `DEC-11-07`.
   * `kWh` $\equiv 3.6 \times 10^6\text{ J} = 3600000\text{ J}$ (exact integer).
5. **Angle Units**:
   * `rad`: Canonical dimensionless angle unit ($L^0 M^0 T^0$, $\text{scale} = 1$).
   * `deg` / `°`: $\frac{\pi}{180}\text{ rad}$ (approximate numerical conversion using `DecimalValue`, `isExact: false`, accompanied by `NumericalApproximationWarning`).

### 5.5 Compound Units Architecture & Affine Unit Prohibition
1. **Catalog vs. Dynamic Composition**: Phase 11 supports both explicit catalog entries (`N`, `J`, `W`, `psi`) and dynamic composition (`kg*m/s^2`, `kW·h`).
2. **Properties of Composed Units**:
   * Combined dimension vector: $D(u_1 \times u_2) = D(u_1).\text{multiply}(D(u_2))$; $D(u_1 / u_2) = D(u_1).\text{divide}(D(u_2))$.
   * Combined scale factor: $\text{scale}(u_1 \times u_2) = \text{scale}_1 \times \text{scale}_2$; $\text{scale}(u_1 / u_2) = \text{scale}_1 / \text{scale}_2$.
3. **Strict Prohibition of Affine Units in Compound Expressions**:
   Affine units (`degC`, `degF`) possess non-zero additive offsets that do not scale linearly under multiplication or division.
   Therefore, compound expressions containing affine units (such as `degC/s`, `kg*degC`, or `W/m/degC`) are **strictly prohibited** and fail with:
   $$\text{DomainError}(message: 'Affine units (°C, °F) cannot form compound units; use absolute Kelvin (K) or temperature intervals (Δ°C).') $$

---

## 6. Quantity Model & QuantityKind Semantics

### 6.1 `QuantityKind` Domain Concept
`[NEW PHASE 11 DECISION — DEC-11-03]`  
To eliminate physical ambiguities in affine arithmetic, `Quantity` includes an explicit `QuantityKind`:

```dart
enum QuantityKind {
  /// Standard physical quantity (e.g., 5 meters, 10 newtons, 300 kelvins).
  ordinary,

  /// Absolute thermodynamic temperature state point (e.g., 20 °C, 68 °F, 293.15 K).
  absoluteTemperature,

  /// Relative temperature difference / interval (e.g., Δ5 °C, Δ9 °F, Δ5 K).
  temperatureInterval,
}
```

### 6.2 Construction & Invariant Validation
`[REVISION 5 VALIDATION ENFORCEMENT]`
A quantity must not contradict its unit's affine status:
1. If `unit.isAffine == true`, `kind` must be `QuantityKind.absoluteTemperature`.
2. If `unit.isAffine == false` and dimension is temperature ($\Theta$), `kind` can be `ordinary` (for Kelvin), `absoluteTemperature` (for Kelvin state), or `temperatureInterval` (for $\Delta\text{K}$).
3. Attempting to construct `Quantity` with an affine unit and `ordinary` or `temperatureInterval` throws `ArgumentError`.

```dart
final class Quantity extends MathValue {
  final ScalarValue value;
  final Unit unit;
  final QuantityKind kind;

  Quantity({
    required this.value,
    required this.unit,
    this.kind = QuantityKind.ordinary,
  }) {
    if (unit.isAffine && kind != QuantityKind.absoluteTemperature) {
      throw ArgumentError(
        'Unit ${unit.symbol} is affine and requires QuantityKind.absoluteTemperature.',
      );
    }
  }

  DimensionVector get dimension => unit.dimension;
  bool get isDimensionless => dimension.isDimensionless;
  bool get isAbsoluteTemperature => kind == QuantityKind.absoluteTemperature;
  bool get isTemperatureInterval => kind == QuantityKind.temperatureInterval;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Quantity) return false;
    return value == other.value && unit == other.unit && kind == other.kind;
  }

  @override
  int get hashCode => Object.hash(value, unit, kind);

  @override
  String toString() {
    final prefix = kind == QuantityKind.temperatureInterval ? 'Δ' : '';
    return '$value $prefix${unit.symbol}';
  }
}
```

---

## 7. Reconciled Temperature Arithmetic & Scalar Operations

### 7.1 Formal Physical Rules Matrix
`[REVISION 5 RECONCILIATION]`  
Scalar operations and arithmetic on temperatures are strictly categorized:

| Left Operand | Operator | Right Operand | Result Kind | Physical Behavior & Error Specification |
|---|:---:|---|---|---|
| **Absolute** ($T_1$) | `+` | **Absolute** ($T_2$) | **REJECTED** | Fails with `DomainError(message: 'Addition of two absolute temperatures is physically undefined; use temperature intervals.')`. |
| **Absolute** ($T_1$) | `-` | **Absolute** ($T_2$) | **Interval** ($\Delta T$) | Computes temperature difference: converts both to base Kelvin, subtracts, and returns interval in Left's interval unit: $(T_1 - T_2)_{\text{K}} \to \Delta T$. |
| **Absolute** ($T$) | `+` | **Interval** ($\Delta T$) | **Absolute** ($T'$) | Offsets temperature state: $\Delta T$ is converted to Left's interval scale **without offset**, then added: $T' = T + \Delta T_{\text{converted}}$. Result is an absolute temperature in Left's unit. |
| **Absolute** ($T$) | `-` | **Interval** ($\Delta T$) | **Absolute** ($T''$) | Offsets temperature state: $T'' = T - \Delta T_{\text{converted}}$. Result is an absolute temperature in Left's unit. |
| **Interval** ($\Delta T_1$) | `+` | **Interval** ($\Delta T_2$) | **Interval** ($\Delta T_3$) | Additive combination of temperature steps: $\Delta T_3 = \Delta T_1 + \Delta T_2$. |
| **Interval** ($\Delta T_1$) | `-` | **Interval** ($\Delta T_2$) | **Interval** ($\Delta T_3$) | Subtractive combination: $\Delta T_3 = \Delta T_1 - \Delta T_2$. |
| **Interval** ($\Delta T$) | `+` | **Absolute** ($T$) | **Absolute** ($T'$) | Commutative addition with absolute state: $\Delta T + T = T + \Delta T$. |
| **Interval** ($\Delta T$) | `-` | **Absolute** ($T$) | **REJECTED** | Subtracting an absolute state from a relative interval is physically undefined $\implies \text{DomainError}$. |
| **Absolute** ($T$) | `*` | **Scalar** ($s$) | **REJECTED** | Scaling an offset temperature directly is physically invalid (e.g. $2 \times 20^\circ\text{C} \ne 40^\circ\text{C}$). Fails with `DomainError(message: 'Direct scalar multiplication of absolute temperature is undefined. Convert to Kelvin first.')`. |
| **Scalar** ($s$) | `*` | **Absolute** ($T$) | **REJECTED** | Commutative rejection $\implies \text{DomainError}$. |
| **Absolute** ($T$) | `/` | **Scalar** ($s$) | **REJECTED** | Fails with `DomainError(message: 'Direct scalar division of absolute temperature is undefined.')`. |
| **Scalar** ($s$) | `/` | **Absolute** ($T$) | **REJECTED** | Fails with `DomainError`. |
| **Interval** ($\Delta T$) | `*` | **Scalar** ($s$) | **Interval** | Linear interval scaling: $s \times \Delta 5^\circ\text{C} = \Delta 10^\circ\text{C}$. Unit and interval kind preserved. |
| **Scalar** ($s$) | `*` | **Interval** ($\Delta T$) | **Interval** | Commutative interval scaling. |
| **Interval** ($\Delta T$) | `/` | **Scalar** ($s$) | **Interval** | Linear interval division. |
| **Scalar** ($s$) | `/` | **Interval** ($\Delta T$) | **Quantity** | Inverts interval dimension ($\Theta^{-1}$). |

---

## 8. Quantity Arithmetic & Dimensional Operations

### 8.1 Addition & Subtraction ($q_1 \pm q_2$)
1. **Dimension Verification**: Requires identical dimensions: $D(q_1) == D(q_2)$. If dimensions differ, fails with `DimensionMismatchError`.
2. **Kind Verification**: Applies Section 7.1 rules if either operand is temperature-related.
3. **Unit Conversion**:
   * If $q_1.\text{unit} == q_2.\text{unit}$, performs scalar arithmetic: $v_{\text{res}} = v_1 \pm v_2$.
   * If units differ, converts $q_2$ to $q_1.\text{unit}$ via `convert(q_2, q_1.unit)` and performs scalar addition.
4. **Result**: $\text{Quantity}(v_{\text{res}}, q_1.\text{unit}, \text{kind})$.

### 8.2 Multiplication ($q_1 \times q_2$) & Base-Normalized Result Assignment
`[REVISION 5 CORRECTION — 4.14]`  
1. **Temperature Rejection**: Absolute temperatures cannot participate in compound multiplication. Fails with `DomainError`.
2. **Dimension Computation**: $D_{\text{res}} = D(q_1).\text{multiply}(D(q_2))$.
3. **Base-Normalized Magnitude & Assigned Unit**:
   * Evaluates components by converting both operands to base units: $v_{1,\text{base}} = \text{toBase}(q_1).\text{value}$, $v_{2,\text{base}} = \text{toBase}(q_2).\text{value}$.
   * The compound magnitude in base units is $v_{\text{base}} = v_{1,\text{base}} \times v_{2,\text{base}}$.
   * **Assigned Unit**: If both operands share units with a direct compound form (e.g. $\text{kW} \times \text{h}$), the resulting magnitude is $v_1 \times v_2$ in the composed unit $\text{kW}\cdot\text{h}$. If evaluated at base level, the resulting magnitude is paired strictly with the coherent SI base compound unit ($\text{kg}\cdot\text{m}^2/\text{s}^2 \equiv \text{J}$). Under no circumstances is a base magnitude paired with an unconverted original unit.

### 8.3 Division ($q_1 / q_2$)
1. **Division by Zero**: If $q_2.\text{value} == 0$, fails with `DivisionByZeroError`.
2. **Temperature Rejection**: Absolute temperatures cannot participate in division. Fails with `DomainError`.
3. **Dimension Computation**: $D_{\text{res}} = D(q_1).\text{divide}(D(q_2))$.
4. **Dimensionless Collapse**:
   * If $D_{\text{res}}.\text{isDimensionless}$, physical dimensions cancel completely.
   * Result **collapses to a pure scalar `ScalarValue`** (e.g. $\frac{10\text{ m}}{2\text{ m}} = 5$, $\frac{100\text{ cm}}{1\text{ m}} = 1$).
   * If dimensions do not cancel, the result remains a `Quantity` with compound dimension.

### 8.4 Powers ($q^r$) & Rational-Power Real Branch Rules
`[REVISION 5 AUDIT — DEC-11-08]`  
Raising a quantity $q$ with magnitude $v$ and unit $u$ to a rational exponent $r = p/q$:

1. **Canonical Exponent Precondition**:
   * Exponent must be represented as a canonical reduced `FractionValue` $r = p/q$ with $q \ge 1$ and $\gcd(|p|, q) == 1$.
   * Unreduced input (e.g. $2/6$) is reduced to $1/3$ before branch evaluation.
2. **Dimensionless Precondition**: Exponent must be dimensionless; dimensional exponents fail with `DomainError`.
3. **Real Branch Evaluation Rules**:
   * **Case $v \ge 0$**: Real power is uniquely defined in $\mathbb{R}$: $v^{p/q} = (\sqrt[q]{v})^p$.
   * **Case $v < 0$ and $q$ is even** ($q \equiv 0 \pmod 2$):
     * The $q$-th root of a negative real number does not exist in $\mathbb{R}$.
     * Example: $(-8)^{1/2}$ fails with:
       $$\text{DomainError}(message: 'Even root of negative quantity is undefined in real domain.', functionName: 'pow', argument: '$v^{$p/$q}') $$
   * **Case $v < 0$ and $q$ is odd** ($q \equiv 1 \pmod 2$):
     * Real $q$-th root is uniquely defined in $\mathbb{R}$ as negative: $\sqrt[q]{v} = -\sqrt[q]{|v|}$.
     * If $p$ is odd: $v^{p/q} = -(|v|^{p/q})$. (Example: $(-8\text{ m}^3)^{1/3} = -2\text{ m}$, $(-8)^{2/6} \to (-8)^{1/3} = -2\text{ m}$).
     * If $p$ is even: $v^{p/q} = +(|v|^{p/q})$. (Example: $(-8)^{2/3} = 4\text{ m}^2$).
4. **Zero Base**:
   * If $v == 0$ and $p > 0$: Returns zero quantity with dimension $D_{\text{res}}$.
   * If $v == 0$ and $p < 0$: Fails with `DivisionByZeroError`.
   * If $v == 0$ and $p == 0$: Returns dimensionless scalar 1.

---

## 9. Mathematical Functions Interaction Matrix

| Function Category | Function Names | Input Constraint | Output Dimension / Value | Diagnostic Behavior |
|---|---|---|---|---|
| **Trigonometric** | `sin`, `cos`, `tan`, `sec`, `csc`, `cot` | **Dimensionless or Angle (`rad`, `deg`, `grad`)** | Dimensionless `ScalarValue` | Non-angle dimensional quantities fail with `DimensionMismatchError`. Angles converted to radians before evaluation. |
| **Inverse Trigonometric** | `asin`, `acos`, `atan`, `atan2` | **Strictly Dimensionless** | Angle `Quantity` in radians (`rad`) | Arguments must be dimensionless ratio. $\text{asin}(5\text{ m})$ fails with `DimensionMismatchError`. |
| **Exponential & Logarithmic** | `exp`, `ln`, `log`, `log10`, `log2` | **Strictly Dimensionless** | Dimensionless `ScalarValue` | Arguments must be dimensionless. $\ln(10\text{ m})$ fails with `DimensionMismatchError`. |
| **Square Root & $n$-th Root** | `sqrt`, `cbrt`, `root(n)` | Satisfies Section 8.4 real-branch rules | $D^{1/n}$ | Roots divide dimension vector by $n$: $\sqrt{4\text{ m}^2} = 2\text{ m}$; $\sqrt{9\text{ m}} = 3\text{ m}^{1/2}$. |
| **Magnitude & Truncation** | `abs`, `floor`, `ceil`, `round`, `truncate` | Any physical quantity | Same unit, magnitude basis, and kind | Evaluated on magnitude in the **current declared unit**: $\text{floor}(3.7\text{ m}) = 3\text{ m}$; $\text{floor}(370\text{ cm}) = 370\text{ cm}$. Preserves `Unit` and `QuantityKind`. |

---

## 10. Corrected EBNF Grammar & Unit Expression Parsing

### 10.1 Two-Tier Parsing Architecture
`[NEW PHASE 11 DECISION — DEC-11-09]`  
1. **Tier 1: Atomic Name & Alias Resolution (`resolveUnit`)**:
   Matches full registered unit names, symbols, and multiword aliases (e.g. `degree Celsius` $\to \text{degC}$, `meter per second` $\to \text{m/s}$) as atomic entities without token splitting.
2. **Tier 2: Composite Expression Parser (`parseUnit`)**:
   Parses compound expressions with explicit operators and implicit whitespace juxtaposition.

### 10.2 Corrected EBNF Grammar Specification
`[REVISION 5 GRAMMAR CORRECTION]`  
The grammar explicitly supports parenthesized integer and rational exponents, signed values, and parenthesized compound subexpressions:

```ebnf
UnitExpression     ::= MultiplicativeExpr ;
MultiplicativeExpr ::= DivisionExpr ( ( '*' | '·' | WHITESPACE ) DivisionExpr )* ;
DivisionExpr       ::= PowerExpr ( '/' PowerExpr )* ;
PowerExpr          ::= PrimaryTerm ( '^' Exponent )? ;
PrimaryTerm        ::= Identifier | '(' UnitExpression ')' ;
Exponent           ::= SignedInteger 
                     | '(' SignedInteger ( '/' UnsignedInteger )? ')' ;
SignedInteger      ::= ('+' | '-')? [0-9]+ ;
UnsignedInteger    ::= [1-9][0-9]* ;
Identifier         ::= [a-zA-Z_°Ωμ][a-zA-Z0-9_°Ωμ]* ;
WHITESPACE         ::= [ \t]+ ;
```

### 10.3 Grammar Invariants & Operator Disambiguation:
1. **Whitespace Disambiguation**:
   Whitespace is tokenized as an operator **only** when adjacent to two unit terms (`kg m`). Whitespace surrounding explicit operators (`*`, `·`, `/`) is ignored as formatting trivia and does **not** introduce extraneous multiplication terms (e.g. `kg m / s^2` parses as `(kg * m) / (s^2)`).
2. **Exponent Rational Parentheses**:
   * Valid: `m^2`, `m^-2`, `m^(1/2)`, `m^(-1/2)`, `m^(+3/4)`.
   * Invalid: `m^1/2` (parsed as `(m^1) / 2`, failing because 2 is not a unit), `m^(1/0)` (rejected with `DivisionByZeroError` or `SyntaxError`).
3. **Greedy Identifiers**:
   Alphanumeric strings are greedily scanned. `kgm` is scanned as a single identifier, failing lookup as an unknown unit ($\implies \text{InvalidUnitError}$), not split into `kg * m`.
4. **Division Left-Associativity**:
   `m/s/s` evaluates left-associatively as `(m/s)/s` $\equiv \text{m/s}^2$.

---

## 11. Conversion, Exactness & Resource Policy

### 11.1 Precision Model by Domain
Phase 11 strictly partitions exactness and resource limits across 5 distinct domains:

| Domain | Representation | Precision Policy | Overflow / Limit Policy |
|---|---|---|---|
| **1. Dimension Exponents** | `FractionValue` | **Strictly Exact**. Denominator $> 0$, $\gcd = 1$. | Exponents exceeding 1,024 bits fail with **`OverflowError`**. Approximation is forbidden. |
| **2. Rational Conversion Factors** | `FractionValue` | **Strictly Exact**. Standard integer/fraction scale factors ($1\text{ in} = \frac{127}{5000}\text{ m}$). | Scale factor components exceeding 1,024 bits fail with **`OverflowError`**. |
| **3. Irrational Conversion Factors** | `DecimalValue` | **High-Precision Approximation**. Used for $\pi$-derived factors ($\text{deg} \to \text{rad}$). | Emits `CalculationMetadata` with `isExact: false` and `NumericalApproximationWarning`. |
| **4. Quantity Magnitudes** | `ScalarValue` (`IntegerValue`, `FractionValue`, `DecimalValue`) | Preserves incoming `ScalarValue` precision. Chained rational operations maintain exact fractions. | If magnitude rational bits exceed 1,024 bits, transitions to `DecimalValue` with `PrecisionLossWarning`. |
| **5. Round-Trip Invariant** | Linear rational conversions | $\text{convert}(\text{convert}(q, u_2), u_1) == q$. | Lossless identity guaranteed strictly for rational linear units within 1024-bit limits. |

---

## 12. Derived-Unit Canonicalization, Formatting & Semantic Meaning

### 12.1 Canonicalization vs. Semantic Identity
`[REVISION 5 CORRECTION]`  
Quantities sharing identical dimension vectors ($M L^2 T^{-2}$) represent fundamentally different physical concepts:
* **Energy / Work**: Coherent unit Joule (`J`), scalar quantity.
* **Torque / Moment**: Conventional unit Newton-meter (`N·m`), moment/vector quantity.

#### Formatting & Simplification Boundaries:
1. **No Silent Transmutation**: The engine never silently converts `N*m` to `J`, or vice versa.
2. **Explicit Target Simplification (`simplify`)**: When `simplify(q)` is invoked, it suggests the coherent derived unit matching the dimension vector, but does not alter the underlying semantic nature unless requested.
3. **Format Integrity**: Default formatting renders the unit declared on the `Quantity`. Composed units preserve their user-specified expression structure unless explicitly normalized.

---

## 13. Equality, Compatibility & Comparison Model

### 13.1 Three Distinct Comparison Concepts
`[REVISION 5 CLARIFICATION]`  
To prevent semantic conflation:
1. **Dimensional Compatibility (`areCompatible(u1, u2)`)**:
   Evaluates purely whether $D(u_1) == D(u_2)$. Both Energy and Torque are dimensionally compatible.
2. **Numeric Equivalence at Base (`areNumericallyEqual(q1, q2)`)**:
   Evaluates whether $D(q_1) == D(q_2)$ and $\text{toBase}(q1).\text{value} == \text{toBase}(q2).\text{value}$.
3. **Semantic Physical Equality (`areEqual(q1, q2)`)**:
   Evaluates whether two quantities represent the same physical state:
   * Requires $D(q_1) == D(q_2)$.
   * Requires compatible `QuantityKind` (e.g. $20^\circ\text{C} \ne \Delta 20^\circ\text{C}$).
   * Evaluates magnitude equality using exact rational comparison or repository `PrecisionContext.zeroTolerance` ($10^{-15}$):
     $$|v_{1,\text{base}} - v_{2,\text{base}}| \le \text{zeroTolerance}$$

---

## 14. UnitEngine Contract

### 14.1 Public Façade Interface
Defined in `lib/mathematical_core/units/unit_engine.dart`:

```dart
abstract interface class UnitEngine {
  /// Converts a physical [quantity] into the [target] unit.
  MathResult<Quantity> convert(Quantity quantity, Unit target);

  /// Converts a quantity to its canonical SI coherent base representation.
  MathResult<Quantity> toBase(Quantity quantity);

  /// Simplifies a compound quantity to an authoritative coherent derived unit if one exists.
  MathResult<Quantity> simplify(Quantity quantity);

  /// Adds two physical quantities, converting [right] to [left]'s unit.
  MathResult<Quantity> add(Quantity left, Quantity right);

  /// Subtracts [right] from [left], converting [right] to [left]'s unit.
  MathResult<Quantity> subtract(Quantity left, Quantity right);

  /// Multiplies two physical quantities, computing compound dimension.
  MathResult<Quantity> multiply(Quantity left, Quantity right);

  /// Multiplies a physical quantity by a scalar.
  MathResult<Quantity> multiplyScalar(Quantity quantity, ScalarValue scalar);

  /// Divides [left] by [right]. Collapses to pure [ScalarValue] if dimensionless.
  MathResult<MathValue> divide(Quantity left, Quantity right);

  /// Divides a physical quantity by a scalar.
  MathResult<Quantity> divideScalar(Quantity quantity, ScalarValue scalar);

  /// Raises [quantity] to a dimensionless rational power [power].
  MathResult<Quantity> pow(Quantity quantity, FractionValue power);

  /// Parses a composite unit expression string (e.g., "m/s^2", "m^(1/2)").
  MathResult<Unit> parseUnit(String expression);

  /// Parses a complete quantity string (e.g., "9.81 m/s^2", "20 degC").
  MathResult<Quantity> parseQuantity(String expression);

  /// Resolves a unit by its exact symbol or registered alias.
  MathResult<Unit> resolveUnit(String symbolOrName);

  /// Verifies dimensional compatibility between two units.
  bool areCompatible(Unit u1, Unit u2);

  /// Evaluates semantic physical equality between two quantities after base normalization.
  MathResult<bool> areEqual(Quantity q1, Quantity q2);

  /// Formats a quantity to a clean scientific string.
  String formatQuantity(Quantity quantity);
}
```

---

## 15. Read-Only Repository Compatibility Audit

| Specification Contract / API | Actual Repository Symbol & File Location | Line Numbers | Verification Status | Discrepancy & Resolution |
|---|---|---|---|---|
| `MathValue` | `abstract class MathValue`<br>[`lib/mathematical_core/common/math_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/common/math_value.dart) | Lines 6–8 | **CONFIRMED** | Direct compatibility. Unsealed class explicitly designed for quantities. |
| `ScalarValue` | `abstract class ScalarValue extends MathValue`<br>[`lib/mathematical_core/common/math_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/common/math_value.dart) | Lines 11–13 | **CONFIRMED** | Direct compatibility. Magnitude superclass for `Quantity`. |
| `FractionValue` | `final class FractionValue extends ScalarValue`<br>[`lib/mathematical_core/numeric/values/fraction_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/fraction_value.dart) | Lines 10–53 | **CONFIRMED** | Replaces `(int, int)` with arbitrary precision BigInt backing for exponents. |
| `IntegerValue` | `final class IntegerValue extends ScalarValue`<br>[`lib/mathematical_core/numeric/values/integer_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/integer_value.dart) | Lines 7–13 | **CONFIRMED** | Direct compatibility. BigInt-backed integer representation. |
| `DecimalValue` | `final class DecimalValue extends ScalarValue`<br>[`lib/mathematical_core/numeric/values/decimal_value.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/numeric/values/decimal_value.dart) | Lines 20–40 | **CONFIRMED** | Direct compatibility. High-precision decimal for irrational factors. |
| `MathResult<T>` | `sealed class MathResult<T>`<br>[`lib/core/result/math_result.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/result/math_result.dart) | Lines 7–20 | **CONFIRMED** | Direct compatibility. Sealed functional result type. |
| `CalculationMetadata` | `final class CalculationMetadata`<br>[`lib/core/result/calculation_metadata.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/result/calculation_metadata.dart) | Lines 37–51 | **CONFIRMED** | Direct compatibility. Contains `isExact` and warnings list. |
| `PrecisionContext` | `final class PrecisionContext`<br>[`lib/mathematical_core/common/precision_context.dart`](file:///d:/Programming%20projects/nexa_math/lib/mathematical_core/common/precision_context.dart) | Lines 23–36 | **CONFIRMED** | Direct compatibility. Authoritative `zeroTolerance = 1e-15` used for equality. |
| `DimensionMismatchError` | `final class DimensionMismatchError extends MathError`<br>[`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) | Lines 123–134 | **CONFIRMED** | Direct compatibility. Concrete error carrying expected/actual dimension strings. |
| `InvalidUnitError` | `final class InvalidUnitError extends MathError`<br>[`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) | Lines 137–145 | **CONFIRMED** | Direct compatibility. Concrete error carrying `unit`. |
| `DomainError` | `final class DomainError extends MathError`<br>[`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) | Lines 33–43 | **CONFIRMED** | Direct compatibility. Used for invalid temperature operations. |
| `DivisionByZeroError` | `final class DivisionByZeroError extends MathError`<br>[`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) | Lines 25–30 | **CONFIRMED** | Direct compatibility. |
| `OverflowError` | `final class OverflowError extends MathError`<br>[`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) | Lines 46–52 | **CONFIRMED** | Direct compatibility. 1,024-bit rational overflow failure. |
| `SyntaxError` | `final class SyntaxError extends MathError`<br>[`lib/core/errors/math_error.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/errors/math_error.dart) | Lines 75–85 | **CONFIRMED** | Direct compatibility. Unit expression syntax error. |
| `PrecisionLossWarning` | `final class PrecisionLossWarning extends MathWarning`<br>[`lib/core/result/math_warning.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/result/math_warning.dart) | Lines 16–21 | **CONFIRMED** | Direct compatibility. Emitted when magnitude exceeds 1024 bits. |
| `NumericalApproximationWarning` | `final class NumericalApproximationWarning extends MathWarning`<br>[`lib/core/result/math_warning.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/result/math_warning.dart) | Lines 32–37 | **CONFIRMED** | Direct compatibility. Emitted for irrational conversions. |
| `UnitConversionWarning` | `final class UnitConversionWarning extends MathWarning`<br>[`lib/core/result/math_warning.dart`](file:///d:/Programming%20projects/nexa_math/lib/core/result/math_warning.dart) | Lines 48–53 | **CONFIRMED** | Direct compatibility. |
| `DimensionVector`, `Unit`, `Quantity`, `QuantityKind`, `UnitEngine` | Proposed new contracts | N/A | **PROPOSED** | Target contracts for Phase 11. Not yet implemented. |

---

## 16. Architecture & Package Structure

```text
lib/mathematical_core/units/
├── dimension_vector.dart           // 7-tuple BigInt-backed FractionValue dimension vector model
├── unit.dart                       // Unit model with scale, offset, and immutable aliases
├── quantity.dart                   // Quantity MathValue model & QuantityKind enum
├── unit_system.dart                // BaseDimension enum & ISQ constants
├── unit_registry.dart              // Built-in SI, Imperial, and named unit registry
├── unit_converter.dart             // Exact rational and affine conversion pipeline
├── parser/
│   ├── unit_token.dart             // Token types for unit lexing
│   ├── unit_lexer.dart             // Lexical analyzer for unit strings (whitespace handling)
│   └── unit_parser.dart            // Recursive descent parser supporting parenthesized exponents
├── unit_engine.dart                // Abstract interface facade
├── default_unit_engine.dart        // Concrete implementation coordinating components
└── units.dart                      // Barrel export file for the units module
```

---

## 17. Invariant-Driven Testing & Acceptance Specification

Future Phase 11 implementation must satisfy the following formal mathematical invariants:

### 17.1 Dimension Invariants
1. **Multiplication Associativity & Commutativity**:
   $$D_1.\text{multiply}(D_2) == D_2.\text{multiply}(D_1)$$
   $$(D_1.\text{multiply}(D_2)).\text{multiply}(D_3) == D_1.\text{multiply}(D_2.\text{multiply}(D_3))$$
2. **Division Inverse**:
   $$D.\text{divide}(D) == \text{DimensionVector.dimensionless}$$
3. **Power Composition**:
   $$(D.\text{pow}(r_1)).\text{pow}(r_2) == D.\text{pow}(r_1 \times r_2)$$
4. **Canonical Reduction**: Exponent numerators and denominators must always satisfy $\gcd(|p|, q) == 1$ and $q \ge 1$.
5. **Deterministic Overflow**: Exponent components $> 1024$ bits fail with `OverflowError`.

### 17.2 Conversion Invariants
1. **Round-Trip Identity**: For all rational linear conversions within 1024-bit limits: $\text{convert}(\text{convert}(q, u_2), u_1) == q$.
2. **Base Conversion Consistency**: $\text{toBase}(1\text{ in}) == \text{Quantity}(\text{FractionValue.fromInts}(127, 5000), \text{m})$.
3. **Prefix Linear Scaling**: $\text{convert}(1\text{ km}, \text{m}) == \text{Quantity}(1000, \text{m})$.
4. **Affine Temperature Consistency**:
   * $0\ ^\circ\text{C} = 273.15\text{ K}$, $100\ ^\circ\text{C} = 373.15\text{ K}$.
   * $32\ ^\circ\text{F} = 0\ ^\circ\text{C}$, $212\ ^\circ\text{F} = 100\ ^\circ\text{C}$.
   * $-40\ ^\circ\text{C} = -40\ ^\circ\text{F}$.
   * Single-offset application: converting $100^\circ\text{C} \to ^\circ\text{F} \to ^\circ\text{C}$ yields exactly $100^\circ\text{C}$.

### 17.3 Quantity Arithmetic & Kind Invariants
1. **Absolute Temperature Addition Rejection**: $T_1 + T_2 \implies \text{DomainError}$.
2. **Absolute Temperature Scaling Rejection**: $T \times s \implies \text{DomainError}$; $T / s \implies \text{DomainError}$.
3. **Temperature Difference Extraction**: $100\ ^\circ\text{C} - 20\ ^\circ\text{C} = \Delta 80\ ^\circ\text{C} = \Delta 80\text{ K}$ (`QuantityKind.temperatureInterval`).
4. **Offset State Arithmetic**: $20\ ^\circ\text{C} + \Delta 5\ ^\circ\text{C} = 25\ ^\circ\text{C}$ (`QuantityKind.absoluteTemperature`).
5. **Cross-Scale Offset Isolation**: $20\ ^\circ\text{C} + \Delta 9\ ^\circ\text{F} = 20\ ^\circ\text{C} + \Delta 5\ ^\circ\text{C} = 25\ ^\circ\text{C}$.
6. **Dimension Mismatch Rejection**: $10\text{ m} + 5\text{ s} \implies \text{DimensionMismatchError}$.
7. **Dimensionless Division Collapse**: $\frac{10\text{ m}}{2\text{ m}} = 5$ (`IntegerValue(5)`, `ScalarValue`).
8. **Real Rational Powers**: $(-8\text{ m}^3)^{1/3} = -2\text{ m}$; $(-8\text{ m}^3)^{2/3} = 4\text{ m}^2$; $(-8\text{ m}^3)^{1/2} \implies \text{DomainError}$.

### 17.4 Parser Invariants
1. **Parenthesized Rational Exponents**: `m^(1/2)` parses to dimension $L^{1/2}$; `m^(-2)` parses to $L^{-2}$.
2. **Whitespace Disambiguation**: `kg m / s^2` parses as `(kg * m) / (s^2)`.
3. **Multiword Names**: `resolveUnit('degree Celsius')` resolves to Celsius before composite parsing.
4. **Invalid Syntax Rejection**: `m^(1/0)` and `m^1/2` fail with syntax/division errors.

### 17.5 Regression Invariant
* **483 / 483** pre-existing tests (Phases 0–10) must remain 100% passing.

---

## 18. Decision Register & Architectural Proposals

| Decision ID | Topic | Current Proposal | Mathematical & Architectural Implications | Evidence Needed | Remaining Ambiguity / Trade-Off | Recommended Decision | Status |
|---|---|---|---|---|---|---|:---:|
| **DEC-11-01** | **Dimensional Exponent Representation** | `FractionValue` (BigInt-backed) with canonical reduction $\gcd(|p|, q) == 1, q \ge 1$. | Eliminates 64-bit platform limitations of native Dart int; enforces 1,024-bit limits on Windows & Android; components $> 1024$ bits fail with `OverflowError`. | Code inspection of `lib/mathematical_core/numeric/values/fraction_value.dart`. | Reuses established repository rational model; slightly higher memory than raw 64-bit ints. | **Option B: FractionValue Exponents** | `PROPOSED — PENDING OWNER APPROVAL` |
| **DEC-11-02** | **Quantity Hierarchy Placement** | Direct subtype of `MathValue` (`final class Quantity extends MathValue`). | Non-scalar behavior preserved ($5\text{ m} + 3$ undefined). Compatible with unsealed `MathValue`. | Code inspection of `lib/mathematical_core/common/math_value.dart`. | Quantities cannot be passed directly where `ScalarValue` is strictly required. | **Option A: Direct subtype of MathValue** | `PROPOSED — PENDING OWNER APPROVAL` |
| **DEC-11-03** | **Affine Temperature Arithmetic Model** | Formal `QuantityKind` distinguishing `ordinary`, `absoluteTemperature`, and `temperatureInterval`. | Prevents physical nonsense addition ($T_1 + T_2 \implies \text{DomainError}$); extracts differences as intervals ($T_1 - T_2 = \Delta T$). | Standard in scientific software (GNU Units, Modelica, F# Units). | Requires extra enum field inside `Quantity`. | **Option B: Formal QuantityKind Distinction** | `PROPOSED — PENDING OWNER APPROVAL` |
| **DEC-11-04** | **Expression Engine Integration Boundary** | Autonomous `UnitEngine.parseQuantity` in Phase 11; defer Phase 3 `ExpressionParser` AST integration. | Protects sealed Phase 3 parser and 483 regression test baseline during Phase 11 development. | Expression engine tokenizer and parser contracts inspection. | Units cannot be entered in general mathematical expressions until Phase 11 integration bridge is built. | **Option B: Autonomous Unit Parser First** | `PROPOSED — PENDING OWNER APPROVAL` |
| **DEC-11-05** | **Affine Transformation Formula** | Canonical formula $v_{\text{base}} = v \times \text{scale} + \text{offset}$ with single-offset invariant. | Fahrenheit $\text{scale} = 5/9, \text{offset} = 45967/180$. Guarantees single-offset application during conversions. | Exact algebraic derivation of Fahrenheit-Kelvin linear relationship. | None; eliminates implementation inference. | **Option A: $v_{\text{base}} = v \times \text{scale} + \text{offset}$** | `PROPOSED — PENDING OWNER APPROVAL` |
| **DEC-11-06** | **Prefix Resolution Precedence** | Exact unit symbol match first, then longest valid prefix decomposition. | Resolves `Pa` as Pascal (not pico-Ampere) and `min` as minute (not milli-inch). | Prefix and base symbol catalog collisions analysis. | Prevents using `pA` as a shortcut for Pascal. | **Option B: Exact Match Precedence** | `PROPOSED — PENDING OWNER APPROVAL` |
| **DEC-11-07** | **Standard Catalog Physical Conventions** | Standardized conventions: thermochemical calorie, ISO IT BTU ($1055.05585262\text{ J}$), mechanical hp, US liquid gallon, avoirdupois pound. | All unit factors are exact standards; distinguishes exact definitions from rounded engineering values ($1055.056\text{ J}$). | ISO 31-4 and NIST SP 811 standards documents. | Owner must confirm whether ISO IT BTU ($1055.05585262\text{ J}$) or rounded $1055.056\text{ J}$ is preferred. | **Option B: Explicitly Standardized Conventions** | `PROPOSED — PENDING OWNER APPROVAL` |
| **DEC-11-08** | **Negative Base Rational Powers** | Real-branch evaluation ($q$ odd allows real root; $q$ even fails in real domain) after exponent reduction. | Accurately models real physical roots: $(-8\text{ m}^3)^{1/3} = -2\text{ m}$; $(-8)^{2/6} \to (-8)^{1/3} = -2$. Even roots fail with `DomainError`. | Real analysis theorems on fractional exponents. | Does not return complex numbers for real quantities. | **Option B: Real Branch Rules** | `PROPOSED — PENDING OWNER APPROVAL` |
| **DEC-11-09** | **Lexical Whitespace vs. Multiword Names** | Two-tier architecture: dedicated atomic name resolution (`resolveUnit`) followed by composite expression parser (`parseUnit`). | Multiword names (`degree Celsius`) resolve cleanly; composite expressions treat whitespace as juxtaposition multiplication. | Lexer grammar edge-case analysis. | Multiword compound expressions require quotes or symbol equivalents. | **Option B: Two-Tier Parsing Architecture** | `PROPOSED — PENDING OWNER APPROVAL` |

---

## 19. Implementation Readiness Gate

```text
Phase 11 — Units & Dimensional Analysis
────────────────────────────────────────
Specification: REVISION 5
Mathematical Consistency: VERIFIED & HARDENED
Repository API Compatibility: AUDITED READ-ONLY WITH CODE EVIDENCE
Decision Register: 9 PROPOSALS PENDING OWNER APPROVAL (DEC-11-01 through DEC-11-09)
Implementation Status: NOT AUTHORIZED

Status:
READY FOR OWNER ARCHITECTURAL REVIEW — IMPLEMENTATION NOT AUTHORIZED
```

### Architectural Verdict
1. **Mathematical Rigor**: All dimensional formulas, canonical rational reductions, affine single-offset equations, real-branch rational powers, and declared-unit floor/round rules are defined unambiguously.
2. **Repository Consistency**: 100% verified against existing `MathValue`, `ScalarValue`, `FractionValue`, `IntegerValue`, `DecimalValue`, `MathResult<T>`, `MathError`, `MathWarning`, and `PrecisionContext` contracts.
3. **Historical Protection**: Phase 10 remains verified, closed, and untouched. Full regression suite stands at 483/483 passing tests.
4. **Action Required**: Project Owner review and formal approval of the Decision Register (DEC-11-01 through DEC-11-09) is required before code implementation begins. Implementation is strictly not authorized until owner sign-off.
