# CALCULATOR MASTER SPECIFICATION

## Advanced Scientific, Engineering & Mathematical Computing Platform

**Project:** Scientific Calculator / Mathematical Computing Platform
**Technology:** Flutter + Dart
**Target Platforms:** Windows + Android
**Architecture:** Clean Architecture + Shared Dart Mathematical Core
**Development Standard:** Production-Ready
**Document Status:** Master Specification / Single Source of Truth
**Specification Version:** 1.0.0
**Purpose:** Definitive product, mathematical, architectural, UX, persistence, testing, and implementation specification

---

# 1. DOCUMENT AUTHORITY

This document is the **Single Source of Truth (SSOT)** for the calculator project.

All implementation agents, developers, reviewers, and future modifications MUST use this specification as the authoritative reference.

If another document, prompt, generated plan, implementation assumption, or agent interpretation conflicts with this specification:

> **This specification takes precedence.**

An implementation agent MUST NOT silently reduce, reinterpret, remove, replace, or redesign a requirement defined as mandatory here.

If a requirement is technically impossible to implement exactly as specified, the agent MUST:

1. Identify the conflict.
2. Explain the technical limitation.
3. Propose the smallest compatible alternative.
4. Obtain explicit approval before changing the requirement.

The agent MUST NOT solve specification conflicts by silently changing the product behavior.

---

# 2. PRODUCT DEFINITION

The application is an advanced multi-platform mathematical application built with Flutter and Dart.

It is not intended to be merely a visual clone of a traditional scientific calculator.

The product is defined as:

> **Scientific Calculator + Engineering Calculator + Graphing Calculator + Mathematical Solver + Statistics Tool + Programmer Calculator + Unit Converter + Formula Workspace + Mathematical Notebook**

The final product is therefore a:

> **Mathematical Computing Platform**

The original product concept explicitly defines the goal as expanding traditional calculator functionality into a unified mathematical and engineering environment.

---

# 3. PRODUCT LEVELS

The product architecture is designed around three progressive capability levels.

```text
LEVEL 1
Scientific Calculator
        ↓
LEVEL 2
Advanced Engineering & Mathematics
        ↓
LEVEL 3
Mathematical Computing Platform
```

## Level 1 — Scientific Calculator

Core everyday and scientific calculation.

## Level 2 — Advanced Engineering & Mathematics

Advanced equations, statistics, graphing, complex numbers, matrices, vectors, calculus, probability, units, regression, and programmer functions.

## Level 3 — Mathematical Computing Platform

Workspaces, sessions, spreadsheets, formula libraries, mathematical notebooks, reusable variables/functions, graphs, tables, calculations, notes, and extensible mathematical modules.

These levels describe the product architecture and capability scope; they do NOT authorize building a separate application for each level.

---

# 4. CORE PRODUCT PRINCIPLE

The most important architectural decision is:

> **The Mathematical Engine is an independent product-level subsystem. Flutter is the presentation and interaction layer.**

The application MUST NOT be designed as a Flutter UI with mathematical logic embedded inside widgets.

Instead:

```text
Flutter UI
    ↓
Application Layer
    ↓
Mathematical Core
    ↓
Mathematical Models / Algorithms
```

Windows and Android MUST use the same Dart Mathematical Core.

There MUST NOT be:

```text
Windows Mathematical Engine
Android Mathematical Engine
```

Instead:

```text
              Flutter UI
             /          \
        Windows        Android
             \          /
          Application
               |
      Dart Mathematical Core
               |
    ┌──────────┼──────────┐
    │          │          │
 Parser     Numeric    Symbolic
             Engine     Engine
    │          │          │
    └──────────┼──────────┘
               |
      Mathematical Models
```

The same mathematical input MUST use the same mathematical implementation on both platforms.

---

# 5. TARGET PLATFORMS

## 5.1 Windows

Windows is a first-class target.

The application MUST provide a genuine desktop experience rather than simply scaling the Android interface.

Required capabilities include:

* Mouse interaction.
* Full keyboard interaction.
* Numeric keypad support.
* Keyboard shortcuts.
* Copy/paste.
* Context menus.
* Resizable application layout.
* Large mathematical workspace.
* Persistent navigation/sidebar where appropriate.
* History panel.
* Graph panel.
* Spreadsheet panel.
* Desktop-oriented multi-panel layouts.

The original requirements explicitly define Windows as a desktop mathematics environment with these interaction patterns.

---

# 6. ANDROID

Android is also a first-class target.

The Android UI MUST be touch-first.

Required capabilities include:

* Large touch targets.
* Touch-friendly keypad.
* Swipe navigation where appropriate.
* Portrait orientation.
* Landscape orientation.
* Long-press secondary functions.
* Clipboard integration.
* Result sharing.
* Session persistence.
* Preservation of the same Mathematical Core used by Windows.

The Android application MUST NOT contain a second implementation of mathematical algorithms.

---

# 7. OFFLINE-FIRST REQUIREMENT

The mathematical system is fundamentally offline-first.

The following functionality MUST operate locally without requiring:

* API
* Server
* Internet
* Cloud service

Core offline functionality includes:

* Scientific calculation.
* Expression evaluation.
* Equation solving.
* Graphing.
* Statistics.
* Matrix operations.
* Vector operations.
* Complex numbers.
* Unit conversion.
* Core calculus.
* Core symbolic mathematics.
* Programmer calculations.

The original product definition explicitly establishes offline-first operation for mathematical modules.

Internet/cloud functionality MUST NOT become a dependency of the mathematical engine.

---

# 8. PRIMARY APPLICATION MODULES

The application architecture MUST support the following modules:

1. Calculate
2. Statistics
3. Graphing
4. Equation Solver
5. Complex Numbers
6. Matrix
7. Vector
8. Spreadsheet
9. Probability
10. Distribution
11. Calculus
12. Programmer
13. Unit Conversion
14. Formula Library
15. Table Mode
16. Calculation Workspace
17. Sessions
18. History
19. Variables / Functions
20. Mathematical Explanation

Modules MUST communicate through well-defined application/domain interfaces rather than directly depending on Flutter widgets.

---

# 9. CALCULATE — SCIENTIFIC CALCULATOR

The Calculate module is the primary entry point.

The user MUST be able to perform simple calculations immediately without being forced into Workspace, Session, or advanced-module navigation.

Example:

```text
7 × 8 =
```

MUST remain a first-class use case.

The application MUST support:

### Arithmetic

* Addition
* Subtraction
* Multiplication
* Division
* Parentheses
* Operator precedence
* Unary operators

### Numeric operations

* Fractions
* Percentages
* Powers
* Roots
* Factorial
* Permutations
* Combinations
* Absolute value

### Constants

* π
* e

### Logarithmic functions

* log
* ln
* Exponential functions

### Trigonometry

* sin
* cos
* tan
* Inverse trigonometric functions
* Hyperbolic functions
* Inverse hyperbolic functions

### Angle functionality

* DEG
* RAD
* GRAD
* DMS
* Angle conversion

### Display modes

* FIX
* SCI
* NORM
* Engineering notation
* Scientific notation
* Fraction display

These requirements are part of the original calculator definition.

---

# 10. EXPRESSION ENGINE

The Expression Engine is the central mathematical subsystem.

It MUST NOT be implemented as a collection of UI button callbacks and nested conditionals.

The required pipeline is:

