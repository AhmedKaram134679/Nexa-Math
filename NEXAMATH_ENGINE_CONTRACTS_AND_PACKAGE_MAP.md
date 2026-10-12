# NexaMath Engine Contracts & Package Map

**Project:** NexaMath **Document:** Engine Contracts & Package Map **Status:**
Implementation-Ready Architecture Contract **Authority:** Engineering Source of
Truth for Public Engine APIs and Package Boundaries **Platform:** Windows +
Android **Framework:** Flutter **Language:** Dart **Architecture:** Clean
Architecture + Domain-Driven Mathematical Core **Primary Principle:** The
Mathematical Core is a platform-independent Dart product embedded inside
NexaMath.

---

# 1. Purpose

This document converts the NexaMath Implementation Blueprint into an explicit
implementation contract.

It defines:

- Exact package ownership.
- Exact public interfaces.
- Exact model ownership.
- Engine boundaries.
- Allowed dependencies.
- Forbidden dependencies.
- Public API rules.
- Value-type hierarchy.
- Expression evaluation contracts.
- Exact/approximate calculation contracts.
- Error contracts.
- Application-to-engine boundaries.
- Infrastructure boundaries.
- Presentation boundaries.
- Dependency Injection requirements.
- Testing contracts.
- Export rules.
- Package-level acceptance criteria.

This document exists to prevent implementation drift.

A Coding Agent MUST treat this document as an architectural contract, not as
optional guidance.

---

# 2. Architectural Authority

The architecture has four logical layers:

```text
┌──────────────────────────────────────────────────────────────┐
│                       Presentation                            │
│             Flutter UI / Screens / Widgets                  │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                       Application                            │
│      Use Cases / Sessions / Workspaces / History            │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                    Mathematical Core                         │
│ Numeric / Expression / Algebra / Symbolic / Calculus        │
│ Solver / Matrix / Vector / Complex / Statistics / Units     │
│ Probability / Formula / Graphing / Programmer               │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                           Core                               │
│ Result / Errors / Validation / Configuration / Contracts    │
└──────────────────────────────────────────────────────────────┘


Infrastructure implements interfaces required by Application/Core
and MUST NOT become a dependency of Mathematical Core.
```

The dependency direction is:

```text
Presentation
     ↓
Application
     ↓
Mathematical Core
     ↓
Core
```

Infrastructure may implement contracts from lower layers but must never become a
lower-layer dependency.

---

# 3. Fundamental Architectural Rule

The following rule is absolute:

> The Mathematical Core MUST compile and operate without Flutter, Android APIs,
> Windows APIs, platform channels, filesystem access, network access, database
> access, or UI dependencies.

The Mathematical Core must be usable from:

```dart
void main() {
  // Pure Dart mathematical execution.
}
```

without initializing Flutter.

---

# 4. Package Root

The authoritative source structure is:

```text
lib/
│
├── core/
│
├── mathematical_core/
│   ├── numeric/
│   ├── expression/
│   ├── algebra/
│   ├── symbolic/
│   ├── calculus/
│   ├── solver/
│   ├── complex/
│   ├── matrix/
│   ├── vector/
│   ├── statistics/
│   ├── probability/
│   ├── units/
│   ├── formula/
│   ├── graphing/
│   └── programmer/
│
├── application/
│   ├── calculate/
│   ├── history/
│   ├── variables/
│   ├── sessions/
│   ├── workspaces/
│   ├── spreadsheet/
│   └── settings/
│
├── infrastructure/
│   ├── persistence/
│   ├── repositories/
│   ├── platform/
│   └── configuration/
│
└── presentation/
    ├── calculate/
    ├── statistics/
    ├── graphing/
    ├── solver/
    ├── complex/
    ├── matrix/
    ├── vector/
    ├── spreadsheet/
    ├── probability/
    ├── calculus/
    ├── programmer/
    ├── units/
    ├── formulas/
    ├── sessions/
    ├── workspaces/
    ├── history/
    └── settings/
```

---

# 5. Public API Philosophy

Every Engine MUST expose one primary public façade.

Example:

```dart
abstract interface class NumericEngine {
  ...
}
```

```dart
abstract interface class ExpressionEngine {
  ...
}
```

```dart
abstract interface class MatrixEngine {
  ...
}
```

Internal algorithms MUST NOT become accidental public APIs.

For example:

```text
ExpressionEngine
    ↓
Lexer
    ↓
Parser
    ↓
AST
    ↓
Evaluator
```

The consumer normally depends on:

```text
ExpressionEngine
```

not:

```text
Lexer
Parser
Evaluator
```

Internal classes may remain public in Dart when required for package
organization, but they MUST NOT be exported through the engine's public barrel
API unless explicitly required.

---

# 6. Shared Core Contracts

## 6.1 Result Contract

All fallible mathematical operations MUST use a consistent result model.

```dart
sealed class MathResult<T> {
  const MathResult();
}
```

Implementations:

```dart
final class MathSuccess<T> extends MathResult<T> {
  final T value;
  final CalculationMetadata metadata;

  const MathSuccess(
    this.value, {
    this.metadata = const CalculationMetadata(),
  });
}
```

```dart
final class MathFailure<T> extends MathResult<T> {
  final MathError error;
  final CalculationMetadata metadata;

  const MathFailure(
    this.error, {
    this.metadata = const CalculationMetadata(),
  });
}
```

---

# 7. Calculation Metadata

```dart
final class CalculationMetadata {
  final bool isExact;
  final ApproximationMetadata? approximation;
  final List<MathWarning> warnings;

  const CalculationMetadata({
    this.isExact = false,
    this.approximation,
    this.warnings = const [],
  });
}
```

Approximation metadata:

```dart
final class ApproximationMetadata {
  final int? precision;
  final String? method;
  final double? absoluteError;
  final double? relativeError;
  final bool converged;

  const ApproximationMetadata({
    this.precision,
    this.method,
    this.absoluteError,
    this.relativeError,
    this.converged = true,
  });
}
```

This prevents the application from confusing:

```text
Exact result
```

with:

```text
Numerical approximation
```

---

# 8. Error Contract

All mathematical failures MUST derive from:

```dart
sealed class MathError {
  final String message;
  final String code;

  const MathError({
    required this.message,
    required this.code,
  });
}
```

Required error categories include:

```text
InvalidExpression
SyntaxError
UnknownIdentifier
UnknownFunction
InvalidArgument
DivisionByZero
DomainError
Overflow
Underflow
PrecisionLoss
DimensionMismatch
InvalidUnit
MatrixDimensionError
SingularMatrix
InvalidMatrix
InvalidVector
NoSolution
InfiniteSolutions
ConvergenceFailure
UnsupportedOperation
InvalidBase
InvalidBitWidth
InvalidProbability
InvalidDistributionParameter
FormulaInputMissing
FormulaInputInvalid
CircularReference
DependencyError
```

Errors MUST be typed.

Consumers MUST NOT parse human-readable error messages to determine error
categories.

---

# 9. Warning Contract

Warnings are non-fatal conditions:

```dart
sealed class MathWarning {
  final String code;
  final String message;

  const MathWarning({
    required this.code,
    required this.message,
  });
}
```

Examples:

```text
PrecisionLossWarning
NearZeroWarning
NumericalApproximationWarning
ConvergenceWarning
UnitConversionWarning
```

---

# 10. Mathematical Value Hierarchy

A critical architectural rule is that expression evaluation MUST NOT be
restricted to `NumericValue`.

NexaMath supports multiple mathematical value categories.

The authoritative top-level value abstraction is:

```dart
sealed class MathValue {
  const MathValue();
}
```

Conceptually:

```text
MathValue
│
├── ScalarValue
│   ├── IntegerValue
│   ├── DecimalValue
│   ├── FractionValue
│   └── ComplexNumber
│
├── Matrix
├── Vector
├── Quantity
├── Polynomial
└── SymbolicExpression
```

Not every expression is required to support every value type.

Each engine explicitly declares which value types it accepts.

---

# 11. Scalar Numeric Contract

```dart
sealed class ScalarValue extends MathValue {
  const ScalarValue();
}
```

Required scalar implementations:

```dart
final class IntegerValue extends ScalarValue {
  final BigInt value;

  const IntegerValue(this.value);
}
```

```dart
final class DecimalValue extends ScalarValue {
  final Decimal value;

  const DecimalValue(this.value);
}
```

