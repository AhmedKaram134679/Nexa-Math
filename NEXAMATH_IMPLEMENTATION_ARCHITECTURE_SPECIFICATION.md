# NexaMath

## Implementation Architecture Specification

**Project:** NexaMath
**Product Type:** Mathematical Computing Platform
**Platforms:** Windows + Android
**Technology:** Flutter + Dart
**Architecture:** Clean Architecture + Modular Engine Architecture
**Status:** Architecture Specification
**Authority:** Derived from `CALCULATOR_MASTER_SPECIFICATION.md`

---

# 1. Document Purpose

This document defines the implementation architecture of **NexaMath**.

It translates the product and mathematical requirements defined in the Master Specification into a concrete software architecture consisting of:

* packages
* folders
* modules
* classes
* interfaces
* models
* value objects
* contracts
* dependency boundaries
* engine responsibilities
* application services
* infrastructure services
* presentation boundaries
* persistence boundaries
* testing boundaries

This document is the implementation-level architectural contract for NexaMath.

The Master Specification defines **what NexaMath must do**.

This document defines **how NexaMath must be structured to do it**.

---

# 2. Architectural Objective

NexaMath must not be implemented as a large Flutter application with mathematical logic scattered across widgets, controllers, screens, and utility classes.

The architecture must establish a strict separation:

```text
Presentation
      ↓
Application
      ↓
Domain / Mathematical Core
      ↓
Infrastructure
```

The Mathematical Core must remain independent from:

* Flutter
* Android APIs
* Windows APIs
* UI widgets
* navigation
* persistence implementations
* platform-specific services
* networking
* graphical UI rendering

The same Mathematical Core must be executable on Windows and Android.

---

# 3. High-Level Architecture

```text
                         ┌──────────────────────┐
                         │      Flutter UI      │
                         │ Windows + Android    │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │   Presentation       │
                         │ Controllers / State  │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │    Application       │
                         │ Use Cases / Services │
                         └──────────┬───────────┘
                                    │
                                    ▼
              ┌────────────────────────────────────────┐
              │          NexaMath Mathematical Core    │
              │                                        │
              │ Expression                             │
              │ Numeric                                │
              │ Algebra                                │
              │ Symbolic                               │
              │ Calculus                               │
              │ Solver                                 │
              │ Complex                                │
              │ Matrix                                 │
              │ Vector                                 │
              │ Statistics                             │
              │ Probability                             │
              │ Units                                  │
              │ Formula                                │
              │ Graphing                               │
              │ Programmer                             │
              └──────────────────┬─────────────────────┘
                                 │
                                 ▼
              ┌────────────────────────────────────────┐
              │       Shared Mathematical Models       │
              └────────────────────────────────────────┘

              ┌────────────────────────────────────────┐
              │ Spreadsheet / Workspace / Sessions     │
              └────────────────────────────────────────┘

              ┌────────────────────────────────────────┐
              │          Infrastructure                 │
              │ Persistence / Files / Platform         │
              └────────────────────────────────────────┘
```

---

# 4. Package Architecture

The primary package structure is:

```text
lib/
├── core/
├── mathematical_core/
├── application/
├── infrastructure/
└── presentation/
```

The architecture must not place mathematical algorithms directly inside `presentation/`.

---

# 5. Complete Folder Structure

The initial architectural target is:

```text
lib/
│
├── core/
│   ├── errors/
│   ├── result/
│   ├── validation/
│   ├── configuration/
│   ├── localization/
│   └── utilities/
│
├── mathematical_core/
│   │
│   ├── expression/
│   │   ├── lexer/
│   │   ├── parser/
│   │   ├── ast/
│   │   ├── evaluator/
│   │   ├── functions/
│   │   ├── operators/
│   │   ├── tokens/
│   │   └── expression_engine.dart
│   │
│   ├── numeric/
│   │   ├── integer/
│   │   ├── decimal/
│   │   ├── fraction/
│   │   ├── precision/
│   │   ├── rounding/
│   │   └── numeric_engine.dart
│   │
│   ├── algebra/
│   │   ├── polynomial/
│   │   ├── simplification/
│   │   ├── expansion/
│   │   └── factorization/
│   │
│   ├── symbolic/
│   │   ├── expressions/
│   │   ├── simplifier/
│   │   ├── substitution/
│   │   ├── differentiation/
│   │   ├── limits/
│   │   └── integration/
│   │
│   ├── calculus/
│   │   ├── differentiation/
│   │   ├── integration/
│   │   ├── numerical/
│   │   └── approximation/
│   │
│   ├── solver/
│   │   ├── linear/
│   │   ├── quadratic/
│   │   ├── cubic/
│   │   ├── quartic/
│   │   ├── polynomial/
│   │   ├── numerical/
│   │   ├── systems/
│   │   └── nonlinear/
│   │
│   ├── complex/
│   │   ├── rectangular/
│   │   ├── polar/
│   │   └── complex_number.dart
│   │
│   ├── matrix/
│   │   ├── operations/
│   │   ├── decomposition/
│   │   ├── systems/
│   │   └── matrix.dart
│   │
│   ├── vector/
│   │   ├── operations/
│   │   └── vector.dart
│   │
│   ├── statistics/
│   │   ├── descriptive/
│   │   ├── regression/
│   │   └── correlation/
│   │
│   ├── probability/
│   │   ├── distributions/
│   │   ├── probability/
│   │   └── sampling/
│   │
│   ├── units/
│   │   ├── dimensions/
│   │   ├── units/
│   │   ├── quantities/
│   │   └── conversion/
│   │
│   ├── formulas/
│   │   ├── physics/
│   │   ├── geometry/
│   │   ├── finance/
│   │   ├── chemistry/
│   │   ├── custom/
│   │   └── formula_engine.dart
│   │
│   ├── graphing/
│   │   ├── functions/
│   │   ├── sampling/
│   │   ├── analysis/
│   │   ├── coordinates/
│   │   └── graph_engine.dart
│   │
│   └── programmer/
│       ├── bases/
│       ├── bitwise/
│       └── programmer_engine.dart
│
├── application/
│   ├── calculator/
│   ├── history/
│   ├── variables/
│   ├── sessions/
│   ├── workspace/
│   ├── spreadsheet/
│   ├── formulas/
│   ├── graphing/
│   ├── settings/
│   └── shared/
│
├── infrastructure/
│   ├── persistence/
│   ├── filesystem/
│   ├── platform/
│   ├── import_export/
│   └── logging/
│
└── presentation/
    ├── app/
    ├── navigation/
    ├── theme/
    ├── shared/
    ├── calculator/
    ├── statistics/
    ├── graphing/
    ├── solver/
    ├── calculus/
    ├── complex/
    ├── matrix/
    ├── vector/
    ├── programmer/
    ├── units/
    ├── formulas/
    ├── spreadsheet/
    ├── workspace/
    ├── history/
    ├── sessions/
    └── settings/
```

