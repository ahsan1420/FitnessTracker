import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'tracking_repository.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final _repo = TrackingRepository();
  DateTime _day = DateTime.now();

  String _food = 'Apple';
  final _qty = TextEditingController(text: '1');
  final _search = TextEditingController();

  static const Map<String, int> caloriesPerServing = {
    'Apple': 95,
    'Banana': 105,
    'Orange': 62,
    'Blueberries (1 cup)': 84,
    'Boiled Egg': 78,
    'Paneer (100g)': 265,
    'Chicken Breast (100g)': 165,
    'Grilled Fish (100g)': 206,
    'Rice (1 cup cooked)': 205,
    'Brown Rice (1 cup)': 216,
    'Sweet Potato (100g)': 86,
    'Oats (1/2 cup)': 150,
    'Whole Wheat Bread (1 slice)': 80,
    'Salad bowl': 180,
    'Greek Yogurt (1 cup)': 130,
    'Milk (1 cup)': 150,
    'Peanut butter (1 tbsp)': 95,
    'Almonds (28g)': 164,
    'Avocado (100g)': 160,
  };

  @override
  void dispose() {
    _qty.dispose();
    _search.dispose();
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

  Future<void> _add() async {
    final qty = int.tryParse(_qty.text.trim()) ?? 1;
    final per = caloriesPerServing[_food] ?? 0;
    final add = (qty <= 0 ? 0 : qty) * per;
    try {
      await _repo.addFoodCalories(day: _day, addCalories: add);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $add kcal')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = dayKey(_day);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final filteredFoods = caloriesPerServing.keys
        .where(
          (f) => f.toLowerCase().contains(_search.text.trim().toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food / Calories'),
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
            Text('Date: $key', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (user != null)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snap) {
                  final goal = (snap.data?.data()?['goal'] ?? '').toString();
                  final g = goal.toLowerCase();
                  final tips = g.contains('lose')
                      ? const [
                          'Lean protein (chicken, eggs)',
                          'Salad / veggies',
                          'Oats / high fiber',
                        ]
                      : g.contains('gain') || g.contains('muscle')
                      ? const [
                          'Rice / oats',
                          'Milk / yogurt',
                          'Peanut butter / nuts',
                        ]
                      : const ['Balanced meals', 'Enough protein', 'Hydration'];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.trim().isEmpty
                                ? 'Food suggestions'
                                : 'Food suggestions (Goal: $goal)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...tips.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $t'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (user != null) const SizedBox(height: 12),
            StreamBuilder(
              stream: _repo.foodForDay(_day),
              builder: (context, snapshot) {
                final total = (snapshot.data?.data()?['totalCalories'] as num?)
                        ?.toInt() ??
                    0;
                return Text(
                  'Today consumed: $total kcal',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: primaryText),
                );
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search healthy food',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredFoods.take(16).map((food) {
                final selected = _food == food;
                return ChoiceChip(
                  label: Text('$food (${caloriesPerServing[food]} kcal)'),
                  selected: selected,
                  onSelected: (_) => setState(() => _food = food),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity (servings)',
                prefixIcon: const Icon(Icons.numbers_outlined),
                helperText:
                    '${caloriesPerServing[_food] ?? 0} kcal per serving',
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _add, child: const Text('Add')),
            const SizedBox(height: 10),
            Text(
              'Selected: $_food',
              style: TextStyle(color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

