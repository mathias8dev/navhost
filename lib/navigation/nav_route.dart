import 'package:flutter/widgets.dart';

typedef NavWidgetBuilder = Widget Function(Map<String, String> params);
typedef NavTransitionBuilder = Widget Function(
    Widget child, Animation<double> animation);

class NavRoute {
  final String path;
  final NavWidgetBuilder builder;
  final NavTransitionBuilder? transition;
  final Duration transitionDuration;

  const NavRoute(
    this.path,
    this.builder, {
    this.transition,
    this.transitionDuration = const Duration(milliseconds: 300),
  });
}