This is an architectural target. Individual files must only be created when required by an actual implementation contract.

---

# 6. Core Layer

`core/` contains application-independent infrastructure concepts shared by the application.

It must not contain domain-specific mathematical algorithms.

## 6.1 Errors

```text
core/errors/
```

Primary types:

```dart
abstract interface class NexaMathError {}

final class InvalidExpressionError implements NexaMathError {}
final class SyntaxError implements NexaMathError {}
final class DivisionByZeroError implements NexaMathError {}
final class DomainError implements NexaMathError {}
final class OverflowError implements NexaMathError {}
final class UnderflowError implements NexaMathError {}
final class PrecisionLossError implements NexaMathError {}
final class DimensionMismatchError implements NexaMathError {}
final class MatrixDimensionError implements NexaMathError {}
final class SingularMatrixError implements NexaMathError {}
final class NoSolutionError implements NexaMathError {}
final class InfiniteSolutionsError implements NexaMathError {}
final class ConvergenceFailureError implements NexaMathError {}
final class ValidationError implements NexaMathError {}
```

Errors must be explicit.

No mathematical failure may silently return an invalid numeric value.

---

# 7. Result Contract

Mathematical engines must not depend on UI exceptions.

A unified result abstraction is required:

```dart
sealed class MathResult<T> {
  const MathResult();
}

final class MathSuccess<T> extends MathResult<T> {
  final T value;
  const MathSuccess(this.value);
}

final class MathFailure<T> extends MathResult<T> {
  final NexaMathError error;
  const MathFailure(this.error);
}
```

The exact implementation may evolve, but the contract must preserve:

```text
Success → typed value
Failure → typed mathematical error
```

---

# 8. Mathematical Core

The Mathematical Core is the most important architectural boundary in NexaMath.

It must be:

* Dart-only
* Flutter-independent
* platform-independent
* deterministic
* testable without UI
* reusable by every mathematical feature

The Master Specification explicitly requires a shared Dart Mathematical Core for Windows and Android.

---

# 9. Numeric Engine

The Numeric Engine provides the fundamental mathematical value system.

Required conceptual types:

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

These are not UI models.

They are mathematical domain models.

## 9.1 Numeric Contracts

```dart
abstract interface class NumericValue {
  NumericKind get kind;
}

enum NumericKind {
  integer,
  decimal,
  fraction,
  complex,
  matrix,
  vector,
  polynomial,
  quantity,
}
```

The implementation must support controlled promotion between compatible numeric representations.

Example:

```text
Integer
   ↓
Decimal

Integer
   ↓
Fraction

Real
   ↓
Complex
```

Promotion rules must be deterministic and documented.

---

# 10. Precision Architecture

The system must not depend exclusively on Dart `double`.

Precision responsibilities belong to:

```text
mathematical_core/numeric/precision/
mathematical_core/numeric/rounding/
```

Required concepts:

```text
PrecisionContext
RoundingMode
SignificantDigits
DisplayPrecision
CalculationPrecision
```

Calculation precision and display precision must remain separate.

For example:

```text
Internal result:
1.234567890123...

Displayed result:
1.235
```

The display formatting must never destroy the internal mathematical value.

---

# 11. Expression Engine

The Expression Engine is the central dependency of NexaMath.

Architecture:

```text
Source Expression
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
Numeric / Symbolic Result
```

This architecture is required because the Expression Engine is reused by calculator, graphing, solver, table, spreadsheet, symbolic mathematics, and workspace features. The Master Specification defines the same Lexer → Parser → AST → Evaluator model.

---

# 12. Lexer Contract

```dart
abstract interface class Lexer {
  MathResult<List<Token>> tokenize(String source);
}
```

Responsibilities:

* lexical analysis
* number recognition
* identifiers
* operators
* parentheses
* commas
* function names
* unit symbols where supported
* constants

The lexer must not evaluate expressions.

---

