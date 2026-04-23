import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tracking_repository.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  DateTime _startOfWeek(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  bool _isOnOrAfter(String day, String startDayKey) =>
      day.compareTo(startDayKey) >= 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Progress')),
        body: SafeArea(child: Center(child: Text('Not signed in'))),
      );
    }

    final now = DateTime.now();
    final startWeekKey = dayKey(_startOfWeek(now));
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final lastOfMonth = DateTime(now.year, now.month + 1, 0);
    final firstMonthKey = dayKey(firstOfMonth);
    final lastMonthKey = dayKey(lastOfMonth);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;

    final weightsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('weights')
        .orderBy('day', descending: true)
        .limit(14);

    final waterQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('water')
        .orderBy('day', descending: true)
        .limit(14);

    final workoutsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .orderBy('createdAt', descending: true)
        .limit(50);

    final monthlyStepsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('step_logs')
        .where('day', isGreaterThanOrEqualTo: firstMonthKey)
        .where('day', isLessThanOrEqualTo: lastMonthKey)
        .orderBy('day', descending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Weekly stats (from $startWeekKey)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: primaryText),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: weightsQuery.snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];
                final latest = docs.isNotEmpty
                    ? (docs.first.data()['weightKg'] as num?)?.toDouble()
                    : null;

                double? previous;
                String? latestDay;
                if (docs.isNotEmpty) {
                  latestDay = docs.first.data()['day']?.toString();
                }
                for (var i = 1; i < docs.length; i++) {
                  final d = docs[i].data();
                  final day = d['day']?.toString();
                  if (day != null && day != latestDay) {
                    previous = (d['weightKg'] as num?)?.toDouble();
                    break;
                  }
                }

                final delta = (latest != null && previous != null)
                    ? latest - previous
                    : null;

                return _StatCard(
                  title: 'Latest weight',
                  value: latest == null
                      ? '—'
                      : '${latest.toStringAsFixed(1)} kg',
                  subtitle: delta == null
                      ? 'Add weights on different days to compare'
                      : 'Change vs last entry: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                  icon: Icons.monitor_weight_outlined,
                  footer: docs.length < 2
                      ? null
                      : SizedBox(height: 140, child: _WeightChart(docs: docs)),
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: waterQuery.snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];

                int weeklyTotal = 0;
                int daysCounted = 0;
                for (final d in docs) {
                  final data = d.data();
                  final day = (data['day'] ?? '').toString();
                  if (day.isEmpty) continue;
                  if (!_isOnOrAfter(day, startWeekKey)) continue;
                  weeklyTotal += (data['totalMl'] as num?)?.toInt() ?? 0;
                  daysCounted += 1;
                }

                final avg = daysCounted == 0 ? 0 : (weeklyTotal / daysCounted);

                return _StatCard(
                  title: 'Water (this week)',
                  value: '${(weeklyTotal / 1000).toStringAsFixed(2)} L',
                  subtitle: daysCounted == 0
                      ? 'No water logs this week'
                      : 'Avg per logged day: ${(avg / 1000).toStringAsFixed(2)} L',
                  icon: Icons.water_drop_outlined,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: workoutsQuery.snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];

                int count = 0;
                int minutes = 0;
                int calories = 0;

                for (final d in docs) {
                  final data = d.data();
                  final day = (data['day'] ?? '').toString();
                  if (day.isEmpty) continue;
                  if (!_isOnOrAfter(day, startWeekKey)) continue;

                  count += 1;
                  minutes += (data['durationMin'] as num?)?.toInt() ?? 0;
                  calories += (data['calories'] as num?)?.toInt() ?? 0;
                }

                return _StatCard(
                  title: 'Workouts (this week)',
                  value: '$count workouts',
                  subtitle: count == 0
                      ? 'No workouts logged this week'
                      : '$minutes min · $calories kcal',
                  icon: Icons.fitness_center_outlined,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: monthlyStepsQuery.snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];
                int monthSteps = 0;
                int monthWalking = 0;
                for (final d in docs) {
                  final data = d.data();
                  monthSteps += (data['steps'] as num?)?.toInt() ?? 0;
                  monthWalking +=
                      (data['walkingMinutes'] as num?)?.toInt() ?? 0;
                }

                return _StatCard(
                  title: 'Walking (this month)',
                  value: '$monthSteps steps',
                  subtitle: '$monthWalking min walking',
                  icon: Icons.directions_walk,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  footer: docs.isEmpty
                      ? null
                      : SizedBox(
                          height: 160,
                          child: _MonthlyStepsChart(docs: docs),
                        ),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              'Monthly walking chart resets view monthly, history stays saved.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.primaryText,
    required this.secondaryText,
    this.footer,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color primaryText;
  final Color secondaryText;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: primaryText.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryText.withValues(alpha: 0.14)),
              ),
              child: Icon(icon, color: secondaryText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: secondaryText)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: secondaryText)),
                  if (footer != null) ...[
                    const SizedBox(height: 12),
                    footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyStepsChart extends StatelessWidget {
  const _MonthlyStepsChart({required this.docs});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < docs.length; i++) {
      final data = docs[i].data();
      final steps = (data['steps'] as num?)?.toDouble() ?? 0;
      final dayString = (data['day'] ?? '').toString();
      final dayOfMonth = int.tryParse(
            dayString.length >= 10 ? dayString.substring(8, 10) : '',
          ) ??
          (i + 1);
      groups.add(
        BarChartGroupData(
          x: dayOfMonth,
          barRods: [
            BarChartRodData(
              toY: steps,
              width: 8,
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF6C63FF),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: groups,
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.docs});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    final points = <FlSpot>[];
    final reversed = docs.reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      final w = (reversed[i].data()['weightKg'] as num?)?.toDouble();
      if (w == null) continue;
      points.add(FlSpot(i.toDouble(), w));
    }
    if (points.length < 2) return const SizedBox.shrink();

    final minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) == 0 ? 1.0 : (maxY - minY) * 0.2;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: const Color(0xFF6C63FF),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
