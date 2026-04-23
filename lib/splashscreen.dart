import 'dart:async';
import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AuthGate(settings: widget.settings),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.settings.darkMode;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Colors.black, Color(0xFF6C63FF), Color(0xFF8E85FF)]
                : const [Colors.white, Color(0xFF6C63FF), Color(0xFF8E85FF)],
          ),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: Color(0xFF6C63FF),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'FitTracker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Track your fitness journey',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