# 13. Parser Contract

```dart
abstract interface class ExpressionParser {
  MathResult<ExpressionNode> parse(List<Token> tokens);
}
```

Responsibilities:

* precedence
* associativity
* unary operators
* binary operators
* function calls
* grouping
* implicit multiplication where supported

The parser must not perform numerical calculation.

---

# 14. AST

The AST is the shared expression representation.

Conceptual hierarchy:

```dart
sealed class ExpressionNode {}

final class NumberNode extends ExpressionNode {}
final class ConstantNode extends ExpressionNode {}
final class VariableNode extends ExpressionNode {}
final class UnaryNode extends ExpressionNode {}
final class BinaryNode extends ExpressionNode {}
final class FunctionCallNode extends ExpressionNode {}
final class FractionNode extends ExpressionNode {}
final class UnitExpressionNode extends ExpressionNode {}
```

The AST must be independent from Flutter rendering.

---

# 15. Evaluator Contract

```dart
abstract interface class ExpressionEvaluator {
  MathResult<NumericValue> evaluate(
    ExpressionNode expression,
    EvaluationContext context,
  );
}
```

`EvaluationContext` provides:

```text
Variables
Constants
Functions
Angle Mode
Precision
Numeric Configuration
Unit Context
```

The evaluator must not access application storage directly.

---

# 16. Expression Engine Public API

A façade may expose:

```dart
abstract interface class ExpressionEngine {
  MathResult<ExpressionNode> parse(String source);

  MathResult<NumericValue> evaluate(
    String source,
    EvaluationContext context,
  );

  MathResult<NumericValue> evaluateAst(
    ExpressionNode expression,
    EvaluationContext context,
  );
}
```

Other engines should depend on this public contract rather than directly depending on lexer/parser implementation details.

---

# 17. Symbolic Engine

The Symbolic Engine operates primarily on expressions/ASTs rather than evaluated numeric values.

Responsibilities:

```text
Simplification
Expansion
Factorization
Substitution
Symbolic Differentiation
Limits
Supported Symbolic Integration
Polynomial Manipulation
```

The Master Specification explicitly limits symbolic integration to what can be supported reliably rather than implying unrestricted computer algebra parity.

Public contract:

```dart
abstract interface class SymbolicEngine {
  MathResult<ExpressionNode> simplify(ExpressionNode expression);

  MathResult<ExpressionNode> expand(ExpressionNode expression);

  MathResult<ExpressionNode> factor(ExpressionNode expression);

  MathResult<ExpressionNode> substitute(
    ExpressionNode expression,
    Map<String, ExpressionNode> substitutions,
  );

  MathResult<ExpressionNode> differentiate(
    ExpressionNode expression,
    String variable,
  );
}
```

Unsupported symbolic operations must return explicit failures rather than incorrect results.

---

# 18. Algebra Engine

The Algebra Engine provides reusable algebraic algorithms.

Responsibilities:

```text
Polynomial representation
Polynomial arithmetic
Expansion
Factorization
Coefficient extraction
Degree calculation
Polynomial evaluation
```

The Solver and Symbolic Engine may consume Algebra Engine contracts.

---

# 19. Solver Engine

The Solver Engine is divided into exact and numerical solving.

```text
solver/
├── linear/
├── quadratic/
├── cubic/
├── quartic/
├── polynomial/
├── numerical/
├── systems/
└── nonlinear/
```

## 19.1 Exact Solvers

```dart
abstract interface class ExactEquationSolver {
  MathResult<EquationSolution> solve(Equation equation);
}
```

Implementations:

```text
LinearEquationSolver
QuadraticEquationSolver
CubicEquationSolver
QuarticEquationSolver
PolynomialEquationSolver
```

## 19.2 Numerical Solvers

```dart
abstract interface class NumericalEquationSolver {
  MathResult<NumericalSolution> solve(
    Equation equation,
    NumericalSolverOptions options,
  );
}
```

Potential algorithms:

```text
Bisection
Newton-Raphson
Secant
```

Numerical solutions must identify themselves as approximations.

---

# 20. Calculus Engine

Responsibilities:

```text
Symbolic differentiation
Numerical differentiation
Symbolic integration where supported
Numerical integration
Definite integration
Approximation
```

Public contracts:

```dart
abstract interface class DifferentiationEngine {}

abstract interface class IntegrationEngine {}

abstract interface class NumericalCalculusEngine {}
```

Calculus must reuse the Expression and Symbolic engines rather than creating a second expression system.

---

# 21. Complex Number Engine

Complex numbers are a core numeric model, not merely a UI mode.

```dart
final class ComplexNumber {
  final NumericValue real;
  final NumericValue imaginary;
}
```

Required operations:

```text
Addition
Subtraction
Multiplication
Division
Powers
Roots
Conjugate
Magnitude
Argument
Rectangular ↔ Polar
```

The Complex Engine must be usable by:

* Expression Engine
* Solver
* Matrix Engine
* Calculus
* Calculator
* Programmer-independent mathematical functions where applicable

---

# 22. Matrix Engine

The Matrix Engine owns matrix mathematical behavior.

```dart
abstract interface class MatrixEngine {
  MathResult<Matrix> add(Matrix a, Matrix b);

  MathResult<Matrix> subtract(Matrix a, Matrix b);

  MathResult<Matrix> multiply(Matrix a, Matrix b);

  MathResult<Matrix> transpose(Matrix matrix);

  MathResult<NumericValue> determinant(Matrix matrix);

  MathResult<Matrix> inverse(Matrix matrix);

  MathResult<int> rank(Matrix matrix);

  MathResult<NumericValue> trace(Matrix matrix);
}
```

