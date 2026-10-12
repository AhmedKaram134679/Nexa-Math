# NexaMath — Implementation Roadmap

**Project:** NexaMath **Document:** Implementation Roadmap **Document Type:**
Engineering Execution Plan **Status:** Authoritative Implementation Roadmap
**Target Platforms:** Windows + Android **Framework:** Flutter **Language:**
Dart **Architecture:** Clean Architecture + Modular Mathematical Core **Primary
Goal:** Production-ready implementation

---

# 1. Document Purpose

This document defines the exact engineering execution order for implementing
NexaMath.

It is not a product specification and it is not an architectural proposal.

The purpose of this document is to translate the already-approved NexaMath
architecture into a controlled implementation sequence that can be executed by
Coding Agents without allowing uncontrolled architectural changes, premature UI
implementation, dependency violations, or incomplete feature delivery.

This roadmap must be used together with:

1. `CALCULATOR_MASTER_SPECIFICATION.md`
2. `NEXAMATH_IMPLEMENTATION_BLUEPRINT.md`
3. `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md`

These documents have different responsibilities:

| Document                                       | Responsibility                                                               |
| ---------------------------------------------- | ---------------------------------------------------------------------------- |
| `CALCULATOR_MASTER_SPECIFICATION.md`           | Defines what NexaMath must become                                            |
| `NEXAMATH_IMPLEMENTATION_BLUEPRINT.md`         | Defines the architecture and internal structure                              |
| `NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md` | Defines contracts, models, public APIs, package boundaries, and dependencies |
| `NEXAMATH_IMPLEMENTATION_ROADMAP.md`           | Defines how implementation must proceed                                      |

No implementation phase may redefine the responsibilities of the previous
documents without an explicit architectural review.

---

# 2. Implementation Philosophy

NexaMath must be implemented as a mathematical computing platform rather than as
a UI-first calculator application.

The implementation order therefore follows the dependency direction:

```text
Core
  ↓
Numeric System
  ↓
Expression Engine
  ↓
Mathematical Engines
  ↓
Application Layer
  ↓
Infrastructure
  ↓
Flutter Presentation
  ↓
Platform Integration
  ↓
Production Verification
```

The following principle is mandatory:

> The mathematical engine must exist independently of Flutter.

Flutter is the presentation and interaction layer.

The mathematical engine must be executable and testable without Flutter widgets.

---

# 3. Global Implementation Rules

Every Coding Agent working on NexaMath must follow these rules.

## 3.1 Production Code Only

The implementation must not contain:

- TODO
- FIXME
- placeholder implementations
- fake implementations
- mocked production behavior
- empty methods
- `throw UnimplementedError()` in production paths
- temporary hardcoded values
- example-only implementations
- silently reduced functionality
- duplicate domain models created for convenience

If a requested feature cannot be implemented correctly within the current phase,
the Agent must report the blocker rather than silently replacing the feature
with a weaker implementation.

---

# 3.2 Architecture Must Be Preserved

Agents must not:

- move responsibilities between layers without approval
- introduce circular dependencies
- bypass public engine contracts
- access internal engine implementations from Presentation
- place mathematical algorithms inside Flutter widgets
- place UI concerns inside Mathematical Core
- make Mathematical Core depend on Flutter
- make Expression Engine depend on Graphing, Solver, Spreadsheet, or UI
- make Algebra depend on Symbolic
- create duplicate versions of canonical mathematical models

---

# 3.3 Phase Isolation

A Coding Agent must work only within the assigned phase unless the task
explicitly authorizes cross-phase integration.

An Agent must not start implementing future features merely because the required
classes appear obvious.

For example:

- Graphing must not be implemented during Expression Engine.
- Flutter calculator UI must not be implemented during Numeric Engine.
- Spreadsheet must not be implemented during Application Layer.
- Persistence must not leak into Mathematical Core.

---

# 3.4 Test-Driven Completion

Every phase must include:

1. Unit tests
2. Contract tests where applicable
3. Edge-case tests
4. Failure/error tests
5. Regression tests for previous functionality

A phase is not complete merely because the code compiles.

---

# 3.5 Deterministic Mathematical Behavior

Mathematical operations must produce deterministic results across Windows and
Android for identical inputs and configuration.

Platform-specific behavior must not alter mathematical results.

---

# 3.6 Exact vs Approximate Results

The implementation must explicitly distinguish:

- exact results
- approximate results
- numerical approximations
- precision-limited results
- convergence failures
- unsupported symbolic operations

The system must never present an approximation as an exact mathematical result.

---

# 4. Phase Overview

The complete implementation sequence is:

