import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About / Help')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'FitTracker\n\nPlanned features:\n- Weight tracking\n- Water intake\n- Workouts\n- Progress & history\n\nIf you need support, add your contact info here.',
          ),
        ),
      ),
    );
  }
}