Additional algorithms may include:

```text
Matrix powers
Linear systems
LU decomposition
QR decomposition
Gaussian elimination
Eigenvalues
Eigenvectors
```

Only implemented and verified algorithms may be exposed publicly.

The Master Specification identifies these as matrix capabilities and future extensions.

---

# 23. Vector Engine

Required operations:

```text
Addition
Subtraction
Dot Product
Cross Product
Magnitude
Normalization
Angle
Projection
```

Contract:

```dart
abstract interface class VectorEngine {
  MathResult<Vector> add(Vector a, Vector b);

  MathResult<Vector> subtract(Vector a, Vector b);

  MathResult<NumericValue> dot(Vector a, Vector b);

  MathResult<Vector> cross(Vector a, Vector b);

  MathResult<NumericValue> magnitude(Vector vector);
}
```

---

# 24. Statistics Engine

Responsibilities:

```text
Mean
Median
Mode
Minimum
Maximum
Range
Variance
Standard Deviation
Quartiles
Percentiles
Sum
Correlation
```

Regression is separated as a specialized subsystem.

The Master Specification requires these statistical operations and relationship analysis.

---

# 25. Regression Engine

Required regression contracts:

```dart
abstract interface class RegressionModel {
  RegressionType get type;

  MathResult<RegressionResult> fit(
    RegressionDataset dataset,
  );
}
```

Supported model types:

```text
Linear
Quadratic
Cubic
Logarithmic
Exponential
Power
Geometric
```

Result model:

```text
Equation
Coefficients
Correlation
Predicted Values
Residuals
```

Graphing must consume regression results without owning regression algorithms.

---

# 26. Probability Engine

The Probability Engine owns:

```text
Probability calculations
Distributions
PDF
CDF
Inverse CDF
Random sampling
```

Distribution implementations must conform to a common contract:

```dart
abstract interface class ProbabilityDistribution {
  MathResult<double> pdf(double x);

  MathResult<double> cdf(double x);

  MathResult<double> inverseCdf(double probability);

  MathResult<double> sample(RandomSource source);
}
```

Supported distributions initially include:

```text
Normal
Binomial
Poisson
Uniform
Exponential
Geometric
```

Additional distributions may be added without changing the consuming application contracts.

---

# 27. Unit & Dimensional Analysis Engine

Units are not implemented as a simple converter.

The engine must model:

```text
Dimension
Unit
Quantity
Conversion
Derived Dimension
```

Example:

```text
10 m + 50 cm
```

must be interpreted through quantities and dimensions before evaluation.

Architecture:

```text
Expression
    ↓
Quantity
    ↓
Dimension Analysis
    ↓
Normalization
    ↓
Calculation
    ↓
Result Quantity
```

Required contract:

```dart
abstract interface class UnitEngine {
  MathResult<Quantity> convert(
    Quantity quantity,
    Unit targetUnit,
  );

  MathResult<Quantity> add(
    Quantity a,
    Quantity b,
  );

  MathResult<Quantity> multiply(
    Quantity a,
    Quantity b,
  );
}
```

Dimensionally invalid expressions must produce `DimensionMismatchError`.

---

# 28. Formula Engine

Formula Library entries must be structured objects rather than plain text.

Conceptual model:

```dart
final class FormulaDefinition {
  final String id;
  final String name;
  final String category;
  final ExpressionNode expression;
  final List<FormulaVariable> variables;
  final List<Unit> requiredUnits;
  final String description;
}
```

Categories include:

```text
Physics
Geometry
Finance
Chemistry
Custom
```

The Formula Engine must use the Mathematical Core to evaluate formulas.

The Master Specification explicitly defines structured formulas with variables, units, descriptions, categories, inputs, and outputs.

---

# 29. Graphing Engine

The Graphing Engine must remain independent from Flutter rendering.

Architecture:

```text
Function
   ↓
Expression Engine
   ↓
Evaluation
   ↓
Graph Sampling Engine
   ↓
Graph Data
   ↓
Renderer
```

Responsibilities:

```text
Function sampling
Discontinuity detection
Coordinate generation
Root detection
Intersection analysis
Maximum/minimum analysis
Derivative visualization
Integral visualization
```

The Flutter graph widget only renders graph data.

It must not calculate mathematical points itself.

---

# 30. Programmer Engine

Responsibilities:

```text
Binary
Octal
Decimal
Hexadecimal

AND
OR
XOR
NOT

Bit Shift
Bit Rotation
Bit Masks
```

Integer widths:

```text
8-bit
16-bit
32-bit
64-bit
```

The Programmer Engine must use explicit integer-width semantics rather than relying on UI formatting.

---

# 31. Application Layer

The Application Layer coordinates use cases.

It must not contain low-level mathematical algorithms.

Examples:

```text
CalculateExpressionUseCase
EvaluateFormulaUseCase
SolveEquationUseCase
CalculateStatisticsUseCase
PerformRegressionUseCase
GenerateGraphUseCase
CalculateDerivativeUseCase
CalculateIntegralUseCase
ConvertUnitUseCase
PerformMatrixOperationUseCase
PerformVectorOperationUseCase
```

Each use case orchestrates one application-level operation.

