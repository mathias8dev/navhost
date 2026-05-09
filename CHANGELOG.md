## 0.1.4

- Fix README examples to use two-param route builders.

## 0.1.3

- **Breaking:** `NavWidgetBuilder` now receives two parameters: `params` (path) and `queryParams` (query string). Update route builders from `(_)` to `(_, _)`.
- Query parameters are parsed from navigation paths and deep link URLs.
- `NavBackStackEntry` exposes `queryParams` alongside `params`.
- Deep links now preserve query parameters (e.g. `myapp://item/42?ref=email`).
- Add migration guides from GoRouter, auto_route, Navigator 1.0, and GetX.

## 0.1.2

- Add navhost_state companion package teaser to README.

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
