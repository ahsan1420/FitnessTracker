import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'createprofilescreen.dart';
import 'package:flutter/material.dart';
import 'authservices.dart';
import 'app_theme.dart';
import 'update_weight_screen.dart';
import 'water_tracker_screen.dart';
import 'add_workout_screen.dart';
import 'food_log_screen.dart';
import 'tracking_repository.dart';
import 'steps_tracker_screen.dart';
import 'services/step_tracking_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StepTrackingService _stepService = StepTrackingService();

  @override
  void initState() {
    super.initState();
    _stepService.syncTodayStepsToFirestore();
  }

  List<String> getSuggestedExercises(String goal) {
    final g = goal.toLowerCase();

    if (g.contains('lose')) {
      return ['Brisk Walking', 'Jump Rope', 'Cycling', 'HIIT'];
    } else if (g.contains('muscle') || g.contains('gain')) {
      return ['Push Ups', 'Squats', 'Dumbbell Workout', 'Strength Training'];
    } else if (g.contains('fit')) {
      return ['Walking', 'Yoga', 'Stretching', 'Light Cardio'];
    } else {
      return ['Walking', 'Stretching', 'Bodyweight Exercise'];
    }
  }

  bool isProfileComplete(Map<String, dynamic>? data) {
    if (data == null) return false;

    final values = [
      data['name'],
      data['age'],
      data['gender'],
      data['height'],
      data['weight'],
      data['goal'],
    ];

    return values.every(
      (value) => value != null && value.toString().trim().isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final surface = isDark ? AppTheme.surface : Colors.white;
    final today = dayKey(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();

            final String displayName =
                (data?['name'] != null &&
                    data!['name'].toString().trim().isNotEmpty)
                ? data['name'].toString()
                : (data?['firstName'] != null &&
                      data!['firstName'].toString().trim().isNotEmpty)
                ? data['firstName'].toString()
                : (user?.displayName?.trim().isNotEmpty == true
                      ? user!.displayName!.trim()
                      : (user?.email?.split('@').first ?? 'User'));

            final height = data?['height'];
            final weight = data?['weight'];
            final goal = data?['goal'] ?? 'Not added yet';
            final profileDone = isProfileComplete(data);
            final exercises = getSuggestedExercises(goal.toString());

            String formatValue(dynamic value, String unit) {
              if (value == null) return 'Not added';
              return '$value $unit';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8E85FF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back,',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Today Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('workouts')
                        .where('day', isEqualTo: today)
                        .snapshots(),
                    builder: (context, workoutSnap) {
                      final workoutDocs = workoutSnap.data?.docs ?? const [];
                      int todayWorkoutMin = 0;
                      int todayBurnedCalories = 0;
                      for (final d in workoutDocs) {
                        final w = d.data();
                        todayWorkoutMin +=
                            (w['durationMin'] as num?)?.toInt() ?? 0;
                        todayBurnedCalories +=
                            (w['calories'] as num?)?.toInt() ?? 0;
                      }

                      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .collection('water')
                            .doc(today)
                            .snapshots(),
                        builder: (context, waterSnap) {
                          final waterMl =
                              (waterSnap.data?.data()?['totalMl'] as num?)
                                      ?.toInt() ??
                                  0;
                          final waterL = (waterMl / 1000).toStringAsFixed(2);

                          return StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user?.uid)
                                .collection('step_logs')
                                .doc(today)
                                .snapshots(),
                            builder: (context, stepsSnap) {
                              final steps =
                                  (stepsSnap.data?.data()?['steps'] as num?)
                                          ?.toInt() ??
                                      0;
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SummaryCard(
                                          title: 'Calories Burned',
                                          value: '$todayBurnedCalories',
                                          icon: Icons.local_fire_department,
                                          primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          surface: surface,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SummaryCard(
                                          title: 'Water',
                                          value: '$waterL L',
                                          icon: Icons.water_drop_outlined,
                                          primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          surface: surface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SummaryCard(
                                          title: 'Workout',
                                          value: '$todayWorkoutMin min',
                                          icon: Icons.fitness_center,
                                          primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          surface: surface,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SummaryCard(
                                          title: 'Steps',
                                          value: '$steps',
                                          icon: Icons.directions_walk,
                                          primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          surface: surface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Height',
                          value: formatValue(height, 'cm'),
                          icon: Icons.height,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          surface: surface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Weight',
                          value: formatValue(weight, 'kg'),
                          icon: Icons.monitor_weight_outlined,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          surface: surface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProfileWideCard(
                    title: 'Goal',
                    value: goal.toString(),
                    icon: Icons.flag_outlined,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    surface: surface,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Suggested Exercises',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...exercises.map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                exercise,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActionTile(
                    icon: Icons.person_outline,
                    title: profileDone ? 'Update Profile' : 'Complete Profile',
                    subtitle: profileDone
                        ? 'Edit your name, age, gender, height, weight and goal'
                        : 'Add name, age, gender, height, weight and goal',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompleteProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ActionTile(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Update Weight',
                    subtitle: 'Track your latest body weight',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UpdateWeightScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ActionTile(
                    icon: Icons.water_drop_outlined,
                    title: 'Log Water Intake',
                    subtitle: 'Keep your daily hydration updated',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WaterTrackerScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ActionTile(
                    icon: Icons.sports_gymnastics_outlined,
                    title: 'Add Workout',
                    subtitle: 'Record today’s exercise',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddWorkoutScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ActionTile(
                    icon: Icons.directions_walk_outlined,
                    title: 'Track Steps',
                    subtitle: 'Add your daily step count and walking minutes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StepsTrackerScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ActionTile(
                    icon: Icons.restaurant_outlined,
                    title: 'Log Food / Calories',
                    subtitle: 'Add what you ate (auto calories)',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FoodLogScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        await authService.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color primaryText;
  final Color secondaryText;
  final Color surface;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.primaryText,
    required this.secondaryText,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ProfileWideCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color primaryText;
  final Color secondaryText;
  final Color surface;

  const ProfileWideCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.primaryText,
    required this.secondaryText,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: secondaryText, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final surface = isDark ? AppTheme.surface : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF6C63FF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: secondaryText, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