---

# 32. Calculator Application Module

```text
application/calculator/
```

Responsibilities:

```text
Expression submission
Calculation execution
Answer memory
Angle mode
Display mode
Calculation state
```

It consumes the Expression Engine.

It must not know how Lexer or Parser are implemented.

---

# 33. History Module

```text
application/history/
```

Responsibilities:

```text
Record calculation
Retrieve history
Replay
Edit
Delete
Copy
Search
Pin
```

The Master Specification requires persistent calculation history and replay capabilities.

Contract:

```dart
abstract interface class HistoryRepository {
  Future<MathResult<void>> save(CalculationHistoryEntry entry);

  Future<MathResult<List<CalculationHistoryEntry>>> getAll();

  Future<MathResult<void>> delete(String id);

  Future<MathResult<void>> update(CalculationHistoryEntry entry);
}
```

---

# 34. Variables Module

Responsibilities:

```text
Global constants
Session variables
User variables
Functions
Answer memory
```

Contract:

```dart
abstract interface class VariableRepository {
  MathResult<void> setVariable(
    String name,
    NumericValue value,
  );

  MathResult<NumericValue> getVariable(String name);

  MathResult<void> removeVariable(String name);

  bool contains(String name);
}
```

---

# 35. Session Architecture

A Session represents a logical mathematical environment.

Example:

```text
Math
Physics
Engineering
Statistics
Personal
```

A session may contain:

```text
History
Variables
Functions
Settings
Calculations
```

This distinction must remain separate from Workspace.

The Master Specification defines Sessions and Workspaces as related but different concepts.

---

# 36. Workspace Architecture

A Workspace is a mathematical project/document.

Example:

```text
Physics Experiment
```

Contents:

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

Workspace is therefore closer to a mathematical notebook than a simple calculator session.

Contract:

```dart
abstract interface class WorkspaceRepository {
  Future<MathResult<void>> save(Workspace workspace);

  Future<MathResult<Workspace>> load(String id);

  Future<MathResult<List<Workspace>>> list();

  Future<MathResult<void>> delete(String id);
}
```

---

# 37. Spreadsheet Engine

The Spreadsheet must be independent from the UI.

Architecture:

```text
Spreadsheet
    ↓
Cell Model
    ↓
Formula Parser
    ↓
Dependency Graph
    ↓
Recalculation Engine
    ↓
Cell Values
```

Required concepts:

```text
Spreadsheet
Cell
CellAddress
CellValue
CellFormula
DependencyGraph
RecalculationEngine
```

The Spreadsheet Engine may consume the Expression Engine.

The Mathematical Core must not depend on Spreadsheet.

This dependency direction is mandatory.

---

# 38. Table Mode

Table Mode consumes the Graphing/Expression infrastructure.

Example:

```text
f(x) = x² + 2x + 1
```

It evaluates a defined range:

```text
x → f(x)
```

It may support multiple functions for comparison.

It must not implement its own expression parser.

---

# 39. Infrastructure Layer

Infrastructure provides implementations for application contracts.

Examples:

```text
SQLite / local database
JSON persistence
File storage
Import/export
Logging
Platform services
```

Mathematical Core must not depend on Infrastructure.

---

# 40. Persistence Boundary

Domain models must not directly serialize themselves through Flutter or database APIs.

Instead:

```text
Domain Model
    ↓
DTO / Persistence Model
    ↓
Repository
    ↓
Storage
```

This prevents persistence concerns from contaminating the Mathematical Core.

---

# 41. Presentation Layer

Presentation is responsible for:

```text
Widgets
Screens
Navigation
State
Input
Formatting
Rendering
Accessibility
Localization
```

It must not perform mathematical algorithms.

Bad:

```dart
onPressed: () {
  final result = x * y + z;
}
```

Preferred:

```text
UI
 ↓
Controller
 ↓
Use Case
 ↓
Mathematical Engine
 ↓
Result
 ↓
UI
```

---

# 42. State Management

The architecture must keep presentation state separate from mathematical domain state.

A presentation controller may own:

```text
Current input
Current display
Selected mode
Loading state
Error presentation
Selected history item
Selected graph
```

It must not own:

```text
Polynomial algorithms
Matrix algorithms
Parser implementation
Unit conversion mathematics
Regression algorithms
```

---

# 43. Dependency Rules

The following dependencies are mandatory:

```text
presentation
      ↓
application
      ↓
mathematical_core
      ↓
core
```

Infrastructure may implement contracts required by Application:

```text
application → abstraction
infrastructure → abstraction implementation
```

Forbidden:

```text
mathematical_core → Flutter
mathematical_core → presentation
mathematical_core → infrastructure
mathematical_core → Android
mathematical_core → Windows

presentation → mathematical implementation details
presentation → database internals
```

---

# 44. Engine Dependency Rules

The following dependency direction is required:

```text
Expression
   ↓
Numeric

Algebra
   ↓
Numeric

Symbolic
   ↓
Expression + Algebra

Calculus
   ↓
Expression + Symbolic + Numeric

Solver
   ↓
Expression + Algebra + Numeric

Graphing
   ↓
Expression + Numeric + Calculus

Statistics
   ↓
Numeric

Regression
   ↓
Statistics + Numeric

Probability
   ↓
Numeric

Units
   ↓
Numeric + Expression

Formula
   ↓
Expression + Units + Numeric

Spreadsheet
   ↓
Expression + Application contracts
```

