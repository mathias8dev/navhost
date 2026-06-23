/// A snapshot of a single entry in the navigation back stack.
///
/// Each entry records the [path] that was navigated to, any route
/// [params] extracted from path segments (e.g. `/user/:id` yields `{id: "42"}`),
/// and any [queryParams] from the URL query string.
class NavBackStackEntry {
  /// The route path for this entry (e.g. `/home` or `/user/42`).
  final String path;

  /// Path parameters extracted from dynamic segments.
  final Map<String, String> params;

  /// Query parameters from the URL (e.g. `?ref=email` yields `{ref: "email"}`).
  final Map<String, String> queryParams;

  /// The full URL location for this entry, including query parameters.
  String get location => Uri(
        path: path,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      ).toString();

  /// Creates a back stack entry for the given [path] and optional [params] and [queryParams].
  const NavBackStackEntry({
    required this.path,
    this.params = const {},
    this.queryParams = const {},
  });

  @override
  String toString() =>
      'NavBackStackEntry(path: $path, params: $params, queryParams: $queryParams)';
}
