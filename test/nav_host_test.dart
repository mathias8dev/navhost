import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navhost/navhost.dart';

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  group('NavHost widget', () {
    testWidgets('renders initial route', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
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
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/detail', (p, q) => const Text('Detail')),
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
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/detail', (p, q) => const Text('Detail')),
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
          NavRoute('/', (p, q) => const Text('Home')),
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
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
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
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B')),
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

    testWidgets('switchTo rebuilds content when only query params change',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => Text(q['tab'] ?? 'home')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      expect(find.text('home'), findsOneWidget);

      nav.switchTo('/?tab=favorites');
      await tester.pumpAndSettle();
      expect(find.text('favorites'), findsOneWidget);
    });

    testWidgets('NavController.of returns controller', (tester) async {
      late NavController found;
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute(
              '/',
              (p, q) => Builder(
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

    testWidgets('controller swap via didUpdateWidget', (tester) async {
      final nav1 = NavController(
        initialRoute: '/a',
        routes: [NavRoute('/a', (p, q) => const Text('A'))],
      );
      final nav2 = NavController(
        initialRoute: '/b',
        routes: [NavRoute('/b', (p, q) => const Text('B'))],
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
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B'),
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
              defaultEnterTransition: (child, animation) => SlideTransition(
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

    testWidgets('unmatched route renders default not found', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/unknown');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
      expect(find.text('Route not found: /unknown'), findsOneWidget);
      expect(nav.backStack.map((entry) => entry.path), ['/', '/unknown']);
    });

    testWidgets('unmatched route stays visible in a multi-route stack',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/a');
      await tester.pumpAndSettle();
      nav.navigate('/unknown');
      await tester.pumpAndSettle();
      nav.navigate('/b');
      await tester.pumpAndSettle();

      expect(find.text('B'), findsOneWidget);
      expect(nav.currentPath, '/b');
      expect(nav.backStack.map((entry) => entry.path), [
        '/',
        '/a',
        '/unknown',
        '/b',
      ]);

      nav.pop();
      await tester.pumpAndSettle();

      expect(find.text('Route not found: /unknown'), findsOneWidget);
      expect(nav.currentPath, '/unknown');
    });

    testWidgets('unmatched navigation renders notFoundBuilder when configured',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        notFoundBuilder: (path, queryParams) => Text('Not found: $path'),
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/unknown');
      await tester.pumpAndSettle();

      expect(find.text('Not found: /unknown'), findsOneWidget);
      expect(nav.currentPath, '/unknown');
      expect(nav.canPop, true);
    });
  });

  group('MaterialApp.router integration', () {
    testWidgets('renders via delegate and parser', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Root')),
          NavRoute('/page', (p, q) => const Text('Page')),
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

  group('Nested NavHost (sub-routing)', () {
    testWidgets('child NavHost renders its own routes', (tester) async {
      final rootNav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Root')),
        ],
      );

      final childNav = NavController(
        initialRoute: '/tab1',
        routes: [
          NavRoute('/tab1', (p, q) => const Text('Tab 1')),
          NavRoute('/tab2', (p, q) => const Text('Tab 2')),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: rootNav.delegate,
        routeInformationParser: rootNav.parser,
      ));

      rootNav.navigate('/');
      await tester.pumpAndSettle();

      final nestedRootNav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute(
            '/',
            (p, q) => Column(
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
          NavRoute('/tab1', (p, q) => const Text('Tab 1')),
          NavRoute('/tab2', (p, q) => const Text('Tab 2')),
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
          NavRoute('/home', (p, q) => const Text('Home Tab')),
          NavRoute('/settings', (p, q) => const Text('Settings Tab')),
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
          NavRoute('/a', (p, q) => const Text('Nav1-A')),
          NavRoute('/b', (p, q) => const Text('Nav1-B')),
        ],
      );
      final nav2 = NavController(
        initialRoute: '/x',
        routes: [
          NavRoute('/x', (p, q) => const Text('Nav2-X')),
          NavRoute('/y', (p, q) => const Text('Nav2-Y')),
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

      nav1.navigate('/b');
      await tester.pumpAndSettle();
      expect(find.text('Nav1-B'), findsOneWidget);
      expect(nav1.currentPath, '/b');

      expect(nav2.currentPath, '/x');
    });

    testWidgets('child NavHost deep navigation and popUntil', (tester) async {
      final childNav = NavController(
        initialRoute: '/p1',
        routes: [
          NavRoute('/p1', (p, q) => const Text('P1')),
          NavRoute('/p2', (p, q) => const Text('P2')),
          NavRoute('/p3', (p, q) => const Text('P3')),
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

    testWidgets('NavController.of returns nearest controller', (tester) async {
      late NavController foundInChild;
      final childNav = NavController(
        initialRoute: '/child',
        routes: [
          NavRoute(
            '/child',
            (p, q) => Builder(
              builder: (context) {
                foundInChild = NavController.of(context);
                return const Text('Child');
              },
            ),
          ),
        ],
      );

      final shellNav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute(
            '/',
            (p, q) => NavHost(navController: childNav),
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
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B')),
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

  group('Back button — single NavHost', () {
    testWidgets('back pops current route', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/detail', (p, q) => const Text('Detail')),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: nav.delegate,
        routeInformationParser: nav.parser,
      ));
      await tester.pumpAndSettle();

      nav.navigate('/detail');
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      await _pressBack(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(nav.backStack.length, 1);
    });

    testWidgets('back does not pop at root', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: nav.delegate,
        routeInformationParser: nav.parser,
      ));
      await tester.pumpAndSettle();

      await _pressBack(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(nav.backStack.length, 1);
    });

    testWidgets('controller pop at root keeps the rendered page',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: nav.delegate,
        routeInformationParser: nav.parser,
      ));
      await tester.pumpAndSettle();

      nav.pop();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(nav.backStack.length, 1);
    });

    testWidgets('external unknown route renders default not found',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: nav.delegate,
        routeInformationParser: nav.parser,
      ));
      await tester.pumpAndSettle();

      await (nav.delegate as RouterDelegate<String>)
          .setNewRoutePath('/missing');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Route not found: /missing'), findsOneWidget);
      expect(nav.currentPath, '/missing');
      expect(nav.backStack.length, 1);
    });

    testWidgets(
        'external unknown route renders notFoundBuilder when configured',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        notFoundBuilder: (path, queryParams) =>
            Text('Not found: $path from=${queryParams['from']}'),
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: nav.delegate,
        routeInformationParser: nav.parser,
      ));
      await tester.pumpAndSettle();

      await (nav.delegate as RouterDelegate<String>)
          .setNewRoutePath('/missing?from=test');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Not found: /missing from=test'), findsOneWidget);
      expect(nav.currentEntry.location, '/missing?from=test');
    });

    testWidgets('back pops correct route and resolves future', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/detail', (p, q) => const Text('Detail')),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: nav.delegate,
        routeInformationParser: nav.parser,
      ));
      await tester.pumpAndSettle();

      final future = nav.navigate<String>('/detail');
      await tester.pumpAndSettle();

      await _pressBack(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(await future, isNull);
    });
  });

  group('Back button — nested NavHost', () {
    NavController makeInnerNav() => NavController(
          initialRoute: '/inner-home',
          routes: [
            NavRoute('/inner-home', (p, q) => const Text('Inner Home')),
            NavRoute('/inner-detail', (p, q) => const Text('Inner Detail')),
          ],
        );

    NavController makeOuterNav(NavController inner) => NavController(
          initialRoute: '/',
          routes: [
            NavRoute('/', (p, q) => NavHost(navController: inner)),
            NavRoute('/outer-page', (p, q) => const Text('Outer Page')),
          ],
        );

    testWidgets(
        'MaterialApp.router: back pops inner NavHost first when inner canPop',
        (tester) async {
      final inner = makeInnerNav();
      final outer = makeOuterNav(inner);
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: outer.delegate,
        routeInformationParser: outer.parser,
      ));
      await tester.pumpAndSettle();

      inner.navigate('/inner-detail');
      await tester.pumpAndSettle();
      expect(find.text('Inner Detail'), findsOneWidget);
      expect(inner.canPop, true);
      expect(outer.canPop, false);

      await _pressBack(tester);

      expect(find.text('Inner Home'), findsOneWidget);
      expect(inner.backStack.length, 1);
      expect(outer.backStack.length, 1);
    });

    testWidgets(
        'MaterialApp.router: back pops outer NavHost when inner is exhausted',
        (tester) async {
      final inner = makeInnerNav();
      final outer = makeOuterNav(inner);
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: outer.delegate,
        routeInformationParser: outer.parser,
      ));
      await tester.pumpAndSettle();

      outer.navigate('/outer-page');
      await tester.pumpAndSettle();
      expect(find.text('Outer Page'), findsOneWidget);
      expect(outer.canPop, true);

      await _pressBack(tester);

      expect(find.text('Inner Home'), findsOneWidget);
      expect(outer.backStack.length, 1);
    });

    testWidgets(
        'MaterialApp.router: back sequences outer pop then inner pop correctly',
        (tester) async {
      final inner = makeInnerNav();
      final outer = makeOuterNav(inner);
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: outer.delegate,
        routeInformationParser: outer.parser,
      ));
      await tester.pumpAndSettle();

      inner.navigate('/inner-detail');
      outer.navigate('/outer-page');
      await tester.pumpAndSettle();
      expect(find.text('Outer Page'), findsOneWidget);

      await _pressBack(tester);
      expect(find.text('Inner Detail'), findsOneWidget);
      expect(outer.backStack.length, 1);
      expect(inner.backStack.length, 2);

      await _pressBack(tester);
      expect(find.text('Inner Home'), findsOneWidget);
      expect(inner.backStack.length, 1);
    });

    testWidgets(
        'MaterialApp(home: NavHost): back pops inner NavHost first when inner canPop',
        (tester) async {
      final inner = makeInnerNav();
      final outer = makeOuterNav(inner);
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: outer)));
      await tester.pumpAndSettle();

      inner.navigate('/inner-detail');
      await tester.pumpAndSettle();
      expect(find.text('Inner Detail'), findsOneWidget);

      await _pressBack(tester);

      expect(find.text('Inner Home'), findsOneWidget);
      expect(inner.backStack.length, 1);
    });

    testWidgets(
        'MaterialApp(home: NavHost): back pops outer NavHost when inner is exhausted',
        (tester) async {
      final inner = makeInnerNav();
      final outer = makeOuterNav(inner);
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: outer)));
      await tester.pumpAndSettle();

      outer.navigate('/outer-page');
      await tester.pumpAndSettle();
      expect(find.text('Outer Page'), findsOneWidget);

      await _pressBack(tester);

      expect(find.text('Inner Home'), findsOneWidget);
      expect(outer.backStack.length, 1);
    });
  });
}