```text
Source Expression
      ↓
Lexer
      ↓
Token Stream
      ↓
Parser
      ↓
AST
      ↓
Semantic Validation
      ↓
Evaluator
      ↓
Typed Mathematical Result
```

---

# 11. LEXER

The Lexer is responsible only for converting textual mathematical input into tokens.

It MUST recognize, as applicable:

* Numbers.
* Decimal numbers.
* Scientific notation.
* Identifiers.
* Variables.
* Function names.
* Constants.
* Operators.
* Parentheses.
* Commas.
* Equality symbols.
* Unit identifiers.
* Complex-number notation.
* Matrix/vector syntax where supported.

The Lexer MUST NOT perform mathematical evaluation.

---

# 12. PARSER

The Parser converts tokens into an Abstract Syntax Tree.

Operator precedence MUST be deterministic and centrally defined.

The parser MUST correctly distinguish:

* Unary minus.
* Binary subtraction.
* Function calls.
* Parentheses.
* Powers.
* Multiplication.
* Division.
* Addition.
* Subtraction.
* Implicit multiplication where supported.
* Variable references.
* Constants.

The parser MUST produce structured errors rather than generic failures.

---

# 13. AST

The AST is the shared representation of mathematical expressions.

It MUST support nodes required for:

* Literal values.
* Variables.
* Constants.
* Unary operations.
* Binary operations.
* Function calls.
* Powers.
* Fractions.
* Comparisons/equations where required.
* Units/quantities where required.
* Symbolic expressions.

The AST MUST be reusable by:

* Calculator.
* Solver.
* Graphing.
* Symbolic mathematics.
* Calculus.
* Table mode.
* Spreadsheet.
* Formula Library.
* Workspace.

---

# 14. EVALUATOR

The Evaluator MUST evaluate AST expressions using the appropriate mathematical numeric types.

It MUST NOT assume every expression is a Dart `double`.

The result MUST be represented using an appropriate domain value.

---

# 15. NUMERIC TYPE SYSTEM

The Mathematical Core MUST use a typed numerical architecture.

The following mathematical value types are required as architectural concepts:

```text
Integer
Decimal
Fraction
Complex
Matrix
Vector
Polynomial
Quantity
```

`double` MAY be used internally where mathematically appropriate, especially for numerical algorithms, but MUST NOT be the universal representation of all mathematical values.

The system MUST explicitly account for:

* Precision.
* Rounding.
* Floating-point error.
* Significant digits.
* Scientific notation.
* Exact values where practical.
* Numerical approximations where exact values are impossible or inappropriate.

This requirement exists because the application is intended to provide professional mathematical functionality rather than relying exclusively on floating-point arithmetic.

---

# 16. EXACT VS APPROXIMATE RESULTS

Every mathematical operation MUST have a clear distinction between:

```text
Exact
```

and:

```text
Approximate / Numerical
```

Examples:

```text
1/3
```

should be representable as an exact Fraction where applicable.

A numerical integration result may be marked as approximate.

Numerical solver results MUST NOT be presented as mathematically exact unless the underlying algorithm genuinely provides an exact result.

---

# 17. PRECISION POLICY

The engine MUST define a centralized precision policy.

Precision MUST NOT be decided independently inside individual modules.

The policy must cover:

* Internal computation precision.
* Display precision.
* Rounding mode.
* Significant digits.
* Decimal presentation.
* Scientific notation.
* Engineering notation.
* Numerical tolerance.
* Equality tolerance for approximate values.
* Convergence tolerance.

The UI display precision MUST NOT silently alter the underlying stored mathematical value.

---

# 18. MATHEMATICAL DISPLAY

The application MUST provide professional mathematical rendering.

Expressions should be displayed in textbook-style form where appropriate.

Examples:

```text
1/2 + 3/4
```

may render visually as:

```text
  1   3
  ─ + ─
  2   4
```

Likewise:

```text
√(25)
x²
10⁻³
```

should be rendered using mathematical typography where appropriate.

The internal mathematical representation and visual representation MUST remain separate.

---

# 19. MEMORY, VARIABLES AND FUNCTIONS

The system MUST support:

* Answer Memory.
* Variables.
* Constants.
* Function Memory.
* Session Variables.

Example:

```text
A = 25
B = 10
C = A × B
```

The variable system MUST support references between variables.

Variable scope MUST be explicit.

At minimum:

```text
Session Scope
```

MUST be supported.

Persistent/user-level variables MAY be supported where compatible with the persistence architecture.

Variables MUST be represented through the Mathematical Core and MUST NOT be stored only as UI state.

---

# 20. HISTORY

The application MUST maintain calculation history.

Each history item should preserve enough information to reproduce the calculation.

A history entry should conceptually include:

* Original expression.
* Result.
* Mathematical context/settings when relevant.
* Timestamp.
* Relevant session.
* Exact/approximate status where relevant.

Users MUST be able to:

* Replay.
* Edit.
* Copy.
* Delete.
* Reuse.
* Search.
* Pin important calculations.

Windows should make efficient use of the larger display by allowing persistent history panels.

The original requirements explicitly define replay, edit, copy, delete, reuse, search, and pin functionality.

---

# 21. EQUATION SOLVER

The Equation Solver MUST distinguish between different solving strategies.

It MUST support, as applicable:

* Linear equations.
* Quadratic equations.
* Cubic equations.
* Quartic equations.
* Polynomial equations.
* Simultaneous equations.
* Systems of equations.
* Numerical equations.
* Nonlinear equations.

The original specification establishes these solver categories.

---

# 22. EXACT SOLVERS

Where mathematically appropriate, dedicated exact algorithms MUST be used.

Examples:

* Linear equations.
* Quadratic equations.
* Supported cubic equations.
* Supported quartic equations.
* Polynomial manipulation where exact symbolic representation is available.

Exact solutions MUST remain distinct from numerical approximations.

---

# 23. NUMERICAL SOLVERS

Numerical solving MUST be isolated from exact solving.

The architecture MUST allow methods such as:

* Bisection.
* Newton-Raphson.
* Secant.
* Other validated numerical methods.

A numerical solver MUST expose:

* Initial conditions/interval where required.
* Tolerance.
* Maximum iterations.
* Convergence state.
* Approximate result.
* Failure reason if convergence is not achieved.

A failed numerical solve MUST NOT be reported as a valid solution.

---

# 24. SYSTEMS OF EQUATIONS

The solver MUST support systems as a separate problem category.

Linear systems may be solved using matrix-based methods.

Nonlinear systems MUST use appropriate numerical techniques and MUST clearly indicate approximate results.

The solver MUST distinguish:

```text
No Solution
Infinite Solutions
Unique Solution
Approximate Solution
Convergence Failure
```

---

# 25. SYMBOLIC MATHEMATICS

Symbolic Mathematics is a core advanced module.

It MUST be based on structured symbolic expressions rather than string manipulation.

Required capabilities include, according to supported mathematical scope:

* Simplification.
* Expansion.
* Factorization.
* Polynomial manipulation.
* Substitution.
* Symbolic differentiation.
* Limits.
* Supported symbolic integration.

Example:

```text
expand((x + 2)^3)
```

should be able to produce:

```text
x³ + 6x² + 12x + 8
```

and:

```text
factor(x² - 5x + 6)
```

should be able to produce:

```text
(x - 2)(x - 3)
```

These examples and capabilities are part of the original product concept.

---

