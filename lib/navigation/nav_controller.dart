import 'package:flutter/material.dart';

import 'bottom_sheet_config.dart';
import 'nav_route.dart';
export 'bottom_sheet_config.dart' show BottomSheetConfig;
export 'nav_route.dart' show NavTransitionBuilder;

// --- Presentation mode (decided at navigate call site) ---

enum RoutePresentation { push, bottomSheet }

class _RouteEntry {
  final String path;
  final RoutePresentation presentation;
  final BottomSheetConfig? bottomSheetConfig;
  final Widget? inlineChild;

  const _RouteEntry(
    this.path, {
    this.presentation = RoutePresentation.push,
    this.bottomSheetConfig,
    this.inlineChild,
  });
}

// --- NavController ---

class NavController extends ChangeNotifier {
  final List<NavRoute> routes;
  final String initialRoute;
  final List<_RouteEntry> _stack;

  NavController({
    required this.routes,
    this.initialRoute = '/',
  }) : _stack = [_RouteEntry(initialRoute)];

  late final delegate = _NavRouterDelegate(this);
  late final parser = _NavRouteInformationParser();

  GlobalKey<NavigatorState> get navigatorKey => delegate.navigatorKey;
  NavigatorState? get navigator => navigatorKey.currentState;

  String get currentPath => _stack.last.path;
  bool get canPop => _stack.length > 1;

  void navigate(String path,
      {RoutePresentation presentation = RoutePresentation.push}) {
    _stack.add(_RouteEntry(path, presentation: presentation));
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

  void showBottomSheet(String path, {BottomSheetConfig config = const BottomSheetConfig()}) {
    _stack.add(_RouteEntry(
      path,
      presentation: RoutePresentation.bottomSheet,
      bottomSheetConfig: config,
    ));
    notifyListeners();
  }

  void showBottomSheetWidget(Widget child, {BottomSheetConfig config = const BottomSheetConfig()}) {
    _stack.add(_RouteEntry(
      '__sheet_${_syntheticId++}',
      presentation: RoutePresentation.bottomSheet,
      bottomSheetConfig: config,
      inlineChild: child,
    ));
    notifyListeners();
  }

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

  void popUntil(String path) {
    while (canPop && _stack.last.path != path) {
      _stack.removeLast();
    }
    notifyListeners();
  }

  void popUntilWhere(bool Function(String path) predicate) {
    while (canPop && !predicate(_stack.last.path)) {
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

// --- InheritedWidget (private, accessed via NavController.of) ---

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

// --- RouterDelegate (wraps Navigator 2.0) ---

class _NavRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  final NavController controller;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  _NavRouterDelegate(this.controller) {
    controller.addListener(notifyListeners);
  }

  @override
  String get currentConfiguration => controller.currentPath;

  @override
  Future<void> setNewRoutePath(String configuration) async {
    controller._stack.clear();
    if (configuration != controller.initialRoute) {
      controller._stack.add(_RouteEntry(controller.initialRoute));
    }
    controller._stack.add(_RouteEntry(configuration));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Page>[];

    for (var i = 0; i < controller._stack.length; i++) {
      final entry = controller._stack[i];
      final key = ValueKey('$i-${entry.path}');

      if (entry.inlineChild != null) {
        if (entry.presentation == RoutePresentation.bottomSheet) {
          pages.add(_BottomSheetPage(
            key: key,
            child: entry.inlineChild!,
            config: entry.bottomSheetConfig ?? const BottomSheetConfig(),
          ));
        } else {
          pages.add(MaterialPage(key: key, child: entry.inlineChild!));
        }
        continue;
      }

      final match = controller._matchPath(entry.path);
      if (match == null) continue;

      final (route, params) = match;
      final child = route.builder(params);

      switch (entry.presentation) {
        case RoutePresentation.bottomSheet:
          pages.add(_BottomSheetPage(
            key: key,
            child: child,
            config: entry.bottomSheetConfig ?? const BottomSheetConfig(),
          ));
        case RoutePresentation.push:
          if (route.transition != null) {
            pages.add(_TransitionPage(
              key: key,
              child: child,
              transition: route.transition!,
              duration: route.transitionDuration,
            ));
          } else {
            pages.add(MaterialPage(key: key, child: child));
          }
      }
    }

    return _NavControllerScope(
      controller: controller,
      child: Navigator(
        key: navigatorKey,
        pages: pages,
        onDidRemovePage: (_) => controller.pop(),
      ),
    );
  }
}

// --- Custom Page as bottom sheet ---

class _BottomSheetPage extends Page {
  final Widget child;
  final BottomSheetConfig config;

  const _BottomSheetPage({
    super.key,
    required this.child,
    required this.config,
  });

  @override
  Route createRoute(BuildContext context) {
    
    return ModalBottomSheetRoute(
      settings: this,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio:
          config.scrollControlDisabledMaxHeightRatio,
      barrierLabel: config.barrierLabel,
      barrierOnTapHint: config.barrierOnTapHint,
      backgroundColor: config.backgroundColor,
      elevation: config.elevation,
      shape: config.shape,
      clipBehavior: config.clipBehavior,
      constraints: config.constraints,
      modalBarrierColor: config.modalBarrierColor,
      isDismissible: config.isDismissible,
      enableDrag: config.enableDrag,
      showDragHandle: config.showDragHandle,
      requestFocus: config.requestFocus,
      transitionAnimationController: config.transitionAnimationController,
      anchorPoint: config.anchorPoint,
      useSafeArea: config.useSafeArea,
      sheetAnimationStyle: config.sheetAnimationStyle,
      builder: (_) => FractionallySizedBox(
        heightFactor: config.heightFactor,
        child: child,
      ),
    );
  }
}

// --- Custom Page with transition ---

class _TransitionPage extends Page {
  final Widget child;
  final NavTransitionBuilder transition;
  final Duration duration;

  const _TransitionPage({
    super.key,
    required this.child,
    required this.transition,
    required this.duration,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) =>
          transition(child, animation),
    );
  }
}

// --- RouteInformationParser ---

class _NavRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation.uri.path;
  }

  @override
  RouteInformation? restoreRouteInformation(String configuration) {
    return RouteInformation(uri: Uri.parse(configuration));
  }
}
