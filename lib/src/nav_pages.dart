part of 'nav_controller.dart';

class _DialogPage extends Page {
  final Widget child;
  final DialogConfig config;
  final Completer<dynamic>? completer;

  const _DialogPage({
    super.key,
    required this.child,
    required this.config,
    this.completer,
  });

  @override
  Route createRoute(BuildContext context) {
    final route = DialogRoute(
      context: context,
      settings: this,
      barrierDismissible: config.barrierDismissible,
      barrierColor: config.barrierColor,
      barrierLabel: config.barrierLabel,
      anchorPoint: config.anchorPoint,
      requestFocus: config.requestFocus,
      traversalEdgeBehavior: config.traversalEdgeBehavior,
      builder: (_) => child,
    );
    if (completer != null) {
      route.popped.then((result) {
        if (!completer!.isCompleted) {
          completer!.complete(result);
        }
      });
    }
    return route;
  }
}

class _BottomSheetPage extends Page {
  final Widget child;
  final BottomSheetConfig config;
  final Completer<dynamic>? completer;

  const _BottomSheetPage({
    super.key,
    required this.child,
    required this.config,
    this.completer,
  });

  @override
  Route createRoute(BuildContext context) {
    final route = ModalBottomSheetRoute(
      settings: this,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio:
          config.scrollControlDisabledMaxHeightRatio,
      barrierLabel: config.barrierLabel,
      barrierOnTapHint: config.barrierOnTapHint,
      backgroundColor: config.backgroundColor,
      elevation: config.elevation,
      shape: config.shape,
      clipBehavior: config.clipBehavior,
      constraints: config.constraints,
      modalBarrierColor: config.modalBarrierColor,
      isDismissible: config.isDismissible,
      enableDrag: config.enableDrag,
      showDragHandle: config.showDragHandle,
      requestFocus: config.requestFocus,
      transitionAnimationController: config.transitionAnimationController,
      anchorPoint: config.anchorPoint,
      useSafeArea: config.useSafeArea,
      sheetAnimationStyle: config.sheetAnimationStyle,
      builder: (_) => config.heightFactor != null
          ? FractionallySizedBox(
              heightFactor: config.heightFactor!, child: child)
          : child,
    );
    if (completer != null) {
      route.popped.then((result) {
        if (!completer!.isCompleted) {
          completer!.complete(result);
        }
      });
    }
    return route;
  }
}

class _TransitionPage extends Page {
  final Widget child;
  final NavTransitionBuilder enterTransition;
  final NavTransitionBuilder? exitTransition;
  final NavTransitionBuilder? popEnterTransition;
  final NavTransitionBuilder? popExitTransition;
  final Duration duration;
  final Duration reverseDuration;
  final Completer<dynamic>? completer;

  const _TransitionPage({
    super.key,
    required this.child,
    required this.enterTransition,
    this.exitTransition,
    this.popEnterTransition,
    this.popExitTransition,
    required this.duration,
    required this.reverseDuration,
    this.completer,
  });

  @override
  Route createRoute(BuildContext context) {
    final route = PageRouteBuilder(
      settings: this,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final primary = animation.status == AnimationStatus.reverse
            ? (popExitTransition ?? enterTransition)
            : enterTransition;
        var result = primary(child, animation);

        final secondary = secondaryAnimation.status == AnimationStatus.reverse
            ? (popEnterTransition ?? exitTransition)
            : exitTransition;
        if (secondary != null) {
          result = secondary(result, secondaryAnimation);
        }

        return result;
      },
    );
    if (completer != null) {
      route.popped.then((result) {
        if (!completer!.isCompleted) {
          completer!.complete(result);
        }
      });
    }
    return route;
  }
}

class _MaterialPage<T> extends MaterialPage<T> {
  final Completer<dynamic>? completer;

  const _MaterialPage({
    required super.child,
    super.key,
    this.completer,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    final route = super.createRoute(context);
    if (completer != null) {
      route.popped.then((result) {
        if (!completer!.isCompleted) {
          completer!.complete(result);
        }
      });
    }
    return route;
  }
}
