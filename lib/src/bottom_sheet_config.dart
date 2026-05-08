import 'package:flutter/material.dart';

/// Configuration for presenting a route as a modal bottom sheet.
///
/// Wraps the parameters accepted by [showModalBottomSheet], allowing them
/// to be passed through the navigation API.
class BottomSheetConfig {
  /// Fraction of the screen height the sheet occupies, between 0.0 and 1.0.
  final double heightFactor;

  /// Semantic label for the modal barrier.
  final String? barrierLabel;

  /// Hint text announced when the barrier is tapped.
  final String? barrierOnTapHint;

  /// Background color of the bottom sheet surface.
  final Color? backgroundColor;

  /// Z-coordinate elevation of the bottom sheet.
  final double? elevation;

  /// Shape of the bottom sheet (e.g. rounded corners).
  final ShapeBorder? shape;

  /// Clip behavior applied to the sheet's contents.
  final Clip? clipBehavior;

  /// Size constraints for the bottom sheet.
  final BoxConstraints? constraints;

  /// Color of the scrim behind the bottom sheet.
  final Color? modalBarrierColor;

  /// Whether tapping the barrier dismisses the sheet.
  final bool isDismissible;

  /// Whether the user can drag the sheet to dismiss it.
  final bool enableDrag;

  /// Whether to display a drag handle at the top of the sheet.
  final bool? showDragHandle;

  /// Maximum height ratio when scroll control is disabled.
  final double scrollControlDisabledMaxHeightRatio;

  /// Whether the sheet should receive focus when opened.
  final bool? requestFocus;

  /// Controller for the sheet's entrance and exit animations.
  final AnimationController? transitionAnimationController;

  /// Focal point for aligning the sheet on the screen.
  final Offset? anchorPoint;

  /// Whether the sheet respects [SafeArea] insets.
  final bool useSafeArea;

  /// Custom animation style for the sheet transition.
  final AnimationStyle? sheetAnimationStyle;

  /// Creates a bottom sheet configuration with sensible defaults.
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
