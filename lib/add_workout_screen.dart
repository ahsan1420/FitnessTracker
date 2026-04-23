import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'calorie_utils.dart';
import 'tracking_repository.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TrackingRepository();

  final _name = TextEditingController();
  final _duration = TextEditingController();
  final _calories = TextEditingController();
  final _notes = TextEditingController();

  String _exerciseType = 'Running';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _duration.addListener(_recalcCalories);
  }

  void _recalcCalories() async {
    final duration = int.tryParse(_duration.text.trim());
    if (duration == null || duration <= 0) return;

    final user = FirebaseAuth.instance.currentUser;
    double weightKg = 70.0;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final w = (doc.data()?['weight'] as num?)?.toDouble();
        if (w != null && w > 0) weightKg = w;
      } catch (_) {}
    }

    final met = exerciseMet[_exerciseType] ?? 6.0;
    final calories = caloriesBurned(
      met: met,
      weightKg: weightKg,
      durationMin: duration,
    );

    final rounded = calories.round();
    if (_calories.text.trim() == rounded.toString()) return;
    _calories.text = rounded.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    _calories.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _repo.addWorkout(
        name: _name.text.trim(),
        durationMin: int.parse(_duration.text.trim()),
        calories: int.parse(_calories.text.trim()),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Workout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _exerciseType,
                    decoration: const InputDecoration(
                      labelText: 'Exercise type',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: exerciseMet.keys
                        .map(
                          (k) => DropdownMenuItem(value: k, child: Text(k)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _exerciseType = v);
                      _recalcCalories();
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Workout name',
                      hintText: 'e.g. Morning run',
                      prefixIcon: Icon(Icons.fitness_center_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Workout name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      hintText: 'e.g. 30',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Duration is required';
                      }
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null) return 'Enter a valid number';
                      if (parsed <= 0) return 'Duration must be > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _calories,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Calories burned (auto)',
                      hintText: 'Enter duration first',
                      prefixIcon: Icon(Icons.local_fire_department_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Calories is required';
                      }
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null) return 'Enter a valid number';
                      if (parsed < 0) return 'Calories must be ≥ 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hydration tip: drink ~250 mL per 15 min workout.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'How did it feel? sets/reps? etc.',
                      prefixIcon: Icon(Icons.notes_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save workout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

