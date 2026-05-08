part of 'nav_controller.dart';

/// A widget that renders the current navigation stack managed by a [NavController].
///
/// Place this in your widget tree wherever you want route content to appear.
/// It listens to [navController] and rebuilds when the back stack changes.
///
/// ```dart
/// NavHost(
///   navController: controller,
///   defaultEnterTransition: (child, animation) =>
///       FadeTransition(opacity: animation, child: child),
/// );
/// ```
class NavHost extends StatefulWidget {
  /// The controller that manages the navigation back stack.
  final NavController navController;

  /// Default enter transition used when a route does not specify its own.
  final NavTransitionBuilder? defaultEnterTransition;

  /// Default exit transition used when a route does not specify its own.
  final NavTransitionBuilder? defaultExitTransition;

  /// Default pop-enter transition used when a route does not specify its own.
  final NavTransitionBuilder? defaultPopEnterTransition;

  /// Default pop-exit transition used when a route does not specify its own.
  final NavTransitionBuilder? defaultPopExitTransition;

  /// Duration of the default forward navigation transition.
  final Duration defaultTransitionDuration;

  /// Duration of the default reverse (pop) transition.
  final Duration? defaultReverseTransitionDuration;

  /// Creates a [NavHost] that displays pages from [navController].
  const NavHost({
    super.key,
    required this.navController,
    this.defaultEnterTransition,
    this.defaultExitTransition,
    this.defaultPopEnterTransition,
    this.defaultPopExitTransition,
    this.defaultTransitionDuration = const Duration(milliseconds: 300),
    this.defaultReverseTransitionDuration,
  });

  @override
  State<NavHost> createState() => _NavHostState();
}

class _NavHostState extends State<NavHost> {
  @override
  void initState() {
    super.initState();
    widget.navController.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(NavHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navController != widget.navController) {
      oldWidget.navController.removeListener(_onChanged);
      widget.navController.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.navController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.navController.canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.navController.pop();
        }
      },
      child: _NavControllerScope(
        controller: widget.navController,
        child: Navigator(
          key: widget.navController.navigatorKey,
          pages: _buildPages(
            widget.navController,
            defaultEnterTransition: widget.defaultEnterTransition,
            defaultExitTransition: widget.defaultExitTransition,
            defaultPopEnterTransition: widget.defaultPopEnterTransition,
            defaultPopExitTransition: widget.defaultPopExitTransition,
            defaultTransitionDuration: widget.defaultTransitionDuration,
            defaultReverseTransitionDuration:
                widget.defaultReverseTransitionDuration,
          ),
          onDidRemovePage: (_) => widget.navController.pop(),
        ),
      ),
    );
  }
}
