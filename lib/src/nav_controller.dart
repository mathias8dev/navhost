import 'dart:async';

import 'package:flutter/material.dart';

import 'bottom_sheet_config.dart';
import 'dialog_config.dart';
import 'nav_back_stack_entry.dart';
import 'nav_interceptor.dart';
import 'nav_route.dart';
export 'bottom_sheet_config.dart' show BottomSheetConfig;
export 'dialog_config.dart' show DialogConfig;
export 'nav_back_stack_entry.dart' show NavBackStackEntry;
export 'nav_interceptor.dart' show NavInterceptor;
export 'nav_route.dart' show NavTransitionBuilder;

part 'nav_controller_imperative.dart';
part 'nav_controller_overlays.dart';
part 'nav_page_builder.dart';
part 'nav_pages.dart';
part 'nav_route_matcher.dart';
part 'nav_router_delegate.dart';
part 'nav_host.dart';

/// Central navigation controller that manages the back stack and route resolution.
///
/// Create a [NavController] with a list of [NavRoute]s, then pass it to a
/// [NavHost] widget. Use the declarative methods ([navigate], [pop], [switchTo])
/// to drive navigation, or the imperative methods ([push], [pushBottomSheet],
/// [pushDialog]) when you need a [Future] result.
///
/// ```dart
/// final nav = NavController(
///   routes: [
///     NavRoute('/', (_, _) => const HomePage()),
///     NavRoute('/detail/:id', (p, _) => DetailPage(id: p['id']!)),
///   ],
/// );
/// nav.navigate('/detail/42');
/// ```
class NavController extends ChangeNotifier {
  /// The list of routes this controller can resolve.
  final List<NavRoute> routes;

  /// The path shown when the controller is first created.
  final String initialRoute;

  /// Interceptors evaluated before each navigation request.
  final List<NavInterceptor> interceptors;
  final List<_RouteEntry> _stack;

  /// Global key used to access the underlying [NavigatorState].
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Creates a controller with the given [routes] and optional [initialRoute].
  NavController({
    required this.routes,
    this.initialRoute = '/',
    this.interceptors = const [],
  }) : _stack = [_parseEntry(initialRoute)];

  /// Router delegate for use with [Router] widget.
  late final delegate = _NavRouterDelegate(this);

  /// Route information parser for use with [Router] widget.
  late final parser = _NavRouteInformationParser();

  /// The [NavigatorState] managed by this controller, or `null` if not yet mounted.
  NavigatorState? get navigator => navigatorKey.currentState;

  /// The path at the top of the back stack.
  String get currentPath => _stack.last.path;

  /// Whether there is more than one entry on the stack.
  bool get canPop => _stack.length > 1;

  /// A [NavBackStackEntry] for the current (topmost) route.
  NavBackStackEntry get currentEntry => _toEntry(_stack.last);

  /// A [NavBackStackEntry] for the route below the current one, or `null`.
  NavBackStackEntry? get previousEntry =>
      _stack.length > 1 ? _toEntry(_stack[_stack.length - 2]) : null;

  /// An unmodifiable view of the entire back stack as [NavBackStackEntry] objects.
  List<NavBackStackEntry> get backStack =>
      List.unmodifiable(_stack.map(_toEntry));

  NavBackStackEntry _toEntry(_RouteEntry entry) {
    final match = _matchPath(entry.path);
    return NavBackStackEntry(
      path: entry.path,
      params: match?.$2 ?? const {},
      queryParams: entry.queryParams,
    );
  }

  void _notify() => notifyListeners();

  static _RouteEntry _parseEntry(
    String fullPath, {
    RoutePresentation presentation = RoutePresentation.push,
    BottomSheetConfig? bottomSheetConfig,
    DialogConfig? dialogConfig,
    Widget? inlineChild,
    Completer<dynamic>? completer,
  }) {
    final uri = Uri.parse(fullPath);
    return _RouteEntry(
      uri.path,
      queryParams: uri.queryParameters,
      presentation: presentation,
      bottomSheetConfig: bottomSheetConfig,
      dialogConfig: dialogConfig,
      inlineChild: inlineChild,
      completer: completer,
    );
  }

