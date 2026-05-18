import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navhost/navhost.dart';

void main() {
  group('Awaiting results (Declarative & Imperative)', () {
    testWidgets('navigate and pop with result', (tester) async {
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
      await tester.pumpAndSettle();

      final future = nav.navigate<String>('/detail');
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      nav.pop('hello');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      expect(await future, 'hello');
    });

    testWidgets('showBottomSheet and pop with result', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/sheet', (p, q) => const Text('Sheet')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      final future = nav.showBottomSheet<int>('/sheet');
      await tester.pumpAndSettle();
      expect(find.text('Sheet'), findsOneWidget);

      nav.pop(42);
      await tester.pumpAndSettle();

      expect(await future, 42);
    });

    testWidgets('showDialog and pop with result', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/dialog', (p, q) => const Text('Dialog')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      final future = nav.showDialog<bool>('/dialog');
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);

      nav.pop(true);
      await tester.pumpAndSettle();

      expect(await future, true);
    });

    testWidgets('navigateWidget and pop with result', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      final future = nav.navigateWidget<String>(const Text('Widget'));
      await tester.pumpAndSettle();
      expect(find.text('Widget'), findsOneWidget);

      nav.pop('widget_result');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      expect(await future, 'widget_result');
    });

    testWidgets('showBottomSheetWidget and pop with result', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      final future =
          nav.showBottomSheetWidget<int>(const Text('Sheet Widget'));
      await tester.pumpAndSettle();

      nav.pop(99);
      await tester.pumpAndSettle();

      expect(await future, 99);
    });

    testWidgets('showDialogWidget and pop with result', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      final future = nav.showDialogWidget<bool>(const Text('Dialog Widget'));
      await tester.pumpAndSettle();

      nav.pop(true);
      await tester.pumpAndSettle();

      expect(await future, true);
    });

    testWidgets('hanging futures complete with null on replace',
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

      final futureA = nav.navigate<String>('/a');
      await tester.pumpAndSettle();

      nav.switchTo('/b');
      await tester.pumpAndSettle();

      expect(await futureA, isNull);
    });

    testWidgets('hanging futures complete with null on popUpTo',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B')),
          NavRoute('/c', (p, q) => const Text('C')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/a');
      await tester.pumpAndSettle();
      final futureB = nav.navigate<String>('/b');
      await tester.pumpAndSettle();

      nav.navigate('/c', popUpTo: '/a');
      await tester.pumpAndSettle();

      expect(await futureB, isNull);
    });

    test('popUntil completes hanging futures with null', () async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B')),
          NavRoute('/c', (p, q) => const Text('C')),
        ],
      );
      nav.navigate('/a');
      final futureB = nav.navigate<String>('/b');
      final futureC = nav.navigate<String>('/c');

      nav.popUntil('/a');

      expect(await futureB, isNull);
      expect(await futureC, isNull);
      expect(nav.currentPath, '/a');
    });

    test('popUntilWhere completes hanging futures with null', () async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B')),
          NavRoute('/c', (p, q) => const Text('C')),
        ],
      );
      nav.navigate('/a');
      final futureB = nav.navigate<String>('/b');
      final futureC = nav.navigate<String>('/c');

      nav.popUntilWhere((path) => path == '/a');

      expect(await futureB, isNull);
      expect(await futureC, isNull);
      expect(nav.currentPath, '/a');
    });

    testWidgets(
        'launchSingleTop skipped — returns existing entry future, resolves on pop',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/a', (p, q) => const Text('A')),
        ],
      );
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      final first = nav.navigate<String>('/a');
      await tester.pumpAndSettle();

      final second = nav.navigate<String>('/a', launchSingleTop: true);
      expect(nav.backStack.length, 2);

      nav.pop('done');
      await tester.pumpAndSettle();

      expect(await first, 'done');
      expect(await second, 'done');
    });

    test(
        'launchSingleTop skipped on initial route (no completer) — returns null',
        () async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      final result = await nav.navigate<String>('/', launchSingleTop: true);
      expect(result, isNull);
      expect(nav.backStack.length, 1);
    });

    testWidgets('switchTo result future resolves when new route is popped',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B')),
        ],
      );
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      nav.navigate('/a');
      await tester.pumpAndSettle();

      final futureB = nav.switchTo<String>('/b');
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);

      nav.pop('from_b');
      await tester.pumpAndSettle();

      expect(await futureB, 'from_b');
    });

    testWidgets(
        'navigate with replace: result future resolves when new route is popped',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/a', (p, q) => const Text('A')),
          NavRoute('/b', (p, q) => const Text('B')),
        ],
      );
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      nav.navigate('/a');
      final oldFuture = nav.navigate<String>('/b');
      await tester.pumpAndSettle();

      final newFuture = nav.navigate<String>('/a', replace: true);
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);

      expect(await oldFuture, isNull);

      nav.pop('replaced_result');
      await tester.pumpAndSettle();
      expect(await newFuture, 'replaced_result');
    });

    testWidgets('mix declarative and imperative pushes with result',
        (tester) async {
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
      await tester.pumpAndSettle();

      final future = nav.push<String>('/detail');
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      nav.pop('imperative_result');
      await tester.pumpAndSettle();

      expect(await future, 'imperative_result');
    });

    testWidgets('mix pushBottomSheet and declarative pop', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/sheet', (p, q) => const Text('Sheet')),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      final future = nav.pushBottomSheet<int>('/sheet');
      await tester.pumpAndSettle();
      expect(find.text('Sheet'), findsOneWidget);

      nav.pop(99);
      await tester.pumpAndSettle();

      expect(await future, 99);
    });

    testWidgets('pushWidget and pop with result', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      final future = nav.pushWidget<String>(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).pop('widget_result'),
            child: const Text('Widget Page'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Widget Page'), findsOneWidget);

      await tester.tap(find.text('Widget Page'));
      await tester.pumpAndSettle();

      expect(await future, 'widget_result');
    });

    testWidgets('pushBottomSheetWidget and pop with result', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      final future = nav.pushBottomSheetWidget<int>(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).pop(7),
            child: const Text('Sheet'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sheet'));
      await tester.pumpAndSettle();

      expect(await future, 7);
    });

    testWidgets('pushDialogWidget and pop with result', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [NavRoute('/', (p, q) => const Text('Home'))],
      );
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      final future = nav.pushDialogWidget<bool>(
        AlertDialog(
          actions: [
            TextButton(
              onPressed: () => Navigator.of(
                      tester.element(find.byType(AlertDialog)))
                  .pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(await future, true);
    });

    testWidgets('mixing context.navigator.pop with declarative navigation',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute(
              '/detail',
              (p, q) => Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop('from_navigator');
                        },
                        child: const Text('Detail'),
                      );
                    },
                  )),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      final future = nav.navigate<String>('/detail');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Detail'));
      await tester.pumpAndSettle();

      expect(await future, 'from_navigator');
    });
  });
}
