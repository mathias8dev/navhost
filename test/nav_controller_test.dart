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
      NavRoute('/', (p, q) => _page('Home')),
      NavRoute('/a', (p, q) => _page('A')),
      NavRoute('/b', (p, q) => _page('B')),
      NavRoute('/c', (p, q) => _page('C')),
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

    test('backStack entry exposes full location', () {
      final nav = _createController();
      nav.navigate('/a?tab=favorites');
      expect(nav.currentEntry.location, '/a?tab=favorites');
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
      expect(
          nav.backStack.map((e) => e.path).toList(), ['/', '/a', '/b', '/c']);
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

  group('route information', () {
    test('external route path replaces stack without seeding initial route',
        () async {
      final nav = NavController(
        initialRoute: '/splash',
        routes: [
          NavRoute('/splash', (p, q) => _page('Splash')),
          NavRoute('/home', (p, q) => _page('Home')),
        ],
      );

      await (nav.delegate as RouterDelegate<String>).setNewRoutePath('/home');

      expect(nav.currentPath, '/home');
      expect(nav.canPop, false);
      expect(nav.backStack.map((entry) => entry.path), ['/home']);
    });

    test('external unknown route path replaces stack with default not found',
        () async {
      final nav = _createController();
      nav.navigate('/a');

      await (nav.delegate as RouterDelegate<String>)
          .setNewRoutePath('/missing');

      expect(nav.currentPath, '/missing');
      expect(nav.canPop, false);
      expect(nav.currentEntry.params, isEmpty);
      expect(nav.backStack.map((entry) => entry.path), ['/missing']);
    });

    test('external unknown route path uses notFoundBuilder when configured',
        () async {
      final nav = NavController(
        initialRoute: '/',
        notFoundBuilder: (path, queryParams) => _page('Not found'),
        routes: [NavRoute('/', (p, q) => _page('Home'))],
      );

      await (nav.delegate as RouterDelegate<String>)
          .setNewRoutePath('/missing');

      expect(nav.currentPath, '/missing');
      expect(nav.canPop, false);
      expect(nav.currentEntry.params, isEmpty);
      expect(nav.backStack.map((entry) => entry.path), ['/missing']);
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

    test('skips if already at destination with same query params', () {
      final nav = _createController();
      nav.navigate('/a?tab=favorites');
      var count = 0;
      nav.addListener(() => count++);
      nav.navigate('/a?tab=favorites', launchSingleTop: true);
      expect(count, 0);
      expect(nav.backStack.length, 2);
    });

    test('navigates if query params differ', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/a?tab=favorites', launchSingleTop: true);
      expect(nav.currentPath, '/a');
      expect(nav.currentEntry.queryParams, {'tab': 'favorites'});
      expect(nav.backStack.length, 3);
    });

    test('skips if same query params are passed in different order', () {
      final nav = _createController();
      nav.navigate('/a?tab=favorites&filter=recent');
      var count = 0;
      nav.addListener(() => count++);
      nav.navigate('/a?filter=recent&tab=favorites', launchSingleTop: true);
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
          NavRoute('/', (p, q) => const Text('Home')),
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
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/item/:id',
              (p, q) => Text('id:${p['id']},ref:${q['ref']},src:${q['src']}')),
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
      expect(nav.currentEntry.queryParams, {'lang': 'en', 'draft': 'true'});
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

    test('launchSingleTop compares query params', () {
      final nav = _createController();
      nav.navigate('/a?x=1');
      var count = 0;
      nav.addListener(() => count++);
      nav.navigate('/a?x=2', launchSingleTop: true);
      expect(count, 1);
      expect(nav.currentEntry.queryParams, {'x': '2'});
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

    test('blocked navigate returns null future immediately', () async {
      final nav = _createController(
        interceptors: [_BlockInterceptor('/a')],
      );
      final result = await nav.navigate<String>('/a');
      expect(result, isNull);
      expect(nav.currentPath, '/');
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
      expect(nav.currentPath, '/a');
    });

    test('showBottomSheetWidget uses default config with null heightFactor',
        () {
      final nav = _createController();
      nav.showBottomSheetWidget(const Text('Sheet'));
      expect(nav.currentPath, startsWith('__sheet_'));
    });

    test(
        'pop removes showBottomSheetWidget entry and returns to previous route',
        () {
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

  group('Edge cases', () {
    test('navigate to same path without launchSingleTop allows duplicates', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/a');
      expect(nav.backStack.length, 3);
      expect(nav.backStack.map((e) => e.path).toList(), ['/', '/a', '/a']);
    });

    test('navigate to unmatched route uses default not found', () {
      final nav = _createController();
      nav.navigate('/nonexistent');
      expect(nav.currentPath, '/nonexistent');
      expect(nav.backStack.map((e) => e.path).toList(), [
        '/',
        '/nonexistent',
      ]);
    });

    test('unmatched route stays in multi-route stack', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.navigate('/nonexistent');
      nav.navigate('/b');

      expect(nav.currentPath, '/b');
      expect(nav.backStack.map((e) => e.path).toList(), [
        '/',
        '/a',
        '/nonexistent',
        '/b',
      ]);
    });

    test('popUpToInclusive on root then pushes — stack never empty', () {
      final nav = _createController();
      nav.navigate('/a', popUpTo: '/', popUpToInclusive: true);
      expect(nav.backStack.length, 1);
      expect(nav.currentPath, '/a');
    });

    test('popUpToInclusive on root with launchSingleTop then pushes', () {
      final nav = _createController();
      nav.navigate('/a',
          popUpTo: '/', popUpToInclusive: true, launchSingleTop: true);
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

    test('mixed presentation sequence — navigate, sheet, dialog, pop all', () {
      final nav = _createController();
      nav.navigate('/a');
      nav.showBottomSheet('/b');
      nav.showDialog('/c');
      expect(nav.backStack.length, 4);
      expect(
          nav.backStack.map((e) => e.path).toList(), ['/', '/a', '/b', '/c']);

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
      nav.navigate('/a', popUpTo: '/a', launchSingleTop: true);
      expect(nav.backStack.map((e) => e.path).toList(), ['/', '/a']);
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
      nav.navigate('/b', popUpTo: '/a', popUpToInclusive: true);
      expect(nav.backStack.map((e) => e.path).toList(), ['/', '/b']);
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
  });
}
