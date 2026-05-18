part of 'nav_controller.dart';

/// Inherited widget that lets nested [NavHost]s register their [NavController]
/// with the nearest ancestor [NavHost], enabling the outer [PopScope] to block
/// the system back button while an inner NavHost still has routes to pop.
class _NavHostScope extends InheritedWidget {
  final _NavHostState _state;

  const _NavHostScope({
    required _NavHostState state,
    required super.child,
  }) : _state = state;

  @override
  bool updateShouldNotify(_NavHostScope old) => false;

  static _NavHostState? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_NavHostScope>()?._state;
}

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
  // Child NavControllers registered by nested NavHosts.
  final Set<NavController> _children = {};
  // Cached reference to the parent NavHostState to safely unregister in dispose.
  _NavHostState? _parentState;

  bool get _childCanPop => _children.any((c) => c.canPop);
  bool get _effectiveCanPop => widget.navController.canPop || _childCanPop;

  void _registerChild(NavController child) {
    if (_children.add(child)) {
      child.addListener(_onChildChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _unregisterChild(NavController child) {
    if (_children.remove(child)) {
      child.removeListener(_onChildChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onChildChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.navController.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newParent = _NavHostScope._maybeOf(context);
    if (newParent != _parentState) {
      _parentState?._unregisterChild(widget.navController);
      _parentState = newParent;
      _parentState?._registerChild(widget.navController);
    }
  }

  @override
  void didUpdateWidget(NavHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navController != widget.navController) {
      oldWidget.navController.removeListener(_onChanged);
      widget.navController.addListener(_onChanged);
      _parentState?._unregisterChild(oldWidget.navController);
      _parentState?._registerChild(widget.navController);
    }
  }

  @override
  void dispose() {
    widget.navController.removeListener(_onChanged);
    _parentState?._unregisterChild(widget.navController);
    for (final child in _children) {
      child.removeListener(_onChildChanged);
    }
    _children.clear();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _NavHostScope(
      state: this,
      child: PopScope(
        canPop: !_effectiveCanPop,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (widget.navController.canPop) {
            widget.navController.pop();
          } else {
            // Delegate to nested NavHosts via the inner navigator's maybePop,
            // which finds the child NavHost's PopScope.
            widget.navController.navigator?.maybePop();
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
            onDidRemovePage: (_) => widget.navController._syncStack(),
          ),
        ),
      ),
    );
  }
}
