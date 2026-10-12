# Core Layer

## Purpose
The `core/` layer contains domain-neutral technical contracts, results, error contracts, validation primitives, configuration models, and shared utilities.

## Architectural Rules
1. Must NOT depend on Flutter.
2. Must NOT depend on `mathematical_core/`, `application/`, `infrastructure/`, or `presentation/`.
3. Must remain completely platform-neutral (runnable on pure Dart VM).
