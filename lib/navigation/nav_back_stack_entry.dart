class NavBackStackEntry {
  final String path;
  final Map<String, String> params;

  const NavBackStackEntry({required this.path, this.params = const {}});

  @override
  String toString() => 'NavBackStackEntry(path: $path, params: $params)';
}