```dart
final class FractionValue extends ScalarValue {
  final BigInt numerator;
  final BigInt denominator;

  const FractionValue(
    this.numerator,
    this.denominator,
  );
}
```

Complex values are scalar mathematical values but are owned by the Numeric
layer.

---

# 12. Complex Number Ownership

There MUST NOT be two competing complex-number models.

The authoritative model is:

```text
mathematical_core/numeric/complex/
```

with:

```dart
final class ComplexNumber extends ScalarValue {
  final Decimal real;
  final Decimal imaginary;

  const ComplexNumber({
    required this.real,
    required this.imaginary,
  });
}
```

The Complex Engine operates on this model.

There MUST NOT be a second independent:

```text
ComplexValue
```

model.

`ComplexNumber` is the canonical complex value.

---

# 13. Polynomial Ownership

There MUST NOT be both:

```text
PolynomialValue
```

and:

```text
Polynomial
```

as competing mathematical models.

The authoritative model is:

```dart
final class Polynomial extends MathValue {
  final List<ScalarValue> coefficients;
  final String variable;

  const Polynomial({
    required this.coefficients,
    required this.variable,
  });
}
```

Polynomial algorithms operate on this model.

---

# 14. Quantity Ownership

There MUST NOT be both:

```text
QuantityValue
```

and:

```text
Quantity
```

The authoritative model is:

```dart
final class Quantity extends MathValue {
  final ScalarValue value;
  final Unit unit;

  const Quantity({
    required this.value,
    required this.unit,
  });
}
```

---

# 15. Numeric Engine Contract

Package:

```text
mathematical_core/numeric/
```

Primary contract:

```dart
abstract interface class NumericEngine {
  MathResult<ScalarValue> add(
    ScalarValue left,
    ScalarValue right,
  );

  MathResult<ScalarValue> subtract(
    ScalarValue left,
    ScalarValue right,
  );

  MathResult<ScalarValue> multiply(
    ScalarValue left,
    ScalarValue right,
  );

  MathResult<ScalarValue> divide(
    ScalarValue left,
    ScalarValue right,
  );

  MathResult<ScalarValue> power(
    ScalarValue base,
    ScalarValue exponent,
  );

  MathResult<ScalarValue> negate(
    ScalarValue value,
  );

  MathResult<ScalarValue> absolute(
    ScalarValue value,
  );

  MathResult<ScalarValue> factorial(
    ScalarValue value,
  );

  MathResult<ScalarValue> convert(
    ScalarValue value,
    NumericType targetType,
  );
}
```

Numeric engine owns:

- Numeric promotion.
- Exact arithmetic.
- Decimal arithmetic.
- Fraction arithmetic.
- Integer arithmetic.
- Rounding.
- Precision.
- Overflow handling.
- Numeric comparison.
- Scalar elementary operations.

---

# 16. Numeric Type Promotion

Promotion MUST be deterministic.

Conceptual ordering:

```text
Integer
   ↓
Fraction
   ↓
Decimal
   ↓
Complex
```

Promotion rules MUST be centralized.

No engine may invent its own promotion rules.

---

# 17. Expression Package

Path:

```text
mathematical_core/expression/
```

Structure:

```text
expression/
├── lexer/
├── parser/
├── ast/
├── evaluator/
├── functions/
├── operators/
├── semantic/
└── expression_engine.dart
```

---

# 18. Expression AST

The AST is the canonical representation of parsed expressions.

Required node families:

```dart
sealed class ExpressionNode {
  const ExpressionNode();
}
```

Required nodes include:

```text
NumberNode
IdentifierNode
ConstantNode
UnaryOperationNode
BinaryOperationNode
FunctionCallNode
GroupNode
MatrixNode
VectorNode
QuantityNode
```

Additional nodes may be introduced only when required by the language
specification.

---

# 19. Lexer Contract

```dart
abstract interface class Lexer {
  MathResult<List<Token>> tokenize(String source);
}
```

The lexer:

- Converts source text into tokens.
- Detects lexical errors.
- Does not evaluate expressions.
- Does not perform symbolic simplification.
- Does not solve equations.
- Does not access application state.

---

# 20. Parser Contract

```dart
abstract interface class Parser {
  MathResult<ExpressionNode> parse(
    List<Token> tokens,
  );
}
```

Parser responsibilities:

- Syntax.
- Operator precedence.
- Associativity.
- Grouping.
- Function invocation syntax.
- Identifiers.
- Literals.

Parser MUST NOT:

- Evaluate expressions.
- Resolve application variables.
- Perform numerical approximation.
- Access repositories.
- Access Flutter.

---

# 21. Expression Evaluation Contract

The evaluator returns a general `MathValue`.

```dart
abstract interface class ExpressionEvaluator {
  MathResult<EvaluationResult> evaluate(
    ExpressionNode expression,
    EvaluationContext context,
  );
}
```

```dart
final class EvaluationResult {
  final MathValue value;
  final ExpressionNode? exactForm;
  final CalculationMetadata metadata;

  const EvaluationResult({
    required this.value,
    this.exactForm,
    this.metadata = const CalculationMetadata(),
  });
}
```

This permits:

```text
2 + 3 → 5
sqrt(2) → exact symbolic form + approximation when requested
2 × Matrix → Matrix
10 m + 50 cm → Quantity
```

---

# 22. Evaluation Context

```dart
final class EvaluationContext {
  final Map<String, MathValue> variables;
  final AngleMode angleMode;
  final NumericSettings numericSettings;
  final FunctionRegistry functionRegistry;
  final ConstantRegistry constantRegistry;

  const EvaluationContext({
    required this.variables,
    required this.angleMode,
    required this.numericSettings,
    required this.functionRegistry,
    required this.constantRegistry,
  });
}
```

The context is supplied by the caller.

The expression engine MUST NOT retrieve variables from persistence.

---

# 23. Expression Engine Façade

```dart
abstract interface class ExpressionEngine {
  MathResult<ParsedExpression> parse(
    String source,
  );

  MathResult<EvaluationResult> evaluate(
    String source,
    EvaluationContext context,
  );

  MathResult<EvaluationResult> evaluateAst(
    ExpressionNode expression,
    EvaluationContext context,
  );
}
```

`ExpressionEngine` internally coordinates:

```text
Lexer
Parser
Semantic validation
Evaluator
Function registry
Constant registry
```

---

# 24. Units and Expression Parsing

Expression parsing and dimensional analysis MUST remain separate
responsibilities.

The parser may recognize quantity syntax and produce:

```text
QuantityNode
```

but it MUST NOT perform unit conversion.

The dependency is:

```text
Expression AST
       ↓
Semantic Resolution
       ↓
Unit Engine
```

The Expression package may depend on the stable Unit contracts required to
represent quantity expressions.

The Unit Engine MUST NOT depend on the Expression Engine.

Therefore:

```text
Expression → Units Contracts
Units      → Core + Numeric
```

and never:

```text
Units → Expression
```

This prevents circular dependency.

---

# 25. Function Registry

```dart
abstract interface class FunctionRegistry {
  MathFunction? resolve(String name);
}
```

```dart
abstract interface class MathFunction {
  String get name;

  int? get minimumArguments;

  int? get maximumArguments;

  MathResult<MathValue> invoke(
    List<MathValue> arguments,
    EvaluationContext context,
  );
}
```

Built-in functions include:

```text
sin
cos
tan
asin
acos
atan
sinh
cosh
tanh
asinh
acosh
atanh
sqrt
cbrt
log
ln
exp
abs
floor
ceil
round
factorial
gcd
lcm
min
max
```

Additional functions may be added through the registry without modifying the
parser.

---

# 26. Algebra Package

Path:

```text
mathematical_core/algebra/
```

Primary façade:

```dart
abstract interface class AlgebraEngine {
  MathResult<Polynomial> toPolynomial(
    ExpressionNode expression,
    String variable,
  );

  MathResult<Polynomial> add(
    Polynomial left,
    Polynomial right,
  );

  MathResult<Polynomial> subtract(
    Polynomial left,
    Polynomial right,
  );

  MathResult<Polynomial> multiply(
    Polynomial left,
    Polynomial right,
  );

  MathResult<Polynomial> expand(
    Polynomial polynomial,
  );

  MathResult<Polynomial> factor(
    Polynomial polynomial,
  );

  MathResult<Polynomial> simplify(
    Polynomial polynomial,
  );
}
```

Algebra may consume Expression AST.

Algebra MUST NOT depend on Symbolic Engine.

