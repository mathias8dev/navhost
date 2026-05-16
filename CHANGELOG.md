## 0.1.11

- Broaden Dart SDK constraint from `^3.11.3` to `">=3.0.0"` for compatibility with a wider range of Flutter versions.

## 0.1.10

- README: fix four coherence issues — nested NavHost example now uses `_tabController.routes[i].path` consistently with the recommended pattern; fixed invalid Dart `_protectedRoutes.any(to.startsWith)` → `_protectedRoutes.any((r) => to.startsWith(r))`; removed phantom `AppRoutes.settings` reference and added missing `AppRoutes.orders` / `AppRoutes.onboarding` constants; replaced `to.startsWith(AppRoutes.detail)` (template string, never matches) with `to.startsWith(AppRoutes.profile)`.
- README: expand NavHost defaults transition example with all four variants (`defaultEnterTransition`, `defaultExitTransition`, `defaultPopEnterTransition`, `defaultPopExitTransition`) — push uses fade, pop uses slide to distinguish the two directions. Add note that all transition parameters are optional.

## 0.1.9

- Add "Recommended patterns" section to README covering: route constants, typed path builders (`DetailPage.path()` and `AppRoutes.buildPath()`), IDs-in-URLs philosophy, interceptors for cross-cutting concerns, and `switchTo` vs `navigate` for tab navigation.

## 0.1.8

- Add migration guide from duck_router — covers route definition, router setup, navigation, and interceptors, with a comparison table of the key trade-offs between the two routers.

## 0.1.7

- `BottomSheetConfig.heightFactor` is now nullable. When `null` (the new default), bottom sheets size to their content instead of being constrained to a fixed screen fraction. Pass an explicit value (e.g. `heightFactor: 0.85`) to restore the previous behaviour.

## 0.1.6

- Update README getting started snippet to use `^latest` for the version constraint.

## 0.1.5

- Add "Using with other libraries" section with integration examples for Provider, Riverpod, Bloc, GetX, and get_it.
- Add table of contents to README.

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
