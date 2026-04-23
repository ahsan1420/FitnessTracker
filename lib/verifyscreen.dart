import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authservices.dart';
import 'loginscreen.dart';

class Authverify extends StatefulWidget {
  const Authverify({super.key});

  @override
  State<Authverify> createState() => _AuthverifyState();
}

class _AuthverifyState extends State<Authverify> {
  final AuthService authService = AuthService();

  Future<void> refreshUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null && user.emailVerified) {
      await authService.signOut();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verify your email first')));
      setState(() {});
    }
  }

  Future<void> resendEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email sent again')),
    );
  }

  Future<void> signOut() async {
    await authService.signOut();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - 140),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 80,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Please verify your email first',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.email ?? 'No email found',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: resendEmail,
                      child: const Text('Resend Verification Email'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: refreshUser,
                      child: const Text('I Verified, Refresh'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: signOut, child: const Text('Sign Out')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
