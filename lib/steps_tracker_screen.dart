import 'package:flutter/material.dart';

import 'services/step_tracking_service.dart';
import 'tracking_repository.dart';

class StepsTrackerScreen extends StatefulWidget {
  const StepsTrackerScreen({super.key});

  @override
  State<StepsTrackerScreen> createState() => _StepsTrackerScreenState();
}

class _StepsTrackerScreenState extends State<StepsTrackerScreen> {
  final _repo = TrackingRepository();
  final _stepService = StepTrackingService();
  final _stepsController = TextEditingController();
  final _minutesController = TextEditingController();
  final DateTime _day = DateTime.now();
  String _status = 'Tap sync to read steps from Health.';

  @override
  void dispose() {
    _stepsController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _add(int steps, int minutes) async {
    await _repo.addSteps(
      day: _day,
      steps: steps,
      walkingMinutes: minutes,
      source: 'manual',
    );
  }

  Future<void> _syncAutoSteps() async {
    final result = await _stepService.syncTodayStepsToFirestore();
    if (!mounted) return;
    setState(() => _status = result.message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final key = dayKey(_day);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Steps')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Date: $key', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic Step Tracking',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _syncAutoSteps,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync from Health'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: _repo.stepsForDay(_day),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final steps = (data?['steps'] as num?)?.toInt() ?? 0;
                final walkingMinutes =
                    (data?['walkingMinutes'] as num?)?.toInt() ?? 0;
                final source = (data?['source'] ?? 'unknown').toString();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today steps: $steps',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text('Walking minutes: $walkingMinutes'),
                        const SizedBox(height: 4),
                        Text('Source: $source'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => _add(500, 5),
                  child: const Text('+500 steps'),
                ),
                ElevatedButton(
                  onPressed: () => _add(1000, 10),
                  child: const Text('+1000 steps'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Custom steps',
                prefixIcon: Icon(Icons.directions_walk),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Walking minutes (optional)',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final s = int.tryParse(_stepsController.text.trim()) ?? 0;
                final m = int.tryParse(_minutesController.text.trim()) ?? 0;
                if (s <= 0) return;
                await _add(s, m);
                _stepsController.clear();
                _minutesController.clear();
              },
              child: const Text('Add steps'),
            ),
          ],
        ),
      ),
    );
  }
}
