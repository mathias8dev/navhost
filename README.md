# navhost

A Compose-inspired declarative navigation wrapper for Flutter's Navigator 2.0.

`navhost` brings Jetpack Compose's `NavController` / `NavHost` mental model to Flutter — declarative back stack management, path-based routing with parameters, Compose-style 4-way transitions, interceptors, and modal support — all built on top of Flutter's standard Navigator 2.0 APIs.

## Features

- **Declarative navigation** — `navigate()`, `pop()`, `popUntil()`, `switchTo()` manage a back stack that drives `Navigator.pages`
- **Path parameters** — `/user/:uid/post/:pid` extracts `{uid: "42", pid: "7"}`
- **Compose-style transitions** — `enterTransition`, `exitTransition`, `popEnterTransition`, `popExitTransition` per route or as NavHost defaults
- **Navigation interceptors** — redirect or block navigation before the stack changes (auth guards, onboarding flows)
- **`launchSingleTop`** — avoid duplicate entries at the top of the stack
- **`popUpTo` / `popUpToInclusive`** — pop the stack to a target before pushing
- **Bottom sheets & dialogs** — declarative (stack-managed) and imperative (returns a result)
- **Inline widget navigation** — push arbitrary widgets without defining a route
- **Back stack observation** — `currentEntry`, `previousEntry`, `backStack` with path and params
- **Nested NavHosts** — sub-routing with independent back stacks (tab navigation)
- **`MaterialApp.router` integration** — provides `routerDelegate` and `routeInformationParser`

## Getting started

```yaml
dependencies:
  navhost: ^0.1.0
```

```dart
import 'package:navhost/navhost.dart';
```

## Usage

### Basic setup

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navController = NavController(
    routes: [
      NavRoute('/', (_) => const HomePage()),
      NavRoute('/item/:id', (params) => DetailPage(id: params['id']!)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: _navController.delegate,
      routeInformationParser: _navController.parser,
    );
  }
}
```

### Navigation

```dart
final nav = context.navController;

// Push onto the stack
nav.navigate('/item/42');

// Replace the entire stack
nav.switchTo('/home');

// Avoid duplicate top entry
nav.navigate('/item/1', launchSingleTop: true);

// Pop to a target, then push
nav.navigate('/settings', popUpTo: '/', popUpToInclusive: false);

// Pop back
nav.pop();
nav.popUntil('/home');
nav.popUntil('/home', inclusive: true);
```

### Transitions

Per route:

```dart
NavRoute(
  '/detail',
  (_) => const DetailPage(),
  enterTransition: (child, animation) =>
      SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
  popExitTransition: (child, animation) =>
      SlideTransition(
        position: Tween(begin: Offset.zero, end: const Offset(1, 0))
            .animate(animation),
        child: child,
      ),
),
```

Or as NavHost defaults:

```dart
NavHost(
  navController: _navController,
  defaultEnterTransition: (child, animation) =>
      FadeTransition(opacity: animation, child: child),
  defaultTransitionDuration: const Duration(milliseconds: 200),
)
```

### Interceptors

```dart
class AuthInterceptor extends NavInterceptor {
  final bool Function() isLoggedIn;
  AuthInterceptor(this.isLoggedIn);

  @override
  String? intercept(String from, String to) {
    if (to.startsWith('/protected') && !isLoggedIn()) return '/login';
    return null; // allow
  }
}

final nav = NavController(
  routes: [...],
  interceptors: [AuthInterceptor(() => userLoggedIn)],
);
```

Return `null` to allow, a different path to redirect, or `from` to block.

### Bottom sheets & dialogs

Declarative (managed by the back stack):

```dart
nav.showBottomSheet('/item/1', config: const BottomSheetConfig(
  heightFactor: 0.85,
  showDragHandle: true,
));

nav.showDialog('/confirm');
```

Imperative (returns a result):

```dart
final result = await nav.pushDialogWidget<bool>(
  AlertDialog(
    title: const Text('Confirm'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
    ],
  ),
);
```

### Nested NavHost (tab navigation)

```dart
class MainPage extends StatefulWidget { ... }

class _MainPageState extends State<MainPage> {
  final _tabController = NavController(
    initialRoute: '/home',
    routes: [
      NavRoute('/home', (_) => const HomePage()),
      NavRoute('/settings', (_) => const SettingsPage()),
      NavRoute('/item/:id', (p) => DetailPage(id: p['id']!)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavHost(navController: _tabController),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (i) => _tabController.switchTo(['/home', '/settings'][i]),
        items: const [...],
      ),
    );
  }
}
```

### Back stack observation

```dart
final nav = context.navController;

nav.currentEntry.path;    // "/item/42"
nav.currentEntry.params;  // {id: "42"}
nav.previousEntry?.path;  // "/home"
nav.backStack;            // List<NavBackStackEntry>
nav.canPop;               // true
```

`NavController` extends `ChangeNotifier`, so you can listen to back stack changes:

```dart
nav.addListener(() {
  print('Stack changed: ${nav.backStack.map((e) => e.path)}');
});
```

## State management

Looking for reactive state management? Check out [navhost_state](https://pub.dev/packages/navhost_state) — GetX-style `.obs` reactive values, auto-tracking `Obs` widgets, and scoped ViewModels that are tied to the route lifecycle. Zero boilerplate, fine-grained rebuilds.

## Example

See the [example app](example/) for a full showcase of all navigation features.

## License

MIT
