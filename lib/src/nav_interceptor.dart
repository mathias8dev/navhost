abstract class NavInterceptor {
  /// Return `null` to allow navigation, or a redirect path.
  String? intercept(String from, String to);
}
