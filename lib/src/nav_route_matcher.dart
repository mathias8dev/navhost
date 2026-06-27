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
    _ScoredRouteMatch? bestMatch;
    for (var index = 0; index < routes.length; index++) {
      final route = routes[index];
      final params = NavController._extractParams(route.path, path);
      if (params == null) continue;

      final match = _ScoredRouteMatch(
        route: route,
        params: params,
        score: _scoreRoute(route.path),
        declarationIndex: index,
      );
      if (bestMatch == null || match.isMoreSpecificThan(bestMatch)) {
        bestMatch = match;
      }
    }
    if (bestMatch == null) return null;
    return (bestMatch.route, bestMatch.params);
  }

  int _scoreRoute(String pattern) {
    final segments = Uri.parse(pattern).pathSegments;
    var score = segments.length;

    for (final segment in segments) {
      if (segment == '*') {
        score -= 2;
      } else if (segment.startsWith(':')) {
        score += 3;
      } else if (segment.isEmpty) {
        score += 1;
      } else {
        score += 10;
      }
    }
    return score;
  }
}

class _ScoredRouteMatch {
  final NavRoute route;
  final Map<String, String> params;
  final int score;
  final int declarationIndex;

  const _ScoredRouteMatch({
    required this.route,
    required this.params,
    required this.score,
    required this.declarationIndex,
  });

  bool isMoreSpecificThan(_ScoredRouteMatch other) {
    if (score != other.score) return score > other.score;
    return declarationIndex < other.declarationIndex;
  }
}
