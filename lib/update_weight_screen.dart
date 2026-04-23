import 'package:flutter/material.dart';

import 'tracking_repository.dart';

class UpdateWeightScreen extends StatefulWidget {
  const UpdateWeightScreen({super.key});

  @override
  State<UpdateWeightScreen> createState() => _UpdateWeightScreenState();
}

class _UpdateWeightScreenState extends State<UpdateWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _repo = TrackingRepository();

  DateTime _day = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_weightController.text.trim());

    setState(() => _saving = true);
    try {
      await _repo.saveWeightForDay(day: _day, weightKg: value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = dayKey(_day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Weight'),
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
              stream: _repo.weightForDay(_day),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final weight = (data?['weightKg'] as num?)?.toDouble();
                return Text(
                  weight == null
                      ? 'Saved weight: —'
                      : 'Saved weight: ${weight.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Current weight (kg)',
                      hintText: 'e.g. 65.5',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Weight is required';
                      }
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null) return 'Enter a valid number';
                      if (parsed <= 0) return 'Weight must be > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
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