# 26. SYMBOLIC MATHEMATICS BOUNDARY

The project MUST NOT claim to be a complete replacement for Mathematica, Maple, SymPy, or a general-purpose computer algebra system.

Symbolic functionality MUST be implemented according to algorithms that can be tested and guaranteed within the supported domain.

Unsupported symbolic cases MUST produce a structured:

```text
UnsupportedOperation
```

or equivalent domain-specific error.

The application MUST NOT generate plausible-looking symbolic results that cannot be mathematically validated.

---

# 27. SYMBOLIC ENGINE STRUCTURE

The symbolic engine should conceptually contain:

```text
Symbolic Expression Tree
        ↓
Simplification
        ↓
Polynomial Algebra
        ↓
Expansion
        ↓
Factorization
        ↓
Substitution
        ↓
Differentiation
        ↓
Limits
        ↓
Supported Integration
```

Each transformation MUST preserve mathematical correctness.

---

# 28. GRAPHING ENGINE

Graphing MUST be an independent engine.

Required conceptual pipeline:

```text
Function
   ↓
Expression Engine
   ↓
Evaluation
   ↓
Graph Sampling Engine
   ↓
Coordinate Mapping
   ↓
Renderer
```

The graph renderer MUST NOT implement mathematical evaluation itself.

The Graphing Engine MUST support:

* `y = x²`
* `y = sin(x)`
* `y = e^x`
* Multiple functions.
* Zoom.
* Pan.
* Grid.
* Axes.
* Coordinates.
* Trace.
* Roots.
* Intersections.
* Maximums.
* Minimums.
* Derivative curves.
* Integral visualization.

These graphing capabilities are part of the original scope.

---

# 29. GRAPH SAMPLING

The graphing subsystem MUST NOT simply evaluate a fixed number of equally spaced points without considering discontinuities and numerical behavior.

The architecture MUST allow:

* Adaptive sampling.
* Discontinuity detection.
* Invalid-domain detection.
* Numerical overflow handling.
* Plot clipping.
* Configurable viewport.
* Sampling density appropriate to zoom level.

The renderer MUST never interpret invalid mathematical results as ordinary graph points.

---

# 30. CALCULUS ENGINE

The Calculus module MUST support:

### Differentiation

* Symbolic differentiation where supported.
* Numerical differentiation.

Example:

```text
d/dx (x² + 3x)
```

### Integration

* Supported symbolic indefinite integration.
* Numerical indefinite/definite functionality where appropriate.
* Definite integration.

Example:

```text
∫₀⁵ x² dx
```

### Visualization

* Integral result.
* Numerical approximation.
* Graphical representation.

The original product scope explicitly includes symbolic and numerical differentiation, integration, approximation, and graph visualization.

---

# 31. NUMERICAL CALCULUS

Numerical calculus operations MUST expose appropriate tolerance and convergence information internally.

Numerical integration MUST distinguish:

```text
Calculated Result
Estimated Error
Convergence / Failure
```

where the underlying algorithm supports such information.

---

# 32. STATISTICS ENGINE

The Statistics module MUST support:

* Mean.
* Median.
* Mode.
* Minimum.
* Maximum.
* Range.
* Variance.
* Standard deviation.
* Quartiles.
* Percentiles.
* Sum.

The system MUST support datasets and relationships between variables.

These capabilities are explicitly defined in the original scope.

---

# 33. REGRESSION ENGINE

Required regression families include:

* Linear.
* Quadratic.
* Cubic.
* Logarithmic.
* Exponential.
* Power.
* Geometric.

The system should expose:

* Equation.
* Coefficients.
* Correlation where mathematically applicable.
* Predicted values.
* Residuals.
* Graph.

Regression MUST use shared numerical/matrix infrastructure where appropriate.

---

# 34. PROBABILITY ENGINE

The Probability subsystem MUST be independently structured.

Required distributions include:

* Normal.
* Binomial.
* Poisson.
* Uniform.
* Exponential.
* Geometric.
* Additional distributions as the validated engine supports.

Required operations include:

* PDF.
* CDF.
* Inverse CDF.
* Probability calculations.
* Random sampling.

The original scope explicitly defines these distribution categories and operations.

---

# 35. DISTRIBUTION API CONTRACT

Every distribution implementation SHOULD expose a consistent conceptual interface:

```text
density(x)
cdf(x)
inverseCdf(p)
sample(...)
```

Not every distribution necessarily supports every operation in every mathematical context; unsupported operations MUST be reported explicitly.

---

# 36. COMPLEX NUMBERS

Complex numbers MUST be a core mathematical type.

They MUST NOT be implemented merely as a special calculator mode.

Required operations:

* Addition.
* Subtraction.
* Multiplication.
* Division.
* Powers.
* Roots.
* Conjugate.
* Magnitude.
* Argument.

Representations:

```text
Rectangular
Polar
```

must be supported with conversion between them.

Example:

```text
3 + 4i
```

is a valid complex number representation.

These requirements are part of the original scope.

---

# 37. MATRIX ENGINE

Matrix functionality MUST be a core mathematical subsystem.

Required matrix sizes include:

```text
2×2
3×3
4×4
```

The architecture MUST NOT hard-code the entire engine exclusively around these dimensions.

Larger matrices MAY be supported according to validated implementation and performance.

Required operations:

* Addition.
* Subtraction.
* Multiplication.
* Scalar multiplication.
* Transpose.
* Determinant.
* Inverse.
* Rank.
* Trace.
* Matrix powers.
* Linear systems.

Future extensibility:

* Eigenvalues.
* Eigenvectors.
* LU decomposition.
* QR decomposition.
* Gaussian elimination.

The latter are future extensions unless explicitly promoted to mandatory scope later.

---

# 38. MATRIX VALIDATION

The Matrix Engine MUST validate dimensions before operations.

Examples:

```text
Invalid dimensions
Singular matrix
Invalid inverse
```

MUST result in structured mathematical errors.

The engine MUST NOT crash or silently produce invalid matrices.

---

# 39. VECTOR ENGINE

Required operations:

* Vector addition.
* Vector subtraction.
* Dot product.
* Cross product.
* Magnitude.
* Normalization.
* Angle between vectors.
* Projection.

Cross product MUST be limited to mathematically valid dimensions unless a mathematically defined generalized operation is intentionally implemented.

---

# 40. PROGRAMMER CALCULATOR

The Programmer module MUST support:

```text
BIN
OCT
DEC
HEX
```

Required bitwise operations:

* AND.
* OR.
* XOR.
* NOT.
* Bit shift.
* Bit rotation.
* Bit masks.

Required integer widths:

```text
8-bit
16-bit
32-bit
64-bit
```

The programmer calculator MUST define signed/unsigned behavior explicitly in its domain model.

Binary representation MUST be visually clear.

The original requirements establish these programmer-calculator capabilities.

---

# 41. UNIT & DIMENSION ENGINE

Unit conversion MUST NOT be implemented merely as a list of multiplication factors.

The application MUST have a real:

> **Dimensional Analysis Engine**

The core concepts are:

```text
Quantity
Unit
Dimension
Conversion
Derived Dimension
```

Example:

```text
10 m + 50 cm
```

MUST normalize compatible units before performing the addition.

The engine MUST understand that:

```text
m
cm
km
```

are units of the same dimension:

```text
Length
```

and that:

```text
m/s
```

is a derived dimension.