---

# 27. Symbolic Package

Path:

```text
mathematical_core/symbolic/
```

Primary façade:

```dart
abstract interface class SymbolicEngine {
  MathResult<SymbolicExpression> simplify(
    ExpressionNode expression,
  );

  MathResult<SymbolicExpression> expand(
    ExpressionNode expression,
  );

  MathResult<SymbolicExpression> factor(
    ExpressionNode expression,
  );

  MathResult<SymbolicExpression> substitute(
    ExpressionNode expression,
    Map<String, ExpressionNode> substitutions,
  );

  MathResult<SymbolicExpression> differentiate(
    ExpressionNode expression,
    String variable,
  );

  MathResult<SymbolicExpression> limit(
    ExpressionNode expression,
    String variable,
    ExpressionNode point,
  );

  MathResult<SymbolicExpression> integrate(
    ExpressionNode expression,
    String variable,
  );
}
```

Symbolic functionality MUST be explicitly bounded by supported algorithms.

Unsupported symbolic operations MUST return:

```text
UnsupportedOperation
```

and MUST NOT silently approximate unless the API explicitly requests numerical
fallback.

---

# 28. Symbolic Expression

```dart
final class SymbolicExpression extends MathValue {
  final ExpressionNode expression;

  const SymbolicExpression(this.expression);
}
```

Symbolic values are not equivalent to numeric approximations.

---

# 29. Complex Engine

Path:

```text
mathematical_core/complex/
```

Primary façade:

```dart
abstract interface class ComplexEngine {
  MathResult<ComplexNumber> add(
    ComplexNumber left,
    ComplexNumber right,
  );

  MathResult<ComplexNumber> subtract(
    ComplexNumber left,
    ComplexNumber right,
  );

  MathResult<ComplexNumber> multiply(
    ComplexNumber left,
    ComplexNumber right,
  );

  MathResult<ComplexNumber> divide(
    ComplexNumber left,
    ComplexNumber right,
  );

  MathResult<ComplexNumber> power(
    ComplexNumber base,
    ComplexNumber exponent,
  );

  MathResult<DecimalValue> magnitude(
    ComplexNumber value,
  );

  MathResult<DecimalValue> argument(
    ComplexNumber value,
  );

  MathResult<ComplexNumber> conjugate(
    ComplexNumber value,
  );

  MathResult<ComplexNumber> fromPolar(
    DecimalValue magnitude,
    DecimalValue angle,
  );

  MathResult<PolarComplex> toPolar(
    ComplexNumber value,
  );
}
```

`ComplexNumber` remains owned by Numeric.

---

# 30. Matrix Engine

Path:

```text
mathematical_core/matrix/
```

Canonical model:

```dart
final class Matrix extends MathValue {
  final int rows;
  final int columns;
  final List<List<ScalarValue>> values;

  const Matrix({
    required this.rows,
    required this.columns,
    required this.values,
  });
}
```

Primary interface:

```dart
abstract interface class MatrixEngine {
  MathResult<Matrix> add(
    Matrix left,
    Matrix right,
  );

  MathResult<Matrix> subtract(
    Matrix left,
    Matrix right,
  );

  MathResult<Matrix> multiply(
    Matrix left,
    Matrix right,
  );

  MathResult<Matrix> scalarMultiply(
    Matrix matrix,
    ScalarValue scalar,
  );

  MathResult<Matrix> transpose(
    Matrix matrix,
  );

  MathResult<ScalarValue> determinant(
    Matrix matrix,
  );

  MathResult<Matrix> inverse(
    Matrix matrix,
  );

  MathResult<int> rank(
    Matrix matrix,
  );

  MathResult<ScalarValue> trace(
    Matrix matrix,
  );

  MathResult<Matrix> power(
    Matrix matrix,
    int exponent,
  );
}
```

Advanced operations may include:

```text
LU decomposition
QR decomposition
Gaussian elimination
Eigenvalues
Eigenvectors
```

when implemented and tested.

---

# 31. Vector Engine

Canonical model:

```dart
final class Vector extends MathValue {
  final List<ScalarValue> components;

  const Vector(this.components);
}
```

Primary interface:

```dart
abstract interface class VectorEngine {
  MathResult<Vector> add(
    Vector left,
    Vector right,
  );

  MathResult<Vector> subtract(
    Vector left,
    Vector right,
  );

  MathResult<Vector> scalarMultiply(
    Vector vector,
    ScalarValue scalar,
  );

  MathResult<ScalarValue> dot(
    Vector left,
    Vector right,
  );

  MathResult<Vector> cross(
    Vector left,
    Vector right,
  );

  MathResult<DecimalValue> magnitude(
    Vector vector,
  );

  MathResult<Vector> normalize(
    Vector vector,
  );

  MathResult<DecimalValue> angle(
    Vector left,
    Vector right,
  );

  MathResult<Vector> projection(
    Vector vector,
    Vector onto,
  );
}
```

---

# 32. Calculus Engine

Primary interface:

```dart
abstract interface class CalculusEngine {
  MathResult<SymbolicExpression> differentiate(
    ExpressionNode expression,
    String variable,
  );

  MathResult<NumericDerivative> numericalDerivative(
    ExpressionNode expression,
    String variable,
    ScalarValue point,
    NumericalCalculusOptions options,
  );

  MathResult<SymbolicExpression> integrate(
    ExpressionNode expression,
    String variable,
  );

  MathResult<ScalarValue> definiteIntegral(
    ExpressionNode expression,
    String variable,
    ScalarValue lower,
    ScalarValue upper,
    NumericalCalculusOptions options,
  );

  MathResult<ScalarValue> limit(
    ExpressionNode expression,
    String variable,
    ScalarValue point,
  );
}
```

Calculus may depend on:

```text
Expression
Symbolic
Numeric
```

It MUST NOT be required by Expression.

---

# 33. Equation Solver

Canonical equation model:

```dart
final class Equation {
  final ExpressionNode left;
  final ExpressionNode right;

  const Equation({
    required this.left,
    required this.right,
  });
}
```

Primary interface:

```dart
abstract interface class EquationSolver {
  MathResult<EquationSolution> solve(
    Equation equation,
    SolverOptions options,
  );

  MathResult<SystemSolution> solveSystem(
    List<Equation> equations,
    List<String> variables,
    SolverOptions options,
  );
}
```

Solver implementations are divided into:

```text
Exact
Numerical
System
```

---

# 34. Exact Solver Contracts

Required exact solver interfaces:

```dart
abstract interface class LinearEquationSolver {
  MathResult<EquationSolution> solve(Equation equation);
}
```

```dart
abstract interface class QuadraticEquationSolver {
  MathResult<EquationSolution> solve(Equation equation);
}
```

```dart
abstract interface class CubicEquationSolver {
  MathResult<EquationSolution> solve(Equation equation);
}
```

```dart
abstract interface class QuarticEquationSolver {
  MathResult<EquationSolution> solve(Equation equation);
}
```

Exact results MUST remain exact where mathematically representable.

---

# 35. Numerical Solver Contract

```dart
abstract interface class NumericalEquationSolver {
  MathResult<NumericalSolution> solve(
    Equation equation,
    NumericalSolverOptions options,
  );
}
```

Supported algorithms may include:

```text
Newton-Raphson
Bisection
Secant
Brent-style hybrid methods
```

Numerical solutions MUST report:

```text
method
iterations
convergence
tolerance
residual
approximation metadata
```

---

# 36. Statistics Engine

Models:

```dart
final class Dataset {
  final List<ScalarValue> values;

  const Dataset(this.values);
}
```

```dart
final class PairedDataset {
  final Dataset x;
  final Dataset y;

  const PairedDataset({
    required this.x,
    required this.y,
  });
}
```

Primary interface:

```dart
abstract interface class StatisticsEngine {
  MathResult<DescriptiveStatistics> describe(
    Dataset dataset,
  );

  MathResult<PercentileResult> percentile(
    Dataset dataset,
    ScalarValue percentile,
  );

  MathResult<CorrelationResult> correlation(
    PairedDataset dataset,
  );
}
```

Required descriptive results:

```text
count
sum
mean
median
mode
minimum
maximum
range
variance
standard deviation
quartiles
percentiles
```

---

# 37. Regression Engine

Regression belongs inside the Statistics domain but has its own contract.