```text
Phase 0   Project Foundation
Phase 1   Core Contracts
Phase 2   Numeric Engine
Phase 3   Expression Engine
Phase 4   Algebra Engine
Phase 5   Complex / Matrix / Vector
Phase 6   Symbolic Engine
Phase 7   Calculus Engine
Phase 8   Equation Solver
Phase 9   Statistics & Regression
Phase 10  Probability & Distributions
Phase 11  Units & Dimensional Analysis
Phase 12  Formula Engine
Phase 13  Graphing Engine
Phase 14  Programmer Engine
Phase 15  Application Layer
Phase 16  Spreadsheet Engine
Phase 17  Persistence & Infrastructure
Phase 18  Flutter Presentation
Phase 19  Platform Integration & End-to-End Integration
Phase 20  Full Verification & Production Hardening
Phase 21  Production Release
```

No later phase should begin until its required upstream contracts are stable.

---

# 5. Phase 0 — Project Foundation

## Objective

Create the NexaMath Flutter project and establish the repository, package
structure, analysis configuration, testing foundation, and architectural
boundaries.

This phase must not implement mathematical features or UI features.

---

## 5.1 Scope

Create:

```text
lib/
  core/
  mathematical_core/
  application/
  infrastructure/
  presentation/
```

Create the initial test structure:

```text
test/
  core/
  mathematical_core/
  application/
  infrastructure/
  presentation/
```

Establish:

- Flutter project
- Windows support
- Android support
- Dart analysis configuration
- formatting configuration
- linting
- test infrastructure
- dependency management
- project documentation structure
- architecture documentation
- package export boundaries

---

## 5.2 Dependencies

External dependencies must be kept minimal.

Any dependency introduced during this phase must have a documented purpose.

No package should be introduced merely for convenience when equivalent Dart
functionality is sufficient.

---

## 5.3 Forbidden Scope

Do not implement:

- calculator UI
- parser
- evaluator
- mathematical algorithms
- persistence
- graphing
- spreadsheet
- platform update logic

---

## 5.4 Tests

Verify:

- Flutter project builds for Windows
- Flutter project builds for Android
- test suite executes
- analyzer executes
- formatting executes
- project structure matches architecture

---

## 5.5 Acceptance Criteria

Phase 0 is complete when:

- project builds successfully
- Windows target is valid
- Android target is valid
- analysis passes
- formatting passes
- test infrastructure passes
- required directory structure exists
- no architectural boundary is violated

---

# 6. Phase 1 — Core Contracts

## Objective

Implement the foundational contracts used by every subsequent layer.

---

## 6.1 Scope

Implement:

- core error hierarchy
- `MathResult<T>`
- validation contracts
- calculation metadata
- evaluation metadata
- mathematical context
- angle mode
- precision configuration
- numerical configuration
- calculation settings
- shared identifiers where required

---

## 6.2 Error System

Implement the approved error model including, where applicable:

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
```

Errors must carry enough structured information for Presentation to display
meaningful messages without exposing internal implementation details.

---

## 6.3 Tests

Test:

- error construction
- error classification
- metadata propagation
- result success/failure behavior
- validation behavior
- configuration defaults
- serialization if applicable

---

## 6.4 Acceptance Criteria

No mathematical engine may need to create its own incompatible error system.

The Core contracts must be reusable by every later engine.

---

# 7. Phase 2 — Numeric Engine

## Objective

Create NexaMath's canonical numerical value system.

The Numeric Engine is one of the most important foundations in the entire
project.

---

## 7.1 Scope

Implement:

```text
NumericValue
IntegerValue
DecimalValue
FractionValue
ComplexValue
```

and the approved supporting numeric abstractions.

Where applicable, support:

```text
PolynomialValue
QuantityValue
```

through their canonical domain owners and engine contracts.

---

## 7.2 Numeric Operations

Implement the required operations:

- addition
- subtraction
- multiplication
- division
- powers
- roots where supported
- comparison
- sign
- absolute value
- rounding
- precision handling
- conversion
- promotion

---

## 7.3 Numeric Promotion

Implement deterministic promotion rules.

Examples:

```text
Integer + Integer → Integer
Integer + Decimal → Decimal
Integer + Fraction → appropriate promoted exact representation
Real + Complex → Complex
```

The exact promotion policy must follow the Engine Contracts document.

---

## 7.4 Precision

The implementation must explicitly handle:

- precision
- scale
- rounding
- significant digits
- scientific notation
- floating-point limitations
- overflow
- underflow
- precision loss

The implementation must not assume `double` is sufficient for every mathematical
operation.

---

## 7.5 Tests

Create extensive tests for:

- integer arithmetic
- decimal arithmetic
- fractions
- mixed-type operations
- precision
- rounding
- negative values
- zero
- very large values
- very small values
- overflow
- underflow
- promotion
- equality
- deterministic behavior

---

## 7.6 Acceptance Criteria

The Numeric Engine must be independently testable without Flutter.

No Expression, Graphing, Solver, or UI implementation is allowed to compensate
for missing Numeric Engine behavior.

---

# 8. Phase 3 — Expression Engine

## Objective

Implement the central expression-processing pipeline.

This is the heart of NexaMath.

---

## 8.1 Architecture

Mandatory pipeline:

```text
Expression
   ↓
Lexer
   ↓
Tokens
   ↓
Parser
   ↓
AST
   ↓
