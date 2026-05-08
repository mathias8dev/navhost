import 'package:flutter/widgets.dart';

import 'nav_controller.dart';

/// Convenience extensions on [BuildContext] for accessing navigation.
extension NavContextExtension on BuildContext {
  /// Returns the nearest [NavController] in the widget tree.
  NavController get navController => NavController.of(this);

  /// Returns the [NavigatorState] managed by the nearest [NavController].
  NavigatorState? get navigator => navController.navigator;
}