```dart
abstract interface class RegressionEngine {
  MathResult<RegressionResult> linear(
    PairedDataset dataset,
  );

  MathResult<RegressionResult> quadratic(
    PairedDataset dataset,
  );

  MathResult<RegressionResult> cubic(
    PairedDataset dataset,
  );

  MathResult<RegressionResult> logarithmic(
    PairedDataset dataset,
  );

  MathResult<RegressionResult> exponential(
    PairedDataset dataset,
  );

  MathResult<RegressionResult> power(
    PairedDataset dataset,
  );
}
```

`RegressionResult` MUST contain:

```text
model
coefficients
equation
correlation
R² where applicable
predictions
residuals
```

---

# 38. Probability Engine

Canonical interface:

```dart
abstract interface class ProbabilityEngine {
  MathResult<ProbabilityResult> probability(
    ProbabilityDistribution distribution,
    ProbabilityQuery query,
  );

  MathResult<ScalarValue> pdf(
    ProbabilityDistribution distribution,
    ScalarValue x,
  );

  MathResult<ScalarValue> cdf(
    ProbabilityDistribution distribution,
    ScalarValue x,
  );

  MathResult<ScalarValue> inverseCdf(
    ProbabilityDistribution distribution,
    ScalarValue probability,
  );

  MathResult<Dataset> sample(
    ProbabilityDistribution distribution,
    int count,
    RandomSource randomSource,
  );
}
```

Canonical query model:

```dart
sealed class ProbabilityQuery {
  const ProbabilityQuery();
}
```

Implementations may include:

```text
PointProbabilityQuery
IntervalProbabilityQuery
LowerTailQuery
UpperTailQuery
```

Required distributions include:

```text
Normal
Binomial
Poisson
Uniform
Exponential
Geometric
```

Additional distributions may be added without modifying the engine façade.

---

# 39. Units Engine

Path:

```text
mathematical_core/units/
```

Core model:

```dart
final class Dimension {
  final Map<BaseDimension, int> powers;

  const Dimension(this.powers);
}
```

```dart
final class Unit {
  final String symbol;
  final String name;
  final Dimension dimension;
  final Decimal scale;
  final Decimal offset;

  const Unit({
    required this.symbol,
    required this.name,
    required this.dimension,
    required this.scale,
    required this.offset,
  });
}
```

```dart
final class Quantity extends MathValue {
  final ScalarValue value;
  final Unit unit;

  const Quantity({
    required this.value,
    required this.unit,
  });
}
```

Primary interface:

```dart
abstract interface class UnitEngine {
  MathResult<Quantity> convert(
    Quantity quantity,
    Unit target,
  );

  MathResult<Quantity> add(
    Quantity left,
    Quantity right,
  );

  MathResult<Quantity> subtract(
    Quantity left,
    Quantity right,
  );

  MathResult<Quantity> multiply(
    Quantity left,
    Quantity right,
  );

  MathResult<Quantity> divide(
    Quantity left,
    Quantity right,
  );

  MathResult<Unit> resolveUnit(
    String symbol,
  );

  MathResult<Dimension> dimensionOf(
    Unit unit,
  );
}
```

The Unit Engine MUST perform dimensional analysis.

Example:

```text
10 m + 50 cm
```

is normalized before addition.

Example:

```text
10 m + 5 s
```

must fail with:

```text
DimensionMismatch
```

---

# 40. Formula Engine

Canonical formula model:

```dart
final class FormulaDefinition {
  final String id;
  final String name;
  final String category;
  final ExpressionNode expression;
  final List<FormulaVariable> variables;
  final String description;

  const FormulaDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.expression,
    required this.variables,
    required this.description,
  });
}
```

Variable:

```dart
final class FormulaVariable {
  final String name;
  final String symbol;
  final String description;
  final Dimension? dimension;
  final bool required;

  const FormulaVariable({
    required this.name,
    required this.symbol,
    required this.description,
    this.dimension,
    this.required = true,
  });
}
```

Result:

```dart
final class FormulaResult {
  final MathValue value;
  final Map<String, MathValue> inputs;
  final CalculationMetadata metadata;

  const FormulaResult({
    required this.value,
    required this.inputs,
    required this.metadata,
  });
}
```

Primary interface:

```dart
abstract interface class FormulaEngine {
  MathResult<FormulaResult> evaluate(
    FormulaDefinition formula,
    Map<String, MathValue> inputs,
  );

  MathResult<FormulaDefinition> register(
    FormulaDefinition formula,
  );

  MathResult<FormulaDefinition> resolve(
    String id,
  );

  List<FormulaDefinition> listByCategory(
    String category,
  );
}
```

---

# 41. Graphing Engine

Canonical models:

```dart
final class GraphFunction {
  final String id;
  final String expression;
  final String variable;

  const GraphFunction({
    required this.id,
    required this.expression,
    required this.variable,
  });
}
```

```dart
final class GraphRange {
  final Decimal xMin;
  final Decimal xMax;
  final Decimal yMin;
  final Decimal yMax;

  const GraphRange({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });
}
```

```dart
final class GraphPoint {
  final Decimal x;
  final Decimal y;

  const GraphPoint({
    required this.x,
    required this.y,
  });
}
```

Primary interface:

```dart
abstract interface class GraphEngine {
  MathResult<GraphSeries> sample(
    GraphFunction function,
    GraphRange range,
    GraphSamplingOptions options,
  );

  MathResult<List<GraphSeries>> sampleMultiple(
    List<GraphFunction> functions,
    GraphRange range,
    GraphSamplingOptions options,
  );

  MathResult<GraphAnalysisResult> analyze(
    GraphFunction function,
    GraphRange range,
    GraphAnalysisOptions options,
  );
}
```

Graphing pipeline:

```text
GraphFunction
      ↓
Expression Engine
      ↓
Evaluation
      ↓
Sampling Engine
      ↓
Discontinuity Detection
      ↓
GraphSeries
      ↓
Flutter Renderer
```

The renderer is Presentation responsibility.

---

# 42. Graph Analysis

Graph analysis may provide:

```text
roots
intersections
trace values
local maxima
local minima
derivative values
integral information
coordinates
```

GraphEngine MUST NOT render pixels.

---

# 43. Programmer Engine

Programmer calculations operate on integer semantics.

Canonical models:

```dart
enum IntegerBase {
  binary,
  octal,
  decimal,
  hexadecimal,
}
```

```dart
enum IntegerWidth {
  bits8,
  bits16,
  bits32,
  bits64,
}
```

```dart
final class ProgrammerValue extends MathValue {
  final BigInt value;
  final IntegerBase base;
  final IntegerWidth width;

  const ProgrammerValue({
    required this.value,
    required this.base,
    required this.width,
  });
}
```

Primary interface:

```dart
abstract interface class ProgrammerEngine {
  MathResult<ProgrammerValue> and(
    ProgrammerValue left,
    ProgrammerValue right,
  );

  MathResult<ProgrammerValue> or(
    ProgrammerValue left,
    ProgrammerValue right,
  );

  MathResult<ProgrammerValue> xor(
    ProgrammerValue left,
    ProgrammerValue right,
  );

  MathResult<ProgrammerValue> not(
    ProgrammerValue value,
  );

  MathResult<ProgrammerValue> shiftLeft(
    ProgrammerValue value,
    int amount,
  );

  MathResult<ProgrammerValue> shiftRight(
    ProgrammerValue value,
    int amount,
  );

  MathResult<ProgrammerValue> rotateLeft(
    ProgrammerValue value,
    int amount,
  );

  MathResult<ProgrammerValue> rotateRight(
    ProgrammerValue value,
    int amount,
  );

  MathResult<ProgrammerValue> convertBase(
    ProgrammerValue value,
    IntegerBase base,
  );
}
```

Bit width semantics MUST be deterministic.

---

# 44. Application Layer

Application coordinates user intent.

It does not implement mathematical algorithms.

Example:

```text
CalculateExpressionUseCase
        ↓
ExpressionEngine
        ↓
Mathematical Result
        ↓
History Repository
```

---

# 45. Calculate Use Case

```dart
abstract interface class CalculateExpressionUseCase {
  Future<MathResult<CalculationResult>> execute(
    CalculateExpressionRequest request,
  );
}
```

The use case may:

- Load session variables.
- Build evaluation context.
- Invoke Expression Engine.
- Persist history.
- Return application-level result.

It MUST NOT implement arithmetic itself.

---

# 46. Calculation Result

