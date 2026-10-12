# NexaMath

## Implementation Blueprint

**Project:** NexaMath
**Product Type:** Mathematical Computing Platform
**Platforms:** Windows + Android
**Technology:** Flutter + Dart
**Architecture:** Clean Architecture + Modular Mathematical Engine Architecture
**Status:** Pre-Implementation Blueprint
**Authority:** Implementation refinement of `NEXAMATH_IMPLEMENTATION_ARCHITECTURE_SPECIFICATION.md`

---

# 1. Purpose

This document defines the concrete implementation blueprint for NexaMath.

It establishes:

* concrete domain models
* interfaces
* services
* engine façades
* repositories
* value objects
* enums
* contracts
* dependency boundaries
* public APIs
* internal implementation boundaries
* dependency graph
* prohibited dependencies
* implementation order

This document exists to prevent implementation agents from inventing architectural decisions during coding.

A coding agent must implement the architecture defined here rather than redesigning it during feature implementation.

---

# 2. Architectural Layers

NexaMath consists of five major architectural areas:

```text
┌─────────────────────────────────────────────────────┐
│                    Presentation                     │
│ Flutter Widgets / Controllers / UI State            │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                    Application                      │
│ Use Cases / Application Services / DTOs             │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│               Mathematical Core                     │
│ Mathematical Models + Engines + Algorithms          │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                       Core                          │
│ Result / Errors / Validation / Shared Contracts     │
└─────────────────────────────────────────────────────┘

Infrastructure implements application/domain abstractions
and is never a dependency of the Mathematical Core.
```

---

# 3. Package Ownership

The ownership boundaries are:

```text
core/
    Shared technical/domain-neutral contracts

mathematical_core/
    Mathematical truth and algorithms

application/
    User-oriented use cases and orchestration

infrastructure/
    External systems and persistence

presentation/
    Flutter UI and interaction
```

No package may violate its ownership boundary.

---

# 4. Complete Blueprint Folder Structure

```text
lib/
│
├── core/
│   │
│   ├── errors/
│   │   ├── nexa_math_error.dart
│   │   ├── validation_error.dart
│   │   ├── calculation_error.dart
│   │   └── persistence_error.dart
│   │
│   ├── result/
│   │   ├── math_result.dart
│   │   ├── result_extensions.dart
│   │   └── result_helpers.dart
│   │
│   ├── validation/
│   │   ├── validator.dart
│   │   └── validation_result.dart
│   │
│   ├── configuration/
│   │   ├── app_configuration.dart
│   │   └── feature_flags.dart
│   │
│   └── utilities/
│       └── ...
│
├── mathematical_core/
│   │
│   ├── common/
│   │   ├── math_context.dart
│   │   ├── evaluation_context.dart
│   │   ├── angle_mode.dart
│   │   ├── precision_context.dart
│   │   └── numeric_kind.dart
│   │
│   ├── numeric/
│   │   ├── numeric_value.dart
│   │   ├── integer/
│   │   │   └── integer_value.dart
│   │   ├── decimal/
│   │   │   └── decimal_value.dart
│   │   ├── fraction/
│   │   │   └── fraction_value.dart
│   │   ├── complex/
│   │   │   └── complex_value.dart
│   │   ├── polynomial/
│   │   │   └── polynomial_value.dart
│   │   ├── quantity/
│   │   │   └── quantity_value.dart
│   │   ├── numeric_operations.dart
│   │   ├── numeric_comparator.dart
│   │   ├── numeric_promoter.dart
│   │   ├── precision/
│   │   │   ├── precision_context.dart
│   │   │   ├── rounding_mode.dart
│   │   │   └── significant_digits.dart
│   │   └── numeric_engine.dart
│   │
│   ├── expression/
│   │   ├── tokens/
│   │   │   ├── token.dart
│   │   │   ├── token_type.dart
│   │   │   └── source_position.dart
│   │   ├── lexer/
│   │   │   ├── lexer.dart
│   │   │   └── expression_lexer.dart
│   │   ├── ast/
│   │   │   ├── expression_node.dart
│   │   │   ├── number_node.dart
│   │   │   ├── variable_node.dart
│   │   │   ├── constant_node.dart
│   │   │   ├── unary_node.dart
│   │   │   ├── binary_node.dart
│   │   │   ├── function_call_node.dart
│   │   │   ├── fraction_node.dart
│   │   │   └── quantity_node.dart
│   │   ├── parser/
│   │   │   ├── expression_parser.dart
│   │   │   └── recursive_descent_parser.dart
│   │   ├── evaluator/
│   │   │   ├── expression_evaluator.dart
│   │   │   └── ast_evaluator.dart
│   │   ├── functions/
│   │   │   ├── math_function.dart
│   │   │   ├── function_registry.dart
│   │   │   └── built_in_functions.dart
│   │   ├── operators/
│   │   │   ├── operator_definition.dart
│   │   │   └── operator_registry.dart
│   │   ├── expression_engine.dart
│   │   └── evaluation_context.dart
│   │
│   ├── algebra/
│   │   ├── polynomial/
│   │   │   ├── polynomial.dart
│   │   │   ├── polynomial_operations.dart
│   │   │   └── polynomial_parser.dart
│   │   ├── simplification/
│   │   │   └── algebraic_simplifier.dart
│   │   ├── expansion/
│   │   │   └── expression_expander.dart
│   │   └── factorization/
│   │       └── polynomial_factorizer.dart
│   │
│   ├── symbolic/
│   │   ├── symbolic_engine.dart
│   │   ├── simplification/
│   │   │   └── symbolic_simplifier.dart
│   │   ├── substitution/
│   │   │   └── expression_substitutor.dart
│   │   ├── differentiation/
│   │   │   └── symbolic_differentiator.dart
│   │   ├── limits/
│   │   │   └── symbolic_limit_solver.dart
│   │   └── integration/
│   │       └── symbolic_integrator.dart
│   │
│   ├── calculus/
│   │   ├── calculus_engine.dart
│   │   ├── differentiation/
│   │   │   └── numerical_differentiator.dart
│   │   ├── integration/
│   │   │   ├── numerical_integrator.dart
│   │   │   └── integration_method.dart
│   │   └── approximation/
│   │       └── approximation_engine.dart
│   │
│   ├── solver/
│   │   ├── equation.dart
│   │   ├── equation_solution.dart
│   │   ├── numerical_solution.dart
│   │   ├── solver_options.dart
│   │   ├── equation_solver.dart
│   │   ├── exact/
│   │   │   ├── linear_solver.dart
│   │   │   ├── quadratic_solver.dart
│   │   │   ├── cubic_solver.dart
│   │   │   ├── quartic_solver.dart
│   │   │   └── polynomial_solver.dart
│   │   ├── numerical/
│   │   │   ├── bisection_solver.dart
│   │   │   ├── newton_raphson_solver.dart
│   │   │   └── secant_solver.dart
│   │   └── systems/
│   │       ├── linear_system_solver.dart
│   │       └── nonlinear_system_solver.dart
│   │
│   ├── complex/
│   │   ├── complex_number.dart
│   │   ├── complex_operations.dart
│   │   ├── rectangular_form.dart
│   │   ├── polar_form.dart
│   │   └── complex_engine.dart
│   │
│   ├── matrix/
│   │   ├── matrix.dart
│   │   ├── matrix_shape.dart
│   │   ├── matrix_operations.dart
│   │   ├── matrix_engine.dart
│   │   ├── decomposition/
│   │   │   ├── gaussian_elimination.dart
│   │   │   ├── lu_decomposition.dart
│   │   │   └── qr_decomposition.dart
│   │   └── advanced/
│   │       ├── eigenvalue_solver.dart
│   │       └── eigenvector_solver.dart
│   │
│   ├── vector/
│   │   ├── vector.dart
│   │   ├── vector_operations.dart
│   │   └── vector_engine.dart
│   │
│   ├── statistics/
│   │   ├── dataset.dart
│   │   ├── descriptive/
│   │   │   ├── descriptive_statistics.dart
│   │   │   └── statistics_result.dart
│   │   ├── correlation/
│   │   │   └── correlation_calculator.dart
│   │   ├── regression/
│   │   │   ├── regression_model.dart
│   │   │   ├── regression_result.dart
│   │   │   ├── linear_regression.dart
│   │   │   ├── quadratic_regression.dart
│   │   │   ├── cubic_regression.dart
│   │   │   ├── logarithmic_regression.dart
│   │   │   ├── exponential_regression.dart
│   │   │   ├── power_regression.dart
│   │   │   └── geometric_regression.dart
│   │   └── statistics_engine.dart
│   │
│   ├── probability/
│   │   ├── probability_engine.dart
│   │   ├── probability_result.dart
│   │   ├── distribution.dart
│   │   ├── distributions/
│   │   │   ├── normal_distribution.dart
│   │   │   ├── binomial_distribution.dart
│   │   │   ├── poisson_distribution.dart
│   │   │   ├── uniform_distribution.dart
│   │   │   ├── exponential_distribution.dart
│   │   │   └── geometric_distribution.dart
│   │   └── sampling/
│   │       └── random_source.dart
│   │
│   ├── units/
│   │   ├── dimension.dart
│   │   ├── dimension_vector.dart
│   │   ├── unit.dart
│   │   ├── quantity.dart
│   │   ├── unit_system.dart
│   │   ├── unit_registry.dart
│   │   ├── unit_converter.dart
│   │   └── unit_engine.dart
│   │
│   ├── formulas/
│   │   ├── formula_definition.dart
│   │   ├── formula_variable.dart
│   │   ├── formula_result.dart
│   │   ├── formula_category.dart
│   │   ├── formula_repository.dart
│   │   ├── formula_engine.dart
│   │   ├── physics/
│   │   ├── geometry/
│   │   ├── finance/
│   │   ├── chemistry/
│   │   └── custom/
│   │
│   ├── graphing/
│   │   ├── graph_function.dart
│   │   ├── graph_range.dart
│   │   ├── graph_point.dart
│   │   ├── graph_series.dart
│   │   ├── graph_result.dart
│   │   ├── graph_engine.dart
│   │   ├── sampling/
│   │   │   ├── graph_sampler.dart
│   │   │   └── adaptive_sampler.dart
│   │   └── analysis/
│   │       ├── root_detector.dart
│   │       ├── intersection_detector.dart
│   │       └── extrema_detector.dart
│   │
│   └── programmer/
│       ├── integer_base.dart
│       ├── integer_width.dart
│       ├── programmer_value.dart
│       ├── bitwise_operation.dart
│       └── programmer_engine.dart
│
├── application/
│   │
│   ├── calculator/
│   │   ├── calculate_expression_use_case.dart
│   │   ├── calculator_state.dart
│   │   └── calculator_service.dart
│   │
│   ├── history/
│   │   ├── calculation_history_entry.dart
│   │   ├── history_repository.dart
│   │   └── history_service.dart
│   │
│   ├── variables/
│   │   ├── variable_definition.dart
│   │   ├── variable_repository.dart
│   │   └── variable_service.dart
│   │
│   ├── sessions/
│   │   ├── session.dart
│   │   ├── session_repository.dart
│   │   └── session_service.dart
│   │
│   ├── workspace/
│   │   ├── workspace.dart
│   │   ├── workspace_repository.dart
│   │   └── workspace_service.dart
│   │
│   ├── spreadsheet/
│   │   ├── spreadsheet.dart
│   │   ├── cell.dart
│   │   ├── cell_address.dart
│   │   ├── cell_value.dart
│   │   ├── dependency_graph.dart
│   │   ├── spreadsheet_engine.dart
│   │   └── spreadsheet_repository.dart
│   │
│   ├── settings/
│   │   ├── application_settings.dart
│   │   └── settings_repository.dart
│   │
│   └── shared/
│       ├── application_result.dart
│       └── operation_metadata.dart
│
├── infrastructure/
│   │
│   ├── persistence/
│   │   ├── database/
│   │   ├── repositories/
│   │   ├── mappers/
│   │   └── serializers/
│   │
│   ├── filesystem/
│   ├── logging/
│   └── platform/
│       ├── windows/
│       └── android/
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
    ├── sessions/
    ├── history/
    └── settings/
```

