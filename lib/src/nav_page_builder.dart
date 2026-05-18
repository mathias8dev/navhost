part of 'nav_controller.dart';

/// How a route entry is presented in the navigation stack.
enum RoutePresentation {
  /// Standard full-screen page push.
  push,

  /// Presented as a modal bottom sheet.
  bottomSheet,

  /// Presented as a dialog overlay.
  dialog,
}

class _RouteEntry {
  final String path;
  final Map<String, String> queryParams;
  final RoutePresentation presentation;
  final BottomSheetConfig? bottomSheetConfig;
  final DialogConfig? dialogConfig;
  final Widget? inlineChild;
  final Completer<dynamic>? completer;

  const _RouteEntry(
    this.path, {
    this.queryParams = const {},
    this.presentation = RoutePresentation.push,
    this.bottomSheetConfig,
    this.dialogConfig,
    this.inlineChild,
    this.completer,
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
      child = matchedRoute.builder(params, entry.queryParams);
    }

    switch (entry.presentation) {
      case RoutePresentation.bottomSheet:
        pages.add(_BottomSheetPage(
          key: key,
          child: child,
          config: entry.bottomSheetConfig ?? const BottomSheetConfig(),
          completer: entry.completer,
        ));
      case RoutePresentation.dialog:
        pages.add(_DialogPage(
          key: key,
          child: child,
          config: entry.dialogConfig ?? const DialogConfig(),
          completer: entry.completer,
        ));
      case RoutePresentation.push:
        final enter = route?.enterTransition ?? defaultEnterTransition;
        if (enter != null) {
          final duration =
              route?.transitionDuration ?? defaultTransitionDuration;
          pages.add(_TransitionPage(
            key: key,
            child: child,
            enterTransition: enter,
            exitTransition: route?.exitTransition ?? defaultExitTransition,
            popEnterTransition:
                route?.popEnterTransition ?? defaultPopEnterTransition,
            popExitTransition:
                route?.popExitTransition ?? defaultPopExitTransition,
            duration: duration,
            reverseDuration: route?.reverseTransitionDuration ??
                defaultReverseTransitionDuration ??
                duration,
            completer: entry.completer,
          ));
        } else {
          pages.add(_MaterialPage(
            key: key,
            child: child,
            completer: entry.completer,
          ));
        }
    }
  }

  return pages;
}