No engine may create a duplicate implementation of functionality already owned by another engine.

---

# 45. Single Ownership Rule

Every mathematical capability must have one authoritative owner.

Examples:

```text
Parsing → Expression Engine
Numeric representation → Numeric Engine
Polynomial algebra → Algebra Engine
Symbolic differentiation → Symbolic Engine
Numerical integration → Calculus Engine
Matrix multiplication → Matrix Engine
Unit conversion → Units Engine
Regression fitting → Regression subsystem
Probability distributions → Probability Engine
Function sampling → Graphing Engine
```

Other modules consume these capabilities through contracts.

---

# 46. Cross-Platform Determinism

For equivalent inputs and identical mathematical configuration:

```text
Windows result == Android result
```

The Mathematical Core must not use platform-specific floating-point behavior where deterministic behavior is required.

Tests must verify cross-platform mathematical consistency.

---

# 47. Display Formatting Boundary

Mathematical calculation and mathematical presentation are separate concerns.

The Mathematical Core returns mathematical values.

Presentation converts them into:

```text
Decimal display
Fraction display
Scientific notation
Engineering notation
Textbook display
```

Example:

```text
NumericValue
      ↓
DisplayFormatter
      ↓
Rendered mathematical representation
```

The display formatter must never modify the source mathematical value.

---

# 48. Angle Mode

Angle mode is a mathematical evaluation configuration.

Supported modes:

```text
DEG
RAD
GRAD
```

It belongs in `EvaluationContext`, not inside widgets.

Example:

```dart
final evaluationContext = EvaluationContext(
  angleMode: AngleMode.degree,
);
```

---

# 49. Display Modes

The following display configurations must be represented independently from mathematical values:

```text
FIX
SCI
NORM
Engineering
```

Display configuration affects presentation/formatting, not the underlying exact mathematical result.

---

# 50. Error Propagation

Errors must follow:

```text
Mathematical Engine
       ↓
MathResult
       ↓
Application Use Case
       ↓
Presentation State
       ↓
Localized User Message
```

Mathematical errors must not be translated inside the Mathematical Core.

The Core reports semantic errors.

The Presentation layer decides how to communicate them to the user.

---

# 51. Validation Architecture

Validation must occur at the appropriate boundary.

Examples:

```text
Expression syntax → Parser
Matrix dimensions → Matrix Engine
Unit compatibility → Units Engine
Probability range → Probability Engine
Formula required inputs → Formula Engine
UI form validation → Presentation
```

Validation must not be duplicated unnecessarily.

---

# 52. Calculation Explanation Engine

A dedicated explanation subsystem should consume structured mathematical operations.

Architecture:

```text
Calculation
     ↓
Operation Analysis
     ↓
Explanation Steps
     ↓
Structured Explanation
     ↓
Presentation
```

The explanation engine must be deterministic for supported operations.

It must not depend on an AI service for basic mathematical derivations.

---

# 53. Testing Architecture

Testing must exist at multiple levels.

```text
Unit Tests
Engine Tests
Contract Tests
Integration Tests
Golden Tests
Regression Tests
Cross-Platform Tests
UI Tests
```

The Mathematical Core must have the highest test density.

---

# 54. Mathematical Engine Tests

Every engine must test:

```text
Normal cases
Boundary cases
Invalid input
Domain errors
Precision behavior
Numerical stability
Regression cases
```

Examples:

```text
Division by zero
sqrt(-1) in real mode
log(0)
log(-1)
Singular matrix
Zero determinant
Invalid unit addition
Non-convergent numerical solver
Invalid probability
```

---

# 55. Golden Tests

Golden/regression cases should cover important mathematical behavior.

Example:

```text
Input:
sin(30)

Configuration:
DEG

Expected:
0.5
```

Equivalent execution on Windows and Android must produce equivalent mathematical results.

---

# 56. No Silent Fallback Rule

NexaMath must never silently replace an exact algorithm with an approximate algorithm without communicating the difference.

Example:

```text
Exact solution
```

must be distinguishable from:

```text
Numerical approximation
```

Similarly, unsupported symbolic operations must produce an explicit unsupported/limitation result.

---

# 57. Performance Architecture

Expensive mathematical operations must not block the UI thread unnecessarily.

Potentially expensive operations include:

```text
Large matrix calculations
Large polynomial operations
Symbolic manipulation
Graph sampling
Large spreadsheet recalculation
Regression
Numerical integration
Large statistical datasets
```

Application services may execute these through appropriate asynchronous/isolate mechanisms while preserving Mathematical Core purity.

The exact concurrency implementation belongs outside the mathematical algorithms themselves.

---

# 58. Offline-First Requirement

The Mathematical Core must operate without:

```text
Internet
API
Server
Cloud
```

The Master Specification defines NexaMath as Offline First for its mathematical functionality.

Cloud functionality, if introduced later, must be an optional infrastructure capability and must never become a dependency of basic mathematical computation.

---

# 59. Windows Architecture

Windows-specific services belong under:

```text
infrastructure/platform/windows/
```

Examples may include:

```text
Window management
Keyboard integration
File dialogs
Desktop integration
```

None of these may be imported by Mathematical Core.

---

# 60. Android Architecture

Android-specific services belong under:

```text
infrastructure/platform/android/
```

Examples:

```text
Clipboard
Sharing
Platform lifecycle
Android-specific storage
```

Again, Mathematical Core must remain unaware of Android.

