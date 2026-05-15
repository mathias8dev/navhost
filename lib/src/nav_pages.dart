part of 'nav_controller.dart';

class _DialogPage extends Page {
  final Widget child;
  final DialogConfig config;

  const _DialogPage({
    super.key,
    required this.child,
    required this.config,
  });

  @override
  Route createRoute(BuildContext context) {
    return DialogRoute(
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
  }
}

class _BottomSheetPage extends Page {
  final Widget child;
  final BottomSheetConfig config;

  const _BottomSheetPage({
    super.key,
    required this.child,
    required this.config,
  });

  @override
  Route createRoute(BuildContext context) {
    return ModalBottomSheetRoute(
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
          ? FractionallySizedBox(heightFactor: config.heightFactor!, child: child)
          : child,
    );
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

  const _TransitionPage({
    super.key,
    required this.child,
    required this.enterTransition,
    this.exitTransition,
    this.popEnterTransition,
    this.popExitTransition,
    required this.duration,
    required this.reverseDuration,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (_, _, _) => child,
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
  }
}
