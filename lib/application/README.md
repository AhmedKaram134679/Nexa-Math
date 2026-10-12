# Application Layer

## Purpose
The `application/` layer coordinates use cases, orchestrates calculation sessions, manages workspaces and history, and maps domain results to application-level structures.

## Architectural Rules
1. May depend on `core/` and `mathematical_core/`.
2. Must NOT depend on `presentation/` or concrete `infrastructure/` implementations (only interfaces/abstractions).
3. Independent of Flutter UI widgets.