---

# 42. UNIT VALIDATION

The engine MUST reject dimensionally invalid operations.

For example:

```text
10 meters + 5 kilograms
```

MUST NOT produce a numeric result.

It MUST produce a:

```text
DimensionMismatch
```

or equivalent structured error.

---

# 43. INITIAL UNIT CATEGORIES

At minimum the unit system must accommodate:

### Length

* km
* m
* cm
* mm
* mile
* yard
* foot
* inch

### Mass

* kg
* g
* mg
* lb
* oz

### Time

* second
* minute
* hour
* day

Additional categories SHOULD be supported through the extensible unit registry.

The original scope explicitly defines these categories and examples.

---

# 44. FORMULA LIBRARY

The Formula Library MUST use structured formula definitions.

A formula MUST NOT be stored only as a text string.

A structured formula definition should contain:

* Formula ID.
* Name.
* Category.
* Expression.
* Variables.
* Required inputs.
* Units.
* Output.
* Description.
* Validation rules.

---

# 45. FORMULA CATEGORIES

Required categories include:

### Physics

```text
F = ma
E = mc²
V = IR
P = VI
```

### Geometry

* Circle area.
* Triangle.
* Sphere.
* Cylinder.
* Cone.

### Finance

* Simple interest.
* Compound interest.
* Loan.
* EMI.
* Present Value.
* Future Value.

### Chemistry

* Moles.
* Molarity.
* Concentration.
* Gas laws.

The original scope defines these formula groups.

---

# 46. CUSTOM FORMULAS

The user MUST be able to create custom formulas.

Custom formulas MUST use the same Mathematical Core expression system.

They MUST NOT introduce a second expression language.

---

# 47. TABLE MODE

Table Mode MUST allow a user to define a function such as:

```text
f(x) = x² + 2x + 1
```

and generate values:

```text
x       f(x)
0       1
1       4
2       9
3       16
```

The system MUST support defining two functions and comparing their results.

Table evaluation MUST reuse the Expression Engine and Graphing evaluation infrastructure.

---

# 48. SPREADSHEET ENGINE

Spreadsheet MUST be an independent subsystem.

The Spreadsheet MUST consume the Mathematical Core.

The Mathematical Core MUST NOT depend on the Spreadsheet.

Example:

```text
A       B       C
--------------------
10      20      =A1+B1
15      30      =A2+B2
20      40      =A3+B3
```

Required functionality:

* Cell references.
* Formulas.
* Copy.
* Paste.
* Fill.
* SUM.
* MEAN.
* Mathematical functions.
* Data analysis.

Future functionality:

* CSV import/export.
* Sorting.
* Filtering.
* Charts.

These requirements are directly derived from the original product scope.

---

# 49. SPREADSHEET DEPENDENCY GRAPH

Spreadsheet formulas MUST be represented as dependencies.

Example:

```text
A1 → C1
B1 → C1
```

When A1 or B1 changes, C1 MUST be recalculated.

The architecture MUST allow circular-reference detection.

Circular references MUST produce structured errors instead of infinite recalculation.

---

# 50. CALCULATION WORKSPACE

The Workspace is a higher-level mathematical document.

Example:

```text
Physics Experiment
```

A Workspace may contain:

```text
Variables
Constants
Equations
Calculations
Tables
Graphs
Results
Notes
```

The user MUST be able to save and reopen a Workspace.

This turns the application into a:

> **Mathematical Notebook**

The Workspace MUST reuse existing mathematical modules rather than implementing independent calculation logic.

The original concept explicitly defines this Workspace structure.

---

# 51. SESSION SYSTEM

The application MUST support multiple sessions.

Example:

```text
Math
Physics
Engineering
Statistics
Personal
```

A session conceptually contains:

* History.
* Variables.
* Functions.
* Settings.
* Calculations.

Session isolation MUST prevent accidental leakage of session-specific variables or settings into another session.

---

# 52. QUICK CALCULATION UX

Advanced architecture MUST NOT damage basic calculator usability.

When the application opens, a user should be able to calculate immediately.

The first interaction path should not require:

```text
Create Workspace
→ Create Session
→ Configure Module
→ Enter Calculation
```

Instead:

```text
Open App
→ Enter Calculation
→ Get Result
```

Advanced functionality remains available without obstructing normal use.

---

# 53. ERROR & VALIDATION SYSTEM

A unified error system MUST exist across the Mathematical Core.

Errors MUST be structured, typed, and user-displayable.

Required categories include:

```text
DivisionByZero
DomainError
Overflow
Underflow
InvalidExpression
SyntaxError
DimensionMismatch
MatrixDimensionError
SingularMatrix
NoSolution
InfiniteSolutions
ConvergenceFailure
PrecisionLoss
UnsupportedOperation
InvalidArgument
CircularReference
```

Modules MAY define specialized errors, but they MUST integrate with the shared error architecture.

---

# 54. ERROR DISPLAY POLICY

Internal error objects MUST NOT be exposed directly as raw stack traces to users.

The UI MUST translate mathematical errors into understandable messages.

Development builds may log technical diagnostics.

Production UI should provide:

* What went wrong.
* Where possible, which input caused it.
* What the user can correct.

---

# 55. CALCULATION EXPLANATION ENGINE

The application SHOULD contain a deterministic, non-AI Explanation Engine.

Its purpose is to provide reliable step-by-step explanations for operations whose derivation is supported.

Examples:

```text
x² - 5x + 6 = 0
```

may explain:

```text
Factor polynomial
→ Find factors
→ Set each factor to zero
→ Obtain roots
```

The Explanation Engine MUST be based on actual mathematical transformations performed by the engine.

It MUST NOT fabricate reasoning.

AI explanation is a future capability and MUST NOT be a dependency of the core explanation system.

---

# 56. ARCHITECTURAL LAYERS

The project MUST follow Clean Architecture principles.

Conceptually:

```text
Presentation
    ↓
Application
    ↓
Domain
    ↓
Infrastructure
```

The Mathematical Core should be as independent as reasonably possible from Flutter.

---

# 57. DOMAIN LAYER

The domain layer contains mathematical concepts and business rules.

Examples:

```text
Expression
Token
AstNode
NumericValue
Fraction
ComplexNumber
Matrix
Vector
Polynomial
Quantity
Unit
Dimension
Equation
Dataset
Distribution
Formula
Workspace
Session
Calculation
```

Domain objects MUST NOT depend on Flutter widgets.

---

# 58. APPLICATION LAYER

The Application layer orchestrates use cases.

Examples:

```text
EvaluateExpression
SolveEquation
PlotFunction
CalculateStatistics
PerformRegression
EvaluateDistribution
DifferentiateExpression
IntegrateExpression
CalculateMatrixOperation
CalculateVectorOperation
ConvertQuantity
EvaluateFormula
RecalculateSpreadsheet
CreateWorkspace
LoadWorkspace
```

Use cases MUST depend on abstractions rather than concrete UI implementations.

---

# 59. INFRASTRUCTURE LAYER

Infrastructure handles:

* Persistence.
* File storage.
* Serialization.
* Platform-specific services.
* Clipboard integration.
* Sharing.
* Desktop-specific behavior.
* Android-specific integration.

Mathematical algorithms MUST NOT be moved into Infrastructure merely because they are difficult.

---

# 60. PRESENTATION LAYER

Flutter is responsible for:

