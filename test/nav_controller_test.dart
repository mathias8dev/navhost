import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navhost/navhost.dart';

Widget _page(String label) => Text(label);

NavController _createController({
  List<NavInterceptor> interceptors = const [],
}) {
  return NavController(
    initialRoute: '/',
    interceptors: interceptors,
    routes: [
      NavRoute('/', (_, _) => _page('Home')),
      NavRoute('/a', (_, _) => _page('A')),
      NavRoute('/b', (_, _) => _page('B')),
      NavRoute('/c', (_, _) => _page('C')),
      NavRoute('/item/:id', (p, _) => _page('Item ${p['id']}')),
      NavRoute('/user/:uid/post/:pid',
          (p, _) => _page('User ${p['uid']} Post ${p['pid']}')),
    ],
  );
}

class _RedirectInterceptor extends NavInterceptor {
  final String from;
  final String to;
  _RedirectInterceptor({required this.from, required this.to});

  @override
  String? intercept(String currentPath, String targetPath) {
    if (targetPath == from) return to;
    return null;
  }
}

class _BlockInterceptor extends NavInterceptor {
  final String blocked;
  _BlockInterceptor(this.blocked);

  @override
  String? intercept(String currentPath, String targetPath) {
    if (targetPath == blocked) return currentPath;
    return null;
  }
}