---

# 61. UI Platform Strategy

Windows and Android share:

```text
Mathematical Core
Application Layer
Domain Models
Use Cases
Persistence contracts
```

But may have different presentation strategies.

```text
                    Shared
                      │
        ┌─────────────┴─────────────┐
        │                           │
     Windows                     Android
   Desktop UX                   Touch UX
```

This follows the Master Specification's requirement that Windows and Android share the same Dart Mathematical Core while providing platform-appropriate UX.

---

# 62. Windows UX Boundary

Windows presentation may expose:

```text
Persistent Sidebar
History Panel
Graph Panel
Spreadsheet Panel
Keyboard Shortcuts
Numpad
Context Menus
Resizable Workspace
```

These are presentation concerns.

---

# 63. Android UX Boundary

Android presentation may expose:

```text
Touch Keypad
Swipe Navigation
Large Touch Targets
Portrait
Landscape
Long-Press Functions
Clipboard
Sharing
Session Persistence
```

These are presentation concerns.

---

# 64. Shared UI Components

Shared UI components belong under:

```text
presentation/shared/
```

Examples:

```text
MathDisplay
ExpressionInput
ResultCard
ErrorView
NumericKeyboard
FormulaField
MatrixEditor
VectorEditor
```

A shared UI component may consume domain values, but must not implement domain algorithms.

---

# 65. Public Engine APIs

Each major engine should expose a small public API.

The rest of the implementation must remain internal to the engine.

Example:

```text
graphing/
    graph_engine.dart        ← public façade
    functions/               ← internal
    sampling/                ← internal
    analysis/                ← internal
```

Consumers should depend on:

```dart
GraphEngine
```

rather than:

```dart
GraphSampler
AdaptiveSamplingAlgorithm
RootScanner
```

unless those components are explicitly part of the public contract.

---

# 66. Dependency Injection

Dependencies should be injected through abstractions.

Example:

```dart
class CalculateExpressionUseCase {
  final ExpressionEngine expressionEngine;
  final VariableRepository variableRepository;

  CalculateExpressionUseCase(
    this.expressionEngine,
    this.variableRepository,
  );
}
```

This allows:

```text
Testing
Replacement
Isolation
Multiple implementations
```

without modifying use cases.

---

# 67. Repository Pattern

Repositories belong to application/infrastructure boundaries.

Example:

```text
application/history/
    history_repository.dart

infrastructure/persistence/
    local_history_repository.dart
```

The application depends on the abstraction.

Infrastructure provides the implementation.

---

# 68. DTO Boundary

Persistence DTOs must not automatically become mathematical domain objects.

Example:

```text
HistoryEntryDto
      ↓
HistoryMapper
      ↓
CalculationHistoryEntry
```

This protects domain models from storage schema changes.

---

# 69. Configuration

Application-wide configuration belongs under:

```text
core/configuration/
```

Mathematical evaluation configuration belongs in:

```text
mathematical_core/
```

UI configuration belongs in:

```text
presentation/
```

These concerns must not be mixed.

---

# 70. Localization

Localization is a presentation/application concern.

Mathematical symbols and semantic identifiers remain language-neutral.

For example:

```text
DivisionByZeroError
```

is a domain error.

The Arabic UI may display:

```text
لا يمكن القسمة على صفر
```

while English may display:

```text
Division by zero is not allowed.
```

The error itself remains language-independent.

---

# 71. Accessibility

Accessibility belongs primarily to Presentation.

Requirements include:

```text
Keyboard navigation
Touch accessibility
Semantic labels
Readable mathematical results
Scalable text
Sufficient interaction targets
Screen-reader-compatible controls where applicable
```

The Mathematical Core remains independent from accessibility implementation.

---

# 72. Security Boundary

The Mathematical Core must treat user expressions and formulas as data.

Expression evaluation must not provide arbitrary code execution.

User-entered expressions must never be interpreted as Dart code.

There must be no:

```text
eval()
dynamic code execution
arbitrary script execution
```

inside the expression system.

---

# 73. Future AI Integration Boundary

If an AI Explanation Assistant is added later:

```text
AI Service
    ↓
Application Layer
    ↓
Mathematical Core
```

AI must not become the source of truth for numerical correctness.

The Mathematical Core remains authoritative.

AI may explain or assist, but verified mathematical computation remains deterministic and local.

---

# 74. Future Cloud Sync Boundary

If Cloud Sync is added:

```text
Application
    ↓
Sync Contract
    ↓
Infrastructure
    ↓
Cloud Provider
```

The Mathematical Core remains offline and independent.

---

# 75. Future Plugin Architecture

Future plugins must communicate through explicit extension contracts.

Potential model:

```text
Plugin
   ↓
Plugin API
   ↓
Application
   ↓
Mathematical Core Contracts
```

Plugins must not gain unrestricted access to internal implementation details.

---

# 76. Architecture Rules for Coding Agents

Any implementation agent working on NexaMath must follow these rules.

### Rule 1

Do not place mathematical algorithms inside Flutter widgets.

### Rule 2

Do not duplicate the Expression Parser.

### Rule 3

Do not create separate mathematical engines for Windows and Android.

### Rule 4

Do not make the Mathematical Core depend on Flutter.

### Rule 5

Do not use `double` as the universal mathematical representation.

### Rule 6

Do not silently downgrade exact calculations to approximations.

### Rule 7

Do not create placeholder implementations.

