## 0.1.1

- Add dartdoc comments to all public API elements (library, classes, constructors, fields, methods, typedefs, enums, and extensions).

## 0.1.0

- Initial release.
- `NavController` with declarative navigation (navigate, pop, popUntil, switchTo, replace).
- `NavHost` widget with Compose-style 4-way transitions (enter, exit, popEnter, popExit).
- Route-level and NavHost-level default transitions.
- `launchSingleTop` and `popUpTo` / `popUpToInclusive` navigation options.
- `NavInterceptor` for pre-navigation guards (redirect / block).
- Back stack observation (`backStack`, `currentEntry`, `previousEntry`).
- Bottom sheet and dialog navigation (declarative and imperative with results).
- Inline widget navigation (`navigateWidget`, `pushWidget`).
- Path parameter extraction (e.g. `/item/:id`).
- `BuildContext` extensions (`navController`, `navigator`).
