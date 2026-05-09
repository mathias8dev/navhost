part of 'nav_controller.dart';

class _NavRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  final NavController controller;

  @override
  GlobalKey<NavigatorState> get navigatorKey => controller.navigatorKey;

  _NavRouterDelegate(this.controller) {
    controller.addListener(notifyListeners);
  }

  @override
  String get currentConfiguration => controller.currentPath;

  @override
  Future<void> setNewRoutePath(String configuration) async {
    controller._stack.clear();
    final entry = NavController._parseEntry(configuration);
    if (entry.path != controller.initialRoute) {
      controller._stack.add(NavController._parseEntry(controller.initialRoute));
    }
    controller._stack.add(entry);
  }

  @override
  Widget build(BuildContext context) {
    return _NavControllerScope(
      controller: controller,
      child: Navigator(
        key: navigatorKey,
        pages: _buildPages(controller),
        onDidRemovePage: (_) => controller.pop(),
      ),
    );
  }
}

class _NavRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation.uri.toString();
  }

  @override
  RouteInformation? restoreRouteInformation(String configuration) {
    return RouteInformation(uri: Uri.parse(configuration));
  }
}