### Rule 8

Do not add TODO-based incomplete architecture.

### Rule 9

Do not create fake implementations solely to satisfy compilation.

### Rule 10

Do not bypass existing engine contracts without architectural justification.

### Rule 11

Every new engine capability must have tests.

### Rule 12

Every public contract must have a clear responsibility.

---

# 77. Implementation Order

Implementation must follow the architecture rather than starting from UI.

Recommended order:

```text
PHASE 1
Core Errors + Result + Validation
        ↓
PHASE 2
Numeric Engine
        ↓
PHASE 3
Expression Engine
        ↓
PHASE 4
Algebra
        ↓
PHASE 5
Complex / Matrix / Vector
        ↓
PHASE 6
Symbolic Mathematics
        ↓
PHASE 7
Solver
        ↓
PHASE 8
Calculus
        ↓
PHASE 9
Statistics / Regression / Probability
        ↓
PHASE 10
Units / Dimensional Analysis
        ↓
PHASE 11
Formula Engine
        ↓
PHASE 12
Graphing
        ↓
PHASE 13
Spreadsheet
        ↓
PHASE 14
Workspace / Sessions
        ↓
PHASE 15
Application Layer
        ↓
PHASE 16
Persistence
        ↓
PHASE 17
Windows + Android Presentation
        ↓
PHASE 18
Full Integration + Regression
```

---

# 78. Initial Vertical Slice

Before implementing every module, NexaMath should prove the architecture using one complete vertical path:

```text
Flutter Input
      ↓
CalculateExpressionUseCase
      ↓
ExpressionEngine
      ↓
Lexer
      ↓
Parser
      ↓
AST
      ↓
Evaluator
      ↓
NumericEngine
      ↓
MathResult
      ↓
Presentation
```

Example:

```text
sin(30) + sqrt(25) * 2
```

The vertical slice must prove:

```text
Parsing
Evaluation
Numeric result
Angle mode
Error handling
Display formatting
Windows execution
Android execution
```

before large-scale UI expansion.

---

# 79. Architectural Acceptance Criteria

The architecture is considered valid only when:

* Mathematical Core compiles without Flutter dependencies.
* Windows and Android consume the same Mathematical Core.
* Expression parsing is centralized.
* Numeric representation is centralized.
* Mathematical errors are typed.
* Exact and numerical results are distinguishable.
* Units use dimensional analysis.
* Graphing does not calculate through UI widgets.
* Spreadsheet does not become a dependency of Mathematical Core.
* Persistence does not contaminate domain models.
* UI does not contain mathematical algorithms.
* Mathematical engines can be unit-tested independently.
* Major engines expose explicit contracts.
* Dependency direction is enforceable.
* Unsupported operations fail explicitly.
* No placeholder implementation is accepted as production functionality.

---

# 80. Architectural Definition of NexaMath

NexaMath is therefore defined architecturally as:

```text
                    NEXAMATH
                       │
        ┌──────────────┴──────────────┐
        │                             │
   Application                    Presentation
        │                             │
        └──────────────┬──────────────┘
                       │
              Mathematical Core
                       │
      ┌────────────────┼─────────────────┐
      │                │                 │
 Expression        Numeric          Mathematical
   Engine           Engine             Engines
      │                │                 │
      └────────────────┼─────────────────┘
                       │
              Mathematical Models
```

The fundamental architectural principle is:

> **NexaMath is a mathematical computing platform whose user interface is built with Flutter, but whose mathematical intelligence exists independently as a reusable Dart Mathematical Core.**

The Flutter application is therefore the presentation and application environment around the Mathematical Core—not the Mathematical Core itself.

---

# 81. Final Architectural Principle

The project must always preserve this separation:

```text
WHAT THE USER SEES
        ↓
Presentation

WHAT THE APPLICATION DOES
        ↓
Application

HOW MATHEMATICS IS COMPUTED
        ↓
Mathematical Core

HOW DATA IS STORED
        ↓
Infrastructure
```

This separation is the foundation that allows NexaMath to grow from:

```text
Scientific Calculator
```

to:

```text
Advanced Engineering & Mathematics
```

and ultimately:

```text
Mathematical Computing Platform
```

without requiring the mathematical foundation to be rebuilt.

---

# 82. Relationship to Master Specification

`CALCULATOR_MASTER_SPECIFICATION.md` remains the product-level source of truth.

This document becomes the implementation-level architectural source of truth.

Therefore:

```text
CALCULATOR_MASTER_SPECIFICATION.md
             ↓
Product Requirements
             ↓
NEXAMATH_IMPLEMENTATION_ARCHITECTURE_SPECIFICATION.md
             ↓
Architecture / Contracts
             ↓
Implementation
             ↓
Tests / Verification
```

Neither document should silently contradict the other.

If an implementation requirement cannot be satisfied within the architecture, the architecture must be explicitly revised rather than bypassed through an ad-hoc implementation.

---

# 83. Final Status

**Project:** NexaMath
**Architecture:** Clean Architecture + Modular Mathematical Engine Architecture
**Platforms:** Windows + Android
**Mathematical Core:** Shared Dart implementation
**Network Dependency:** None for core mathematical computation
**UI Framework:** Flutter
**Primary Mathematical Architecture:** Lexer → Parser → AST → Evaluator
**Numeric Architecture:** Typed mathematical values with controlled precision
**Status:** Architecture Specification Ready for Implementation Planning
