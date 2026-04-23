import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_settings.dart';
import 'authservices.dart';
import 'help_screen.dart';
import 'update_email_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              subtitle: Text(settings.darkMode ? 'Black theme' : 'White theme'),
              trailing: Switch(
                value: settings.darkMode,
                onChanged: (v) => settings.darkMode = v,
              ),
            ),
            const Divider(height: 24),
            if (user != null)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data();
                  final hour = (data?['reminderHour'] as num?)?.toInt();
                  final minute = (data?['reminderMinute'] as num?)?.toInt();
                  final has = hour != null && minute != null;
                  final label = has
                      ? TimeOfDay(hour: hour, minute: minute).format(context)
                      : 'Not set';

                  return ListTile(
                    leading: const Icon(Icons.alarm_outlined),
                    title: const Text('Reminder time'),
                    subtitle: Text(label),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: has
                            ? TimeOfDay(hour: hour, minute: minute)
                            : TimeOfDay.now(),
                      );
                      if (picked == null) return;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                        'reminderHour': picked.hour,
                        'reminderMinute': picked.minute,
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    },
                  );
                },
              )
            else
              const ListTile(
                leading: Icon(Icons.alarm_outlined),
                title: Text('Reminder time'),
                subtitle: Text('Sign in to configure reminders'),
              ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Update email'),
              subtitle: Text(user?.email ?? '—'),
              onTap: user == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UpdateEmailScreen(),
                        ),
                      );
                    },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('About / Help'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                );
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                await auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