* UI.
* Navigation.
* Layout.
* Input.
* Rendering.
* Interaction.
* Visual mathematical display.
* Accessibility.
* Platform-specific UX adaptation.

Flutter widgets MUST NOT become the source of truth for mathematical state.

---

# 61. STATE MANAGEMENT

State management MUST be modular and predictable.

UI state MUST be separated from mathematical/domain state.

The implementation agent MAY select the appropriate state-management mechanism, provided that:

1. Domain logic remains independent.
2. Mathematical state is testable without Flutter widgets.
3. State transitions are deterministic.
4. No mathematical algorithm is embedded in UI widgets.

---

# 62. PERSISTENCE

Persistent data should include, as applicable:

* Sessions.
* History.
* Variables.
* Functions.
* Formula Library custom entries.
* Workspaces.
* User preferences.
* Calculator settings.
* Spreadsheet documents.

Persistence format MUST support schema evolution.

The application MUST be able to handle future database/schema migrations safely.

---

# 63. DATA SEPARATION

The following concepts MUST remain logically distinguishable:

```text
Application Settings
Session Settings
Session Variables
Global/User Variables
History
Workspace Data
Formula Library
Spreadsheet Documents
```

They MUST NOT be dumped into one unstructured settings object.

---

# 64. CROSS-PLATFORM DETERMINISM

For deterministic mathematical operations:

```text
Same Input
+ Same Mathematical Settings
= Same Mathematical Result
```

on:

```text
Windows
Android
```

The application MUST NOT allow platform-specific floating-point/UI behavior to create unexplained mathematical differences.

Where platform-level numerical differences are unavoidable, the engine MUST normalize behavior through the shared Dart implementation.

---

# 65. LOCALIZATION

The architecture MUST support localization.

At minimum the application is expected to support:

* Arabic.
* English.

The mathematical expression language itself MUST remain stable regardless of UI language.

UI translations MUST NOT change mathematical semantics.

---

# 66. RTL SUPPORT

Arabic UI MUST support proper RTL layout.

Mathematical expressions MUST remain visually correct when displayed inside RTL interfaces.

The implementation MUST distinguish:

```text
UI Direction
```

from:

```text
Mathematical Expression Direction
```

---

# 67. WINDOWS KEYBOARD SUPPORT

The Windows application MUST support direct keyboard entry where possible.

Important input classes include:

* Digits.
* Operators.
* Parentheses.
* Decimal separator.
* Enter.
* Backspace.
* Delete.
* Escape.
* Arrow navigation.
* Copy.
* Paste.
* Undo/redo where applicable.
* Numpad.

Keyboard shortcuts MUST be centrally defined rather than duplicated throughout widgets.

---

# 68. ANDROID INPUT SUPPORT

Android must provide:

* Large touch targets.
* Touch keypad.
* Secondary functions.
* Long-press behavior.
* Clipboard integration.
* Sharing.

The UI must adapt between portrait and landscape.

---

# 69. ACCESSIBILITY

The application SHOULD provide:

* Accessible labels.
* Logical focus order.
* Sufficient touch target sizes.
* Keyboard accessibility on Windows.
* Screen-reader-friendly controls where practical.
* Avoidance of information conveyed solely through color.

Accessibility MUST NOT compromise mathematical correctness.

---

# 70. GRAPHICAL RENDERING SEPARATION

Mathematical rendering MUST be separated from mathematical evaluation.

For example:

```text
AST
 ↓
Math Renderer
 ↓
Visual Mathematical Layout
```

and:

```text
AST
 ↓
Evaluator
 ↓
Mathematical Result
```

These are separate concerns.

---

# 71. PERFORMANCE PRINCIPLES

The application must remain responsive during normal calculations.

Potentially expensive operations include:

* Symbolic algebra.
* Polynomial factorization.
* Large matrix operations.
* Numerical integration.
* Numerical equation solving.
* Graph sampling.
* Spreadsheet recalculation.
* Large statistical datasets.

The architecture MUST allow expensive work to execute without blocking the UI unnecessarily.

---

# 72. GRAPH PERFORMANCE

Graph rendering MUST be optimized independently from mathematical evaluation.

The system SHOULD:

* Cache reusable calculations.
* Avoid unnecessary recalculation.
* Sample according to viewport requirements.
* Recompute only when function or viewport changes.
* Keep rendering responsive.

---

# 73. SPREADSHEET PERFORMANCE

Spreadsheet recalculation SHOULD update only affected dependencies where practical.

A change to:

```text
A1
```

should not blindly recalculate the entire spreadsheet if dependency analysis can determine the affected cells.

---

# 74. TESTING STRATEGY

Testing is mandatory.

The project MUST include:

### Unit Tests

For:

* Lexer.
* Parser.
* AST.
* Evaluator.
* Numeric types.
* Fractions.
* Complex numbers.
* Matrix.
* Vector.
* Polynomial.
* Units.
* Statistics.
* Regression.
* Probability.
* Solver.
* Calculus.
* Symbolic transformations.

### Integration Tests

For:

* Expression → evaluation.
* Expression → graph.
* Expression → solver.
* Expression → symbolic operation.
* Spreadsheet → Mathematical Core.
* Formula → calculation.
* Workspace → calculations.

### UI Tests

For critical user workflows.

---

# 75. MATHEMATICAL GOLDEN TESTS

The Mathematical Core MUST contain a reliable set of known mathematical test cases.

Examples should include:

```text
2 + 3 = 5
7 × 8 = 56
(5 + 3)^2 / 4 = 16
sin(30°) = 0.5
sqrt(25) = 5
```

and advanced cases involving:

* Fractions.
* Complex numbers.
* Matrices.
* Units.
* Equations.
* Calculus.
* Statistics.
* Regression.
* Probability.

The goal is to detect regressions in mathematical correctness.

---

# 76. ERROR TESTING

The test suite MUST explicitly test invalid cases.

Examples:

```text
1 / 0
sqrt(-1)
log(-1)
invalid syntax
matrix dimension mismatch
inverse of singular matrix
incompatible units
non-convergent numerical equation
circular spreadsheet reference
```

The application MUST produce the appropriate structured error rather than crashing.

---

# 77. REGRESSION PROTECTION

Any mathematical bug fixed in the project MUST result in a regression test.

Agents MUST NOT fix a mathematical issue by changing only the UI behavior while leaving the underlying mathematical defect unresolved.

---

# 78. NO PLACEHOLDER IMPLEMENTATION

Production implementation MUST NOT contain:

```text
TODO
FIXME
NotImplemented
placeholder result
fake calculation
hard-coded demonstration result
mock algorithm presented as production
```

unless explicitly confined to a test or development-only fixture.

The delivered production functionality MUST be complete for the declared scope.

---

# 79. NO SILENT SCOPE REDUCTION

An implementation agent MUST NOT interpret a large specification as permission to implement only:

```text
Basic Calculator
```

and claim completion.

If implementation is staged, each stage MUST explicitly state which defined modules are complete and which remain.

The product specification remains the full target.

---

# 80. IMPLEMENTATION PHASING

The project is large and MUST be implemented incrementally.

However, phasing does NOT remove any requirement.

Recommended implementation dependency order:

