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

part 'nav_page_builder.dart';
part 'nav_pages.dart';
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

  static _RouteEntry _parseEntry(String fullPath, {
    RoutePresentation presentation = RoutePresentation.push,
    BottomSheetConfig? bottomSheetConfig,
    DialogConfig? dialogConfig,
    Widget? inlineChild,
  }) {
    final uri = Uri.parse(fullPath);
    return _RouteEntry(
      uri.path,
      queryParams: uri.queryParameters,
      presentation: presentation,
      bottomSheetConfig: bottomSheetConfig,
      dialogConfig: dialogConfig,
      inlineChild: inlineChild,
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
  void navigate(
    String path, {
    bool replace = false,
    bool launchSingleTop = false,
    String? popUpTo,
    bool popUpToInclusive = false,
  }) {
    final resolved = _applyInterceptors(path);
    if (resolved == null) return;

    final entry = _parseEntry(resolved);

    if (launchSingleTop && currentPath == entry.path) return;

    if (replace) {
      _stack
        ..clear()
        ..add(entry);
    } else {
      if (popUpTo != null) {
        while (_stack.length > 1 && _stack.last.path != popUpTo) {
          _stack.removeLast();
        }
        if (popUpToInclusive &&
            _stack.isNotEmpty &&
            _stack.last.path == popUpTo) {
          _stack.removeLast();
        }
      }
      _stack.add(entry);
    }
    notifyListeners();
  }

  String? _applyInterceptors(String to) {
    var target = to;
    for (final interceptor in interceptors) {
      final result = interceptor.intercept(currentPath, target);
      if (result == currentPath) return null;
      if (result != null) target = result;
    }
    return target;
  }

  int _syntheticId = 0;

  /// Pushes an arbitrary [child] widget onto the declarative stack.
  void navigateWidget(Widget child) {
    _stack.add(_RouteEntry(
      '__page_${_syntheticId++}',
      inlineChild: child,
    ));
    notifyListeners();
  }

  /// Presents a route identified by [path] as a modal bottom sheet.
  void showBottomSheet(String path,
      {BottomSheetConfig config = const BottomSheetConfig()}) {
    _stack.add(_parseEntry(
      path,
      presentation: RoutePresentation.bottomSheet,
      bottomSheetConfig: config,
    ));
    notifyListeners();
  }

  /// Presents an arbitrary [child] widget as a modal bottom sheet.
  void showBottomSheetWidget(Widget child,
      {BottomSheetConfig config = const BottomSheetConfig()}) {
    _stack.add(_RouteEntry(
      '__sheet_${_syntheticId++}',
      presentation: RoutePresentation.bottomSheet,
      bottomSheetConfig: config,
      inlineChild: child,
    ));
    notifyListeners();
  }

  /// Presents a route identified by [path] as a dialog.
  void showDialog(String path, {DialogConfig config = const DialogConfig()}) {
    _stack.add(_parseEntry(
      path,
      presentation: RoutePresentation.dialog,
      dialogConfig: config,
    ));
    notifyListeners();
  }

  /// Presents an arbitrary [child] widget as a dialog.
  void showDialogWidget(Widget child,
      {DialogConfig config = const DialogConfig()}) {
    _stack.add(_RouteEntry(
      '__dialog_${_syntheticId++}',
      presentation: RoutePresentation.dialog,
      dialogConfig: config,
      inlineChild: child,
    ));
    notifyListeners();
  }

  /// Replaces the entire stack with a single entry for [path].
  void switchTo(String path) => navigate(path, replace: true);

  /// Removes the topmost entry from the stack, if possible.
  void pop() {
    if (canPop) {
      _stack.removeLast();
      notifyListeners();
    }
  }

  // --- Imperative methods (bypass stack, return results) ---

  /// Imperatively pushes the route for [path] and returns a [Future] with the result.
  Future<T?> push<T>(String path) {
    final uri = Uri.parse(path);
    final match = _matchPath(uri.path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return navigator!.push<T>(MaterialPageRoute(
      builder: (_) => route.builder(params, uri.queryParameters),
    ));
  }

  /// Imperatively pushes an arbitrary [child] widget and returns a [Future] with the result.
  Future<T?> pushWidget<T>(Widget child) {
    return navigator!.push<T>(MaterialPageRoute(
      builder: (_) => child,
    ));
  }

  /// Imperatively shows the route for [path] as a bottom sheet, returning a [Future].
  Future<T?> pushBottomSheet<T>(
    String path, {
    BottomSheetConfig config = const BottomSheetConfig(),
  }) {
    final uri = Uri.parse(path);
    final match = _matchPath(uri.path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return _showModalBottomSheet<T>(
      child: route.builder(params, uri.queryParameters),
      config: config,
    );
  }

  /// Imperatively shows an arbitrary [child] widget as a bottom sheet, returning a [Future].
  Future<T?> pushBottomSheetWidget<T>(
    Widget child, {
    BottomSheetConfig config = const BottomSheetConfig(),
  }) {
    return _showModalBottomSheet<T>(child: child, config: config);
  }

  Future<T?> _showModalBottomSheet<T>({
    required Widget child,
    required BottomSheetConfig config,
  }) {
    final context = navigatorKey.currentContext!;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: config.backgroundColor,
      elevation: config.elevation,
      shape: config.shape,
      clipBehavior: config.clipBehavior,
      constraints: config.constraints,
      barrierColor: config.modalBarrierColor,
      isDismissible: config.isDismissible,
      enableDrag: config.enableDrag,
      showDragHandle: config.showDragHandle,
      anchorPoint: config.anchorPoint,
      useSafeArea: config.useSafeArea,
      sheetAnimationStyle: config.sheetAnimationStyle,
      builder: (_) => FractionallySizedBox(
        heightFactor: config.heightFactor,
        child: child,
      ),
    );
  }

  /// Imperatively shows the route for [path] as a dialog, returning a [Future].
  Future<T?> pushDialog<T>(
    String path, {
    DialogConfig config = const DialogConfig(),
  }) {
    final uri = Uri.parse(path);
    final match = _matchPath(uri.path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return _showDialog<T>(
        child: route.builder(params, uri.queryParameters), config: config);
  }

  /// Imperatively shows an arbitrary [child] widget as a dialog, returning a [Future].
  Future<T?> pushDialogWidget<T>(
    Widget child, {
    DialogConfig config = const DialogConfig(),
  }) {
    return _showDialog<T>(child: child, config: config);
  }

  Future<T?> _showDialog<T>({
    required Widget child,
    required DialogConfig config,
  }) {
    final context = navigatorKey.currentContext!;
    return showAdaptiveDialog<T>(
      context: context,
      barrierDismissible: config.barrierDismissible,
      barrierColor: config.barrierColor,
      barrierLabel: config.barrierLabel,
      anchorPoint: config.anchorPoint,
      requestFocus: config.requestFocus,
      traversalEdgeBehavior: config.traversalEdgeBehavior,
      builder: (_) => child,
    );
  }

  /// Pops entries until [path] is at the top of the stack.
  ///
  /// When [inclusive] is `true`, the entry matching [path] is also removed.
  void popUntil(String path, {bool inclusive = false}) {
    while (canPop && _stack.last.path != path) {
      _stack.removeLast();
    }
    if (inclusive && canPop && _stack.last.path == path) {
      _stack.removeLast();
    }
    notifyListeners();
  }

  /// Pops entries until [predicate] returns `true` for the top entry's path.
  ///
  /// When [inclusive] is `true`, the matching entry is also removed.
  void popUntilWhere(bool Function(String path) predicate,
      {bool inclusive = false}) {
    while (canPop && !predicate(_stack.last.path)) {
      _stack.removeLast();
    }
    if (inclusive && canPop && predicate(_stack.last.path)) {
      _stack.removeLast();
    }
    notifyListeners();
  }

  (NavRoute, Map<String, String>)? _matchPath(String path) {
    for (final route in routes) {
      final params = _extractParams(route.path, path);
      if (params != null) return (route, params);
    }
    return null;
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
