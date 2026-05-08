import 'package:flutter/material.dart';

import 'navigation/nav_controller.dart';
import 'navigation/nav_route.dart';
import 'pages/details_page.dart';
import 'pages/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navController = NavController(
    routes: [
      NavRoute('/', (_) => const MainPage()),
      NavRoute('/item/:id', (params) => DetailsPage(itemId: params['id']!)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Navigator 2.0 Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerDelegate: _navController.delegate,
      routeInformationParser: _navController.parser,
    );
  }
}
