import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'loginscreen.dart';
import 'root_nav.dart';
import 'verifyscreen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        if (!user.emailVerified) {
          return const Authverify();
        }

        return RootNav(settings: settings);
      },
    );
  }
}

