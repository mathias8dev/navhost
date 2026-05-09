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
      NavRoute('/', (_, _) => const HomePage()),
      NavRoute('/item/:id', (params, _) => DetailPage(id: params['id']!)),
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

### Query parameters

Query parameters are parsed automatically and passed as the second argument to the route builder:

```dart
NavRoute('/detail', (params, queryParams) =>
    DetailPage(ref: queryParams['ref'] ?? 'direct')),

// Navigate with query params
nav.navigate('/detail?ref=email&page=2');

// Access via back stack entry
nav.currentEntry.queryParams; // {ref: "email", page: "2"}
```

Path parameters and query parameters are kept separate — no naming conflicts.

### Transitions

Per route:

```dart
NavRoute(
  '/detail',
  (_, _) => const DetailPage(),
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
      NavRoute('/home', (_, _) => const HomePage()),
      NavRoute('/settings', (_, _) => const SettingsPage()),
      NavRoute('/item/:id', (p, _) => DetailPage(id: p['id']!)),
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

## Deep links

navhost supports deep links out of the box via `MaterialApp.router`. When the OS opens your app with a URL, the route is matched automatically against your defined routes — including path parameters and query parameters.

```dart
// These routes handle deep links with no extra configuration
final _navController = NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/item/:id', (params, queryParams) => DetailPage(
      id: params['id']!,
      ref: queryParams['ref'],
    )),
  ],
);
```

Opening `https://example.com/item/42?ref=email` navigates to `DetailPage(id: '42', ref: 'email')` with the initial route underneath in the back stack, so the back button takes the user to `/`. Query parameters are fully preserved from the deep link URL.

### Android setup

Add intent filters to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity ...>
  <!-- Deep links -->
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="myapp" />
  </intent-filter>

  <!-- App links (https) -->
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="example.com" />
  </intent-filter>
</activity>
```

### iOS setup

Add URL schemes and associated domains in `ios/Runner/Info.plist`:

```xml
<!-- Custom URL scheme -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

For universal links, add the associated domain in Xcode under **Signing & Capabilities > Associated Domains**:

```
applinks:example.com
```

### Testing deep links

```bash
# Android
adb shell am start -a android.intent.action.VIEW -d "myapp://item/42"

# iOS
xcrun simctl openurl booted "myapp://item/42"
```

### Guarding deep links with interceptors

Interceptors apply to deep links too — unauthenticated users are redirected before the route is shown:

```dart
NavController(
  routes: [...],
  interceptors: [AuthGuard()],
)
```

If a user opens `myapp://protected/settings` and `AuthGuard` redirects to `/login`, they never see the protected page.

## Migrating from other routers

### From GoRouter

**Route definition:**
```dart
// GoRouter
GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/item/:id', builder: (context, state) =>
        DetailPage(id: state.pathParameters['id']!)),
  ],
)

// navhost
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/item/:id', (params, _) => DetailPage(id: params['id']!)),
  ],
)
```

**Navigation:**
```dart
// GoRouter
context.go('/item/42');
context.push('/item/42');
context.pop();

// navhost
context.navController.switchTo('/item/42');   // replaces stack (like go)
context.navController.navigate('/item/42');   // pushes (like push)
context.navController.pop();
```

**Redirects:**
```dart
// GoRouter
GoRouter(redirect: (context, state) {
  if (!isLoggedIn && state.matchedLocation.startsWith('/protected')) {
    return '/login';
  }
  return null;
})

// navhost
class AuthGuard extends NavInterceptor {
  @override
  String? intercept(String from, String to) {
    if (!isLoggedIn && to.startsWith('/protected')) return '/login';
    return null;
  }
}

NavController(
  interceptors: [AuthGuard()],
)
```

### From auto_route

**Route definition:**
```dart
// auto_route
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: DetailRoute.page, path: '/item/:id'),
  ];
}

// navhost — no code generation needed
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/item/:id', (params, _) => DetailPage(id: params['id']!)),
  ],
)
```

**Navigation:**
```dart
// auto_route
context.router.push(DetailRoute(id: '42'));
context.router.pop();
context.router.replaceAll([HomeRoute()]);

// navhost
context.navController.navigate('/item/42');
context.navController.pop();
context.navController.switchTo('/');
```

### From Navigator 1.0

**Push and pop:**
```dart
// Navigator 1.0
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => DetailPage(id: '42'),
));
Navigator.of(context).pop();

// navhost
context.navController.navigate('/item/42');
context.navController.pop();
```

**Named routes:**
```dart
// Navigator 1.0
MaterialApp(
  routes: {
    '/': (_) => const HomePage(),
    '/settings': (_) => const SettingsPage(),
  },
)
Navigator.of(context).pushNamed('/settings');

// navhost
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/settings', (_, _) => const SettingsPage()),
  ],
)
context.navController.navigate('/settings');
```

### From GetX routing

```dart
// GetX
GetMaterialApp(
  getPages: [
    GetPage(name: '/', page: () => HomePage()),
    GetPage(name: '/item/:id', page: () => DetailPage()),
  ],
)
Get.toNamed('/item/42');
Get.back();
Get.offAllNamed('/');

// navhost
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/item/:id', (params, _) => DetailPage(id: params['id']!)),
  ],
)
context.navController.navigate('/item/42');
context.navController.pop();
context.navController.switchTo('/');
```

### Migration tips

- **Migrate incrementally** — navhost uses `MaterialApp.router`, so switching the router is a one-time change at the app root
- **Path parameters work the same** — `/item/:id` syntax is identical across most routers
- **No code generation** — unlike auto_route, navhost routes are defined inline with no build step
- **Transitions carry over** — navhost supports per-route and global transitions, same as GoRouter and auto_route

## State management

Looking for reactive state management? Check out [navhost_state](https://pub.dev/packages/navhost_state) — GetX-style `.obs` reactive values, auto-tracking `Obs` widgets, and scoped ViewModels that are tied to the route lifecycle. Zero boilerplate, fine-grained rebuilds.

## Example

See the [example app](example/) for a full showcase of all navigation features.

## License

MIT