Evaluator
   ↓
EvaluationResult
```

---

## 8.2 Scope

Implement:

- token definitions
- lexer
- parser
- AST nodes
- operator precedence
- associativity
- unary operators
- binary operators
- function calls
- constants
- variables
- grouping
- implicit multiplication where supported
- mathematical functions
- evaluation context
- evaluation result
- calculation metadata

---

## 8.3 AST

The AST must support the approved mathematical expression model.

Examples:

```text
NumberNode
VariableNode
UnaryOperationNode
BinaryOperationNode
FunctionCallNode
ConstantNode
QuantityNode
```

Additional nodes must be introduced only when required by the approved
expression language.

---

## 8.4 Evaluator

The evaluator must return:

```text
EvaluationResult
```

rather than assuming every result is merely a `NumericValue`.

This allows expressions to eventually evaluate to:

- scalar values
- complex values
- quantities
- matrices
- vectors
- polynomials
- symbolic forms where supported

---

## 8.5 Functions

Implement the approved mathematical function registry and function contracts.

Include, where applicable:

- trigonometric
- inverse trigonometric
- hyperbolic
- inverse hyperbolic
- logarithmic
- exponential
- root
- factorial
- combinatorial
- absolute
- rounding
- angle conversion

---

## 8.6 Angle Modes

Support:

```text
DEG
RAD
GRAD
```

Angle configuration must come from mathematical context rather than UI state.

---

## 8.7 Tests

Mandatory expression tests include:

```text
2 + 3
7 × 8
(5 + 3)^2 / 4
sin(30)
sqrt(25) × 2
log(100) + ln(e)
```

plus:

- precedence
- nested expressions
- unary minus
- nested functions
- invalid syntax
- mismatched parentheses
- undefined variables
- domain errors
- division by zero
- precision behavior
- angle modes
- implicit multiplication
- constants
- quantities where supported

---

## 8.8 Acceptance Criteria

The Expression Engine becomes the shared entry point for later mathematical
functionality.

No separate expression parser may be created inside Graphing, Solver,
Spreadsheet, Formula, or Application layers.

---

# 9. Phase 4 — Algebra Engine

## Objective

Implement foundational algebraic manipulation and polynomial operations.

---

## 9.1 Scope

Implement:

```text
Polynomial
PolynomialOperations
Simplifier
Expander
Factorizer
```

and the approved public `AlgebraEngine`.

---

## 9.2 Capabilities

Implement:

- polynomial construction
- addition
- subtraction
- multiplication
- scalar multiplication
- powers
- expansion
- simplification
- factorization
- substitution
- coefficient access
- degree
- polynomial evaluation

---

## 9.3 Tests

Test:

```text
(x + 2)(x + 3)
x² + 5x + 6
x² - 9
```

including:

- zero coefficients
- negative coefficients
- constant polynomials
- high-degree polynomials
- exact arithmetic
- factorization failures where appropriate

---

## 9.4 Acceptance Criteria

Polynomial behavior must be reusable by:

- Symbolic Engine
- Equation Solver
- Regression where applicable
- Explanation Engine

No duplicate polynomial implementation may be created later.

---

# 10. Phase 5 — Complex / Matrix / Vector Engines

## Objective

Implement the foundational mathematical models required for advanced mathematics
and engineering.

---

# 10.1 Complex Engine

Implement operations for:

- rectangular form
- polar form
- addition
- subtraction
- multiplication
- division
- powers
- roots
- conjugate
- magnitude
- argument
- conversions

Canonical `ComplexNumber` must remain owned by the Numeric layer.

---

# 10.2 Matrix Engine

Implement:

- matrix creation
- indexing
- addition
- subtraction
- multiplication
- scalar multiplication
- transpose
- determinant
- inverse
- rank
- trace
- matrix powers
- linear-system support

Advanced decomposition contracts may include:

- Gaussian elimination
- LU
- QR

as defined by the approved blueprint.

---

# 10.3 Vector Engine

Implement:

- addition
- subtraction
- scalar multiplication
- dot product
- cross product
- magnitude
- normalization
- angle
- projection

---

## 10.4 Tests

Test:

- dimension validation
- invalid matrix multiplication
- singular matrices
- zero vectors
- normalization
- complex edge cases
- determinant correctness
- inverse correctness
- deterministic results

---

## 10.5 Acceptance Criteria

Complex, Matrix, and Vector models must be reusable across later engines.

---

# 11. Phase 6 — Symbolic Engine

## Objective

Implement bounded, reliable symbolic mathematics.

The Symbolic Engine must not claim unlimited computer algebra capabilities.

---

## 11.1 Scope

Implement:

- symbolic expression representation using approved AST/domain structures
- symbolic simplification
- substitution
- expansion
- factorization integration
- symbolic differentiation
- limits
- supported symbolic integration

---

## 11.2 Symbolic Boundaries

Only mathematically supported operations should be exposed.

If an operation cannot be guaranteed to produce a correct symbolic result, the
system must return an explicit unsupported/limited result rather than a
fabricated expression.

---

## 11.3 Examples

Support operations such as:

```text
expand((x + 2)(x + 3))
factor(x² + 5x + 6)
differentiate(x² + sin(x))
substitute(x = 5)
```

where supported by the implementation.

---

## 11.4 Tests

Include:

- symbolic simplification
- algebraic identities
- differentiation
- substitution
- limits
- supported integration
- unsupported cases
- exactness preservation

---

## 11.5 Acceptance Criteria

Symbolic functionality must remain independent of UI and must reuse the existing
Expression and Algebra infrastructure.

---

# 12. Phase 7 — Calculus Engine

## Objective

Implement symbolic and numerical calculus.

---

## 12.1 Scope

Implement:

- symbolic differentiation
- numerical differentiation
- symbolic integration where supported
- numerical integration
- definite integration
- approximation
- calculus metadata
- error/convergence handling

---

## 12.2 Numerical Algorithms

Implement approved numerical methods with configurable options.

The engine must expose:

- tolerance
- iteration limits
- convergence information
- approximation metadata

---

## 12.3 Tests

Test:

```text
d/dx(x²)
d/dx(sin(x))
∫x dx
∫₀¹ x² dx
```

plus:

- numerical convergence
- divergence
- discontinuities
- singularities
- precision
- invalid intervals

---

# 13. Phase 8 — Equation Solver

## Objective

Implement exact and numerical equation solving.

---

## 13.1 Solver Categories

The Solver must distinguish:

### Exact

- linear
- quadratic
- cubic
- quartic
- supported polynomial systems

### Numerical

- Newton-Raphson
- Bisection
- Secant
- other approved numerical methods

### Systems

- linear systems
- supported nonlinear systems

---

## 13.2 Result Model

Solutions must clearly distinguish:

- exact solution
- numerical approximation
- no solution
- infinite solutions
- convergence failure

---

## 13.3 Tests

Test:

```text
2x + 4 = 10
x² - 5x + 6 = 0
```

and:

- repeated roots
- complex roots
- no real roots
- singular systems
- inconsistent systems
- infinite-solution systems
- numerical convergence failures

---

# 14. Phase 9 — Statistics & Regression

## Objective

Implement descriptive statistics and regression analysis.

---

## 14.1 Statistics

Implement:

- count
- sum
- mean
- median
- mode
- minimum
- maximum
- range
- variance
- standard deviation
- quartiles
- percentiles

---

## 14.2 Paired Data

Implement:

- covariance
- correlation
- paired datasets
- predicted values
- residuals

---

## 14.3 Regression

Implement approved regression models:

- linear
- quadratic
- cubic
- logarithmic
- exponential
- power
- geometric

Each result must expose structured information such as:

- coefficients
- equation
- correlation where applicable
- predicted values
- residuals
- model metadata

---

## 14.4 Tests

Test empty datasets, single-value datasets, duplicate values, negative values,
large values, and regression edge cases.

---

# 15. Phase 10 — Probability & Distributions

## Objective

Implement probability calculations and statistical distributions.

---

## 15.1 Distribution Architecture

Implement the approved `ProbabilityDistribution` contract and concrete
distribution implementations.

---

## 15.2 Required Capabilities

Support where defined:

- PDF
- CDF
- inverse CDF
- probability queries
- random sampling

---

## 15.3 Initial Distributions

Implement:

- Normal
- Binomial
- Poisson
- Uniform
- Exponential
- Geometric

Additional distributions may be implemented according to the Master
Specification and approved scope.

---

## 15.4 Tests

Test:

- valid parameters
- invalid parameters
- boundary conditions
- probability normalization
- CDF monotonicity
- inverse-CDF consistency
- deterministic seeded sampling where applicable

---

# 16. Phase 11 — Units & Dimensional Analysis

## Objective

Implement a true unit and dimensional-analysis system rather than a simple
conversion table.

---

## 16.1 Scope

Implement:

```text
Dimension
DimensionVector
Unit
Quantity
UnitEngine
```

---

## 16.2 Capabilities

Support:

- unit conversion
- base dimensions
- derived dimensions
- quantity arithmetic
- compatible addition/subtraction
- multiplication
- division
- powers
- normalization

---

## 16.3 Critical Requirement

Expressions such as:

```text
10 m + 50 cm
```

must be semantically processed as quantities.

The engine must normalize compatible units before arithmetic.

Expressions with incompatible dimensions must produce:

```text
DimensionMismatch
```

rather than silently calculating an invalid result.

---

## 16.4 Tests

Test:

```text
10 m + 50 cm
5 km + 300 m
10 m / 2 s
```

and incompatible operations.

---

# 17. Phase 12 — Formula Engine

## Objective

Implement structured formulas and reusable formula calculations.

---

## 17.1 Scope

Implement:

```text
FormulaDefinition
FormulaVariable
FormulaResult
FormulaEngine
```

---

## 17.2 Formula Categories

Initial categories include:

- Physics
- Geometry
- Finance
- Chemistry
- Engineering

---

## 17.3 Formula Structure

A formula must contain structured metadata including:

- identifier
- name
- category
- expression
- variables
- units
- descriptions
- required inputs
- output definition

---

## 17.4 Custom Formulas

Support user-created formulas according to the approved application
architecture.

---

## 17.5 Tests

Test:

- formula parsing
- variable binding
- units
- missing variables
- invalid values
- formula evaluation
- result metadata

---

# 18. Phase 13 — Graphing Engine

## Objective

Implement a UI-independent graphing computation engine.

---

## 18.1 Architecture

```text
GraphFunction
      ↓