---

# 5. Core Foundation Contracts

## 5.1 NexaMathError

```dart
abstract interface class NexaMathError {
  String get code;
  String get technicalMessage;
}
```

The error contract must not contain UI-localized messages.

---

# 6. MathResult

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

Every mathematical operation that can fail must return `MathResult<T>`.

---

# 7. Mathematical Context

## 7.1 MathContext

```dart
final class MathContext {
  final EvaluationContext evaluation;
  final PrecisionContext precision;
}
```

## 7.2 EvaluationContext

```dart
final class EvaluationContext {
  final AngleMode angleMode;
  final PrecisionContext precision;
  final Map<String, NumericValue> variables;
  final FunctionRegistry functions;
  final ConstantRegistry constants;
}
```

`EvaluationContext` is immutable from the perspective of an individual evaluation.

---

# 8. Numeric Architecture

The Numeric Engine is the foundation on which the majority of mathematical engines operate.

---

# 9. NumericValue

```dart
abstract interface class NumericValue {
  NumericKind get kind;

  bool get isExact;
}
```

Required implementations:

```text
IntegerValue
DecimalValue
FractionValue
ComplexValue
PolynomialValue
QuantityValue
```

Matrix and Vector are mathematical structures rather than scalar numeric values and therefore remain their own domain models.

---

# 10. IntegerValue

```dart
final class IntegerValue implements NumericValue {
  final BigInt value;

  @override
  NumericKind get kind => NumericKind.integer;

  @override
  bool get isExact => true;
}
```

`BigInt` is used internally where integer range requires arbitrary precision.

---

# 11. DecimalValue

The concrete representation must provide controlled precision rather than assuming binary floating-point is sufficient for every operation.

```dart
final class DecimalValue implements NumericValue {
  // Exact implementation selected during Numeric Engine implementation.
}
```

The implementation must obey `PrecisionContext`.

---

# 12. FractionValue

```dart
final class FractionValue implements NumericValue {
  final IntegerValue numerator;
  final IntegerValue denominator;

  bool get isProper;
}
```

Invariant:

