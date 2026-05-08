/// Intercepts navigation requests before they are applied.
///
/// Implement this class to redirect, block, or modify navigation targets
/// (e.g. for authentication guards or feature flags).
///
/// ```dart
/// class AuthGuard extends NavInterceptor {
///   @override
///   String? intercept(String from, String to) {
///     if (to == '/settings' && !isLoggedIn) return '/login';
///     return null; // allow navigation
///   }
/// }
/// ```
abstract class NavInterceptor {
  /// Called before each navigation.
  ///
  /// Return `null` to allow navigation to [to], or return a different path
  /// to redirect. Returning [from] cancels navigation entirely.
  String? intercept(String from, String to);
}