```dart
final class CalculationResult {
  final String input;
  final EvaluationResult evaluation;
  final DateTime calculatedAt;

  const CalculationResult({
    required this.input,
    required this.evaluation,
    required this.calculatedAt,
  });
}
```

Formatting belongs outside the mathematical calculation model.

---

# 47. History Contract

```dart
abstract interface class HistoryRepository {
  Future<List<HistoryEntry>> getEntries();

  Future<void> save(
    HistoryEntry entry,
  );

  Future<void> delete(
    String id,
  );

  Future<void> clear();

  Future<void> pin(
    String id,
    bool pinned,
  );
}
```

History stores calculation records.

It MUST NOT become part of the Mathematical Core.

---

# 48. Variable Store

```dart
abstract interface class VariableRepository {
  Future<Map<String, MathValue>> loadVariables(
    String sessionId,
  );

  Future<void> saveVariable(
    String sessionId,
    VariableDefinition variable,
  );

  Future<void> deleteVariable(
    String sessionId,
    String name,
  );
}
```

Mathematical Core receives variables through `EvaluationContext`.

---

# 49. Session Model

A Session represents a calculation environment.

```dart
final class CalculationSession {
  final String id;
  final String name;
  final Map<String, MathValue> variables;
  final SessionSettings settings;

  const CalculationSession({
    required this.id,
    required this.name,
    required this.variables,
    required this.settings,
  });
}
```

A session may contain:

```text
History
Variables
Functions
Constants
Settings
Calculations
```

---

# 50. Workspace Model

Workspace is broader than Session.

A workspace may contain:

```text
Variables
Constants
Equations
Calculations
Tables
Graphs
Results
Notes
Spreadsheet
```

Conceptually:

```text
Workspace
 ├── Session
 ├── Equations
 ├── Calculations
 ├── Tables
 ├── Graphs
 ├── Spreadsheet
 └── Notes
```

Workspace orchestration belongs to Application.

---

# 51. Spreadsheet Engine

Spreadsheet is an independent application engine.

It MUST NOT become a dependency of Expression Engine.

Core models:

```dart
final class CellAddress {
  final int row;
  final int column;

  const CellAddress({
    required this.row,
    required this.column,
  });
}
```

```dart
sealed class CellValue {
  const CellValue();
}
```

Cell values may contain:

```text
MathValue
Text
Boolean
Error
Empty
```

Expression formulas reference cells through a spreadsheet-specific semantic
layer.

---

# 52. Spreadsheet Dependency Graph

```dart
abstract interface class SpreadsheetEngine {
  MathResult<SpreadsheetCalculation> recalculate(
    Spreadsheet sheet,
  );

  MathResult<void> setCell(
    CellAddress address,
    CellInput input,
  );

  MathResult<CellValue> getCellValue(
    CellAddress address,
  );

  MathResult<List<CellAddress>> dependenciesOf(
    CellAddress address,
  );
}
```

Dependency graph:

```text
Cell A1
   ↓
Cell B1
   ↓
Cell C1
```

Circular references MUST be detected.

Circular references MUST return:

```text
CircularReference
```

---

# 53. Spreadsheet and Expression Dependency

Correct direction:

```text
Spreadsheet
     ↓
Expression Engine
     ↓
Numeric Engine
```

Incorrect:

```text
Expression Engine
     ↓
Spreadsheet
```

Expression Engine must remain unaware of spreadsheets.

---

# 54. Display Formatting Boundary

Mathematical calculation and visual formatting are separate.

The Mathematical Core produces:

```text
MathValue
EvaluationResult
CalculationMetadata
```

Presentation produces:

```text
7
1/2
√2
3.14159265
2.50 × 10⁶
```

Formatting contracts belong in a display/presentation-support package, not in
the mathematical algorithms.

---

# 55. Angle Configuration

Angle mode is shared configuration:

```dart
enum AngleMode {
  degrees,
  radians,
  gradians,
}
```

Trigonometric functions consume this context.

The AngleMode MUST NOT be stored globally.

---

# 56. Numeric Settings

```dart
final class NumericSettings {
  final int precision;
  final DisplayNotation notation;
  final int? fixedDigits;
  final bool engineeringNotation;

  const NumericSettings({
    required this.precision,
    required this.notation,
    this.fixedDigits,
    this.engineeringNotation = false,
  });
}
```

---

# 57. Dependency Graph

The authoritative dependency graph is:

```text
CORE
 │
 └── Mathematical Core
       │
       ├── Numeric
       │
       ├── Units
       │
       ├── Expression
       │     ├── Numeric
       │     └── Units Contracts
       │
       ├── Algebra
       │     ├── Numeric
       │     └── Expression AST
       │
       ├── Complex
       │     └── Numeric
       │
       ├── Matrix
       │     └── Numeric
       │
       ├── Vector
       │     └── Numeric
       │
       ├── Symbolic
       │     ├── Expression
       │     └── Algebra
       │
       ├── Calculus
       │     ├── Numeric
       │     ├── Expression
       │     └── Symbolic
       │
       ├── Solver
       │     ├── Numeric
       │     ├── Expression
       │     ├── Algebra
       │     └── Matrix
       │
       ├── Statistics
       │     └── Numeric
       │
       ├── Probability
       │     └── Numeric
       │
       ├── Regression
       │     ├── Numeric
       │     ├── Statistics
       │     └── Expression AST
       │
       ├── Formula
       │     ├── Numeric
       │     ├── Expression
       │     └── Units
       │
       ├── Graphing
       │     ├── Numeric
       │     ├── Expression
       │     └── Calculus Contracts
       │
       └── Programmer
             └── Numeric Integer Semantics
```

---

# 58. Application Dependency Graph

```text
Application
 │
 ├── Calculate
 │      └── Expression
 │
 ├── History
 │      └── Core Models
 │
 ├── Variables
 │      └── Mathematical Core Value Contracts
 │
 ├── Sessions
 │      └── Mathematical Core
 │
 ├── Workspaces
 │      ├── Mathematical Core
 │      └── Spreadsheet
 │
 ├── Spreadsheet
 │      ├── Expression
 │      └── Numeric
 │
 └── Settings
        └── Core Configuration
```

---

# 59. Infrastructure Dependency Graph

Infrastructure implements Application contracts.

```text
Infrastructure
 │
 ├── Persistence
 │
 ├── Repository Implementations
 │
 ├── Windows Platform Services
 │
 ├── Android Platform Services
 │
 └── Configuration
```

Infrastructure may depend on:

```text
Core
Application
Mathematical Core contracts
Flutter/platform APIs
```

Mathematical Core MUST NOT depend on Infrastructure.

---

# 60. Presentation Dependency Graph

```text
Presentation
      ↓
Application
      ↓
Mathematical Core
```

Presentation MUST NOT call low-level mathematical algorithm classes directly
when an engine façade exists.

Correct:

```text
CalculatorScreen
    ↓
CalculateExpressionUseCase
    ↓
ExpressionEngine
```

Incorrect:

```text
CalculatorScreen
    ↓
Parser
    ↓
Evaluator
```

---

# 61. Forbidden Dependencies

The following are explicitly forbidden:

```text
Numeric → Expression
Numeric → Symbolic
Numeric → Flutter
Numeric → Application
Numeric → Infrastructure
```

```text
Expression → Symbolic
Expression → Calculus
Expression → Solver
Expression → Graphing
Expression → Spreadsheet
```

```text
Algebra → Symbolic
```

```text
Mathematical Core → Application
Mathematical Core → Presentation
Mathematical Core → Infrastructure
```

```text
Units → Expression
```

```text
Spreadsheet → Presentation
```

```text
Presentation → Internal Mathematical Algorithms
```

---

# 62. Circular Dependency Rules

The following cycles are forbidden:

```text
Expression ↔ Symbolic
Expression ↔ Calculus
Expression ↔ Solver
Expression ↔ Spreadsheet
Units ↔ Expression
Numeric ↔ Expression
Application ↔ Mathematical Core implementation
```

If a feature appears to require a circular dependency, introduce a
contract/abstraction at the lower appropriate layer instead.

---

# 63. Engine Dependency Matrix

