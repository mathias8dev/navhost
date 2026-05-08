/// A lightweight, declarative navigation library for Flutter.
///
/// NavHost provides a simple yet powerful navigation system built on top of
/// Flutter's [Navigator] 2.0 API. It supports path-based routing with
/// parameters, custom transitions, bottom sheets, dialogs, and navigation
/// interceptors.
///
/// ```dart
/// final controller = NavController(
///   routes: [
///     NavRoute('/', (params) => const HomePage()),
///     NavRoute('/details/:id', (params) => DetailPage(id: params['id']!)),
///   ],
/// );
///
/// // Use NavHost as a widget
/// NavHost(navController: controller);
/// ```
library;

export 'src/bottom_sheet_config.dart';
export 'src/context_extensions.dart';
export 'src/dialog_config.dart';
export 'src/nav_back_stack_entry.dart';
export 'src/nav_controller.dart';
export 'src/nav_interceptor.dart';
export 'src/nav_route.dart';
