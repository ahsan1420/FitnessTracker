import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/health.dart';

import '../tracking_repository.dart';

class StepTrackingResult {
  const StepTrackingResult({
    required this.success,
    required this.steps,
    required this.message,
    this.permissionGranted = false,
  });

  final bool success;
  final int steps;
  final String message;
  final bool permissionGranted;
}

class StepTrackingService {
  StepTrackingService({
    Health? health,
    TrackingRepository? repository,
  }) : _health = health ?? Health(),
       _repository = repository ?? TrackingRepository();

  final Health _health;
  final TrackingRepository _repository;

  static const _types = [HealthDataType.STEPS];
  static const _permissions = [HealthDataAccess.READ];

  Future<bool> requestStepPermission() async {
    final granted = await _health.requestAuthorization(
      _types,
      permissions: _permissions,
    );
    return granted;
  }

  Future<int?> fetchTodaySteps() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final steps = await _health.getTotalStepsInInterval(
      start,
      now,
      includeManualEntry: true,
    );
    return steps;
  }

  Future<StepTrackingResult> syncTodayStepsToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const StepTrackingResult(
        success: false,
        steps: 0,
        message: 'Not signed in.',
      );
    }

    final granted = await requestStepPermission();
    if (!granted) {
      return const StepTrackingResult(
        success: false,
        steps: 0,
        message: 'Step permission not granted.',
        permissionGranted: false,
      );
    }

    final steps = await fetchTodaySteps();
    if (steps == null) {
      return const StepTrackingResult(
        success: false,
        steps: 0,
        message: 'No step data found.',
        permissionGranted: true,
      );
    }

    final today = DateTime.now();
    await _repository.upsertStepLog(
      day: today,
      steps: steps,
      walkingMinutes: (steps / 100).round(),
      source: 'health',
    );

    return StepTrackingResult(
      success: true,
      steps: steps,
      message: 'Today steps synced.',
      permissionGranted: true,
    );
  }
}