| Engine      | Core |  Numeric | Expression | Algebra |           Symbolic | Calculus | Matrix | Statistics |     Units |
| ----------- | ---: | -------: | ---------: | ------: | -----------------: | -------: | -----: | ---------: | --------: |
| Numeric     |    ✓ |        — |          — |       — |                  — |        — |      — |          — |         — |
| Units       |    ✓ |        ✓ |          — |       — |                  — |        — |      — |          — |         — |
| Expression  |    ✓ |        ✓ |          — |       — |                  — |        — |      — |          — | Contracts |
| Algebra     |    ✓ |        ✓ |        AST |       — |                  — |        — |      — |          — |         — |
| Symbolic    |    ✓ | indirect |          ✓ |       ✓ |                  — |        — |      — |          — |         — |
| Complex     |    ✓ |        ✓ |          — |       — |                  — |        — |      — |          — |         — |
| Matrix      |    ✓ |        ✓ |          — |       — |                  — |        — |      — |          — |         — |
| Vector      |    ✓ |        ✓ |          — |       — |                  — |        — |      — |          — |         — |
| Calculus    |    ✓ |        ✓ |          ✓ |       — |                  ✓ |        — |      — |          — |         — |
| Solver      |    ✓ |        ✓ |          ✓ |       ✓ |                  — |        — |      ✓ |          — |         — |
| Statistics  |    ✓ |        ✓ |          — |       — |                  — |        — |      — |          — |         — |
| Probability |    ✓ |        ✓ |          — |       — |                  — |        — |      — |          — |         — |
| Regression  |    ✓ |        ✓ |        AST |       — |                  — |        — |      — |          ✓ |         — |
| Formula     |    ✓ |        ✓ |          ✓ |       — |                  — |        — |      — |          — |         ✓ |
| Graphing    |    ✓ |        ✓ |          ✓ |       — | Calculus contracts |        ✓ |      — |          — |         — |
| Programmer  |    ✓ |  Integer |          — |       — |                  — |        — |      — |          — |         — |

---

# 64. Public Package Exports

Each engine MUST have a public barrel file.

Examples:

```text
numeric.dart
expression.dart
algebra.dart
symbolic.dart
calculus.dart
solver.dart
complex.dart
matrix.dart
vector.dart
statistics.dart
probability.dart
units.dart
formula.dart
graphing.dart
programmer.dart
```

The barrel file exports only intentional public contracts/models.

Internal implementation classes MUST remain internal to the package boundary
whenever practical.

---

# 65. Suggested Export Structure

Example:

```text
mathematical_core/expression/expression.dart
```

exports:

```text
ExpressionEngine
ExpressionNode
Token
ParsedExpression
EvaluationContext
EvaluationResult
MathFunction
FunctionRegistry
```

It does not automatically export:

```text
RecursiveDescentParser
LexerImpl
EvaluatorImpl
InternalTokenScanner
```

---

# 66. Dependency Injection

Concrete implementations MUST be assembled at the Composition Root.

Conceptually:

```text
Composition Root
      │
      ├── NumericEngineImpl
      ├── UnitEngineImpl
      ├── ExpressionEngineImpl
      ├── AlgebraEngineImpl
      ├── SymbolicEngineImpl
      ├── MatrixEngineImpl
      ├── VectorEngineImpl
      ├── SolverImpl
      ├── StatisticsEngineImpl
      ├── ProbabilityEngineImpl
      ├── FormulaEngineImpl
      ├── GraphEngineImpl
      └── ProgrammerEngineImpl
```

Consumers depend on interfaces.

---

# 67. Implementation Ownership

| Responsibility               | Owner                 |
| ---------------------------- | --------------------- |
| Arithmetic                   | Numeric               |
| Precision                    | Numeric               |
| Numeric promotion            | Numeric               |
| Parsing                      | Expression            |
| AST                          | Expression            |
| Expression evaluation        | Expression            |
| Functions                    | Expression            |
| Polynomial operations        | Algebra               |
| Symbolic manipulation        | Symbolic              |
| Differentiation              | Symbolic/Calculus     |
| Integration                  | Symbolic/Calculus     |
| Equation solving             | Solver                |
| Complex arithmetic           | Complex               |
| Matrix operations            | Matrix                |
| Vector operations            | Vector                |
| Descriptive statistics       | Statistics            |
| Regression                   | Statistics/Regression |
| Probability distributions    | Probability           |
| Dimensional analysis         | Units                 |
| Formula execution            | Formula               |
| Function sampling            | Graphing              |
| Graph analysis               | Graphing              |
| Bitwise operations           | Programmer            |
| History                      | Application           |
| Sessions                     | Application           |
| Workspaces                   | Application           |
| Spreadsheet dependency graph | Spreadsheet           |
| Persistence                  | Infrastructure        |
| UI                           | Presentation          |

---

# 68. Exactness Contract

Every engine capable of exact mathematics MUST preserve exactness whenever
supported.

Examples:

```text
1 / 3
```

should not automatically become:

```text
0.3333333333
```

internally.

Likewise:

```text
sqrt(2)
```

should not automatically be reduced to a floating-point approximation if an
exact representation is available.

Approximation is a deliberate operation.

---

# 69. Approximation Contract

When numerical approximation is used, the result MUST expose approximation
metadata.

At minimum:

```text
method
precision/tolerance where applicable
convergence state
```

Numerical algorithms MUST NOT silently present approximations as exact
mathematical answers.

---

# 70. Determinism

The Mathematical Core MUST be deterministic.

Given identical:

```text
input
context
settings
random seed where applicable
```

it MUST produce identical results.

No platform-specific floating-point behavior should intentionally change
mathematical semantics.

---

# 71. Randomness Boundary

Probability sampling requires a random source abstraction:

```dart
abstract interface class RandomSource {
  double nextDouble();

  int nextInt(int max);
}
```

The Probability Engine receives the source.

It MUST NOT instantiate platform-specific random generators internally.

This allows deterministic testing.

---

# 72. Testing Contract

Every engine requires:

```text
Unit Tests
Contract Tests
Boundary Tests
Error Tests
Precision Tests
Regression Tests
```

Critical mathematical algorithms additionally require known-reference tests.

---

# 73. Engine Contract Tests

Every public engine contract MUST have tests proving:

```text
valid input
invalid input
boundary input
error classification
deterministic output
precision behavior
```

---

# 74. Expression Contract Tests

Minimum examples:

```text
2 + 3 = 5
7 × 8 = 56
(5 + 3)^2 / 4 = 16
sin(30°) = 0.5
sqrt(25) × 2 = 10
```

Also required:

```text
division by zero
invalid syntax
unknown identifier
unknown function
nested expressions
operator precedence
parentheses
negative values
scientific notation
fractions
```

---

# 75. Unit Contract Tests

Required:

```text
10 m + 50 cm = 10.5 m
1 km = 1000 m
1 h = 3600 s
```

Invalid:

```text
10 m + 5 s
```

must return:

```text
DimensionMismatch
```

---

# 76. Matrix Contract Tests

Required:

```text
identity matrix
addition
subtraction
multiplication
transpose
determinant
inverse
rank
trace
dimension mismatch
singular matrix
```

---

# 77. Solver Contract Tests

Required:

```text
linear
quadratic
cubic
quartic
multiple roots
no real roots
complex roots where supported
systems
numerical convergence
numerical non-convergence
```

---

# 78. Numerical Precision Tests

The project MUST contain regression tests for:

```text
0.1 + 0.2
large integers
small decimals
fraction arithmetic
repeating decimals
very large powers
very small values
near-zero comparisons
cancellation
```

The purpose is to ensure NexaMath does not accidentally become a `double`-only
calculator.

---

# 79. Application Boundary Tests

Application tests MUST verify:

```text
Use Case
    ↓
Engine
    ↓
Result
    ↓
Repository
```

without requiring Flutter UI.

---

# 80. Infrastructure Boundary Tests

Infrastructure tests verify:

```text
Repository implementation
Persistence
Serialization
Platform adapters
```

without moving persistence logic into mathematical engines.

---

# 81. Presentation Boundary

Presentation should consume:

```text
Application Use Cases
View Models / State
Display Formatting
```

and must not contain mathematical algorithms.

A Flutter widget MUST NOT calculate:

```text
determinants
regression coefficients
derivatives
matrix inverse
unit conversions
```

directly.

---

# 82. Performance Contract

The architecture must support:

```text
large expressions
large matrices
large datasets
graph sampling
spreadsheet recalculation
```

without blocking the UI thread unnecessarily.

Heavy operations may later be moved to isolates.

The Mathematical Core must therefore avoid assumptions that execution always
occurs on the main Flutter isolate.

---

# 83. Serialization Boundary

Mathematical models should not be tightly coupled to persistence serialization.

For example:

```text
Matrix
```

