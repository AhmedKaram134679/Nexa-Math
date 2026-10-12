# NexaMath

**NexaMath** is a production-grade mathematical computing platform built with Flutter and Dart, targeting Windows and Android.

## Architecture
NexaMath is designed with Clean Architecture and a strictly isolated Mathematical Core:

```text
Presentation (Flutter UI, Widgets, Theming)
      ↓
Application (Use Cases, Sessions, Workspaces, DTOs)
      ↓
Mathematical Core (Pure Dart, 15 Computing Engines & Models)
      ↓
Core (Technical Contracts, Errors, MathResult<T>, Validation)

* Infrastructure implements Application/Core abstractions and is NEVER a dependency of Mathematical Core.
```

## Layers Overview
- **`lib/core/`**: Technical domain-neutral contracts, typed error hierarchy (`MathError`), result wrapper (`MathResult<T>`), validation primitives, configuration models, and utilities.
- **`lib/mathematical_core/`**: Independent, pure Dart mathematical computing platform containing 15 engines: Numeric, Expression, Algebra, Symbolic, Calculus, Solver, Complex, Matrix, Vector, Statistics, Probability, Units, Formula, Graphing, and Programmer.
- **`lib/application/`**: Use cases, session orchestration, history, workspace coordination, and application services.
- **`lib/infrastructure/`**: Concrete implementations of persistence, filesystem access, logging, and platform channels.
- **`lib/presentation/`**: Flutter UI shell, screens, widgets, controllers, and visual theming.

## Testing & Quality Assurance
Run static analysis:
```bash
flutter analyze
```

Run test suite:
```bash
flutter test
```

Verify formatting:
```bash
dart format --output=none --set-exit-if-changed .
```
