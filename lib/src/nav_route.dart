import 'package:flutter/widgets.dart';

typedef NavWidgetBuilder = Widget Function(Map<String, String> params);
typedef NavTransitionBuilder = Widget Function(
    Widget child, Animation<double> animation);

class NavRoute {
  final String path;
  final NavWidgetBuilder builder;
  final NavTransitionBuilder? enterTransition;
  final NavTransitionBuilder? exitTransition;
  final NavTransitionBuilder? popEnterTransition;
  final NavTransitionBuilder? popExitTransition;
  final Duration? transitionDuration;
  final Duration? reverseTransitionDuration;

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

  bool get hasTransition => enterTransition != null;
}