Expression Engine
      ↓
Evaluation
      ↓
Graph Sampling Engine
      ↓
Graph Analysis
      ↓
Graph Series
      ↓
Renderer
```

The Renderer itself belongs to Presentation.

---

## 18.2 Scope

Implement:

- function registration
- graph ranges
- sampling
- graph points
- graph series
- discontinuity detection
- roots
- intersections
- trace coordinates
- extrema where supported
- derivative visualization
- integral visualization

---

## 18.3 Examples

Support:

```text
y = x²
y = sin(x)
y = e^x
```

---

## 18.4 Tests

Test:

- valid functions
- invalid functions
- discontinuities
- high-frequency functions
- zoom/range changes
- sampling stability
- root detection
- intersection detection

---

# 19. Phase 14 — Programmer Engine

## Objective

Implement programmer-calculator functionality.

---

## 19.1 Scope

Implement:

```text
IntegerBase
IntegerWidth
ProgrammerValue
ProgrammerEngine
```

---

## 19.2 Bases

Support:

```text
BIN
OCT
DEC
HEX
```

---

## 19.3 Bit Operations

Support:

- AND
- OR
- XOR
- NOT
- shifts
- rotations
- masks

---

## 19.4 Widths

Support:

```text
8-bit
16-bit
32-bit
64-bit
```

according to the approved integer semantics.

---

## 19.5 Tests

Test:

- signed/unsigned behavior
- overflow
- masks
- shifts
- rotations
- base conversion
- width boundaries

---

# 20. Phase 15 — Application Layer

## Objective

Connect mathematical engines to user-facing application workflows without
placing UI logic inside the mathematical core.

---

## 20.1 Scope

Implement:

- calculation use cases
- calculation results
- history
- replay
- variables
- functions
- constants
- sessions
- workspaces
- settings
- explanation workflows

---

## 20.2 Calculation Use Case

Implement the primary workflow:

```text
CalculateExpressionUseCase
```

It must orchestrate:

```text
Input
 ↓
