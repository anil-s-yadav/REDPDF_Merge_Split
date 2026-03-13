import 'package:flutter/material.dart';

import 'package:stitch/screens/home/home_screen.dart';
import 'package:stitch/screens/profile/profile_screen.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final List<Widget> _pages = [const HomeScreen(), const ProfileScreen()];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 20,
        indicatorColor: colorScheme.primary.withAlpha(60),
        selectedIndex: _currentIndex,

        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },

        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home, color: colorScheme.onSurface),
            label: "",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, color: colorScheme.onSurface),
            label: "",
          ),
        ],
      ),
    );
  }
}
