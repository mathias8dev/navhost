part of 'nav_controller.dart';

extension NavControllerOverlays on NavController {
  /// Pushes an arbitrary [child] widget onto the declarative stack.
  Future<T?> navigateWidget<T extends Object?>(Widget child) {
    final completer = Completer<T?>();
    _stack.add(_RouteEntry(
      '__page_${_syntheticId++}',
      inlineChild: child,
      completer: completer,
    ));
    _notify();
    return completer.future;
  }

  /// Presents a route identified by [path] as a modal bottom sheet.
  Future<T?> showBottomSheet<T extends Object?>(String path,
      {BottomSheetConfig config = const BottomSheetConfig()}) {
    final resolved = _applyInterceptors(path);
    if (resolved == null) return Future.value(null);
    final completer = Completer<T?>();
    _stack.add(NavController._parseEntry(
      resolved,
      presentation: RoutePresentation.bottomSheet,
      bottomSheetConfig: config,
      completer: completer,
    ));
    _notify();
    return completer.future;
  }

  /// Presents an arbitrary [child] widget as a modal bottom sheet.
  Future<T?> showBottomSheetWidget<T extends Object?>(Widget child,
      {BottomSheetConfig config = const BottomSheetConfig()}) {
    final completer = Completer<T?>();
    _stack.add(_RouteEntry(
      '__sheet_${_syntheticId++}',
      presentation: RoutePresentation.bottomSheet,
      bottomSheetConfig: config,
      inlineChild: child,
      completer: completer,
    ));
    _notify();
    return completer.future;
  }

  /// Presents a route identified by [path] as a dialog.
  Future<T?> showDialog<T extends Object?>(String path,
      {DialogConfig config = const DialogConfig()}) {
    final resolved = _applyInterceptors(path);
    if (resolved == null) return Future.value(null);
    final completer = Completer<T?>();
    _stack.add(NavController._parseEntry(
      resolved,
      presentation: RoutePresentation.dialog,
      dialogConfig: config,
      completer: completer,
    ));
    _notify();
    return completer.future;
  }

  /// Presents an arbitrary [child] widget as a dialog.
  Future<T?> showDialogWidget<T extends Object?>(Widget child,
      {DialogConfig config = const DialogConfig()}) {
    final completer = Completer<T?>();
    _stack.add(_RouteEntry(
      '__dialog_${_syntheticId++}',
      presentation: RoutePresentation.dialog,
      dialogConfig: config,
      inlineChild: child,
      completer: completer,
    ));
    _notify();
    return completer.future;
  }
}
