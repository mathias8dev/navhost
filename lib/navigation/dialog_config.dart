import 'package:flutter/material.dart';

class DialogConfig {
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool useSafeArea;
  final Offset? anchorPoint;
  final bool? requestFocus;
  final TraversalEdgeBehavior? traversalEdgeBehavior;

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
