part of 'nav_controller.dart';

extension NavControllerImperative on NavController {
  // --- Imperative methods (bypass stack, return results) ---

  /// Imperatively pushes the route for [path] and returns a [Future] with the result.
  Future<T?> push<T>(String path) {
    final uri = Uri.parse(path);
    final match = _matchPath(uri.path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return navigator!.push<T>(MaterialPageRoute(
      builder: (_) => route.builder(params, uri.queryParameters),
    ));
  }

  /// Imperatively pushes an arbitrary [child] widget and returns a [Future] with the result.
  Future<T?> pushWidget<T>(Widget child) {
    return navigator!.push<T>(MaterialPageRoute(
      builder: (_) => child,
    ));
  }

  /// Imperatively shows the route for [path] as a bottom sheet, returning a [Future].
  Future<T?> pushBottomSheet<T>(
    String path, {
    BottomSheetConfig config = const BottomSheetConfig(),
  }) {
    final uri = Uri.parse(path);
    final match = _matchPath(uri.path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return _showModalBottomSheet<T>(
      child: route.builder(params, uri.queryParameters),
      config: config,
    );
  }

  /// Imperatively shows an arbitrary [child] widget as a bottom sheet, returning a [Future].
  Future<T?> pushBottomSheetWidget<T>(
    Widget child, {
    BottomSheetConfig config = const BottomSheetConfig(),
  }) {
    return _showModalBottomSheet<T>(child: child, config: config);
  }

  Future<T?> _showModalBottomSheet<T>({
    required Widget child,
    required BottomSheetConfig config,
  }) {
    final context = navigatorKey.currentContext!;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: config.backgroundColor,
      elevation: config.elevation,
      shape: config.shape,
      clipBehavior: config.clipBehavior,
      constraints: config.constraints,
      barrierColor: config.modalBarrierColor,
      isDismissible: config.isDismissible,
      enableDrag: config.enableDrag,
      showDragHandle: config.showDragHandle,
      anchorPoint: config.anchorPoint,
      useSafeArea: config.useSafeArea,
      sheetAnimationStyle: config.sheetAnimationStyle,
      builder: (_) => config.heightFactor != null
          ? FractionallySizedBox(
              heightFactor: config.heightFactor!, child: child)
          : child,
    );
  }

  /// Imperatively shows the route for [path] as a dialog, returning a [Future].
  Future<T?> pushDialog<T>(
    String path, {
    DialogConfig config = const DialogConfig(),
  }) {
    final uri = Uri.parse(path);
    final match = _matchPath(uri.path);
    assert(match != null, 'No route found for: $path');
    final (route, params) = match!;
    return _showDialog<T>(
        child: route.builder(params, uri.queryParameters), config: config);
  }

  /// Imperatively shows an arbitrary [child] widget as a dialog, returning a [Future].
  Future<T?> pushDialogWidget<T>(
    Widget child, {
    DialogConfig config = const DialogConfig(),
  }) {
    return _showDialog<T>(child: child, config: config);
  }

  Future<T?> _showDialog<T>({
    required Widget child,
    required DialogConfig config,
  }) {
    final context = navigatorKey.currentContext!;
    return showAdaptiveDialog<T>(
      context: context,
      barrierDismissible: config.barrierDismissible,
      barrierColor: config.barrierColor,
      barrierLabel: config.barrierLabel,
      anchorPoint: config.anchorPoint,
      requestFocus: config.requestFocus,
      traversalEdgeBehavior: config.traversalEdgeBehavior,
      builder: (_) => child,
    );
  }
}
