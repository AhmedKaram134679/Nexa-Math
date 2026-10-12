# Presentation Layer

## Purpose
The `presentation/` layer contains all Flutter UI elements: widgets, screens, state management controllers, visual assets, and application theming.

## Architectural Rules
1. Consumes use cases and models through `application/` and public façades.
2. Must NOT bypass Application layer to directly access internal engine implementation algorithms.
3. No mathematical computation algorithms are defined inside UI widgets.
