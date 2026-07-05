part of 'nav_controller.dart';

class _NavRouterDelegate extends RouterDelegate<String>
    with
        ChangeNotifier,
        PopNavigatorRouterDelegateMixin<String>,
        WidgetsBindingObserver {
  final NavController controller;
  bool _hasHandledInitialRoutePath = false;

  @override
  GlobalKey<NavigatorState> get navigatorKey => controller.navigatorKey;

  _NavRouterDelegate(this.controller) {
    controller.addListener(notifyListeners);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  String get currentConfiguration => controller.currentPath;

  @override
  Future<void> setInitialRoutePath(String configuration) async {
    if (_hasHandledInitialRoutePath) return;
    _hasHandledInitialRoutePath = true;

    final entry = NavController._parseEntry(configuration);
    final isDefaultPlatformRoute = entry.location == '/';
    final hasCustomInitialRoute = controller.initialRoute != '/';

    if (!kIsWeb && isDefaultPlatformRoute && hasCustomInitialRoute) {
      return;
    }

    await setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    final entry = NavController._parseEntry(configuration);

    for (final e in controller._stack) {
      if (e.completer != null && !e.completer!.isCompleted) {
        e.completer!.complete(null);
      }
    }

    controller._stack
      ..clear()
      ..add(entry);
    controller._notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NavControllerScope(
      controller: controller,
      child: Navigator(
        key: navigatorKey,
        pages: _buildPages(controller),
        onDidRemovePage: (_) => controller._syncStack(),
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