```text
PHASE 1
Project Foundation
        ↓
PHASE 2
Mathematical Value System
        ↓
PHASE 3
Lexer / Parser / AST
        ↓
PHASE 4
Expression Evaluator
        ↓
PHASE 5
Scientific Calculator
        ↓
PHASE 6
Variables / Memory / History
        ↓
PHASE 7
Complex / Matrix / Vector
        ↓
PHASE 8
Units & Dimensional Analysis
        ↓
PHASE 9
Equation Solver
        ↓
PHASE 10
Symbolic Mathematics
        ↓
PHASE 11
Calculus
        ↓
PHASE 12
Graphing
        ↓
PHASE 13
Statistics / Regression
        ↓
PHASE 14
Probability / Distributions
        ↓
PHASE 15
Programmer Calculator
        ↓
PHASE 16
Formula Library
        ↓
PHASE 17
Table Mode
        ↓
PHASE 18
Spreadsheet
        ↓
PHASE 19
Workspace / Sessions
        ↓
PHASE 20
Cross-platform UX Hardening
        ↓
PHASE 21
Full Verification / Release
```

This is an implementation order, not a reduction of the final product.

---

# 81. CRITICAL IMPLEMENTATION DEPENDENCIES

The following dependency rules are mandatory:

```text
Expression Engine
        ↓
Calculator
Solver
Graphing
Symbolic
Calculus
Table
Spreadsheet
Workspace
```

and:

```text
Numeric Core
        ↓
Complex
Matrix
Vector
Statistics
Regression
Solver
Probability
```

and:

```text
Unit / Dimension Engine
        ↓
Quantity-aware Expression Evaluation
        ↓
Formula Library
Engineering Calculations
```

This architecture prevents duplication.

---

# 82. MATHEMATICAL CORE PACKAGE BOUNDARY

The Mathematical Core SHOULD be organized so that it can conceptually exist independently of Flutter.

A conceptual organization may be:

```text
mathematical_core/
    expression/
    lexer/
    parser/
    ast/
    evaluation/
    numeric/
    symbolic/
    algebra/
    calculus/
    solver/
    complex/
    matrix/
    vector/
    statistics/
    regression/
    probability/
    units/
    formulas/
    graphing/
    errors/
```

The exact directory names MAY differ, but the architectural separation MUST remain.

---

# 83. APPLICATION LAYER ORGANIZATION

A conceptual structure may be:

```text
application/
    calculate/
    history/
    variables/
    solver/
    graphing/
    statistics/
    calculus/
    formulas/
    spreadsheet/
    workspace/
    sessions/
```

Each feature SHOULD expose explicit use cases.

---

# 84. PRESENTATION ORGANIZATION

A conceptual Flutter organization may be:

```text
presentation/
    calculate/
    graphing/
    solver/
    statistics/
    matrix/
    vector/
    complex/
    programmer/
    units/
    formulas/
    spreadsheet/
    workspace/
    sessions/
    settings/
    history/
```

The exact naming can vary, but presentation MUST remain separate from the Mathematical Core.

---

# 85. NAVIGATION

The application MUST make advanced functionality discoverable without overwhelming basic users.

The architecture should allow a primary navigation structure such as:

```text
Calculate
Graphing
Solver
Statistics
Matrix
Vector
Complex
Programmer
Units
Formulas
Spreadsheet
Workspace
```

The final UI design may optimize this structure for Windows and Android independently.

---

# 86. WINDOWS LAYOUT PRINCIPLE

Windows SHOULD exploit large displays.

A possible structure:

```text
┌────────────────────────────────────────────────────────────┐
│ Toolbar / Mode / Settings                                  │
├───────────────┬────────────────────────────┬───────────────┤
│ Navigation    │ Main Mathematical Area     │ History/Panel │
│               │                            │               │
│ Calculate     │ Expression                 │ History       │
│ Graphing      │                            │ Variables     │
│ Solver        │ Result                     │ Functions     │
│ Statistics    │                            │               │
│ ...           │ Keypad / Workspace         │               │
└───────────────┴────────────────────────────┴───────────────┘
```

This is an architectural UX direction, not a fixed pixel-perfect UI specification.

---

# 87. ANDROID LAYOUT PRINCIPLE

Android SHOULD prioritize:

```text
Expression
Result
Keypad
Navigation
```

and use:

* Swipe navigation.
* Bottom navigation where appropriate.
* Expandable advanced controls.
* Long-press secondary functions.
* Portrait/landscape adaptations.

The Android interface MUST NOT attempt to reproduce the Windows multi-panel layout literally.

---

# 88. SETTINGS

Settings MUST be centrally managed.

Expected settings include:

* Angle mode.
* Number display mode.
* Precision.
* Significant digits.
* Scientific notation.
* Engineering notation.
* Theme.
* Language.
* Calculation behavior.
* Graph preferences.
* Unit preferences.

Settings MUST have clearly defined scope:

```text
Global
Session
Module
```

where applicable.

---

# 89. ANGLE MODE

The calculator MUST support:

```text
DEG
RAD
GRAD
```

Angle mode MUST be part of calculation context.

The same expression may legitimately produce different results under different angle modes.

Therefore calculation history and reproducibility SHOULD preserve relevant angle context.

---

# 90. DISPLAY MODE

The display system MUST support:

```text
FIX
SCI
NORM
Engineering
```

Display formatting MUST NOT modify the underlying mathematical value.

---

# 91. FORMULA EVALUATION CONTRACT

Formula Library calculations MUST ultimately use the same expression and quantity engines.

For example:

```text
F = m × a
```

must be evaluated using:

```text
Expression Engine
+
Variables
+
Quantity / Units
+
Numeric Core
```

rather than custom formula-specific arithmetic implementations.

---

# 92. WORKSPACE ARCHITECTURE

A Workspace is a container of mathematical artifacts.

Conceptually:

```text
Workspace
├── Metadata
├── Variables
├── Constants
├── Functions
├── Equations
├── Calculations
├── Tables
├── Graphs
├── Results
└── Notes
```

Artifacts MUST be linked where dependencies exist.

For example:

```text
Variable
   ↓
Equation
   ↓
Calculation
   ↓
Graph
```

---

# 93. SESSION VS WORKSPACE

The two concepts MUST NOT be confused.

### Session

A runtime/user calculation environment.

Contains:

* Current variables.
* Current history.
* Functions.
* Settings.
* Calculations.

### Workspace

A persistent mathematical project/document.

Contains:

* Variables.
* Constants.
* Equations.
* Calculations.
* Tables.
* Graphs.
* Results.
* Notes.

A Workspace MAY be opened within a session.

---

# 94. FORMULA LIBRARY VS WORKSPACE

Formula Library contains reusable mathematical formulas.

Workspace contains a specific user's mathematical work.

Example:

```text
Formula Library:
F = ma
```

may be reused inside:

```text
Workspace:
Physics Experiment
```

---

# 95. SECURITY AND DATA SAFETY

The application is primarily local and offline.

User-created:

* Workspaces.
* Variables.
* History.
* Formulas.
* Spreadsheet data.

MUST be stored safely and predictably.

Imported mathematical content MUST be validated before evaluation.

The expression engine MUST NOT execute arbitrary operating-system commands or arbitrary Dart code.

Mathematical expressions are data, not executable application code.

---

# 96. NO EVAL-BASED CODE EXECUTION

The application MUST NOT implement mathematical expressions by dynamically executing generated source code.

For example, the expression:

```text
2 + 3
```

must be interpreted by:

```text
Lexer → Parser → AST → Evaluator
```

rather than converted into executable Dart/source code.

