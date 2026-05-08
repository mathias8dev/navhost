part of 'nav_controller.dart';

class NavHost extends StatefulWidget {
  final NavController navController;
  final NavTransitionBuilder? defaultEnterTransition;
  final NavTransitionBuilder? defaultExitTransition;
  final NavTransitionBuilder? defaultPopEnterTransition;
  final NavTransitionBuilder? defaultPopExitTransition;
  final Duration defaultTransitionDuration;
  final Duration? defaultReverseTransitionDuration;

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
