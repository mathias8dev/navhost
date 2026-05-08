part of 'nav_controller.dart';

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
          ));
        } else {
          pages.add(MaterialPage(key: key, child: child));
        }
    }
  }

  return pages;
}