```text
denominator != 0
denominator is normalized
fraction is reduced to canonical form
```

---

# 13. NumericEngine

```dart
abstract interface class NumericEngine {
  MathResult<NumericValue> add(
    NumericValue a,
    NumericValue b,
  );

  MathResult<NumericValue> subtract(
    NumericValue a,
    NumericValue b,
  );

  MathResult<NumericValue> multiply(
    NumericValue a,
    NumericValue b,
  );

  MathResult<NumericValue> divide(
    NumericValue a,
    NumericValue b,
  );

  MathResult<NumericValue> power(
    NumericValue base,
    NumericValue exponent,
  );

  MathResult<NumericValue> negate(NumericValue value);

  MathResult<NumericValue> absolute(NumericValue value);
}
```

---

# 14. Numeric Promotion

`NumericPromoter` determines compatible promotion.

```dart
abstract interface class NumericPromoter {
  MathResult<(NumericValue, NumericValue)> promote(
    NumericValue a,
    NumericValue b,
  );
}
```

Promotion must never silently lose exactness.

---

# 15. Expression Engine Models

## 15.1 Token

```dart
final class Token {
  final TokenType type;
  final String lexeme;
  final SourcePosition position;
}
```

## 15.2 TokenType

```text
number
identifier
operator
leftParenthesis
rightParenthesis
comma
endOfInput
```

Additional token types may be introduced only when required by the expression grammar.

---

# 16. ExpressionNode

```dart
sealed class ExpressionNode {
  const ExpressionNode();
}
```

Required implementations:

```text
NumberNode
VariableNode
ConstantNode
UnaryNode
BinaryNode
FunctionCallNode
FractionNode
QuantityNode
```

The AST must remain immutable.

---

# 17. Lexer

```dart
abstract interface class Lexer {
  MathResult<List<Token>> tokenize(String source);
}
```

Concrete implementation:

```text
ExpressionLexer
```

The Lexer may depend on:

```text
Core errors
Token models
Validation
```

It must not depend on:

```text
Flutter
Application
Persistence
Presentation
```

---

# 18. Parser

```dart
abstract interface class ExpressionParser {
  MathResult<ExpressionNode> parse(
    List<Token> tokens,
  );
}
```

Concrete implementation:

```text
RecursiveDescentParser
```

The Parser consumes tokens and produces AST nodes.

It must not evaluate mathematical values.

---

# 19. ExpressionEvaluator

```dart
abstract interface class ExpressionEvaluator {
  MathResult<NumericValue> evaluate(
    ExpressionNode expression,
    EvaluationContext context,
  );
}
```

Concrete implementation:

```text
AstEvaluator
```

Dependencies:

```text
AST
NumericEngine
FunctionRegistry
Variable context
Constants
Units where quantity expressions are involved
```

---

# 20. ExpressionEngine

The façade is:

```dart
abstract interface class ExpressionEngine {
  MathResult<ExpressionNode> parse(
    String source,
  );

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

Concrete implementation:

```text
DefaultExpressionEngine
```

The façade hides:

```text
Lexer
Parser
Evaluator
Operator registry
Function registry
```

---

# 21. Function System

## MathFunction

```dart
abstract interface class MathFunction {
  String get name;

  int? get minimumArguments;

  int? get maximumArguments;

  MathResult<NumericValue> evaluate(
    List<NumericValue> arguments,
    EvaluationContext context,
  );
}
```

The function registry:

```dart
abstract interface class FunctionRegistry {
  MathResult<void> register(MathFunction function);

  MathResult<MathFunction> resolve(String name);

  bool contains(String name);
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
sqrt
cbrt
log
ln
exp
abs
factorial
combinations
permutations
```

The exact supported function list is governed by the Master Specification and subsequent implementation contracts.

---

# 22. Operator System

```dart
final class OperatorDefinition {
  final String symbol;
  final int precedence;
  final Associativity associativity;
  final OperatorArity arity;
}
```

Registry:

```dart
abstract interface class OperatorRegistry {
  MathResult<OperatorDefinition> resolve(String symbol);
}
```

---

# 23. Algebra Engine

## Polynomial

```dart
final class Polynomial {
  final String variable;
  final List<NumericValue> coefficients;

  int get degree;
}
```

Coefficients must be stored in canonical order.

---

# 24. PolynomialOperations

```dart
abstract interface class PolynomialOperations {
  MathResult<Polynomial> add(
    Polynomial a,
    Polynomial b,
  );

  MathResult<Polynomial> subtract(
    Polynomial a,
    Polynomial b,
  );

  MathResult<Polynomial> multiply(
    Polynomial a,
    Polynomial b,
  );

  MathResult<Polynomial> derivative(
    Polynomial polynomial,
  );

  MathResult<NumericValue> evaluate(
    Polynomial polynomial,
    NumericValue x,
  );
}
```

---

# 25. AlgebraicSimplifier

```dart
abstract interface class AlgebraicSimplifier {
  MathResult<ExpressionNode> simplify(
    ExpressionNode expression,
  );
}
```

---

# 26. ExpressionExpander

```dart
abstract interface class ExpressionExpander {
  MathResult<ExpressionNode> expand(
    ExpressionNode expression,
  );
}
```

---

# 27. PolynomialFactorizer

```dart
abstract interface class PolynomialFactorizer {
  MathResult<ExpressionNode> factor(
    ExpressionNode expression,
  );
}
```

---

# 28. Symbolic Engine

## SymbolicEngine

```dart
abstract interface class SymbolicEngine {
  MathResult<ExpressionNode> simplify(
    ExpressionNode expression,
  );

  MathResult<ExpressionNode> expand(
    ExpressionNode expression,
  );

  MathResult<ExpressionNode> factor(
    ExpressionNode expression,
  );

  MathResult<ExpressionNode> substitute(
    ExpressionNode expression,
    Map<String, ExpressionNode> substitutions,
  );

  MathResult<ExpressionNode> differentiate(
    ExpressionNode expression,
    String variable,
  );

  MathResult<ExpressionNode> limit(
    ExpressionNode expression,
    String variable,
    ExpressionNode point,
  );

  MathResult<ExpressionNode> integrate(
    ExpressionNode expression,
    String variable,
  );
}
```

`integrate()` must only succeed for explicitly supported symbolic integration cases.

---

# 29. Symbolic Differentiator

```dart
abstract interface class SymbolicDifferentiator {
  MathResult<ExpressionNode> differentiate(
    ExpressionNode expression,
    String variable,
  );
}
```

It operates on AST.

It does not numerically evaluate the derivative.

---

# 30. Symbolic Integrator

```dart
abstract interface class SymbolicIntegrator {
  MathResult<ExpressionNode> integrate(
    ExpressionNode expression,
    String variable,
  );
}
```

Unsupported integrals must produce an explicit failure.

---

# 31. Calculus Engine

```dart
abstract interface class CalculusEngine {
  MathResult<ExpressionNode> differentiateSymbolically(
    ExpressionNode expression,
    String variable,
  );

  MathResult<NumericValue> differentiateNumerically(
    ExpressionNode expression,
    String variable,
    NumericValue point,
  );

  MathResult<ExpressionNode> integrateSymbolically(
    ExpressionNode expression,
    String variable,
  );

