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

  String get location => Uri(
        path: path,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      ).toString();

  bool hasSameLocationAs(_RouteEntry other) {
    if (path != other.path || queryParams.length != other.queryParams.length) {
      return false;
    }
    for (final entry in queryParams.entries) {
      if (other.queryParams[entry.key] != entry.value) return false;
    }
    return true;
  }
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
    final key = ValueKey('$i-${entry.location}');

    Widget? child;
    NavRoute? route;

    if (entry.inlineChild != null) {
      child = entry.inlineChild!;
    } else {
      final match = controller._matchPath(entry.path);
      if (match == null) {
        final notFoundBuilder = controller.notFoundBuilder;
        child = notFoundBuilder?.call(entry.path, entry.queryParams) ??
            _DefaultNotFoundPage(location: entry.location);
      } else {
        final (matchedRoute, params) = match;
        route = matchedRoute;
        child = matchedRoute.builder(params, entry.queryParams);
      }
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

class _DefaultNotFoundPage extends StatelessWidget {
  final String location;

  const _DefaultNotFoundPage({required this.location});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Text(
        'Route not found: $location',
        style: textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