---

# 97. EXTENSIBILITY

The architecture MUST allow additional mathematical modules without rewriting the core.

Future modules may include:

* Cloud Sync.
* Formula Marketplace.
* User-created functions.
* Advanced charting.
* Mathematical documents.
* Plugin system.
* Additional mathematical modules.
* AI explanation assistant.

These are future capabilities and MUST NOT become mandatory dependencies of the initial offline mathematical core.

The original product concept explicitly defines these as future extensibility directions.

---

# 98. FUTURE FEATURES

The following are explicitly **Future Scope** unless separately promoted:

### Cloud Sync

Synchronization of sessions/workspaces between devices.

### Formula Marketplace

Sharing/distribution of formula packages.

### User-created Functions

Advanced reusable mathematical functions.

### Advanced Charting

More advanced visualization capabilities.

### Mathematical Documents

Richer document-oriented mathematical authoring.

### Plugin System

Third-party mathematical extensions.

### AI Explanation Assistant

Optional AI-powered explanations.

None of these may become required for offline mathematical operation.

---

# 99. WHAT THE PRODUCT IS NOT

The product is NOT:

* A simple four-function calculator.
* A collection of unrelated calculators.
* A Flutter UI with calculation code inside widgets.
* A calculator dependent on an online API.
* A platform-specific mathematical implementation.
* A collection of hard-coded formula buttons.
* A string-replacement expression parser.
* A `double`-only mathematical engine.
* A fake symbolic mathematics interface.
* A simple unit conversion lookup table.

---

# 100. CORE DESIGN PHILOSOPHY

The project MUST follow these principles:

### 1. Correctness over visual complexity

A beautiful wrong mathematical result is unacceptable.

### 2. Shared core over duplicated implementations

One mathematical engine for Windows and Android.

### 3. Deterministic behavior

Same mathematical context → same result.

### 4. Explicit limitations

Unsupported mathematics must be identified rather than guessed.

### 5. Modularity

Each mathematical domain is independently testable.

### 6. Reusability

A capability implemented once should be reused everywhere.

### 7. Offline-first

Core mathematics must not require external services.

### 8. User simplicity

Basic calculations must remain fast and intuitive.

### 9. Production quality

No placeholders or incomplete production paths.

### 10. Extensibility

Future capabilities must be addable without architectural destruction.

---

# 101. ACCEPTANCE CRITERIA — CORE

The project cannot be considered architecturally complete unless:

* Windows and Android use the same Dart Mathematical Core.
* Expression parsing is implemented through Lexer → Parser → AST.
* Evaluation is independent of Flutter widgets.
* Numeric types are not limited to `double`.
* Errors are structured.
* Tests cover mathematical behavior.
* Basic calculator usage remains immediate.
* Offline calculation works.
* UI does not contain core mathematical algorithms.

---

# 102. ACCEPTANCE CRITERIA — SCIENTIFIC CALCULATOR

The Calculate module is complete when it supports the declared arithmetic/scientific operations, angle modes, display modes, constants, fractions, powers, roots, logarithmic/trigonometric functions, factorial, permutations, combinations, and professional expression input/rendering.

---

# 103. ACCEPTANCE CRITERIA — ADVANCED MATHEMATICS

The advanced mathematics layer is complete when the declared modules are implemented through the shared core:

```text
Complex
Matrix
Vector
Solver
Symbolic
Calculus
Statistics
Regression
Probability
Distribution
Units
Programmer
```

with tests and structured error handling.

---

# 104. ACCEPTANCE CRITERIA — GRAPHING

Graphing is complete when a user can:

1. Enter a function.
2. Evaluate it through the shared Expression Engine.
3. Display it graphically.
4. Zoom.
5. Pan.
6. View axes/grid.
7. Use multiple functions.
8. Inspect coordinates.
9. Trace functions.
10. Access supported roots/intersections/extrema/derivative/integral visualizations.

---

# 105. ACCEPTANCE CRITERIA — WORKSPACE

Workspace is complete when the user can:

1. Create a workspace.
2. Name it.
3. Define variables/constants.
4. Add equations.
5. Perform calculations.
6. Create tables.
7. Create graphs.
8. Store results.
9. Add notes.
10. Save.
11. Close.
12. Reopen.
13. Restore its mathematical state.

---

# 106. ACCEPTANCE CRITERIA — SPREADSHEET

Spreadsheet is complete when:

* Cells can contain values.
* Cells can contain formulas.
* Cell references work.
* Dependencies recalculate.
* Copy/paste works.
* Fill works.
* Core mathematical functions work.
* Circular references are detected.
* Mathematical errors are reported safely.

---

# 107. ACCEPTANCE CRITERIA — CROSS-PLATFORM

A representative mathematical test suite MUST execute on both Windows and Android.

Results MUST match within the defined mathematical precision/tolerance rules.

The UI may differ.

The mathematical behavior must not.

---

# 108. ACCEPTANCE CRITERIA — RELEASE QUALITY

Before release:

* Static analysis must pass.
* Unit tests must pass.
* Integration tests must pass.
* Critical UI workflows must pass.
* Mathematical regression tests must pass.
* No production TODO/placeholders may remain.
* No known critical mathematical correctness defects may remain.
* Windows build must be verified.
* Android build must be verified.
* Offline operation must be verified.

---

# 109. AGENT IMPLEMENTATION RULES

Any coding agent working on this project MUST follow these rules.

## Rule 1

Read this specification before modifying the project.

## Rule 2

Do not redesign the architecture without explicit approval.

## Rule 3

Do not move mathematical logic into UI code.

## Rule 4

Do not create platform-specific mathematical implementations.

## Rule 5

Do not replace the Expression Engine with ad-hoc parsing.

## Rule 6

Do not replace the Numeric Core with `double` everywhere.

## Rule 7

Do not silently reduce functionality.

## Rule 8

Do not add fake implementations.

## Rule 9

Do not mark a feature complete if its acceptance criteria are not satisfied.

## Rule 10

Every mathematical bug fix must include regression coverage.

## Rule 11

Every new mathematical capability must be exposed through the appropriate core/application abstraction.

## Rule 12

Every significant architectural decision must be documented.

---

# 110. AGENT CHANGE POLICY

Before modifying existing architecture, the agent MUST determine:

```text
What requirement is being implemented?
Which existing module owns it?
Can an existing abstraction be reused?
Will the change affect Windows?
Will the change affect Android?
Will the change affect mathematical determinism?
Will existing tests continue to protect correctness?
```

The agent MUST prefer minimal, targeted changes over unnecessary rewrites.

---

# 111. AGENT REPORTING REQUIREMENT

After a substantial implementation phase, the agent MUST provide an English engineering walkthrough/report suitable for external review.

The report SHOULD include:

```text
Executive Summary
Implemented Features
Files Changed
Architecture Changes
Mathematical Algorithms
Data Model Changes
Tests Added
Tests Executed
Verification Results
Known Limitations
Remaining Work
```

The report MUST clearly distinguish:

```text
Implemented
Verified
Implemented but not fully verified
Not implemented
Future scope
```

---

# 112. DEFINITION OF "DONE"

A feature is **DONE** only when:

```text
Implementation
+
Integration
+
Error Handling
+
Testing
+
Verification
+
Documentation
```

are complete for its declared scope.

Code existing in the repository is NOT sufficient evidence that a feature is complete.

---

