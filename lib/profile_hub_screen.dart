import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'createprofilescreen.dart';
import 'settings_screen.dart';

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit / Update Profile'),
              subtitle: const Text('Name, age, gender, height, weight, goal'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompleteProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle: const Text('Dark mode, sign out, reminders'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(settings: settings),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