does not implement database storage logic.

Instead:

```text
Matrix
   ↓
MatrixDto / Serializer
   ↓
Persistence
```

The same principle applies to:

```text
Session
Workspace
Formula
History
Spreadsheet
```

---

# 84. No Global Mutable Mathematical State

The following are forbidden:

```dart
static mutable currentAngleMode;
static mutable globalVariables;
static mutable globalHistory;
static mutable globalPrecision;
```

Configuration must be passed through explicit context or application state.

---

# 85. No Hidden Fallbacks

An engine MUST NOT silently change algorithm or precision mode.

For example:

```text
Exact Solver fails
```

must not silently become:

```text
Numerical Solver
```

unless explicitly requested by the caller or defined by a documented solver
policy.

Likewise:

```text
Unit conversion failure
```

must not be ignored.

---

# 86. Unsupported Features

If an operation is not implemented, the engine MUST return a typed:

```text
UnsupportedOperation
```

rather than:

```text
null
0
empty result
fake approximation
```

---

# 87. No Placeholder Implementations

Production implementation MUST NOT contain:

```text
TODO
FIXME
placeholder
dummy return
fake implementation
hardcoded demo result
```

inside production mathematical logic.

A feature is either:

```text
implemented + tested
```

or:

```text
explicitly unsupported through a typed contract
```

---

# 88. Naming Rules

Use:

```text
Engine
Repository
UseCase
Result
Request
Options
Model
Definition
Context
Metadata
```

Examples:

```text
ExpressionEngine
MatrixEngine
FormulaDefinition
CalculationMetadata
SolverOptions
EvaluationContext
HistoryRepository
CalculateExpressionUseCase
```

Avoid vague names such as:

```text
Manager
Helper
Utils
Stuff
Handler
Processor
Service
```

unless the role is genuinely represented by the name.

---

# 89. Class Ownership Rule

Every important domain model has exactly one owner.

Examples:

```text
ComplexNumber → Numeric
Polynomial → Algebra
Quantity → Units
Matrix → Matrix
Vector → Vector
ExpressionNode → Expression
Equation → Solver
Dataset → Statistics
FormulaDefinition → Formula
GraphFunction → Graphing
```

Other engines consume these models rather than redefining them.

---

# 90. Cross-Engine Model Reuse

Allowed:

```text
Solver → Equation
Solver → Matrix
Solver → Polynomial
Solver → Numeric
```

```text
Graphing → ExpressionNode
Graphing → Numeric
```

```text
Formula → Quantity
Formula → ExpressionNode
```

```text
Calculus → ExpressionNode
Calculus → SymbolicExpression
```

Models must not be copied merely to avoid importing another domain package.

---

# 91. Mathematical Core Internal Structure

Recommended internal organization:

```text
mathematical_core/
│
├── numeric/
│   ├── models/
│   ├── arithmetic/
│   ├── precision/
│   ├── promotion/
│   └── numeric.dart
│
├── expression/
│   ├── ast/
│   ├── lexer/
│   ├── parser/
│   ├── evaluator/
│   ├── functions/
│   ├── semantic/
│   └── expression.dart
│
├── algebra/
│   ├── models/
│   ├── polynomial/
│   ├── simplification/
│   └── algebra.dart
│
├── symbolic/
│   ├── models/
│   ├── simplification/
│   ├── substitution/
│   ├── differentiation/
│   ├── limits/
│   ├── integration/
│   └── symbolic.dart
│
├── calculus/
│   ├── differentiation/
│   ├── integration/
│   ├── numerical/
│   └── calculus.dart
│
├── solver/
│   ├── models/
│   ├── exact/
│   ├── numerical/
│   ├── systems/
│   └── solver.dart
│
├── complex/
│   └── complex.dart
│
├── matrix/
│   ├── models/
│   ├── operations/
│   ├── decomposition/
│   └── matrix.dart
│
├── vector/
│   ├── models/
│   ├── operations/
│   └── vector.dart
│
├── statistics/
│   ├── models/
│   ├── descriptive/
│   ├── regression/
│   └── statistics.dart
│
├── probability/
│   ├── models/
│   ├── distributions/
│   ├── algorithms/
│   └── probability.dart
│
├── units/
│   ├── models/
│   ├── dimensions/
│   ├── conversion/
│   └── units.dart
│
├── formula/
│   ├── models/
│   ├── registry/
│   └── formula.dart
│
├── graphing/
│   ├── models/
│   ├── sampling/
│   ├── analysis/
│   └── graphing.dart
│
└── programmer/
    ├── models/
    ├── bitwise/
    ├── conversion/
    └── programmer.dart
```

---

# 92. Dependency Enforcement

The implementation should enforce package boundaries through Dart imports and
architecture tests.

The project should include automated checks capable of detecting forbidden
imports such as:

```text
mathematical_core → flutter
numeric → expression
expression → symbolic
units → expression
expression → spreadsheet
```

Architecture violations must fail CI/build validation.

---

# 93. Public API Stability

Once an engine contract is consumed by another module, breaking changes require
deliberate architectural review.

Do not rename:

```text
ExpressionEngine
NumericEngine
MatrixEngine
Solver
```

or change their fundamental responsibility merely to simplify an implementation.

Implementation complexity belongs behind the contract.

---

# 94. Engine Composition

The intended high-level composition is:

```text
NumericEngine
      │
      ├──────────────┐
      ▼              ▼
 ComplexEngine   UnitEngine
      │              │
      └──────┬───────┘
             ▼
      ExpressionEngine
             │
       ┌─────┴─────┐
       ▼           ▼
   Algebra      Symbolic
       │           │
       └─────┬─────┘
             ▼
          Calculus
             │
       ┌─────┴─────────────┐
       ▼                   ▼
    Solver              Graphing
```

Parallel mathematical domains:

```text
Numeric
 ├── Matrix
 ├── Vector
 ├── Statistics
 ├── Probability
 └── Programmer
```

---

# 95. Application Composition

```text
Presentation
      ↓
Use Cases
      ↓
Sessions / Variables / History / Workspace
      ↓
Mathematical Engines
      ↓
Core Mathematical Results
```

---

# 96. Minimal End-to-End Calculation Flow

For:

```text
(5 + 3)^2 / 4
```

the exact flow is:

```text
Calculator UI
     ↓
CalculateExpressionUseCase
     ↓
ExpressionEngine.evaluate()
     ↓
Lexer
     ↓
Parser
     ↓
ExpressionNode
     ↓
Semantic Validation
     ↓
Evaluator
     ↓
NumericEngine
     ↓
EvaluationResult
     ↓
Application CalculationResult
     ↓
HistoryRepository
     ↓
Presentation Formatting
```

The UI never performs the arithmetic.

---

# 97. Graphing Flow

For:

```text
y = sin(x)
```

the flow is:

```text
Graph Screen
     ↓
Graph Use Case
     ↓
GraphEngine
     ↓
ExpressionEngine
     ↓
Numeric Evaluation
     ↓
Sampling Engine
     ↓
GraphSeries
     ↓
Flutter Graph Renderer
```

---

# 98. Solver Flow

For:

```text
x² - 5x + 6 = 0
```

the flow is:

```text
Solver UI
     ↓
Solver Use Case
     ↓
Equation Parser
     ↓
Equation
     ↓
Polynomial Detection
     ↓
Quadratic Solver
     ↓
Exact EquationSolution
     ↓
Presentation Formatter
```

---

# 99. Spreadsheet Flow

For:

```text
A1 = 10
B1 = 20
C1 = A1 + B1
```

the flow is:

```text
Spreadsheet UI
     ↓
SpreadsheetEngine
     ↓
Dependency Graph
     ↓
Cell Formula Resolution
     ↓
ExpressionEngine
     ↓
NumericEngine
     ↓
CellValue
     ↓
Spreadsheet State
```

Expression Engine remains unaware that the identifier came from a spreadsheet.

---

# 100. Unit Expression Flow

For:

```text
10 m + 50 cm
```

the flow is:

```text
ExpressionEngine
      ↓
AST
      ↓
Quantity Semantic Resolution
      ↓
UnitEngine
      ↓
Dimension Validation
      ↓
Unit Normalization
      ↓
NumericEngine
      ↓
Quantity Result
```

---

# 101. Implementation Order

The Coding Agent MUST implement the system in this order unless an explicit
architecture review authorizes a deviation.

```text
Phase 1
Core Contracts
```

