import 'package:flutter/material.dart';

import 'tracking_repository.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  final _repo = TrackingRepository();
  DateTime _day = DateTime.now();

  Future<void> _pickDay() async {
    final initial = DateTime(_day.year, _day.month, _day.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final key = dayKey(_day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake'),
        actions: [
          IconButton(
            tooltip: 'Pick date',
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Date: $key',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: _repo.waterForDay(_day),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final totalMl = (data?['totalMl'] as num?)?.toInt() ?? 0;
                final liters = totalMl / 1000.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today total: $totalMl mL (${liters.toStringAsFixed(2)} L)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap buttons to add water.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AddWaterButton(
                  label: '+250 mL',
                  onTap: () => _repo.addWaterMl(day: _day, addMl: 250),
                ),
                _AddWaterButton(
                  label: '+500 mL',
                  onTap: () => _repo.addWaterMl(day: _day, addMl: 500),
                ),
                _AddWaterButton(
                  label: '+1000 mL',
                  onTap: () => _repo.addWaterMl(day: _day, addMl: 1000),
                ),
                _AddWaterButton(
                  label: 'Reset',
                  onTap: () => _repo.resetWaterForDay(day: _day),
                  isDanger: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWaterButton extends StatelessWidget {
  const _AddWaterButton({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  final String label;
  final Future<void> Function() onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
      child: OutlinedButton(
        style: isDanger
            ? OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              )
            : null,
        onPressed: () async {
          try {
            await onTap();
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        child: Text(label),
      ),
    );
  }
}