  /// Navigates to [path], optionally clearing or trimming the stack.
  ///
  /// [path] may include query parameters (e.g. `/item/42?ref=email`).
  /// They are available via [NavBackStackEntry.queryParams] and are passed
  /// as the second argument to the route builder.
  ///
  /// When [replace] is `true` the entire stack is replaced with [path].
  /// When [launchSingleTop] is `true` and [path] is already the current
  /// route, navigation is skipped.
  /// [popUpTo] pops routes until the given path is reached before pushing;
  /// set [popUpToInclusive] to also remove the target itself.
  Future<T?> navigate<T extends Object?>(
    String path, {
    bool replace = false,
    bool launchSingleTop = false,
    String? popUpTo,
    bool popUpToInclusive = false,
  }) {
    final resolved = _applyInterceptors(path);
    if (resolved == null) return Future.value(null);

    final completer = Completer<T?>();
    final entry = _parseEntry(resolved, completer: completer);

    if (replace) {
      for (final e in _stack) {
        if (e.completer != null && !e.completer!.isCompleted) {
          e.completer!.complete(null);
        }
      }
      _stack
        ..clear()
        ..add(entry);
    } else {
      if (popUpTo != null) {
        while (_stack.length > 1 && _stack.last.path != popUpTo) {
          final removed = _stack.removeLast();
          if (removed.completer != null && !removed.completer!.isCompleted) {
            removed.completer!.complete(null);
          }
        }
        if (popUpToInclusive &&
            _stack.isNotEmpty &&
            _stack.last.path == popUpTo) {
          final removed = _stack.removeLast();
          if (removed.completer != null && !removed.completer!.isCompleted) {
            removed.completer!.complete(null);
          }
        }
      }
      if (launchSingleTop && currentPath == entry.path) {
        final existing = _stack.last.completer;
        if (existing != null && !existing.isCompleted) {
          return existing.future.then((v) => v as T?);
        }
        return Future.value(null);
      }
      _stack.add(entry);
    }
    notifyListeners();
    return completer.future;
  }

  int _syntheticId = 0;

  /// Replaces the entire stack with a single entry for [path].
  Future<T?> switchTo<T extends Object?>(String path) =>
      navigate<T>(path, replace: true);

  /// Removes the topmost route, if possible.
  /// Always delegates to the Navigator — works for both declarative and imperative routes.
  /// An optional [result] is forwarded to the awaiting [push] caller.
  void pop<T extends Object?>([T? result]) {
    if (navigator != null) {
      navigator!.pop<T>(result);
    } else {
      if (canPop) {
        final removed = _stack.removeLast();
        if (removed.completer != null && !removed.completer!.isCompleted) {
          removed.completer!.complete(result);
        }
        notifyListeners();
      }
    }
  }

  /// Called by [_NavRouterDelegate] via [onDidRemovePage] to sync the declarative
  /// stack after the Navigator removes a page (back gesture, system back button).
  /// Must NOT call [pop] to avoid recursion.
  void _syncStack() {
    if (_stack.length > 1) {
      final removed = _stack.removeLast();
      if (removed.completer != null && !removed.completer!.isCompleted) {
        removed.completer!.complete(null);
      }
      notifyListeners();
    }
  }

  /// Pops entries until [path] is at the top of the stack.
  ///
  /// When [inclusive] is `true`, the entry matching [path] is also removed.
  void popUntil(String path, {bool inclusive = false}) {
    while (canPop && _stack.last.path != path) {
      final removed = _stack.removeLast();
      if (removed.completer != null && !removed.completer!.isCompleted) {
        removed.completer!.complete(null);
      }
    }
    if (inclusive && canPop && _stack.last.path == path) {
      final removed = _stack.removeLast();
      if (removed.completer != null && !removed.completer!.isCompleted) {
        removed.completer!.complete(null);
      }
    }
    notifyListeners();
  }

  /// Pops entries until [predicate] returns `true` for the top entry's path.
  ///
  /// When [inclusive] is `true`, the matching entry is also removed.
  void popUntilWhere(bool Function(String path) predicate,
      {bool inclusive = false}) {
    while (canPop && !predicate(_stack.last.path)) {
      final removed = _stack.removeLast();
      if (removed.completer != null && !removed.completer!.isCompleted) {
        removed.completer!.complete(null);
      }
    }
    if (inclusive && canPop && predicate(_stack.last.path)) {
      final removed = _stack.removeLast();
      if (removed.completer != null && !removed.completer!.isCompleted) {
        removed.completer!.complete(null);
      }
    }
    notifyListeners();
  }

  static Map<String, String>? _extractParams(String pattern, String path) {
    final patternSegments = Uri.parse(pattern).pathSegments;
    final pathSegments = Uri.parse(path).pathSegments;

    if (patternSegments.length != pathSegments.length) return null;

    final params = <String, String>{};
    for (var i = 0; i < patternSegments.length; i++) {
      if (patternSegments[i].startsWith(':')) {
        params[patternSegments[i].substring(1)] = pathSegments[i];
      } else if (patternSegments[i] != pathSegments[i]) {
        return null;
      }
    }
    return params;
  }

  /// Returns the nearest [NavController] from the widget tree above [context].
  static NavController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_NavControllerScope>();
    assert(scope != null, 'No NavController found in context');
    return scope!.controller;
  }
}

class _NavControllerScope extends InheritedWidget {
  final NavController controller;

  const _NavControllerScope({
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(_NavControllerScope oldWidget) =>
      controller != oldWidget.controller;
}
