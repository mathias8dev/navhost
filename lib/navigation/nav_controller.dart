import 'package:flutter/material.dart';

import 'bottom_sheet_config.dart';
import 'dialog_config.dart';
import 'nav_route.dart';
export 'bottom_sheet_config.dart' show BottomSheetConfig;
export 'dialog_config.dart' show DialogConfig;
export 'nav_route.dart' show NavTransitionBuilder;

part 'nav_pages.dart';
part 'nav_router_delegate.dart';
part 'nav_host.dart';

enum RoutePresentation { push, bottomSheet, dialog }

class _RouteEntry {
  final String path;
  final RoutePresentation presentation;
  final BottomSheetConfig? bottomSheetConfig;
  final DialogConfig? dialogConfig;
  final Widget? inlineChild;

  const _RouteEntry(
    this.path, {
    this.presentation = RoutePresentation.push,
    this.bottomSheetConfig,
    this.dialogConfig,
    this.inlineChild,
  });
}

List<Page> _buildPages(
  NavController controller, {
  NavTransitionBuilder? defaultEnterTransition,
  NavTransitionBuilder? defaultExitTransition,
  NavTransitionBuilder? defaultPopEnterTransition,
  NavTransitionBuilder? defaultPopExitTransition,
  Duration defaultTransitionDuration = const Duration(milliseconds: 300),
  Duration? defaultReverseTransitionDuration,
}) {
  final pages = <Page>[];

  for (var i = 0; i < controller._stack.length; i++) {
    final entry = controller._stack[i];
    final key = ValueKey('$i-${entry.path}');

    Widget? child;
    NavRoute? route;

    if (entry.inlineChild != null) {
      child = entry.inlineChild!;
    } else {
      final match = controller._matchPath(entry.path);
      if (match == null) continue;
      final (matchedRoute, params) = match;
      route = matchedRoute;
      child = matchedRoute.builder(params);
    }

    switch (entry.presentation) {
      case RoutePresentation.bottomSheet:
        pages.add(_BottomSheetPage(
          key: key,
          child: child,
          config: entry.bottomSheetConfig ?? const BottomSheetConfig(),
        ));
      case RoutePresentation.dialog:
        pages.add(_DialogPage(
          key: key,
          child: child,
          config: entry.dialogConfig ?? const DialogConfig(),
        ));
      case RoutePresentation.push:
        final enter =
            route?.enterTransition ?? defaultEnterTransition;
        if (enter != null) {
          final duration =
              route?.transitionDuration ?? defaultTransitionDuration;
          pages.add(_TransitionPage(
            key: key,
            child: child,
            enterTransition: enter,
            exitTransition:
                route?.exitTransition ?? defaultExitTransition,
            popEnterTransition:
                route?.popEnterTransition ?? defaultPopEnterTransition,
            popExitTransition:
                route?.popExitTransition ?? defaultPopExitTransition,
            duration: duration,
            reverseDuration: route?.reverseTransitionDuration ??
                defaultReverseTransitionDuration ??
                duration,
          ));
        } else {
          pages.add(MaterialPage(key: key, child: child));
        }
    }
  }

  return pages;
}

class NavController extends ChangeNotifier {
  final List<NavRoute> routes;
  final String initialRoute;
  final List<_RouteEntry> _stack;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavController({
    required this.routes,
    this.initialRoute = '/',
  }) : _stack = [_RouteEntry(initialRoute)];

  late final delegate = _NavRouterDelegate(this);
  late final parser = _NavRouteInformationParser();

  NavigatorState? get navigator => navigatorKey.currentState;

  String get currentPath => _stack.last.path;
  bool get canPop => _stack.length > 1;

  void navigate(
    String path, {
    bool replace = false,
    bool launchSingleTop = false,
    String? popUpTo,
    bool popUpToInclusive = false,
  }) {
    if (launchSingleTop && currentPath == path) return;

    if (replace) {
      _stack
        ..clear()
        ..add(_RouteEntry(path));
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
      _stack.add(_RouteEntry(path));
    }
    notifyListeners();
  }

  int _syntheticId = 0;

  void navigateWidget(Widget child) {
    _stack.add(_RouteEntry(
      '__page_${_syntheticId++}',
      inlineChild: child,
    ));
    notifyListeners();
  }

  void showBottomSheet(String path,
      {BottomSheetConfig config = const BottomSheetConfig()}) {
    _stack.add(_RouteEntry(
      path,
      presentation: RoutePresentation.bottomSheet,
      bottomSheetConfig: config,
    ));
    notifyListeners();
  }

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

  void showDialog(String path, {DialogConfig config = const DialogConfig()}) {
    _stack.add(_RouteEntry(
      path,
      presentation: RoutePresentation.dialog,
      dialogConfig: config,
    ));
    notifyListeners();
  }

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

  void switchTo(String path) => navigate(path, replace: true);

  void pop() {
    if (canPop) {
      _stack.removeLast();
      notifyListeners();
    }
  }

  // --- Imperative methods (bypass stack, return results) ---

  Future<T?> push<T>(String path) {
    final match = _matchPath(path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return navigator!.push<T>(MaterialPageRoute(
      builder: (_) => route.builder(params),
    ));
  }

  Future<T?> pushWidget<T>(Widget child) {
    return navigator!.push<T>(MaterialPageRoute(
      builder: (_) => child,
    ));
  }

  Future<T?> pushBottomSheet<T>(
    String path, {
    BottomSheetConfig config = const BottomSheetConfig(),
  }) {
    final match = _matchPath(path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return _showModalBottomSheet<T>(
      child: route.builder(params),
      config: config,
    );
  }

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

  Future<T?> pushDialog<T>(
    String path, {
    DialogConfig config = const DialogConfig(),
  }) {
    final match = _matchPath(path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return _showDialog<T>(child: route.builder(params), config: config);
  }

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

  void popUntil(String path, {bool inclusive = false}) {
    while (canPop && _stack.last.path != path) {
      _stack.removeLast();
    }
    if (inclusive && canPop && _stack.last.path == path) {
      _stack.removeLast();
    }
    notifyListeners();
  }

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
