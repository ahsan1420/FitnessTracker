import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'home.dart';
import 'progress_screen.dart';
import 'workout_history_screen.dart';
import 'profile_hub_screen.dart';

class RootNav extends StatefulWidget {
  const RootNav({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const HomeScreen(),
      const ProgressScreen(),
      const WorkoutHistoryScreen(),
      ProfileHubScreen(settings: widget.settings),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

