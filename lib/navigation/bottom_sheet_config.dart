import 'package:flutter/material.dart';

class BottomSheetConfig {
  final double heightFactor;
  final String? barrierLabel;
  final String? barrierOnTapHint;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  final Color? modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  final bool? showDragHandle;
  final double scrollControlDisabledMaxHeightRatio;
  final bool? requestFocus;
  final AnimationController? transitionAnimationController;
  final Offset? anchorPoint;
  final bool useSafeArea;
  final AnimationStyle? sheetAnimationStyle;

  const BottomSheetConfig({
    this.heightFactor = 0.85,
    this.barrierLabel,
    this.barrierOnTapHint,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    this.showDragHandle,
    this.scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
    this.requestFocus,
    this.transitionAnimationController,
    this.anchorPoint,
    this.useSafeArea = false,
    this.sheetAnimationStyle,
  });
}
