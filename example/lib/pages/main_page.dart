import 'package:flutter/material.dart';
import 'package:navhost/navhost.dart';

import 'details_page.dart';
import 'home_page.dart';
import 'showcase_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _tabs = ['/home', '/showcase'];
  int _currentIndex = 0;

  final _tabController = NavController(
    initialRoute: '/home',
    routes: [
      NavRoute('/home', (_) => const HomePage()),
      NavRoute('/showcase', (_) => const ShowcasePage()),
      NavRoute('/item/:id', (p) => DetailsPage(itemId: p['id']!)),
    ],
  );

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_onNavChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onNavChanged);
    super.dispose();
  }

  void _onNavChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavHost(
        navController: _tabController,
        defaultEnterTransition: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        defaultTransitionDuration: const Duration(milliseconds: 200),
      ),
      bottomNavigationBar: _tabController.currentEntry.path.contains('/item/')
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                _tabController.switchTo(_tabs[index]);
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.science),
                  label: 'Showcase',
                ),
              ],
            ),
    );
  }
}