Mathematical Context
 ↓
Expression Engine
 ↓
EvaluationResult
 ↓
Application Result
 ↓
History
```

---

## 20.3 History

Support:

- store
- retrieve
- replay
- edit
- copy
- delete
- reuse
- search
- pin

---

## 20.4 Variables

Support:

- answer memory
- constants
- session variables
- function memory
- named variables

Examples:

```text
A = 25
B = 10
C = A × B
```

---

## 20.5 Session vs Workspace

These concepts must remain separate.

### Session

Represents an active calculation environment containing:

- history
- variables
- functions
- settings
- calculations

### Workspace

Represents a persistent mathematical project containing:

- variables
- constants
- equations
- calculations
- tables
- graphs
- results
- notes

---

# 21. Phase 16 — Spreadsheet Engine

## Objective

Implement the spreadsheet system as an independent engine consuming the
Mathematical Core.

---

## 21.1 Scope

Implement:

- workbook
- worksheet
- cells
- cell references
- formulas
- dependency graph
- recalculation
- functions
- ranges
- copy/paste semantics
- fill behavior
- data analysis

---

## 21.2 Dependency Graph

Implement dependency tracking so that changes to one cell propagate only to
affected cells.

---

## 21.3 Circular References

Detect circular references and return structured errors.

The system must not enter an infinite recalculation loop.

---

## 21.4 Tests

Test:

```text
A1 = 10
A2 = 20
A3 = A1 + A2
```

and:

- chained dependencies
- formulas
- ranges
- recalculation
- circular references
- invalid references
- copy/fill behavior

---

# 22. Phase 17 — Persistence & Infrastructure

## Objective

Implement durable storage and external/platform integrations without
contaminating the Mathematical Core.

---

## 22.1 Scope

Implement repository abstractions and concrete infrastructure implementations
for:

- settings
- history
- variables
- sessions
- workspaces
- formulas
- spreadsheet documents

---

## 22.2 Infrastructure Rule

Infrastructure implements contracts defined by upper layers.

The Mathematical Core must never directly depend on:

- filesystem APIs
- database libraries
- Flutter
- Android APIs
- Windows APIs

---

## 22.3 Persistence

Persist:

- application settings
- calculation history
- user variables
- functions
- sessions
- workspaces
- custom formulas
- spreadsheet data

according to approved data models.

---

## 22.4 Migration

Persistence models must support future schema changes.

No direct coupling between domain objects and storage representation should be
introduced.

---

# 23. Phase 18 — Flutter Presentation

## Objective

Implement the production Flutter interface after the mathematical/application
foundations are stable.

This phase is intentionally late.

---

# 23.1 Global UI Architecture

Implement Presentation using the approved architecture.

The UI must communicate with Application use cases and state controllers rather
than directly manipulating Mathematical Core internals.

---

# 23.2 Primary Modes

Implement:

- Calculate
- Statistics
- Graphing
- Equation Solver
- Complex
- Matrix
- Vector
- Spreadsheet
- Probability
- Distribution
- Calculus
- Programmer
- Unit Conversion
- Formula Library

according to the approved UX architecture.

---

# 23.3 Calculator UI

Provide:

- expression input
- mathematical display
- keypad
- scientific functions
- result display
- history access
- variables
- angle mode
- precision mode
- copy/paste
- keyboard support

---

# 23.4 Mathematical Display

The Presentation layer must render mathematical expressions professionally.

The rendering layer must not perform mathematical calculations.

Calculation remains the responsibility of the Mathematical Core.

---

# 23.5 Windows UX

Implement:

- mouse interaction
- keyboard
- numpad
- shortcuts
- resizable window
- persistent navigation
- history panel
- graph panel
- spreadsheet panel
- context menus
- desktop-oriented layout

---

# 23.6 Android UX

Implement:

- touch-first controls
- large touch targets
- portrait mode
- landscape mode
- swipe navigation
- touch keypad
- long-press secondary functions
- clipboard
- sharing
- persistent session state

---

# 23.7 RTL and Localization

The UI must support:

- Arabic
- English
- RTL
- LTR

without modifying mathematical semantics.

---

# 23.8 Accessibility

Implement appropriate:

- semantic labels
- keyboard navigation
- readable contrast
- scalable text
- touch target sizing
- focus behavior

---

# 24. Phase 19 — Platform Integration & End-to-End Integration

## Objective

Connect the complete application to Windows and Android platform behavior.

---

## 24.1 Windows

Verify:

- application startup
- window behavior
- keyboard input
- clipboard
- filesystem access
- persistence
- packaging
- installer integration
- platform-specific behavior

---

## 24.2 Android

Verify:

- application startup
- touch interaction
- lifecycle handling
- persistence
- clipboard
- orientation
- permissions
- Android packaging
- release APK behavior

---

## 24.3 End-to-End Flows

Verify complete workflows:

```text
User Input
 ↓
