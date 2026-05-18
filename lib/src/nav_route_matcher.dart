part of 'nav_controller.dart';

extension NavRouteMatcher on NavController {
  String? _applyInterceptors(String to) {
    var target = to;
    for (final interceptor in interceptors) {
      final result = interceptor.intercept(currentPath, target);
      if (result == currentPath) return null;
      if (result != null) target = result;
    }
    return target;
  }

  (NavRoute, Map<String, String>)? _matchPath(String path) {
    for (final route in routes) {
      final params = NavController._extractParams(route.path, path);
      if (params != null) return (route, params);
    }
    return null;
  }
}
