# navhost

A Compose-inspired declarative navigation wrapper for Flutter's Navigator 2.0.

`navhost` brings Jetpack Compose's `NavController` / `NavHost` mental model to Flutter — declarative back stack management, path-based routing with parameters, Compose-style 4-way transitions, interceptors, and modal support — all built on top of Flutter's standard Navigator 2.0 APIs.

## Table of contents

- [Features](#features)
- [Getting started](#getting-started)
- [Usage](#usage)
  - [Basic setup](#basic-setup)
  - [Navigation](#navigation)
  - [Query parameters](#query-parameters)
  - [Transitions](#transitions)
  - [Interceptors](#interceptors)
  - [Bottom sheets & dialogs](#bottom-sheets--dialogs)
  - [Nested NavHost (tab navigation)](#nested-navhost-tab-navigation)
  - [Back stack observation](#back-stack-observation)
- [Recommended patterns](#recommended-patterns)
  - [Route constants](#route-constants)
  - [Typed path builders](#typed-path-builders)
  - [IDs in URLs, objects through constructors](#ids-in-urls-objects-through-constructors)
  - [Interceptors for cross-cutting concerns](#interceptors-for-cross-cutting-concerns)
  - [`switchTo` for tabs, `navigate` for stack pushes](#switchto-for-tabs-navigate-for-stack-pushes)
- [Deep links](#deep-links)
  - [Android setup](#android-setup)
  - [iOS setup](#ios-setup)
  - [Testing deep links](#testing-deep-links)
  - [Guarding deep links with interceptors](#guarding-deep-links-with-interceptors)
- [Migrating from other routers](#migrating-from-other-routers)
  - [From GoRouter](#from-gorouter)
  - [From auto_route](#from-auto_route)
  - [From Navigator 1.0](#from-navigator-10)
  - [From GetX routing](#from-getx-routing)
  - [From duck_router](#from-duck_router)
- [Using with other libraries](#using-with-other-libraries)
  - [Provider](#provider)
  - [Riverpod](#riverpod)
  - [Bloc / Cubit](#bloc--cubit)
  - [GetX](#getx)
  - [get_it](#get_it)
- [State management](#state-management)
- [Example](#example)
- [License](#license)

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
  navhost: ^latest
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
  // All transition parameters are optional — omit any to use the default (no animation)
  // Push: new page fades in, current page fades out
  defaultEnterTransition: (child, animation) =>
      FadeTransition(opacity: animation, child: child),
  defaultExitTransition: (child, animation) =>
      FadeTransition(opacity: ReverseAnimation(animation), child: child),
  // Pop: top page slides out to the right, previous page slides in from the left
  defaultPopEnterTransition: (child, animation) =>
      SlideTransition(
        position: Tween(begin: const Offset(-0.2, 0), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
  defaultPopExitTransition: (child, animation) =>
      SlideTransition(
        position: Tween(begin: Offset.zero, end: const Offset(1, 0))
            .animate(animation),
        child: child,
      ),
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
// Auto-height — sheet sizes to its content (default)
nav.showBottomSheet('/item/1', config: const BottomSheetConfig(
  showDragHandle: true,
));

// Fixed height — occupy 85% of screen height
nav.showBottomSheet('/item/1', config: const BottomSheetConfig(
  heightFactor: 0.85,
  showDragHandle: true,
));

nav.showDialog('/confirm');
```

Imperative without a route — pass a widget directly:

```dart
// Auto-height (default)
nav.showBottomSheetWidget(
  MyPickerWidget(
    onSelected: (value) {
      doSomething(value);
      nav.pop();
    },
  ),
);

// Fixed height
nav.showBottomSheetWidget(
  MyPickerWidget(...),
  config: const BottomSheetConfig(heightFactor: 0.5),
);
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
        type: BottomNavigationBarType.fixed,
        onTap: (i) => _tabController.switchTo(_tabController.routes[i].path),
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

## Recommended patterns

### Route constants

Define all route paths as `static const` strings in one place. Scattering raw strings like `'/detail/42'` across the codebase makes refactoring brittle and typos silent — the compiler won't catch `/detial/:id`.

```dart
abstract final class AppRoutes {
  static const home       = '/';
  static const detail     = '/detail/:id';
  static const profile    = '/profile';
  static const orders     = '/orders';
  static const login      = '/login';
  static const onboarding = '/onboarding';
}

NavController(
  routes: [
    NavRoute(AppRoutes.home,    (_, _) => const HomePage()),
    NavRoute(AppRoutes.detail,  (p, _) => DetailPage(id: p['id']!)),
    NavRoute(AppRoutes.profile, (_, _) => const ProfilePage()),
    NavRoute(AppRoutes.login,   (_, _) => const LoginPage()),
  ],
)
```

Interceptors and `popUntil` calls now reference the same constants — one rename updates everything:

```dart
if (to.startsWith(AppRoutes.profile) && !isLoggedIn) return AppRoutes.login;
nav.popUntil(AppRoutes.home);
```

### Typed path builders

Raw string interpolation at the call site is error-prone: `'/detail/$id'` silently produces a wrong path if the route template changes. Add a static `path()` method to each page — the method signature enforces required parameters at compile time and the path string is defined in exactly one place. Inspired by GoRouter typed routes, without the code generation:

```dart
class DetailPage extends StatelessWidget {
  final String id;
  const DetailPage({super.key, required this.id});

  static String path({required String id}) => '/detail/$id';

  @override
  Widget build(BuildContext context) => ...;
}

// Call site — no raw strings, params enforced by the compiler
nav.navigate(DetailPage.path(id: '42'));
nav.navigate(DetailPage.path(id: item.id));
```

If you prefer path construction to live in one centralized place rather than on each page class, `AppRoutes` can expose a generic builder instead:

```dart
abstract final class AppRoutes {
  static const detail = '/detail/:id';

  static String buildPath({
    required String route,
    Map<String, String> pathParams  = const {},
    Map<String, String> queryParams = const {},
  }) {
    var path = route;
    for (final e in pathParams.entries) {
      path = path.replaceFirst(':${e.key}', e.value);
    }
    if (queryParams.isNotEmpty) {
      path += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    return path;
  }
}

nav.navigate(AppRoutes.buildPath(
  route: AppRoutes.detail,
  pathParams:  {'id': '42'},
  queryParams: {'ref': 'email'},
));
```

Both eliminate raw string interpolation at call sites — the choice is a style preference: page-owned (`DetailPage.path`) favours cohesion, centralized (`AppRoutes.buildPath`) favours separation.

### IDs in URLs, objects through constructors

Route paths should carry only stable, minimal identifiers — not serialized state. The full object is fetched or passed via the ViewModel.

```dart
// Good — path carries only an ID
NavRoute('/post/:id', (params, _) => PostPage(
  viewModel: PostViewModel(
    id: params['id']!,
    repo: getIt<PostRepository>(),
  ),
))

// Avoid — encoding full objects in the URL breaks deep links
// and makes sharing routes fragile
nav.navigate('/post?title=Hello&body=World&authorId=5&...');
```

Keeping full objects out of URLs avoids several problems: long URLs get silently truncated by the OS, browsers, and messaging apps; changing the object shape breaks every stored or shared link; and URL params are logged by proxies, crash reporters, and analytics — sensitive fields leak. A URL identifies a resource (`/post/42`) — the app fetches the current state from that ID, so the link stays valid even after the post is edited.

### Interceptors for cross-cutting concerns

Auth guards, analytics, onboarding gates, and feature flags belong in `NavInterceptor` — not inside `initState`, route builders, or individual widgets. One interceptor, one responsibility.

```dart
// Auth guard
class AuthInterceptor extends NavInterceptor {
  final AuthService _auth;
  AuthInterceptor(this._auth);

  @override
  String? intercept(String from, String to) {
    if (_protectedRoutes.any((r) => to.startsWith(r)) && !_auth.isLoggedIn) {
      return AppRoutes.login;
    }
    return null;
  }

  static const _protectedRoutes = [AppRoutes.profile, AppRoutes.orders];
}

// Onboarding gate
class OnboardingInterceptor extends NavInterceptor {
  @override
  String? intercept(String from, String to) {
    if (!hasCompletedOnboarding && to == AppRoutes.home) {
      return AppRoutes.onboarding;  // defined in your own AppRoutes
    }
    return null;
  }
}

NavController(
  routes: [...],
  interceptors: [
    AuthInterceptor(getIt<AuthService>()),
    OnboardingInterceptor(),
  ],
)
```

Interceptors compose — each runs in order, and the first non-null redirect wins. They also apply to deep links automatically, so a user opening a protected deep link is redirected before the page is shown.

### `switchTo` for tabs, `navigate` for stack pushes

`navigate` always pushes a new entry onto the back stack. Using it for tab switching silently accumulates history — tapping three tabs leaves three entries and the back button navigates between tabs instead of leaving the app.

```dart
// Correct — switchTo replaces the stack, no history accumulates
BottomNavigationBar(
  onTap: (i) => _tabController.switchTo(_tabController.routes[i].path),
)

// Incorrect — each tab tap pushes a new entry
BottomNavigationBar(
  onTap: (i) => _tabController.navigate(_tabController.routes[i].path),  // builds up history
)
```

As a rule: `switchTo` when the destination replaces the current context (tabs, login → home after auth), `navigate` when the user should be able to back-navigate to where they came from (detail pages, flows).

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

### From duck_router

duck_router uses typed location objects (classes) to define routes and carry parameters. navhost uses string paths with inline parameter extraction instead.

**Route definition:**
```dart
// duck_router — each route is a class
class HomeLocation extends DuckLocation {
  const HomeLocation();
  @override
  String get path => '/';
  @override
  Widget build(BuildContext context) => const HomePage();
}

class DetailLocation extends DuckLocation {
  final String id;
  const DetailLocation({required this.id});
  @override
  String get path => '/detail/$id';
  @override
  Widget build(BuildContext context) => DetailPage(id: id);
}

// navhost — routes are inline, params extracted from path
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/detail/:id', (params, _) => DetailPage(id: params['id']!)),
  ],
)
```

**Router setup:**
```dart
// duck_router
final router = DuckRouter(
  configuration: DuckRouterConfiguration(
    initialLocation: const HomeLocation(),
  ),
);
MaterialApp.router(
  routerConfig: router,
)

// navhost
final _navController = NavController(
  initialRoute: '/',
  routes: [...],
);
MaterialApp.router(
  routerDelegate: _navController.delegate,
  routeInformationParser: _navController.parser,
)
```

**Navigation:**
```dart
// duck_router — navigate by instantiating a location
DuckRouter.of(context).navigate(to: const HomeLocation());
DuckRouter.of(context).navigate(to: DetailLocation(id: '42'));
DuckRouter.of(context).pop();

// navhost — navigate by path string
context.navController.switchTo('/');
context.navController.navigate('/detail/42');
context.navController.pop();
```

**Interceptors / middleware:**
```dart
// duck_router
class AuthInterceptor extends DuckInterceptor {
  @override
  DuckLocation? intercept(DuckLocation location) {
    if (location is ProtectedLocation && !isLoggedIn) {
      return const LoginLocation();
    }
    return null;
  }
}

DuckRouter(
  configuration: DuckRouterConfiguration(
    initialLocation: const HomeLocation(),
    interceptors: [AuthInterceptor()],
  ),
)

// navhost
class AuthInterceptor extends NavInterceptor {
  @override
  String? intercept(String from, String to) {
    if (to.startsWith('/protected') && !isLoggedIn) return '/login';
    return null;
  }
}

NavController(
  routes: [...],
  interceptors: [AuthInterceptor()],
)
```

**Key differences:**

| | duck_router | navhost |
|---|---|---|
| Route definition | Typed `DuckLocation` classes | String path + inline builder |
| Parameters | Constructor fields on location class | `:param` in path string |
| Navigation | `DuckRouter.of(context).navigate(to: LocationInstance())` | `context.navController.navigate('/path/42')` |
| Type safety | Compile-time (location classes) | Runtime (path strings) |
| Code generation | Not required | Not required |

The main trade-off: duck_router gives compile-time safety for routes and parameters at the cost of boilerplate (one class per route). navhost uses string paths — less code, but parameter names are only checked at runtime.

### Migration tips

- **Migrate incrementally** — navhost uses `MaterialApp.router`, so switching the router is a one-time change at the app root
- **Path parameters work the same** — `/item/:id` syntax is identical across most routers
- **No code generation** — unlike auto_route, navhost routes are defined inline with no build step
- **Transitions carry over** — navhost supports per-route and global transitions, same as GoRouter and auto_route

## Using with other libraries

navhost is just a navigation layer — it doesn't impose a state management solution. Your route builders are plain functions that return widgets, so you can wrap them with whatever provider, scope, or DI mechanism you already use.

### Provider

Wrap a route with `ChangeNotifierProvider` to scope a ViewModel to that route. When the route is popped, the provider is removed from the tree and the ViewModel is disposed automatically:

```dart
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/counter', (_, _) => ChangeNotifierProvider(
      create: (_) => CounterModel(),
      child: const CounterPage(),
    )),
  ],
)
```

```dart
// CounterPage reads the model normally
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CounterModel>();
    return Text('${model.count}');
  }
}
```

For multiple providers on a single route:

```dart
NavRoute('/dashboard', (_, _) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => StatsModel()),
    ChangeNotifierProvider(create: (_) => NotificationsModel()),
  ],
  child: const DashboardPage(),
)),
```

### Riverpod

With Riverpod, state lives outside the widget tree, so routes don't need wrapping. Just use `ConsumerWidget` or `Consumer` in your pages:

```dart
// Providers defined at the top level
final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

// Routes — nothing special needed
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/counter', (_, _) => const CounterPage()),
  ],
)
```

```dart
class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

For route-scoped state that auto-disposes when the page is removed, use `autoDispose`:

```dart
final counterProvider = NotifierProvider.autoDispose<CounterNotifier, int>(
  CounterNotifier.new,
);
```

### Bloc / Cubit

Wrap a route with `BlocProvider` for route-scoped Blocs. The Bloc is created when the route is pushed and closed when it's popped:

```dart
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/counter', (_, _) => BlocProvider(
      create: (_) => CounterCubit(),
      child: const CounterPage(),
    )),
    NavRoute('/item/:id', (params, _) => BlocProvider(
      create: (_) => ItemCubit(id: params['id']!),
      child: const ItemPage(),
    )),
  ],
)
```

```dart
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterCubit, int>(
      builder: (context, count) => Text('$count'),
    );
  }
}
```

### GetX

Instantiate controllers inside the route builder. Use `GetBuilder` or `Obx` in the page:

```dart
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/counter', (_, _) {
      Get.put(CounterController());
      return const CounterPage();
    }),
  ],
)
```

```dart
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CounterController>();
    return Obx(() => Text('${ctrl.count}'));
  }
}
```

### get_it

Use [get_it](https://pub.dev/packages/get_it) to resolve dependencies in route builders:

```dart
// Registration
final getIt = GetIt.instance;
getIt.registerFactory(() => CounterViewModel());
getIt.registerSingleton(ApiService());

// Routes
NavController(
  routes: [
    NavRoute('/', (_, _) => const HomePage()),
    NavRoute('/counter', (_, _) => CounterPage(
      vm: getIt<CounterViewModel>(),
    )),
    NavRoute('/item/:id', (params, _) => ItemPage(
      vm: getIt<ItemViewModel>(param1: params['id']!),
    )),
  ],
)
```

### Using path and query parameters with providers

Route builders receive path parameters and query parameters, which you can pass into your providers or ViewModels:

```dart
NavRoute('/item/:id', (params, queryParams) => BlocProvider(
  create: (_) => ItemCubit(
    id: params['id']!,
    ref: queryParams['ref'] ?? 'direct',
  ),
  child: const ItemPage(),
)),
```

### Summary

| Library | Pattern | Scoped to route? |
|---------|---------|-----------------|
| **Provider** | Wrap route with `ChangeNotifierProvider` | Yes — disposed on pop |
| **Riverpod** | Use `ConsumerWidget`; add `.autoDispose` for scoping | Auto-dispose optional |
| **Bloc** | Wrap route with `BlocProvider` | Yes — closed on pop |
| **GetX** | Call `Get.put()` in route builder | Manual (`Get.delete`) |
| **get_it** | Resolve in route builder via `getIt<T>()` | Depends on registration |

The general rule: navhost route builders are widget factories — anything you can wrap around a widget in Flutter, you can use inside a route builder.

## State management

Looking for reactive state management? Check out [navhost_state](https://pub.dev/packages/navhost_state) — GetX-style `.obs` reactive values, auto-tracking `Obs` widgets, and scoped ViewModels that are tied to the route lifecycle. Zero boilerplate, fine-grained rebuilds.

## Example

See the [example app](example/) for a full showcase of all navigation features.

## License

MIT