Flutter UI
 ↓
Application Layer
 ↓
Expression Engine
 ↓
Mathematical Engine
 ↓
Result
 ↓
Application State
 ↓
Presentation
```

---

# 25. Phase 20 — Full Verification & Production Hardening

## Objective

Perform full-system verification before release.

This phase is mandatory.

---

# 25.1 Static Verification

Run:

- `flutter analyze`
- formatting checks
- dependency validation
- architecture checks
- unused-code checks
- dead-code review

Target:

```text
0 analyzer errors
0 analyzer warnings
```

where project policy permits no warnings.

---

# 25.2 Unit Testing

All mathematical engines must have comprehensive unit coverage.

---

# 25.3 Integration Testing

Test interaction between:

- Numeric + Expression
- Expression + Algebra
- Expression + Symbolic
- Expression + Calculus
- Expression + Solver
- Expression + Units
- Formula + Units
- Graphing + Expression
- Spreadsheet + Expression
- Application + Mathematical Core

---

# 25.4 Regression Testing

Create a permanent mathematical regression suite.

Every discovered mathematical defect must produce a regression test.

---

# 25.5 Cross-Platform Testing

Run the same mathematical test vectors on:

- Windows
- Android

The expected mathematical results must remain deterministic.

---

# 25.6 Precision Verification

Verify:

- exact arithmetic
- decimal precision
- fractions
- complex calculations
- matrix calculations
- numerical methods
- rounding
- scientific notation

---

# 25.7 Error Verification

Every major mathematical error must be intentionally tested.

Examples:

```text
DivisionByZero
DomainError
DimensionMismatch
MatrixDimensionError
SingularMatrix
NoSolution
InfiniteSolutions
ConvergenceFailure
PrecisionLoss
InvalidExpression
SyntaxError
```

---

# 25.8 Performance Verification

Measure:

- expression evaluation
- parser performance
- large polynomial operations
- matrix operations
- graph sampling
- statistical calculations
- spreadsheet recalculation
- application startup
- memory usage

Performance problems must be profiled before optimization.

---

# 25.9 UI Verification

Verify:

- responsive layouts
- Windows resizing
- Android orientations
- keyboard navigation
- touch targets
- accessibility
- RTL
- LTR
- localization
- dark/light presentation if included in approved UI scope

---

# 26. Phase 21 — Production Release

## Objective

Produce the release-ready NexaMath application.

---

## 26.1 Release Artifacts

Produce:

- Windows production build
- Windows installer
- Android release APK
- release documentation
- version metadata
- changelog
- test report
- architecture compliance report

---

## 26.2 Release Gate

The project must not be declared production-ready until:

- all required features are implemented
- all mandatory tests pass
- no known critical mathematical defects remain
- analyzer passes
- Windows build passes
- Android build passes
- persistence works
- core calculations are deterministic
- mathematical errors are handled correctly
- no placeholder production code remains

---

# 27. Vertical Slice Strategy

Although implementation follows the engine sequence, one controlled vertical
slice must be created early enough to prove the architecture without prematurely
implementing the complete UI.

The first mathematical vertical slice is:

```text
2 + 3
```

followed by:

```text
(5 + 3)^2 / 4
```

then:

```text
sin(30)
```

then:

```text
sqrt(25) × 2
```

The slice must demonstrate:

```text
Input
 ↓
