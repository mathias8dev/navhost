import 'package:flutter/widgets.dart';

import 'nav_controller.dart';

extension NavContextExtension on BuildContext {
  NavController get navController => NavController.of(this);
}