void main() {
  group('Initial state', () {
    test('starts at initialRoute', () {
      final nav = _createController();
      expect(nav.currentPath, '/');
      expect(nav.canPop, false);
    });

    test('backStack contains only initial route', () {
      final nav = _createController();
      expect(nav.backStack.length, 1);
      expect(nav.backStack.first.path, '/');
    });

    test('previousEntry is null at root', () {
      final nav = _createController();
      expect(nav.previousEntry, isNull);
    });
  });

  group('navigate', () {
    test('pushes route onto stack', () {
      final nav = _createController();
      nav.navigate('/a');
      expect(nav.currentPath, '/a');
      expect(nav.canPop, true);
      expect(nav.backStack.length, 2);
    });

    test('multiple navigations build stack', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      expect(nav.currentPath, '/c');
      expect(nav.backStack.length, 4);
      expect(nav.backStack.map((e) => e.path).toList(),
          ['/', '/a', '/b', '/c']);
    });

    test('notifies listeners', () {
      final nav = _createController();
      var count = 0;
      nav.addListener(() => count++);
      nav.navigate('/a');
      expect(count, 1);
    });
  });

  group('navigate with replace', () {
    test('clears stack and sets new route', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c', replace: true);
      expect(nav.currentPath, '/c');
      expect(nav.canPop, false);
      expect(nav.backStack.length, 1);
    });
  });

  group('switchTo', () {
    test('replaces entire stack', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.switchTo('/b');
      expect(nav.currentPath, '/b');
      expect(nav.canPop, false);
    });
  });

  group('pop', () {
    test('removes top entry', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.pop();
      expect(nav.currentPath, '/a');
      expect(nav.backStack.length, 2);
    });

    test('does nothing at root', () {
      final nav = _createController();
      var count = 0;
      nav.addListener(() => count++);
      nav.pop();
      expect(nav.currentPath, '/');
      expect(count, 0);
    });

    test('notifies listeners', () {
      final nav = _createController();
      nav.navigate('/a');
      var count = 0;
      nav.addListener(() => count++);
      nav.pop();
      expect(count, 1);
    });
  });

  group('popUntil', () {
    test('pops to target path', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      nav.popUntil('/a');
      expect(nav.currentPath, '/a');
      expect(nav.backStack.length, 2);
    });

    test('with inclusive removes target too', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      nav.popUntil('/a', inclusive: true);
      expect(nav.currentPath, '/');
      expect(nav.backStack.length, 1);
    });

    test('does nothing if already at target', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.popUntil('/a');
      expect(nav.currentPath, '/a');
      expect(nav.backStack.length, 2);
    });

    test('does not pop below root', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.popUntil('/nonexistent');
      expect(nav.currentPath, '/');
      expect(nav.canPop, false);
    });
  });

  group('popUntilWhere', () {
    test('pops until predicate matches', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      nav.popUntilWhere((path) => path == '/a');
      expect(nav.currentPath, '/a');
    });

    test('with inclusive removes matched entry', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      nav.popUntilWhere((path) => path == '/a', inclusive: true);
      expect(nav.currentPath, '/');
    });
  });

  group('launchSingleTop', () {
    test('skips if already at destination', () {
      final nav = _createController();
      nav.navigate('/a');
      var count = 0;
      nav.addListener(() => count++);
      nav.navigate('/a', launchSingleTop: true);
      expect(count, 0);
      expect(nav.backStack.length, 2);
    });

    test('navigates if not at destination', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b', launchSingleTop: true);
      expect(nav.currentPath, '/b');
      expect(nav.backStack.length, 3);
    });
  });

  group('popUpTo', () {
    test('pops to target then pushes new route', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      nav.navigate('/a', popUpTo: '/a');
      expect(nav.backStack.map((e) => e.path).toList(), ['/', '/a', '/a']);
    });

    test('popUpTo with inclusive removes target before pushing', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      nav.navigate('/b', popUpTo: '/a', popUpToInclusive: true);
      expect(nav.backStack.map((e) => e.path).toList(), ['/', '/b']);
    });

    test('popUpTo clears to root if target not found', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c', popUpTo: '/nonexistent');
      expect(nav.backStack.map((e) => e.path).toList(), ['/', '/c']);
    });
  });

  group('Path params', () {
    test('single param extracted correctly', () {
      final nav = _createController();
      nav.navigate('/item/42');
      expect(nav.currentEntry.path, '/item/42');
      expect(nav.currentEntry.params, {'id': '42'});
    });

    test('multiple params extracted correctly', () {
      final nav = _createController();
      nav.navigate('/user/7/post/99');
      expect(nav.currentEntry.params, {'uid': '7', 'pid': '99'});
    });

    test('no params for static route', () {
      final nav = _createController();
      expect(nav.currentEntry.params, isEmpty);
    });
  });

  group('Query params', () {
    test('extracted from navigate path', () {
      final nav = _createController();
      nav.navigate('/a?ref=email&page=2');
      expect(nav.currentEntry.path, '/a');
      expect(nav.currentEntry.queryParams, {'ref': 'email', 'page': '2'});
    });

    test('combined with path params', () {
      final nav = _createController();
      nav.navigate('/item/42?source=deeplink');
      expect(nav.currentEntry.path, '/item/42');
      expect(nav.currentEntry.params, {'id': '42'});
      expect(nav.currentEntry.queryParams, {'source': 'deeplink'});
    });

    test('empty when no query string', () {
      final nav = _createController();
      nav.navigate('/a');
      expect(nav.currentEntry.queryParams, isEmpty);
    });

    test('preserved through switchTo', () {
      final nav = _createController();
      nav.switchTo('/b?mode=dark');
      expect(nav.currentEntry.path, '/b');
      expect(nav.currentEntry.queryParams, {'mode': 'dark'});
    });

    test('preserved through replace', () {
      final nav = _createController();
      nav.navigate('/a?x=1', replace: true);
      expect(nav.currentEntry.queryParams, {'x': '1'});
    });

    testWidgets('passed to route builder', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Home')),
          NavRoute('/detail', (_, q) => Text('ref:${q['ref']}')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      nav.navigate('/detail?ref=email');
      await tester.pumpAndSettle();
      expect(find.text('ref:email'), findsOneWidget);
    });

    testWidgets('path params and query params both passed to builder',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Home')),
          NavRoute(
              '/item/:id',
              (p, q) =>
                  Text('id:${p['id']},ref:${q['ref']},src:${q['src']}')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      nav.navigate('/item/42?ref=email&src=deeplink');
      await tester.pumpAndSettle();
      expect(find.text('id:42,ref:email,src:deeplink'), findsOneWidget);
    });

    test('multiple path params with query params', () {
      final nav = _createController();
      nav.navigate('/user/7/post/99?lang=en&draft=true');
      expect(nav.currentEntry.path, '/user/7/post/99');
      expect(nav.currentEntry.params, {'uid': '7', 'pid': '99'});
      expect(
          nav.currentEntry.queryParams, {'lang': 'en', 'draft': 'true'});
    });

    test('query params not affected by pop', () {
      final nav = _createController();
      nav.navigate('/a?x=1');
      nav.navigate('/b?y=2');
      expect(nav.currentEntry.queryParams, {'y': '2'});
      nav.pop();
      expect(nav.currentEntry.queryParams, {'x': '1'});
    });

    test('each stack entry keeps its own query params', () {
      final nav = _createController();
      nav.navigate('/a?x=1');
      nav.navigate('/b?y=2');
      nav.navigate('/c?z=3');
      final entries = nav.backStack;
      expect(entries[0].queryParams, isEmpty);
      expect(entries[1].queryParams, {'x': '1'});
      expect(entries[2].queryParams, {'y': '2'});
      expect(entries[3].queryParams, {'z': '3'});
    });

    test('launchSingleTop compares path without query params', () {
      final nav = _createController();
      nav.navigate('/a?x=1');
      var count = 0;
      nav.addListener(() => count++);
      nav.navigate('/a?x=2', launchSingleTop: true);
      expect(count, 0);
      expect(nav.currentEntry.queryParams, {'x': '1'});
    });
  });

  group('Back stack observation', () {
    test('currentEntry reflects top of stack', () {
      final nav = _createController();
      nav.navigate('/item/5');
      expect(nav.currentEntry.path, '/item/5');
      expect(nav.currentEntry.params, {'id': '5'});
    });

    test('previousEntry reflects entry below top', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      expect(nav.previousEntry?.path, '/a');
    });

    test('backStack is unmodifiable', () {
      final nav = _createController();
      expect(() => nav.backStack.add(NavBackStackEntry(path: '/x')),
          throwsUnsupportedError);
    });
  });

  group('Interceptors', () {
    test('redirect changes destination', () {
      final nav = _createController(
        interceptors: [_RedirectInterceptor(from: '/a', to: '/b')],
      );
      nav.navigate('/a');
      expect(nav.currentPath, '/b');
    });

    test('block cancels navigation', () {
      final nav = _createController(
        interceptors: [_BlockInterceptor('/a')],
      );
      var count = 0;
      nav.addListener(() => count++);
      nav.navigate('/a');
      expect(nav.currentPath, '/');
      expect(count, 0);
    });

    test('interceptors chain — first redirects, second allows', () {
      final nav = _createController(
        interceptors: [
          _RedirectInterceptor(from: '/a', to: '/b'),
          _RedirectInterceptor(from: '/b', to: '/c'),
        ],
      );
      nav.navigate('/a');
      expect(nav.currentPath, '/c');
    });

    test('null return allows navigation', () {
      final nav = _createController(
        interceptors: [_RedirectInterceptor(from: '/x', to: '/y')],
      );
      nav.navigate('/a');
      expect(nav.currentPath, '/a');
    });

    test('interceptor works with launchSingleTop', () {
      final nav = _createController(
        interceptors: [_RedirectInterceptor(from: '/a', to: '/b')],
      );
      nav.navigate('/b');
      nav.navigate('/a', launchSingleTop: true);
      expect(nav.currentPath, '/b');
      expect(nav.backStack.length, 2);
    });
  });

  group('showBottomSheet / showDialog (declarative)', () {
    test('showBottomSheet pushes entry', () {
      final nav = _createController();
      nav.showBottomSheet('/a');
      expect(nav.currentPath, '/a');
      expect(nav.backStack.length, 2);
    });

    test('showDialog pushes entry', () {
      final nav = _createController();
      nav.showDialog('/a');
      expect(nav.currentPath, '/a');
      expect(nav.backStack.length, 2);
    });

    test('showBottomSheetWidget pushes synthetic entry', () {
      final nav = _createController();
      nav.showBottomSheetWidget(const Text('Sheet'));
      expect(nav.backStack.length, 2);
      expect(nav.currentPath, startsWith('__sheet_'));
    });

    test('showDialogWidget pushes synthetic entry', () {
      final nav = _createController();
      nav.showDialogWidget(const Text('Dialog'));
      expect(nav.backStack.length, 2);
      expect(nav.currentPath, startsWith('__dialog_'));
    });

    test('pop removes bottom sheet entry', () {
      final nav = _createController();
      nav.showBottomSheet('/a');
      nav.pop();
      expect(nav.currentPath, '/');
      expect(nav.canPop, false);
    });

    test('pop removes dialog entry', () {
      final nav = _createController();
      nav.showDialog('/a');
      nav.pop();
      expect(nav.currentPath, '/');
    });
  });

  group('BottomSheetConfig', () {
    test('heightFactor defaults to null (auto-height)', () {
      const config = BottomSheetConfig();
      expect(config.heightFactor, isNull);
    });

    test('heightFactor can be set to a fixed value', () {
      const config = BottomSheetConfig(heightFactor: 0.85);
      expect(config.heightFactor, 0.85);
    });

    test('showBottomSheet uses default config with null heightFactor', () {
      final nav = _createController();
      nav.showBottomSheet('/a');
      // entry is pushed regardless of config — config affects rendering only
      expect(nav.currentPath, '/a');
    });

    test('showBottomSheetWidget uses default config with null heightFactor', () {
      final nav = _createController();
      nav.showBottomSheetWidget(const Text('Sheet'));
      expect(nav.currentPath, startsWith('__sheet_'));
    });

    test('pop removes showBottomSheetWidget entry and returns to previous route', () {
      final nav = _createController();
      nav.showBottomSheetWidget(const Text('Sheet'));
      expect(nav.backStack.length, 2);
      nav.pop();
      expect(nav.backStack.length, 1);
      expect(nav.currentPath, '/');
      expect(nav.canPop, false);
    });
  });

  group('navigateWidget', () {
    test('pushes synthetic entry', () {
      final nav = _createController();
      nav.navigateWidget(const Text('Inline'));
      expect(nav.backStack.length, 2);
      expect(nav.currentPath, startsWith('__page_'));
    });

    test('can be popped', () {
      final nav = _createController();
      nav.navigateWidget(const Text('Inline'));
      nav.pop();
      expect(nav.currentPath, '/');
    });

    test('increments synthetic id', () {
      final nav = _createController();
      nav.navigateWidget(const Text('A'));
      final first = nav.currentPath;
      nav.navigateWidget(const Text('B'));
      final second = nav.currentPath;
      expect(first, isNot(second));
    });
  });

  group('NavHost widget', () {
    testWidgets('renders initial route', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (_, _) => const Text('Home'))],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('renders after navigate', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Home')),
          NavRoute('/detail', (_, _) => const Text('Detail')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      nav.navigate('/detail');
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);
    });

    testWidgets('renders after pop', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Home')),
          NavRoute('/detail', (_, _) => const Text('Detail')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      nav.navigate('/detail');
      await tester.pumpAndSettle();
      nav.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('renders path params', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Home')),
          NavRoute('/item/:id', (p, _) => Text('Item ${p['id']}')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      nav.navigate('/item/42');
      await tester.pumpAndSettle();
      expect(find.text('Item 42'), findsOneWidget);
    });

    testWidgets('renders inline widget', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (_, _) => const Text('Home'))],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      nav.navigateWidget(const Text('Inline'));
      await tester.pumpAndSettle();
      expect(find.text('Inline'), findsOneWidget);
    });

    testWidgets('switchTo replaces content', (tester) async {
      final nav = NavController(
        initialRoute: '/a',
        routes: [
          NavRoute('/a', (_, _) => const Text('A')),
          NavRoute('/b', (_, _) => const Text('B')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      expect(find.text('A'), findsOneWidget);
      nav.switchTo('/b');
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('NavController.of returns controller', (tester) async {
      late NavController found;
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => Builder(
                builder: (context) {
                  found = NavController.of(context);
                  return const Text('Home');
                },
              )),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      expect(found, same(nav));
    });
  });

  group('Nested NavHost (sub-routing)', () {
    testWidgets('child NavHost renders its own routes', (tester) async {
      final rootNav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Root')),
        ],
      );

      final childNav = NavController(
        initialRoute: '/tab1',
        routes: [
          NavRoute('/tab1', (_, _) => const Text('Tab 1')),
          NavRoute('/tab2', (_, _) => const Text('Tab 2')),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: rootNav.delegate,
        routeInformationParser: rootNav.parser,
      ));

      // Root renders, now pump a nested NavHost
      rootNav.navigate('/');
      await tester.pumpAndSettle();

      // Rebuild with nested NavHost inside root route
      final nestedRootNav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute(
            '/',
            (_, _) => Column(
              children: [
                const Text('Shell'),
                Expanded(child: NavHost(navController: childNav)),
              ],
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: nestedRootNav.delegate,
        routeInformationParser: nestedRootNav.parser,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Shell'), findsOneWidget);
      expect(find.text('Tab 1'), findsOneWidget);
    });

    testWidgets('child NavHost navigates independently', (tester) async {
      final childNav = NavController(
        initialRoute: '/tab1',
        routes: [
          NavRoute('/tab1', (_, _) => const Text('Tab 1')),
          NavRoute('/tab2', (_, _) => const Text('Tab 2')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavHost(navController: childNav),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tab 1'), findsOneWidget);

      childNav.navigate('/tab2');
      await tester.pumpAndSettle();
      expect(find.text('Tab 2'), findsOneWidget);

      childNav.pop();
      await tester.pumpAndSettle();
      expect(find.text('Tab 1'), findsOneWidget);
    });

    testWidgets('switchTo swaps tabs in child NavHost', (tester) async {
      final tabNav = NavController(
        initialRoute: '/home',
        routes: [
          NavRoute('/home', (_, _) => const Text('Home Tab')),
          NavRoute('/settings', (_, _) => const Text('Settings Tab')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavHost(navController: tabNav),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home Tab'), findsOneWidget);

      tabNav.switchTo('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Settings Tab'), findsOneWidget);
      expect(tabNav.canPop, false);

      tabNav.switchTo('/home');
      await tester.pumpAndSettle();
      expect(find.text('Home Tab'), findsOneWidget);
    });

    testWidgets('two sibling NavHosts are independent', (tester) async {
      final nav1 = NavController(
        initialRoute: '/a',
        routes: [
          NavRoute('/a', (_, _) => const Text('Nav1-A')),
          NavRoute('/b', (_, _) => const Text('Nav1-B')),
        ],
      );
      final nav2 = NavController(
        initialRoute: '/x',
        routes: [
          NavRoute('/x', (_, _) => const Text('Nav2-X')),
          NavRoute('/y', (_, _) => const Text('Nav2-Y')),
        ],
      );

      late int selectedIndex;
      selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: IndexedStack(
                index: selectedIndex,
                children: [
                  NavHost(navController: nav1),
                  NavHost(navController: nav2),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nav1-A'), findsOneWidget);

      // Navigate in nav1
      nav1.navigate('/b');
      await tester.pumpAndSettle();
      expect(find.text('Nav1-B'), findsOneWidget);
      expect(nav1.currentPath, '/b');

      // nav2 is untouched
      expect(nav2.currentPath, '/x');
    });

    testWidgets('child NavHost deep navigation and popUntil',
        (tester) async {
      final childNav = NavController(
        initialRoute: '/p1',
        routes: [
          NavRoute('/p1', (_, _) => const Text('P1')),
          NavRoute('/p2', (_, _) => const Text('P2')),
          NavRoute('/p3', (_, _) => const Text('P3')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavHost(navController: childNav),
          ),
        ),
      );
      await tester.pumpAndSettle();

      childNav.navigate('/p2');
      childNav.navigate('/p3');
      await tester.pumpAndSettle();
      expect(find.text('P3'), findsOneWidget);
      expect(childNav.backStack.length, 3);

      childNav.popUntil('/p1');
      await tester.pumpAndSettle();
      expect(find.text('P1'), findsOneWidget);
      expect(childNav.backStack.length, 1);
    });

    testWidgets('NavController.of returns nearest controller',
        (tester) async {
      late NavController foundInChild;
      final rootNav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Root')),
        ],
      );
      final childNav = NavController(
        initialRoute: '/child',
        routes: [
          NavRoute(
            '/child',
            (_, _) => Builder(
              builder: (context) {
                foundInChild = NavController.of(context);
                return const Text('Child');
              },
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavHost(
              navController: rootNav,
            ),
          ),
        ),
      );

      // Replace root to contain nested NavHost
      final shellNav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute(
            '/',
            (_, _) => NavHost(navController: childNav),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavHost(navController: shellNav),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Child'), findsOneWidget);
      expect(foundInChild, same(childNav));
    });

    testWidgets('child NavHost with default transitions', (tester) async {
      final childNav = NavController(
        initialRoute: '/a',
        routes: [
          NavRoute('/a', (_, _) => const Text('A')),
          NavRoute('/b', (_, _) => const Text('B')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavHost(
              navController: childNav,
              defaultEnterTransition: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              defaultTransitionDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);

      childNav.navigate('/b');
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('MaterialApp.router integration', () {
    testWidgets('renders via delegate and parser', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Root')),
          NavRoute('/page', (_, _) => const Text('Page')),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: nav.delegate,
        routeInformationParser: nav.parser,
      ));
      expect(find.text('Root'), findsOneWidget);
      nav.navigate('/page');
      await tester.pumpAndSettle();
      expect(find.text('Page'), findsOneWidget);
    });
  });

  group('Edge cases', () {
    test('navigate to same path without launchSingleTop allows duplicates',
        () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/a');
      expect(nav.backStack.length, 3);
      expect(nav.backStack.map((e) => e.path).toList(), ['/', '/a', '/a']);
    });

    test('navigate to unmatched route adds to stack but skips in pages', () {
      final nav = _createController();
      nav.navigate('/nonexistent');
      expect(nav.currentPath, '/nonexistent');
      expect(nav.backStack.length, 2);
      expect(nav.currentEntry.params, isEmpty);
    });

    test('popUpToInclusive on root then pushes — stack never empty', () {
      final nav = _createController();
      nav.navigate('/a', popUpTo: '/', popUpToInclusive: true);
      expect(nav.backStack.length, 1);
      expect(nav.currentPath, '/a');
    });

    test('popUntilWhere with never-matching predicate pops to root', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.popUntilWhere((p) => p == '/nonexistent');
      expect(nav.currentPath, '/');
      expect(nav.canPop, false);
    });

    test('popUntil inclusive on root does not empty stack', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.popUntil('/', inclusive: true);
      expect(nav.currentPath, '/');
      expect(nav.backStack.length, 1);
    });

    test('interceptor blocks replace — stack unchanged', () {
      final nav = _createController(
        interceptors: [_BlockInterceptor('/blocked')],
      );
      nav.navigate('/a');
      nav.navigate('/blocked', replace: true);
      expect(nav.currentPath, '/a');
      expect(nav.backStack.length, 2);
    });

    test('interceptor redirects on replace', () {
      final nav = _createController(
        interceptors: [_RedirectInterceptor(from: '/a', to: '/b')],
      );
      nav.navigate('/a', replace: true);
      expect(nav.currentPath, '/b');
      expect(nav.canPop, false);
    });

    test('interceptor on switchTo', () {
      final nav = _createController(
        interceptors: [_BlockInterceptor('/blocked')],
      );
      nav.navigate('/a');
      nav.switchTo('/blocked');
      expect(nav.currentPath, '/a');
    });

    test('mixed presentation sequence — navigate, sheet, dialog, pop all',
        () {
      final nav = _createController();
      nav.navigate('/a');
      nav.showBottomSheet('/b');
      nav.showDialog('/c');
      expect(nav.backStack.length, 4);
      expect(nav.backStack.map((e) => e.path).toList(),
          ['/', '/a', '/b', '/c']);

      nav.pop();
      expect(nav.currentPath, '/b');
      nav.pop();
      expect(nav.currentPath, '/a');
      nav.pop();
      expect(nav.currentPath, '/');
      expect(nav.canPop, false);
    });

    test('popUpTo combined with launchSingleTop', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      // Pop to /a then push /a — but launchSingleTop should block
      // because after popUpTo, /a is on top, and we're pushing /a
      nav.navigate('/a', popUpTo: '/a', launchSingleTop: true);
      // launchSingleTop check happens before stack modification,
      // currentPath is /c != /a, so it proceeds
      expect(nav.backStack.map((e) => e.path).toList(), ['/', '/a', '/a']);
    });

    test('multiple pops at root are no-ops', () {
      final nav = _createController();
      var count = 0;
      nav.addListener(() => count++);
      nav.pop();
      nav.pop();
      nav.pop();
      expect(count, 0);
      expect(nav.currentPath, '/');
    });

    test('backStack observation after popUpTo', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      nav.navigate('/new', popUpTo: '/a', popUpToInclusive: true);
      expect(
          nav.backStack.map((e) => e.path).toList(), ['/', '/new']);
    });

    test('currentEntry params after interceptor redirect', () {
      final nav = _createController(
        interceptors: [
          _RedirectInterceptor(from: '/a', to: '/item/99'),
        ],
      );
      nav.navigate('/a');
      expect(nav.currentEntry.path, '/item/99');
      expect(nav.currentEntry.params, {'id': '99'});
    });

    testWidgets('NavHost controller swap via didUpdateWidget',
        (tester) async {
      final nav1 = NavController(
        initialRoute: '/a',
        routes: [NavRoute('/a', (_, _) => const Text('A'))],
      );
      final nav2 = NavController(
        initialRoute: '/b',
        routes: [NavRoute('/b', (_, _) => const Text('B'))],
      );

      late StateSetter outerSetState;
      var useNav1 = true;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              outerSetState = setState;
              return Scaffold(
                body: NavHost(navController: useNav1 ? nav1 : nav2),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);

      outerSetState(() => useNav1 = false);
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('route-level transition overrides NavHost default',
        (tester) async {
      var usedRouteTransition = false;

      final nav = NavController(
        initialRoute: '/a',
        routes: [
          NavRoute('/a', (_, _) => const Text('A')),
          NavRoute('/b', (_, _) => const Text('B'),
              enterTransition: (child, animation) {
            usedRouteTransition = true;
            return FadeTransition(opacity: animation, child: child);
          }),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavHost(
              navController: nav,
              defaultEnterTransition: (child, animation) =>
                  SlideTransition(
                    position: Tween(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      nav.navigate('/b');
      await tester.pump();
      expect(usedRouteTransition, true);
    });

    testWidgets('unmatched route is skipped in rendered pages',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (_, _) => const Text('Home')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/unknown');
      await tester.pumpAndSettle();
      // /unknown has no matching route, so _buildPages skips it
      // Home should still be visible as the last rendered page
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