Lexer
 ↓
Parser
 ↓
AST
 ↓
Evaluator
 ↓
Numeric Engine
 ↓
EvaluationResult
```

This is an architecture verification slice, not permission to begin full
Presentation development.

---

# 28. Agent Execution Protocol

Every Coding Agent must follow the following procedure.

---

## Step 1 — Read

Before modifying code, the Agent must read:

```text
CALCULATOR_MASTER_SPECIFICATION.md
NEXAMATH_IMPLEMENTATION_BLUEPRINT.md
NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md
NEXAMATH_IMPLEMENTATION_ROADMAP.md
```

and the relevant previous phase report.

---

## Step 2 — Identify Phase

The Agent must explicitly identify:

```text
Current Phase
Current Objective
Allowed Packages
Required Contracts
Dependencies
Forbidden Dependencies
Acceptance Criteria
```

---

## Step 3 — Inspect Existing Code

Before creating or modifying a file, inspect the existing implementation.

Do not recreate existing models.

Do not introduce duplicate abstractions.

---

## Step 4 — Implement

Implement only the assigned phase.

Production quality is mandatory.

---

## Step 5 — Test

Run the complete relevant test suite.

Do not test only the newly created files.

---

## Step 6 — Verify Architecture

Confirm:

- imports
- dependencies
- public API boundaries
- forbidden dependencies
- model ownership
- error ownership

---

## Step 7 — Report

Every Agent must return an English Markdown report.

Recommended filename:

```text
WALKTHROUGH_PHASE_<N>_<NAME>.md
```

The report must contain:

```text
1. Executive Summary
2. Implemented Scope
3. Files Created
4. Files Modified
5. Public APIs Added
6. Models Added
7. Algorithms Implemented
8. Dependencies
9. Tests Added
10. Tests Executed
11. Test Results
12. Architecture Compliance
13. Known Limitations
14. Deferred Work
15. Acceptance Criteria Status
16. Final Verification
```

---

# 29. Agent Permission Model

Agents are allowed to:

- create files required by the current phase
- modify files required by the current phase
- create tests
- refactor local implementation while preserving public contracts
- improve internal implementation quality
- fix defects discovered in the current scope

Agents are not allowed to:

- redefine public contracts without approval
- change canonical model ownership
- introduce new architectural layers
- skip required tests
- remove functionality to make tests pass
- change behavior silently
- modify unrelated modules
- start future phases
- add dependencies without justification
- bypass existing engine contracts

---

# 30. Architectural Review Gates

Architectural review is required before:

### Gate 1

Moving from:

```text
Core → Numeric → Expression
```

to advanced mathematical engines.

### Gate 2

Starting Symbolic Engine.

### Gate 3

Starting Graphing Engine.

### Gate 4

Starting Application Layer.

### Gate 5

Starting Spreadsheet Engine.

### Gate 6

Starting Flutter Presentation.

### Gate 7

Starting final production integration.

At every gate, the previous phase must be considered contractually stable.

---

# 31. Definition of Done

A phase is considered **Done** only when all of the following are true:

```text
[ ] Required implementation completed
[ ] Public contracts implemented
[ ] Canonical models used
[ ] No duplicate domain models
[ ] No forbidden dependencies
[ ] Unit tests implemented
[ ] Edge cases tested
[ ] Error cases tested
[ ] Regression tests preserved
[ ] Analyzer passes
[ ] Formatting passes
[ ] Relevant integration tests pass
[ ] Acceptance criteria satisfied
[ ] No TODO/FIXME placeholders
[ ] No incomplete production paths
[ ] Documentation/report generated
```

---

# 32. Definition of Architecture Complete

The architecture implementation is considered complete only when:

```text
Core
 ↓
Numeric
 ↓
Expression
 ↓
Algebra
 ↓
Complex / Matrix / Vector
 ↓
Symbolic
 ↓
Calculus
 ↓
Solver
 ↓
Statistics
 ↓
Probability
 ↓
Units
 ↓
Formula
 ↓
Graphing
 ↓
Programmer
 ↓
Application
 ↓
Spreadsheet
 ↓
Infrastructure
 ↓
