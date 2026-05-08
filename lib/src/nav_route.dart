import 'package:flutter/widgets.dart';

/// Builds a widget for a route, receiving the extracted path [params].
typedef NavWidgetBuilder = Widget Function(Map<String, String> params);

/// Builds a transition widget that wraps [child] with an [animation].
typedef NavTransitionBuilder = Widget Function(
    Widget child, Animation<double> animation);

/// Defines a navigable route with an optional custom transition.
///
/// Routes are matched by [path], which may contain dynamic segments
/// prefixed with `:` (e.g. `/user/:id`).
///
/// ```dart
/// NavRoute('/profile/:id', (params) => ProfilePage(id: params['id']!));
/// ```
class NavRoute {
  /// URL-like path pattern, optionally containing `:param` segments.
  final String path;

  /// Builds the widget displayed when this route is active.
  final NavWidgetBuilder builder;

  /// Transition applied to the incoming page when navigating forward.
  final NavTransitionBuilder? enterTransition;

  /// Transition applied to the outgoing page when navigating forward.
  final NavTransitionBuilder? exitTransition;

  /// Transition applied to the incoming page when popping back.
  final NavTransitionBuilder? popEnterTransition;

  /// Transition applied to the outgoing page when popping back.
  final NavTransitionBuilder? popExitTransition;

  /// Duration of the forward navigation transition.
  final Duration? transitionDuration;

  /// Duration of the reverse (pop) transition.
  final Duration? reverseTransitionDuration;

  /// Creates a route that maps [path] to a widget via [builder].
  const NavRoute(
    this.path,
    this.builder, {
    this.enterTransition,
    this.exitTransition,
    this.popEnterTransition,
    this.popExitTransition,
    this.transitionDuration,
    this.reverseTransitionDuration,
  });

  /// Whether this route has a custom enter transition.
  bool get hasTransition => enterTransition != null;
}
