# Mathematical Core Layer

## Purpose
The `mathematical_core/` layer contains pure mathematical models, computing engines, and numerical/symbolic algorithms.

## Architectural Rules (Strict & Non-negotiable)
1. Must NOT depend on Flutter (`BuildContext`, `Widget`, `Material`, etc.).
2. Must NOT depend on `application/`, `infrastructure/`, or `presentation/`.
3. Must NOT access platform APIs (Windows, Android, filesystems, network, databases).
4. Must be executable and testable in a pure Dart runtime without Flutter initialized.
5. Must maintain canonical model ownership (e.g. `ComplexNumber`, `Polynomial`, `Quantity`, `Matrix`, `Vector`).

## Subpackages
- `numeric/`
- `expression/`
- `algebra/`
- `symbolic/`
- `calculus/`
- `solver/`
- `complex/`
- `matrix/`
- `vector/`
- `statistics/`
- `probability/`
- `units/`
- `formula/`
- `graphing/`
- `programmer/`