  MathResult<NumericValue> integrateNumerically(
    ExpressionNode expression,
    String variable,
    NumericValue lowerBound,
    NumericValue upperBound,
    IntegrationOptions options,
  );
}
```

The Calculus Engine delegates symbolic operations to Symbolic Engine and numerical operations to numerical calculus algorithms.

---

# 32. Equation Models

```dart
final class Equation {
  final ExpressionNode left;
  final ExpressionNode right;
  final List<String> variables;
}
```

---

# 33. EquationSolution

```dart
final class EquationSolution {
  final SolutionKind kind;
  final List<ExpressionNode> exactSolutions;
  final List<NumericValue> approximateSolutions;
  final bool isExact;
}
```

`SolutionKind`:

```text
unique
multiple
none
infinite
```

---

# 34. EquationSolver

```dart
abstract interface class EquationSolver {
  MathResult<EquationSolution> solve(
    Equation equation,
    SolverOptions options,
  );
}
```

---

# 35. Exact Solver Contracts

```dart
abstract interface class LinearEquationSolver {}

abstract interface class QuadraticEquationSolver {}

abstract interface class CubicEquationSolver {}

abstract interface class QuarticEquationSolver {}

abstract interface class PolynomialEquationSolver {}
```

Each solver must expose a typed `solve()` contract appropriate to its equation type.

---

# 36. Numerical Solver Contracts

```dart
abstract interface class NumericalEquationSolver {
  MathResult<NumericalSolution> solve(
    Equation equation,
    SolverOptions options,
  );
}
```

Implementations:

```text
BisectionSolver
NewtonRaphsonSolver
SecantSolver
```

---

# 37. NumericalSolution

```dart
final class NumericalSolution {
  final NumericValue value;
  final int iterations;
  final NumericValue residual;
  final bool converged;
}
```

---

# 38. Matrix Model

```dart
final class Matrix {
  final int rows;
  final int columns;
  final List<List<NumericValue>> values;

  MatrixShape get shape;
}
```

Invariants:

```text
rows > 0
columns > 0
all rows have equal length
```

---

# 39. MatrixEngine

```dart
abstract interface class MatrixEngine {
  MathResult<Matrix> add(Matrix a, Matrix b);

  MathResult<Matrix> subtract(Matrix a, Matrix b);

  MathResult<Matrix> multiply(Matrix a, Matrix b);

  MathResult<Matrix> scalarMultiply(
    Matrix matrix,
    NumericValue scalar,
  );

  MathResult<Matrix> transpose(Matrix matrix);

  MathResult<NumericValue> determinant(Matrix matrix);

  MathResult<Matrix> inverse(Matrix matrix);

  MathResult<int> rank(Matrix matrix);

  MathResult<NumericValue> trace(Matrix matrix);

  MathResult<Matrix> power(
    Matrix matrix,
    int exponent,
  );
}
```

---

# 40. Vector Model

```dart
final class Vector {
  final List<NumericValue> components;

  int get dimension;
}
```

---

# 41. VectorEngine

```dart
abstract interface class VectorEngine {
  MathResult<Vector> add(Vector a, Vector b);

  MathResult<Vector> subtract(Vector a, Vector b);

  MathResult<NumericValue> dot(Vector a, Vector b);

  MathResult<Vector> cross(Vector a, Vector b);

  MathResult<NumericValue> magnitude(Vector vector);

  MathResult<Vector> normalize(Vector vector);

  MathResult<NumericValue> angle(
    Vector a,
    Vector b,
  );

  MathResult<Vector> projection(
    Vector vector,
    Vector onto,
  );
}
```

---

# 42. Complex Model

```dart
final class ComplexNumber {
  final NumericValue real;
  final NumericValue imaginary;
}
```

---

# 43. ComplexEngine

```dart
abstract interface class ComplexEngine {
  MathResult<ComplexNumber> add(
    ComplexNumber a,
    ComplexNumber b,
  );

  MathResult<ComplexNumber> subtract(
    ComplexNumber a,
    ComplexNumber b,
  );

  MathResult<ComplexNumber> multiply(
    ComplexNumber a,
    ComplexNumber b,
  );

  MathResult<ComplexNumber> divide(
    ComplexNumber a,
    ComplexNumber b,
  );

  MathResult<ComplexNumber> power(
    ComplexNumber base,
    NumericValue exponent,
  );

  MathResult<List<ComplexNumber>> roots(
    ComplexNumber value,
    int degree,
  );

  MathResult<NumericValue> magnitude(
    ComplexNumber value,
  );

  MathResult<NumericValue> argument(
    ComplexNumber value,
  );

  MathResult<ComplexNumber> conjugate(
    ComplexNumber value,
  );
}
```

---

# 44. Statistics Dataset

```dart
final class Dataset {
  final List<NumericValue> values;
}
```

For paired data:

```dart
final class PairedDataset {
  final List<NumericValue> x;
  final List<NumericValue> y;
}
```

---

# 45. DescriptiveStatistics

```dart
abstract interface class DescriptiveStatistics {
  MathResult<NumericValue> mean(Dataset data);

  MathResult<NumericValue> median(Dataset data);

  MathResult<List<NumericValue>> mode(Dataset data);

  MathResult<NumericValue> minimum(Dataset data);

  MathResult<NumericValue> maximum(Dataset data);

  MathResult<NumericValue> range(Dataset data);

  MathResult<NumericValue> variance(Dataset data);

  MathResult<NumericValue> standardDeviation(Dataset data);

  MathResult<NumericValue> percentile(
    Dataset data,
    NumericValue percentile,
  );

  MathResult<List<NumericValue>> quartiles(Dataset data);
}
```

---

# 46. StatisticsEngine

```dart
abstract interface class StatisticsEngine {
  MathResult<StatisticsResult> describe(
    Dataset data,
  );

  MathResult<NumericValue> correlation(
    PairedDataset data,
  );
}
```

---

# 47. Regression Architecture

## RegressionModel

```dart
abstract interface class RegressionModel {
  RegressionType get type;

  MathResult<RegressionResult> fit(
    PairedDataset data,
  );
}
```

## RegressionResult

```dart
final class RegressionResult {
  final RegressionType type;
  final ExpressionNode equation;
  final List<NumericValue> coefficients;
  final NumericValue correlation;
  final List<NumericValue> predictions;
  final List<NumericValue> residuals;
}
```

---

# 48. Probability Distribution

```dart
abstract interface class ProbabilityDistribution {
  MathResult<NumericValue> pdf(
    NumericValue x,
  );

  MathResult<NumericValue> cdf(
    NumericValue x,
  );

  MathResult<NumericValue> inverseCdf(
    NumericValue probability,
  );

  MathResult<NumericValue> sample(
    RandomSource source,
  );
}
```

Implementations:

```text
NormalDistribution
BinomialDistribution
PoissonDistribution
UniformDistribution
ExponentialDistribution
GeometricDistribution
```

---

# 49. ProbabilityEngine

```dart
abstract interface class ProbabilityEngine {
  MathResult<NumericValue> probability(
    ProbabilityExpression expression,
  );

