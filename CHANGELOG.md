## 0.2.4

- Fix `launchSingleTop` to compare the full destination location, including query parameters, instead of only the path.
- Add `NavBackStackEntry.location` for a canonical path + query string representation.
- Include query parameters in generated page keys so replacing a stack entry with the same path but different query parameters rebuilds the rendered page correctly.

## 0.2.3

- Fix `launchSingleTop` + `popUpTo` interaction: the `launchSingleTop` check now runs after `popUpTo` has trimmed the stack, so navigating to a destination that `popUpTo` already brought to the top no longer pushes a duplicate entry.

## 0.2.2

- README: add [navhost_typed](https://pub.dev/packages/navhost_typed) reference at the end of the "Typed path builders" section — points to the companion package for a complete typed-destination solution.

## 0.2.1

- Apply interceptors to `showBottomSheet()` and `showDialog()` — a blocked or redirected path now affects declarative modals consistently with `navigate()`.

## 0.2.0

### Async results

- `navigate()`, `switchTo()`, `navigateWidget()`, `showBottomSheet()`, `showBottomSheetWidget()`, `showDialog()`, `showDialogWidget()` now return `Future<T?>` that resolves when the pushed route is popped.
- `pop([T? result])` accepts an optional result forwarded to the awaiting caller.
- Routes removed by `popUpTo`, `popUntil`, `popUntilWhere`, or `replace`/`switchTo` have their pending futures completed with `null`.
- `launchSingleTop` skipped navigation returns the existing top entry's future instead of an immediate `null`, so the caller still receives the result when the route is eventually popped.
- Imperative push methods (`push`, `pushWidget`, `pushBottomSheet`, `pushBottomSheetWidget`, `pushDialog`, `pushDialogWidget`) already returned `Future<T?>`; they now integrate consistently with the declarative result system.

### Bug fixes

- Fix nested NavHost back button: `canPop` reverted to `_stack.length > 1`. Using `navigator?.canPop()` was stale at build time, causing the inner NavHost's `PopScope` to miss stack updates and fail to intercept the outer navigator's `maybePop()`.

### Internal

- Source split: imperative methods moved to `nav_controller_imperative.dart`, overlay/modal methods to `nav_controller_overlays.dart`, path matching to `nav_route_matcher.dart`.
- Test suite expanded to 118 tests and split into `nav_controller_test.dart` (stack logic), `nav_host_test.dart` (rendering, transitions, back button), and `nav_results_test.dart` (future/result propagation).

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