Presentation
```

is implemented without prohibited dependency inversion or circular dependencies.

---

# 33. Definition of Mathematical Core Complete

The Mathematical Core is complete when the following are independently
executable and testable without Flutter:

- Numeric Engine
- Expression Engine
- Algebra Engine
- Complex Engine
- Matrix Engine
- Vector Engine
- Symbolic Engine
- Calculus Engine
- Equation Solver
- Statistics Engine
- Probability Engine
- Units Engine
- Formula Engine
- Graphing computation engine
- Programmer Engine

---

# 34. Definition of Application Complete

The Application layer is complete when users can conceptually operate the
Mathematical Core through:

- calculations
- history
- variables
- functions
- sessions
- workspaces
- formulas
- tables
- spreadsheets
- explanations
- settings

without requiring mathematical algorithms inside Presentation.

---

# 35. Definition of Product Complete

NexaMath is product-complete when the application provides the integrated
experience defined by the Master Specification:

```text
Scientific Calculator
+
Engineering Calculator
+
Graphing Calculator
+
Mathematical Solver
+
Statistics Tool
+
Programmer Calculator
+
Unit Converter
+
Formula Workspace
+
Mathematical Notebook
```

within a single coherent application architecture.

---

# 36. Post-Release Expansion

Only after the production baseline is stable should the project expand toward:

- cloud synchronization
- user-created advanced functions
- advanced charting
- mathematical documents
- formula marketplace
- plugin architecture
- additional mathematical modules
- AI-assisted mathematical explanations

These features must not destabilize the offline mathematical core.

---

# 37. Recommended Implementation Order for Coding Agents

The actual execution order is therefore:

```text
01. Project Foundation
02. Core Contracts
03. Numeric Engine
04. Expression Engine
05. Algebra Engine
06. Complex Engine
07. Matrix Engine
08. Vector Engine
09. Symbolic Engine
10. Calculus Engine
11. Equation Solver
12. Statistics Engine
13. Regression
14. Probability Engine
15. Units & Dimensional Analysis
16. Formula Engine
17. Graphing Engine
18. Programmer Engine
19. Application Layer
20. Spreadsheet Engine
21. Persistence
22. Infrastructure
23. Flutter Presentation
24. Windows Integration
25. Android Integration
26. End-to-End Integration
27. Full Verification
28. Production Hardening
29. Release
```

The sequence must not be compressed into a single "build the application"
instruction.

Each phase must be implemented, tested, reviewed, and documented before
proceeding.

---

# 38. Final Engineering Principle

NexaMath must not be implemented as:

```text
Flutter UI
    ↓
Calculator Code
    ↓
More Features
```

It must be implemented as:

```text
               NexaMath
                   │
        ┌──────────┴──────────┐
        │                     │
  Flutter Presentation    Application
        │                     │
        └──────────┬──────────┘
                   │
           Mathematical Core
                   │
   ┌───────────────┼────────────────┐
   │               │                │
Numeric        Expression       Mathematical
 System          Engine           Engines
   │               │                │
   │        ┌──────┴──────┐         │
   │        │             │         │
   │      Lexer         Parser      │
   │        │             │         │
   │        └──────┬──────┘         │
   │               │                │
   └────────── Evaluator ───────────┘
                   │
          Application Services
                   │
           Infrastructure
                   │
          Windows / Android
```

The Mathematical Core is the foundation.

The Expression Engine is the central computational pipeline.

The Application Layer is the orchestration layer.

Flutter is the presentation layer.

Infrastructure is an implementation detail.

No platform-specific concern may redefine mathematical behavior.

---

# 39. Roadmap Status

```text
Document: NEXAMATH_IMPLEMENTATION_ROADMAP.md
Status: APPROVED FOR EXECUTION
Implementation Strategy: Phase-by-Phase
Architecture Strategy: Core-First
UI Strategy: Presentation-Late
Testing Strategy: Continuous + Regression
Deployment Strategy: Windows + Android
Mathematical Strategy: Offline-First
Production Standard: Required
```

The next implementation artifact after this roadmap is:

```text
NEXAMATH_CODING_AGENT_MASTER_PROMPT.md
```

That document must convert this roadmap into a strict operational instruction
set for Coding Agents.

It must instruct an Agent to:

1. read all authoritative documents
2. identify the assigned phase
3. inspect the repository
4. implement only the assigned scope
5. preserve architecture
6. execute tests
7. verify dependencies
8. generate an English `walkthrough.md`-style report
9. stop after phase completion
10. wait for review before proceeding to the next phase

No Coding Agent should receive an instruction equivalent to:

> "Build the entire NexaMath application."

The correct execution model is:

```text
Specification
      ↓
Architecture
      ↓
Contracts
      ↓
Roadmap
      ↓
Coding Agent Master Prompt
      ↓
Phase 0
      ↓
Review
      ↓
Phase 1
      ↓
Review
      ↓
...
      ↓
Production Release
```

This controlled sequence is the official implementation path for NexaMath.