```text
Phase 2
Numeric Engine
```

```text
Phase 3
Expression Engine
```

```text
Phase 4
Algebra Engine
```

```text
Phase 5
Complex Engine
Matrix Engine
Vector Engine
```

```text
Phase 6
Symbolic Engine
```

```text
Phase 7
Calculus Engine
```

```text
Phase 8
Equation Solver
```

```text
Phase 9
Statistics + Regression
```

```text
Phase 10
Probability
```

```text
Phase 11
Units + Dimensional Analysis
```

```text
Phase 12
Formula Engine
```

```text
Phase 13
Graphing
```

```text
Phase 14
Programmer Calculator
```

```text
Phase 15
Application Layer
```

```text
Phase 16
Spreadsheet
```

```text
Phase 17
Infrastructure
```

```text
Phase 18
Flutter Presentation
```

---

# 102. Phase Completion Rule

A phase is complete only when:

```text
Public contracts exist
Models are owned correctly
Implementation exists
Unit tests pass
Contract tests pass
Error handling is typed
Architecture dependencies are valid
No placeholders remain
```

Do not move to the next major phase merely because the code compiles.

---

# 103. Vertical Slice Requirement

Before implementing the complete UI, the following mathematical vertical slice
MUST work:

```text
2 + 3
```

```text
(5 + 3)^2 / 4
```

```text
sin(30°)
```

```text
sqrt(25) × 2
```

through:

```text
ExpressionEngine
→ NumericEngine
→ EvaluationResult
```

with automated tests.

---

# 104. First Production Milestone

The first production-ready mathematical milestone is:

```text
Core
+
Numeric
+
Expression
```

with:

```text
Integer
Fraction
Decimal
Complex
Exact arithmetic
Precision configuration
Lexer
Parser
AST
Evaluator
Functions
Constants
Variables
Angle modes
Typed errors
```

Only after this milestone is stable should higher mathematical engines be built
on top.

---

# 105. Acceptance Criteria

The implementation satisfies this document only when all of the following are
true:

### Architecture

- Mathematical Core is pure Dart.
- Flutter is absent from Mathematical Core.
- Infrastructure is not a Mathematical Core dependency.
- No circular engine dependencies exist.
- Public engine façades are clearly defined.

### Models

- ComplexNumber has one owner.
- Polynomial has one owner.
- Quantity has one owner.
- Matrix has one owner.
- Vector has one owner.
- ExpressionNode has one owner.
- Equation has one owner.

### Expression

- Lexer is isolated.
- Parser is isolated.
- AST is canonical.
- Evaluator consumes context.
- Evaluator returns `MathValue`.
- Exact and approximate results are distinguishable.

### Numeric

- No double-only architecture.
- Exact integer/fraction behavior is supported.
- Promotion is centralized.
- Precision behavior is deterministic.

### Units

- Dimensional analysis exists.
- Unit conversion is not string replacement.
- Incompatible dimensions fail explicitly.

### Solver

- Exact and numerical solving are distinct.
- Numerical methods expose convergence information.
- No-solution states are typed.

### Graphing

- Graphing has no rendering responsibility.
- Sampling is separated from Flutter.

### Spreadsheet

- Spreadsheet owns dependency graph.
- Expression Engine does not depend on Spreadsheet.

### Application

- Use cases orchestrate.
- Mathematical algorithms remain in Mathematical Core.
- Persistence remains in Infrastructure.

### Testing

- Engine contracts have automated tests.
- Critical mathematical algorithms have regression tests.
- Architecture boundaries are testable.

---

# 106. Non-Negotiable Rules

The following rules override implementation convenience:

1. **Do not build the calculator UI first and retrofit the mathematical engine
   later.**

2. **Do not implement the Mathematical Core around `double` only.**

3. **Do not duplicate mathematical models between engines.**

4. **Do not allow Expression Engine to depend on higher-level engines.**

5. **Do not allow Mathematical Core to depend on Flutter.**

6. **Do not put mathematical algorithms inside Flutter widgets.**

7. **Do not use repositories from mathematical engines.**

8. **Do not silently approximate exact calculations.**

9. **Do not silently fall back from exact algorithms to numerical algorithms.**

10. **Do not return fake values for unsupported operations.**

11. **Do not use untyped exceptions as the normal mathematical error
    mechanism.**

12. **Do not create circular dependencies to solve implementation convenience.**

13. **Do not expose internal algorithms as the primary public API.**

14. **Do not create global mutable mathematical state.**

15. **Do not add a second model when an existing canonical model already
    represents the concept.**

16. **Do not weaken the architecture simply to make one feature easier to
    implement.**

17. **Do not introduce TODO/placeholder/demo implementations into production
    mathematical code.**

18. **Do not change the public contract without updating this document and its
    contract tests.**

---

# 107. Coding Agent Instructions

Any Coding Agent implementing NexaMath MUST:

1. Read this document before modifying Mathematical Core.
2. Read `CALCULATOR_MASTER_SPECIFICATION.md`.
3. Read `NEXAMATH_IMPLEMENTATION_BLUEPRINT.md`.
4. Respect model ownership.
5. Respect dependency direction.
6. Implement contracts before concrete algorithms.
7. Write tests with each mathematical subsystem.
8. Keep mathematical code platform independent.
9. Report architectural deviations explicitly.
10. Never silently reduce the requested feature scope.
11. Never replace an exact requirement with an approximate implementation
    without documenting it.
12. Never introduce a forbidden dependency to bypass a design problem.
13. Return a detailed English `walkthrough.md`-style implementation report after
    each major phase.

---

# 108. Required Agent Report

After implementation, the Coding Agent MUST report:

```text
1. Files Created
2. Files Modified
3. Contracts Implemented
4. Models Implemented
5. Algorithms Implemented
6. Tests Added
7. Tests Passed
8. Architecture Verification
9. Dependency Verification
10. Known Mathematical Limitations
11. Exact vs Approximate Behavior
12. Performance Notes
13. Any Deviations From This Document
```

If there are no deviations:

```text
Architectural Deviations: NONE
```

must be explicitly stated.

---

# 109. Final Architecture

The complete NexaMath architecture is:

```text
                         ┌─────────────────────┐
                         │      Flutter UI     │
                         │ Windows + Android   │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │    Application     │
                         │ Use Cases / State   │
                         │ Sessions / History  │
                         │ Workspaces / Sheet  │
                         └──────────┬──────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────┐
│                     MATHEMATICAL CORE                        │
│                                                              │
│  Numeric ────────────────┐                                   │
│  Expression              │                                   │
│  Algebra                 │                                   │
│  Symbolic                │                                   │
│  Calculus                │                                   │
│  Solver                  │                                   │
│  Complex                 │                                   │
│  Matrix                  │                                   │
│  Vector                  │                                   │
│  Statistics              │                                   │
│  Probability             │                                   │
│  Units                   │                                   │
│  Formula                 │                                   │
│  Graphing                │                                   │
│  Programmer              │                                   │
│                          │                                   │
│      Shared Mathematical Contracts & Values                  │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │     Core     │
                    │ Errors       │
                    │ Results      │
                    │ Validation   │
                    │ Configuration│
                    └──────────────┘


Infrastructure
       │
       ├── Persistence
       ├── Repositories
       ├── Windows APIs
       └── Android APIs

implements application/platform contracts
without becoming a Mathematical Core dependency.
```

---

# 110. Final Engineering Principle

NexaMath is not architecturally defined as:

```text
Flutter Calculator App
```

It is defined as:

```text
Mathematical Computing Platform
```

with:

```text
Flutter
   ↓
Application
   ↓
Mathematical Core
```

The Mathematical Core is the central engineering asset.

Every calculator mode, graph, solver, spreadsheet, formula, statistics feature,
unit calculation, and future mathematical capability must build upon this shared
foundation rather than implementing independent mathematical logic.

The long-term architectural objective is therefore:

```text
One Mathematical Language
        +
One Mathematical Value System
        +
One Expression Engine
        +
Specialized Mathematical Engines
        +
One Application Orchestration Layer
        +
Platform-Specific Presentation
```

This structure allows NexaMath to grow from:

```text
Scientific Calculator
```

into:

```text
Engineering Calculator
        ↓
Graphing Calculator
        ↓
Mathematical Solver
        ↓
Mathematical Notebook
        ↓
Mathematical Computing Platform
```

without requiring the Mathematical Core to be rewritten when new UI modules or
platforms are introduced.