# 113. DEFINITION OF "VERIFIED"

A feature is **VERIFIED** only when the relevant tests or practical verification have actually been executed.

The agent MUST NOT use words such as:

```text
Verified
Confirmed
Production-ready
Complete
```

unless the available evidence supports that claim.

---

# 114. HANDLING UNKNOWN REQUIREMENTS

If this specification intentionally leaves a detail open, the agent may choose an implementation that:

1. Preserves the architecture.
2. Preserves mathematical correctness.
3. Is extensible.
4. Does not conflict with another requirement.

However, an agent MUST NOT reinterpret a mandatory requirement as optional simply because an implementation detail is unspecified.

---

# 115. PRIORITY ORDER

When making implementation decisions, use this priority order:

```text
1. Mathematical correctness
2. This Master Specification
3. Shared Mathematical Core architecture
4. Cross-platform consistency
5. Data integrity
6. Reliability
7. Performance
8. UX
9. Visual polish
```

Visual convenience MUST NOT override mathematical correctness.

---

# 116. PRODUCT SUCCESS DEFINITION

The product succeeds when it provides a unified environment where a user can move naturally from:

```text
Simple Calculation
```

to:

```text
Scientific Calculation
```

to:

```text
Engineering Calculation
```

to:

```text
Advanced Mathematics
```

to:

```text
Mathematical Analysis
```

to:

```text
Mathematical Workspace
```

without switching applications.

---

# 117. FINAL ARCHITECTURAL VISION

The final system is conceptually:

```text
                         ┌──────────────────────────┐
                         │       Flutter UI         │
                         │                          │
                         │ Windows │ Android       │
                         └────────────┬─────────────┘
                                      │
                         ┌────────────▼─────────────┐
                         │     Application Layer    │
                         │                          │
                         │ Calculate                │
                         │ Solver                   │
                         │ Graphing                 │
                         │ Statistics               │
                         │ Workspace                │
                         │ Spreadsheet              │
                         │ Formula Library          │
                         │ Sessions                 │
                         └────────────┬─────────────┘
                                      │
                         ┌────────────▼─────────────┐
                         │   Mathematical Core      │
                         │                          │
                         │ Expression Engine        │
                         │ Numeric Engine            │
                         │ Symbolic Engine           │
                         │ Algebra                   │
                         │ Calculus                  │
                         │ Solver                   │
                         │ Statistics               │
                         │ Probability              │
                         │ Units / Dimensions       │
                         │ Graph Sampling           │
                         └────────────┬─────────────┘
                                      │
                 ┌────────────────────┼────────────────────┐
                 │                    │                    │
          Mathematical Models    Algorithms          Validation
                 │                    │                    │
          Integer               Exact Methods       Domain Errors
          Decimal               Numerical Methods   Precision
          Fraction              Symbolic Methods    Dimensions
          Complex               Graph Algorithms    Matrix Rules
          Matrix                Statistics          Convergence
          Vector                Regression
          Polynomial            Probability
          Quantity
```

---

# 118. FINAL PRODUCT IDENTITY

The final product MUST be understood as:

> **A complete mathematical and engineering computing environment built around a reusable, deterministic Dart Mathematical Engine and presented through native-feeling Flutter experiences on Windows and Android.**

It begins with the capabilities expected from advanced scientific calculators, but its architecture intentionally extends beyond the traditional calculator model.

The original product vision explicitly describes this transition from a traditional calculator into a broader Mathematical Computing Platform.

---

# 119. FINAL NON-NEGOTIABLE PRINCIPLES

The following statements are considered immutable architectural principles unless explicitly changed in a future version of this specification:

1. **Flutter + Dart**
2. **Windows + Android**
3. **One shared Dart Mathematical Core**
4. **Clean Architecture**
5. **Lexer → Parser → AST → Evaluator**
6. **Typed Numeric System**
7. **No `double`-only architecture**
8. **Symbolic mathematics based on structured expressions**
9. **Solver separated into exact and numerical strategies**
10. **Graphing separated from UI**
11. **Complex as a core mathematical type**
12. **Matrix and Vector as core mathematical models**
13. **Units as dimensional analysis, not simple conversion**
14. **Spreadsheet as an independent subsystem**
15. **Formula Library as structured formulas**
16. **Unified mathematical error system**
17. **Deterministic Calculation Explanation where supported**
18. **Offline-first mathematical operation**
19. **Basic calculator UX remains immediately accessible**
20. **Production implementation — no fake/placeholder functionality**
21. **Mathematical correctness takes precedence over visual/UI convenience**
22. **No silent scope reduction**
23. **No unnecessary architectural rewrites**
24. **Every mathematical bug fix receives regression coverage**
25. **Future features must extend the architecture rather than invalidate it**

---

# 120. MASTER SPECIFICATION STATUS

```text
PRODUCT VISION              LOCKED
PLATFORM TARGETS            LOCKED
CORE ARCHITECTURE            LOCKED
MATHEMATICAL CORE            LOCKED
EXPRESSION ENGINE            LOCKED
NUMERIC ARCHITECTURE         LOCKED
SCIENTIFIC CALCULATOR        LOCKED
SOLVER SCOPE                 LOCKED
SYMBOLIC SCOPE               LOCKED
GRAPHING SCOPE               LOCKED
CALCULUS SCOPE               LOCKED
STATISTICS SCOPE             LOCKED
PROBABILITY SCOPE            LOCKED
COMPLEX NUMBERS              LOCKED
MATRIX                       LOCKED
VECTOR                       LOCKED
PROGRAMMER CALCULATOR        LOCKED
UNIT/DIMENSION ENGINE        LOCKED
FORMULA LIBRARY              LOCKED
TABLE MODE                   LOCKED
SPREADSHEET                  LOCKED
WORKSPACE                    LOCKED
SESSIONS                     LOCKED
OFFLINE-FIRST                LOCKED
ERROR SYSTEM                 LOCKED
TESTING PRINCIPLES           LOCKED
CROSS-PLATFORM CORE          LOCKED
FUTURE EXTENSIBILITY         DEFINED
IMPLEMENTATION ORDER         DEFINED
AGENT RULES                  DEFINED
ACCEPTANCE CRITERIA           DEFINED
```

---

# 121. IMPLEMENTATION START GATE

The project is considered ready to move from **Product Definition & Architecture** into **Implementation** after this Master Specification is accepted as the project baseline.

The implementation process MUST begin with the Mathematical Core and its contracts rather than beginning with visual UI development.

The first engineering objective is therefore:

```text
Project Foundation
        ↓
Mathematical Domain Model
        ↓
Numeric System
        ↓
Expression Language
        ↓
Lexer
        ↓
Parser
        ↓
AST
        ↓
Evaluator
        ↓
Scientific Calculator
```

Only after the mathematical foundation is stable should dependent advanced modules be built.

---

# 122. FINAL STATEMENT

This project is not defined as:

> "A Casio calculator recreated in Flutter."

It is defined as:

> **A Mathematical Computing Platform whose Scientific Calculator is the entry point and whose shared Mathematical Engine is the foundation for scientific calculation, engineering computation, symbolic mathematics, graphing, statistics, probability, calculus, programming, dimensional analysis, spreadsheets, formulas, and persistent mathematical workspaces.**

The architecture is intentionally designed so that future growth does not require rebuilding the mathematical foundation.

**END OF MASTER SPECIFICATION**
