import 'package:flutter/material.dart';

/// Configuration for presenting a route as a dialog.
///
/// Wraps the parameters accepted by [showAdaptiveDialog], allowing them
/// to be passed through the navigation API.
class DialogConfig {
  /// Whether tapping the barrier dismisses the dialog.
  final bool barrierDismissible;

  /// Color of the scrim behind the dialog.
  final Color? barrierColor;

  /// Semantic label for the modal barrier.
  final String? barrierLabel;

  /// Whether the dialog respects [SafeArea] insets.
  final bool useSafeArea;

  /// Focal point for aligning the dialog on the screen.
  final Offset? anchorPoint;

  /// Whether the dialog should receive focus when opened.
  final bool? requestFocus;

  /// Controls focus traversal behavior at the dialog edges.
  final TraversalEdgeBehavior? traversalEdgeBehavior;

  /// Creates a dialog configuration with sensible defaults.
  const DialogConfig({
    this.barrierDismissible = true,
    this.barrierColor = Colors.black54,
    this.barrierLabel,
    this.useSafeArea = true,
    this.anchorPoint,
    this.requestFocus,
    this.traversalEdgeBehavior,
  });
}