  MathResult<ProbabilityDistribution> distribution(
    DistributionType type,
  );
}
```

---

# 50. Unit Architecture

## Dimension

```dart
final class Dimension {
  final DimensionVector vector;
}
```

## DimensionVector

The base-dimension representation must support derived dimensions.

Conceptually:

```text
Length
Mass
Time
Temperature
Current
AmountOfSubstance
LuminousIntensity
```

Derived dimensions are calculated from these base dimensions.

---

# 51. Unit

```dart
final class Unit {
  final String id;
  final String symbol;
  final Dimension dimension;
  final UnitConversion conversion;
}
```

---

# 52. Quantity

```dart
final class Quantity {
  final NumericValue value;
  final Unit unit;
}
```

---

# 53. UnitEngine

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

  MathResult<Quantity> subtract(
    Quantity a,
    Quantity b,
  );

  MathResult<Quantity> multiply(
    Quantity a,
    Quantity b,
  );

  MathResult<Quantity> divide(
    Quantity a,
    Quantity b,
  );
}
```

---

# 54. Formula Model

```dart
final class FormulaDefinition {
  final String id;
  final String name;
  final FormulaCategory category;
  final ExpressionNode expression;
  final List<FormulaVariable> variables;
  final String description;
}
```

---

# 55. FormulaVariable

```dart
final class FormulaVariable {
  final String symbol;
  final String name;
  final Dimension? dimension;
  final bool required;
}
```

---

# 56. FormulaEngine

```dart
abstract interface class FormulaEngine {
  MathResult<List<FormulaDefinition>> getByCategory(
    FormulaCategory category,
  );

  MathResult<FormulaDefinition> getById(
    String id,
  );

  MathResult<FormulaResult> evaluate(
    FormulaDefinition formula,
    Map<String, Quantity> inputs,
  );
}
```

---

# 57. Graphing Models

## GraphFunction

```dart
final class GraphFunction {
  final String id;
  final ExpressionNode expression;
  final String variable;
}
```

## GraphRange

```dart
final class GraphRange {
  final NumericValue xMin;
  final NumericValue xMax;
  final NumericValue yMin;
  final NumericValue yMax;
}
```

## GraphPoint

```dart
final class GraphPoint {
  final NumericValue x;
  final NumericValue y;
  final bool valid;
}
```

## GraphSeries

```dart
final class GraphSeries {
  final GraphFunction function;
  final List<GraphPoint> points;
}
```

---

# 58. GraphEngine

```dart
abstract interface class GraphEngine {
  MathResult<GraphResult> plot(
    GraphFunction function,
    GraphRange range,
    GraphOptions options,
  );

  MathResult<List<GraphPoint>> findRoots(
    GraphFunction function,
    GraphRange range,
  );

  MathResult<List<GraphPoint>> findIntersections(
    GraphFunction first,
    GraphFunction second,
    GraphRange range,
  );

  MathResult<List<GraphPoint>> findExtrema(
    GraphFunction function,
    GraphRange range,
  );
}
```

The Graph Engine owns mathematical sampling.

Flutter owns rendering.

---

# 59. Programmer Model

```dart
enum IntegerBase {
  binary,
  octal,
  decimal,
  hexadecimal,
}

enum IntegerWidth {
  bits8,
  bits16,
  bits32,
  bits64,
}
```

```dart
final class ProgrammerValue {
  final BigInt value;
  final IntegerBase base;
  final IntegerWidth width;
}
```

---

# 60. ProgrammerEngine

```dart
abstract interface class ProgrammerEngine {
  MathResult<ProgrammerValue> convertBase(
    ProgrammerValue value,
    IntegerBase targetBase,
  );

  MathResult<ProgrammerValue> and(
    ProgrammerValue a,
    ProgrammerValue b,
  );

  MathResult<ProgrammerValue> or(
    ProgrammerValue a,
    ProgrammerValue b,
  );

  MathResult<ProgrammerValue> xor(
    ProgrammerValue a,
    ProgrammerValue b,
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
}
```

---

# 61. Application Layer Blueprint

The Application Layer converts user intent into domain operations.

---

# 62. CalculateExpressionUseCase

```dart
final class CalculateExpressionUseCase {
  final ExpressionEngine expressionEngine;
  final VariableRepository variableRepository;

  Future<MathResult<CalculationResult>> execute(
    CalculateExpressionRequest request,
  );
}
```

The use case:

```text
Request
 ↓
Build EvaluationContext
 ↓
ExpressionEngine
 ↓
CalculationResult
```

---

# 63. CalculationResult

```dart
final class CalculationResult {
  final String sourceExpression;
  final ExpressionNode expression;
  final NumericValue value;
  final bool isExact;
}
```

---

# 64. History

```dart
final class CalculationHistoryEntry {
  final String id;
  final String expression;
  final CalculationResult result;
  final DateTime timestamp;
  final bool pinned;
}
```

Repository:

```dart
abstract interface class HistoryRepository {
  Future<MathResult<void>> save(
    CalculationHistoryEntry entry,
  );

  Future<MathResult<List<CalculationHistoryEntry>>> getAll();

  Future<MathResult<List<CalculationHistoryEntry>>> search(
    String query,
  );

  Future<MathResult<void>> delete(
    String id,
  );

  Future<MathResult<void>> update(
    CalculationHistoryEntry entry,
  );
}
```

---

# 65. Variables

```dart
final class VariableDefinition {
  final String name;
  final NumericValue value;
}
```

Repository:

```dart
abstract interface class VariableRepository {
  MathResult<void> set(
    VariableDefinition variable,
  );

  MathResult<VariableDefinition> get(
    String name,
  );

  bool contains(String name);

  MathResult<void> remove(String name);

  List<VariableDefinition> getAll();
}
```

---

# 66. Session

```dart
final class Session {
  final String id;
  final String name;
  final SessionType type;
  final List<CalculationHistoryEntry> history;
  final List<VariableDefinition> variables;
}
```

A Session represents a mathematical environment.

---

# 67. Workspace

```dart
final class Workspace {
  final String id;
  final String name;
  final List<VariableDefinition> variables;
  final List<WorkspaceEquation> equations;
  final List<WorkspaceCalculation> calculations;
  final List<WorkspaceTable> tables;
  final List<WorkspaceGraph> graphs;
  final List<WorkspaceResult> results;
  final String? notes;
}
```

Workspace is a mathematical document/project.

---

# 68. Spreadsheet Architecture

The Spreadsheet is an Application-level subsystem consuming the Mathematical Core.

Core models:

```text
Spreadsheet
Cell
CellAddress
CellValue
CellFormula
DependencyGraph
```

---

# 69. CellAddress

```dart
final class CellAddress {
  final int row;
  final int column;
}
```

---

# 70. Cell

```dart
final class Cell {
  final CellAddress address;
  final CellValue value;
  final String? formula;
}
```

---

# 71. DependencyGraph

```dart
abstract interface class DependencyGraph {
  MathResult<void> updateDependencies(
    CellAddress cell,
    Set<CellAddress> dependencies,
  );

  MathResult<List<CellAddress>> getDependents(
    CellAddress cell,
  );

  MathResult<List<CellAddress>> getDependencies(
    CellAddress cell,
  );

  MathResult<bool> containsCycle();
}
```

---

# 72. SpreadsheetEngine

```dart
abstract interface class SpreadsheetEngine {
  MathResult<CellValue> evaluateCell(
    Spreadsheet spreadsheet,
    CellAddress address,
  );

  MathResult<void> recalculate(
    Spreadsheet spreadsheet,
  );

  MathResult<void> setCellFormula(
    Spreadsheet spreadsheet,
    CellAddress address,
    String formula,
  );
}
```

The Spreadsheet Engine depends on the Expression Engine.

The Expression Engine never depends on Spreadsheet.

---

# 73. Repository Architecture

Repositories are contracts.

Their implementations belong to Infrastructure.

Example:

```text
application/history/history_repository.dart
                 ↑
                 │ interface
                 │
infrastructure/persistence/repositories/
    local_history_repository.dart
```

---

# 74. Infrastructure Repositories

Examples:

```text
LocalHistoryRepository
LocalVariableRepository
LocalSessionRepository
LocalWorkspaceRepository
LocalSettingsRepository
LocalSpreadsheetRepository
```

They implement application-level repository contracts.

---

# 75. Mathematical Core Repository Rule

Mathematical Core must not contain:

```text
HistoryRepository
WorkspaceRepository
DatabaseRepository
FlutterSecureStorage
SQLite
SharedPreferences
File APIs
Android APIs
Windows APIs
```

unless a future architectural decision explicitly creates a pure mathematical persistence abstraction within the Core.

---

# 76. Dependency Graph — High Level

The authoritative dependency graph is:

```text
                         PRESENTATION
                              │
                              ▼
                         APPLICATION
                              │
             ┌────────────────┼─────────────────┐
             │                │                 │
             ▼                ▼                 ▼
       EXPRESSION        STATISTICS        WORKSPACE
       APPLICATION        USE CASES        / SPREADSHEET
             │                │                 │
             └────────────────┼─────────────────┘
                              ▼
                    MATHEMATICAL CORE
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
     EXPRESSION            NUMERIC              UNITS
         │                    │                    │
         ├──────────────┐     │                    │
         ▼              ▼     ▼                    ▼
      ALGEBRA       SYMBOLIC CALCULUS         FORMULA
         │              │       │                │
         └──────┬───────┴───────┴────────────────┘
                │
                ▼
              SOLVER

     MATRIX ← NUMERIC
     VECTOR ← NUMERIC
     COMPLEX ← NUMERIC
     STATISTICS ← NUMERIC
     PROBABILITY ← NUMERIC
     GRAPHING ← EXPRESSION + NUMERIC + CALCULUS
     PROGRAMMER ← NUMERIC / INTEGER SEMANTICS
```

---

# 77. Authoritative Engine Dependency Matrix

| Engine      | May Depend On                                                           |
| ----------- | ----------------------------------------------------------------------- |
| Numeric     | Core                                                                    |
| Expression  | Core + Numeric + Units contracts where required                         |
| Algebra     | Core + Numeric + Expression AST                                         |
| Symbolic    | Core + Expression + Algebra                                             |
| Complex     | Core + Numeric                                                          |
| Matrix      | Core + Numeric                                                          |
| Vector      | Core + Numeric                                                          |
| Calculus    | Core + Numeric + Expression + Symbolic                                  |
| Solver      | Core + Numeric + Expression + Algebra + Matrix where systems require it |
| Statistics  | Core + Numeric                                                          |
| Regression  | Core + Numeric + Statistics + Expression AST                            |
| Probability | Core + Numeric                                                          |
| Units       | Core + Numeric                                                          |
| Formula     | Core + Expression + Numeric + Units                                     |
| Graphing    | Core + Expression + Numeric + Calculus                                  |
| Programmer  | Core + Integer semantics                                                |
| Spreadsheet | Application + Expression + Numeric                                      |
| Workspace   | Application + relevant engine contracts                                 |

---

# 78. Explicit Dependency Graph

The following dependencies are permitted:

```text
Core
 ↑
Numeric
 ↑
Expression
 ↑
Algebra
 ↑
Symbolic
 ↑
Calculus
```

However, this does NOT mean every layer may depend on every layer below it.

The precise allowed relationships are:

```text
NUMERIC
    └── Core

EXPRESSION
    ├── Core
    └── Numeric

ALGEBRA
    ├── Core
    ├── Numeric
    └── Expression AST

SYMBOLIC
    ├── Core
    ├── Expression
    └── Algebra

COMPLEX
    ├── Core
    └── Numeric

MATRIX
    ├── Core
    └── Numeric

VECTOR
    ├── Core
    └── Numeric

CALCULUS
    ├── Core
    ├── Numeric
    ├── Expression
    └── Symbolic

SOLVER
    ├── Core
    ├── Numeric
    ├── Expression
    ├── Algebra
    └── Matrix

STATISTICS
    ├── Core
    └── Numeric

REGRESSION
    ├── Core
    ├── Numeric
    ├── Statistics
    └── Expression AST

PROBABILITY
    ├── Core
    └── Numeric

UNITS
    ├── Core
    └── Numeric

FORMULA
    ├── Core
    ├── Expression
    ├── Numeric
    └── Units

GRAPHING
    ├── Core
    ├── Expression
    ├── Numeric
    └── Calculus

PROGRAMMER
    └── Core + Integer semantics
```

---

# 79. Forbidden Dependency Graph

The following are explicitly forbidden:

```text
Numeric → Expression
Numeric → Symbolic
Numeric → Flutter

Expression → Symbolic
Expression → Calculus
Expression → Solver
Expression → Graphing

Algebra → Symbolic
```

The last item is intentionally forbidden because Algebra provides reusable algebraic primitives while Symbolic consumes them.

Also forbidden:

```text
Mathematical Core → Application
Mathematical Core → Infrastructure
Mathematical Core → Presentation
```

---

# 80. Important Correction: Expression and Symbolic Independence

The Expression Engine is foundational.

Therefore:

```text
Expression
   ↓
Symbolic
```

is permitted.

But:

```text
Expression
   ↓
Symbolic
   ↓
Expression
```

must never occur.

Symbolic may consume AST structures defined by Expression, but Expression must never call Symbolic.

This prevents circular dependencies.

---

# 81. Important Correction: Units and Expression

Units participate in expressions such as:

```text
10 m + 50 cm
```

Therefore, the Expression Engine may recognize quantity syntax and produce:

```text
QuantityNode
```

But unit conversion algorithms remain owned by Units.

The dependency is:

```text
Expression AST
      ↓
Units
      ↓
Numeric
```

not:

```text
Units
      ↓
Expression Engine
```

for basic unit mathematics.

---

# 82. Graphing Dependency

Graphing must never own expression evaluation.

Correct:

```text
GraphEngine
    ↓
ExpressionEngine
    ↓
Evaluator
    ↓
NumericEngine
```

Incorrect:

```text
GraphWidget
    ↓
manual expression evaluation
```

---

# 83. Solver Dependency

Solver must not create another parser.

Correct:

```text
Input
 ↓
ExpressionEngine
 ↓
Equation
 ↓
SolverEngine
```

The Solver consumes structured equations/AST.

---

# 84. Spreadsheet Dependency

Spreadsheet formulas use:

```text
ExpressionEngine
```

but the Expression Engine must not know about:

```text
Cell
Spreadsheet
DependencyGraph
```

Therefore:

```text
Spreadsheet
     ↓
ExpressionEngine
```

is allowed.

```text
ExpressionEngine
     ↓
Spreadsheet
```

is forbidden.

---

# 85. Workspace Dependency

Workspace is an application-level composition layer.

It may reference:

```text
Calculator
Solver
Statistics
Graphing
Formula
Spreadsheet
```

It does not implement these engines.

---

# 86. Dependency Inversion

Application services depend on interfaces.

Example:

```text
CalculateExpressionUseCase
        │
        ├── ExpressionEngine
        └── VariableRepository
```

Implementations are injected.

```text
DefaultExpressionEngine
LocalVariableRepository
```

are selected by composition root.

---

# 87. Composition Root

Dependency construction belongs in one application composition boundary.

Conceptually:

```text
NexaMathApplication
      ↓
DependencyContainer
      ↓
Engine Implementations
      ↓
Use Cases
      ↓
Presentation
```

The UI must not manually construct low-level engines.

---

# 88. Public API Rule

Every engine exposes one principal façade:

```text
NumericEngine
ExpressionEngine
AlgebraEngine
SymbolicEngine
CalculusEngine
EquationSolver
ComplexEngine
MatrixEngine
VectorEngine
StatisticsEngine
ProbabilityEngine
UnitEngine
FormulaEngine
GraphEngine
ProgrammerEngine
SpreadsheetEngine
```

Internal algorithms are not application dependencies.

---

# 89. Internal Algorithm Rule

For example:

```text
GraphEngine
    ├── AdaptiveSampler
    ├── RootDetector
    ├── IntersectionDetector
    └── ExtremaDetector
```

Application code must depend on:

```text
GraphEngine
```

not:

```text
AdaptiveSampler
```

unless a future explicit public contract requires it.

---

# 90. Model Immutability

The following mathematical models should be immutable:

```text
NumericValue
Fraction
ComplexNumber
Matrix
Vector
Polynomial
Dimension
Unit
Quantity
ExpressionNode
Equation
GraphFunction
GraphPoint
GraphSeries
FormulaDefinition
```

Mutation belongs to application state models where appropriate.

---

# 91. Mathematical Equality

Mathematical models must distinguish:

```text
Structural equality
Numerical equality
Approximate equality
```

For example:

```text
1/2
0.5
```

may be numerically equivalent while being structurally different representations.

Comparison behavior must be explicit.

---

# 92. Exactness Contract

Every mathematical result that can preserve exactness must expose:

```dart
bool get isExact;
```

Examples:

```text
2 + 3 → exact
1 / 3 → exact Fraction where possible
sqrt(2) → exact symbolic representation where supported
sin(30°) → exact when mathematically recognized
numerical integration → approximate
Newton-Raphson → approximate
```

---

# 93. Approximation Metadata

Numerical results should expose sufficient metadata to communicate:

```text
converged
iterations
residual
precision
method
```

This is especially important for:

```text
Solver
Calculus
Regression
Graph analysis
Probability
```

---

# 94. Error Ownership Matrix

| Error                        | Owner                       |
| ---------------------------- | --------------------------- |
| SyntaxError                  | Expression                  |
| InvalidExpression            | Expression                  |
| DivisionByZero               | Numeric                     |
| DomainError                  | Numeric / relevant Engine   |
| Overflow                     | Numeric                     |
| Underflow                    | Numeric                     |
| PrecisionLoss                | Numeric                     |
| MatrixDimensionError         | Matrix                      |
| SingularMatrix               | Matrix                      |
| DimensionMismatch            | Units                       |
| NoSolution                   | Solver                      |
| InfiniteSolutions            | Solver                      |
| ConvergenceFailure           | Numerical Solver / Calculus |
| InvalidProbability           | Probability                 |
| UnsupportedSymbolicOperation | Symbolic                    |
| InvalidFormulaInput          | Formula                     |
| CircularReference            | Spreadsheet                 |

---

# 95. Explanation Engine

The Explanation Engine should consume operation metadata rather than inspect arbitrary UI strings.

Conceptual contract:

```dart
abstract interface class ExplanationEngine {
  MathResult<CalculationExplanation> explain(
    CalculationOperation operation,
  );
}
```

`CalculationExplanation` contains:

```text
operation
steps
intermediate expressions
final result
```

This engine remains independent from AI.

---

# 96. Display Formatting

Display formatting is not a mathematical engine.

It belongs to Application/Presentation.

Conceptual contract:

```dart
abstract interface class MathDisplayFormatter {
  String format(
    NumericValue value,
    DisplayFormat format,
  );
}
```

Supported display formats:

```text
Standard
Fixed
Scientific
Engineering
Fraction
Textbook
```

The formatter consumes values but never changes them.

---

# 97. Mathematical Input Formatting

Expression input and display are separate.

```text
Raw Input
   ↓
Expression Parser
```

while:

```text
AST / NumericValue
   ↓
Display Formatter
   ↓
Textbook UI
```

No formatted UI string should become the authoritative mathematical representation.

---

# 98. History Architecture

History stores the user's calculation operation.

It should retain enough information for:

```text
Replay
Edit
Copy
Search
Pin
Delete
```

The authoritative calculation is represented by the expression source plus structured result metadata.

---

# 99. Session vs Workspace

Mandatory distinction:

```text
Session
    = Mathematical environment

Workspace
    = Mathematical document/project
```

Session:

```text
Variables
Functions
History
Settings
Calculations
```

Workspace:

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

---

# 100. Testing Dependency Rules

Tests must mirror architectural ownership.

```text
numeric_test/
expression_test/
algebra_test/
symbolic_test/
calculus_test/
solver_test/
complex_test/
matrix_test/
vector_test/
statistics_test/
probability_test/
units_test/
formula_test/
graphing_test/
programmer_test/
spreadsheet_test/
```

Tests must not bypass public contracts unless specifically testing internal algorithms.

---

# 101. Engine Contract Testing

Every engine façade must have contract tests.

For example:

```text
ExpressionEngineContractTest
MatrixEngineContractTest
UnitEngineContractTest
SolverEngineContractTest
```

Any implementation of an engine must pass its contract tests.

---

# 102. Cross-Platform Contract

The following must execute against the same domain implementation:

```text
Windows
Android
```

Tests should compare:

```text
expression
configuration
result
exactness
error semantics
```

---

# 103. Implementation Sequence

The implementation agent must follow this dependency order.

## Stage 1 — Foundation

```text
Core Errors
MathResult
Validation
Shared Mathematical Context
```

## Stage 2 — Numeric

```text
Integer
Decimal
Fraction
Precision
Rounding
NumericEngine
```

## Stage 3 — Expression

```text
Tokens
Lexer
AST
Parser
Functions
Operators
Evaluator
ExpressionEngine
```

## Stage 4 — Algebra

```text
Polynomial
Simplification
Expansion
Factorization
```

## Stage 5 — Mathematical Structures

```text
Complex
Matrix
Vector
```

## Stage 6 — Symbolic

```text
Simplification
Substitution
Differentiation
Limits
Supported Integration
```

## Stage 7 — Calculus

```text
Numerical Differentiation
Numerical Integration
Approximation
```

## Stage 8 — Solver

```text
Linear
Quadratic
Cubic
Quartic
Polynomial
Systems
Numerical
Nonlinear
```

## Stage 9 — Statistics

```text
Descriptive
Correlation
Regression
```

## Stage 10 — Probability

```text
Distributions
PDF
CDF
Inverse CDF
Sampling
```

## Stage 11 — Units

```text
Dimensions
Units
Quantities
Conversion
Dimensional Analysis
```

## Stage 12 — Formula

```text
Formula Definitions
Formula Registry
Formula Evaluation
```

## Stage 13 — Graphing

```text
Sampling
Roots
Intersections
Extrema
Graph Data
```

## Stage 14 — Programmer

```text
Bases
Widths
Bitwise Operations
```

## Stage 15 — Spreadsheet

```text
Cells
References
Dependency Graph
Recalculation
```

## Stage 16 — Application

```text
Calculator
History
Variables
Sessions
Workspace
Settings
```

## Stage 17 — Infrastructure

```text
Persistence
Filesystem
Platform Services
Logging
```

## Stage 18 — Presentation

```text
Windows UI
Android UI
Shared Components
Navigation
Localization
Accessibility
```

---

# 104. Vertical Slice Before Full UI

Before implementing the complete application interface, the following must work end-to-end:

```text
User Input
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
CalculationResult
    ↓
DisplayFormatter
    ↓
Flutter UI
```

The slice must support at least:

```text
2 + 3
(5 + 3)^2 / 4
sin(30)
sqrt(25) * 2
```

with appropriate angle mode and error handling.

---

# 105. Architectural Completion Criteria

The blueprint is considered correctly implemented when:

### Mathematical Core

* Mathematical Core compiles independently from Flutter.
* All core engines expose explicit contracts.
* Domain models are independent from UI.
* Numeric precision is controlled.
* Expression parsing is centralized.
* Errors are typed.
* Exactness is explicit.

### Dependencies

* No circular engine dependency exists.
* No Mathematical Core dependency points toward Application.
* No Mathematical Core dependency points toward Presentation.
* No Mathematical Core dependency points toward Infrastructure.
* Spreadsheet does not become a Mathematical Core dependency.
* Graphing does not contain an independent expression evaluator.

### Application

* Use Cases orchestrate domain engines.
* Repositories are abstractions.
* Sessions and Workspaces remain distinct.
* History remains persistent through repository abstractions.

### Presentation

* Widgets do not perform mathematical algorithms.
* UI renders mathematical results.
* Display formatting is separated from calculation.
* Windows and Android share the same Mathematical Core.

---

# 106. Non-Negotiable Architectural Rules

The following rules are absolute.

## Rule 1

There is exactly one authoritative Expression Engine.

## Rule 2

There is exactly one authoritative Numeric Engine.

## Rule 3

Flutter must never become the Mathematical Core.

## Rule 4

Windows and Android must not contain separate mathematical implementations.

## Rule 5

No engine may silently duplicate another engine's responsibility.

## Rule 6

No UI component may contain mathematical algorithms.

## Rule 7

No mathematical engine may access persistence directly.

## Rule 8

No mathematical engine may access platform APIs.

## Rule 9

Exact and approximate results must remain distinguishable.

## Rule 10

Unsupported mathematical operations must fail explicitly.

## Rule 11

No TODO or placeholder implementation is accepted as production completion.

## Rule 12

No coding agent may change the dependency graph without an explicit architectural revision.

---

# 107. Final Dependency Diagram

```text
                           ┌───────────────────┐
                           │    PRESENTATION   │
                           │     Flutter       │
                           └─────────┬─────────┘
                                     │
                                     ▼
                           ┌───────────────────┐
                           │    APPLICATION    │
                           │   Use Cases       │
                           └─────────┬─────────┘
                                     │
                  ┌──────────────────┼───────────────────┐
                  │                  │                   │
                  ▼                  ▼                   ▼
             Calculator          Workspace          Spreadsheet
                  │                  │                   │
                  └──────────────────┼───────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │         MATHEMATICAL CORE            │
                  │                                     │
                  │  ┌──────────┐     ┌──────────────┐ │
                  │  │ Numeric  │◄────│  Expression  │ │
                  │  └────┬─────┘     └──────┬───────┘ │
                  │       │                  │         │
                  │       │          ┌───────▼──────┐  │
                  │       │          │    Algebra   │  │
                  │       │          └───────┬──────┘  │
                  │       │                  │         │
                  │       │          ┌───────▼──────┐  │
                  │       └─────────►│   Symbolic   │  │
                  │                  └───────┬──────┘  │
                  │                          │         │
                  │                  ┌───────▼──────┐  │
                  │                  │   Calculus   │  │
                  │                  └──────────────┘  │
                  │                                     │
                  │  Matrix ◄──── Numeric               │
                  │  Vector ◄──── Numeric               │
                  │  Complex ◄─── Numeric               │
                  │  Statistics ◄ Numeric               │
                  │  Probability ◄ Numeric               │
                  │  Units ◄──── Numeric                │
                  │  Formula ◄── Expression + Units     │
                  │  Solver ◄─── Expression + Algebra   │
                  │  Graphing ◄─ Expression + Calculus  │
                  │  Programmer ◄ Integer semantics     │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                           ┌───────────────────┐
                           │       CORE        │
                           │ Errors / Result   │
                           └───────────────────┘


              ┌──────────────────────────────────────┐
              │          INFRASTRUCTURE              │
              │                                      │
              │ Persistence / Files / Platform APIs  │
              └──────────────────────────────────────┘
                              ▲
                              │
                         implements
                              │
                     Application Contracts
```

---

# 108. Final Architectural Identity

The implementation architecture of NexaMath is therefore:

```text
                 NEXAMATH
                    │
       ┌────────────┴────────────┐
       │                         │
  Mathematical Core          Application
       │                         │
       │                    User Workflows
       │                         │
       └────────────┬────────────┘
                    │
               Presentation
                    │
             Windows / Android
```

The most important rule is:

> **The Mathematical Core is the product's computational foundation. Flutter is the cross-platform presentation environment around it.**

The architecture must therefore be implemented **from the inside outward**:

```text
Core
 ↓
Numeric
 ↓
Expression
 ↓
Mathematical Engines
 ↓
Application
 ↓
Infrastructure
 ↓
Presentation
```

and never in the reverse direction.

---

# 109. Blueprint Status

**Project:** NexaMath
**Master Specification:** Defined
**Architecture Specification:** Defined
**Implementation Blueprint:** Defined
**Engine Contracts:** Defined
**Primary Models:** Defined
**Dependency Graph:** Defined
**Dependency Restrictions:** Defined
**Implementation Order:** Defined

**Next architectural artifact before coding:**

`NEXAMATH_ENGINE_CONTRACTS_AND_PACKAGE_MAP.md`

This artifact should formalize the final public API of every engine, package export boundaries, allowed imports, dependency rules, and contract-level acceptance tests before the first production implementation begins.