/// A snapshot of a single entry in the navigation back stack.
///
/// Each entry records the [path] that was navigated to and any route
/// [params] extracted from path segments (e.g. `/user/:id` yields `{id: "42"}`).
class NavBackStackEntry {
  /// The route path for this entry (e.g. `/home` or `/user/42`).
  final String path;

  /// Path parameters extracted from dynamic segments.
  final Map<String, String> params;

  /// Creates a back stack entry for the given [path] and optional [params].
  const NavBackStackEntry({required this.path, this.params = const {}});

  @override
  String toString() => 'NavBackStackEntry(path: $path, params: $params)';
}
