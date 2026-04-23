import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String dayKey(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

class TrackingRepository {
  TrackingRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged in user.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _userDoc() =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> _weightsCol() =>
      _userDoc().collection('weights');

  CollectionReference<Map<String, dynamic>> _waterCol() =>
      _userDoc().collection('water');

  CollectionReference<Map<String, dynamic>> _workoutsCol() =>
      _userDoc().collection('workouts');

  CollectionReference<Map<String, dynamic>> _foodCol() =>
      _userDoc().collection('food');

  CollectionReference<Map<String, dynamic>> _stepLogsCol() =>
      _userDoc().collection('step_logs');

  Stream<DocumentSnapshot<Map<String, dynamic>>> weightForDay(DateTime day) {
    return _weightsCol().doc(dayKey(day)).snapshots();
  }

  Future<void> saveWeightForDay({
    required DateTime day,
    required double weightKg,
  }) async {
    final key = dayKey(day);

    await _weightsCol().doc(key).set({
      'day': key,
      'weightKg': weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _userDoc().set({
      'weight': weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> waterForDay(DateTime day) {
    return _waterCol().doc(dayKey(day)).snapshots();
  }

  Future<void> addWaterMl({required DateTime day, required int addMl}) async {
    final key = dayKey(day);
    final doc = _waterCol().doc(key);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = (snap.data()?['totalMl'] as num?)?.toInt() ?? 0;

      tx.set(doc, {
        'day': key,
        'totalMl': current + addMl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> resetWaterForDay({required DateTime day}) async {
    final key = dayKey(day);

    await _waterCol().doc(key).set({
      'day': key,
      'totalMl': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Query<Map<String, dynamic>> workoutsQuery() =>
      _workoutsCol().orderBy('createdAt', descending: true);

  Future<void> addWorkout({
    required String name,
    required int durationMin,
    required int calories,
    String? notes,
    DateTime? when,
  }) async {
    final dt = when ?? DateTime.now();

    await _workoutsCol().add({
      'name': name,
      'durationMin': durationMin,
      'calories': calories,
      'notes': (notes ?? '').trim(),
      'day': dayKey(dt),
      'createdAt': Timestamp.fromDate(dt),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> foodForDay(DateTime day) {
    return _foodCol().doc(dayKey(day)).snapshots();
  }

  Future<void> addFoodCalories({
    required DateTime day,
    required int addCalories,
  }) async {
    final key = dayKey(day);
    final doc = _foodCol().doc(key);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = (snap.data()?['totalCalories'] as num?)?.toInt() ?? 0;

      tx.set(doc, {
        'day': key,
        'totalCalories': current + addCalories,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> stepsForDay(DateTime day) {
    return _stepLogsCol().doc(dayKey(day)).snapshots();
  }

  Future<void> addSteps({
    required DateTime day,
    required int steps,
    int walkingMinutes = 0,
    String source = 'manual',
  }) async {
    final key = dayKey(day);
    final doc = _stepLogsCol().doc(key);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final currentSteps = (snap.data()?['steps'] as num?)?.toInt() ?? 0;
      final currentWalk =
          (snap.data()?['walkingMinutes'] as num?)?.toInt() ?? 0;

      tx.set(doc, {
        'day': key,
        'steps': currentSteps + steps,
        'walkingMinutes': currentWalk + walkingMinutes,
        'source': source,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> upsertStepLog({
    required DateTime day,
    required int steps,
    int walkingMinutes = 0,
    required String source,
  }) async {
    final key = dayKey(day);

    await _stepLogsCol().doc(key).set({
      'day': key,
      'steps': steps,
      'walkingMinutes': walkingMinutes,
      'source': source,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Query<Map<String, dynamic>> stepsQuery() =>
      _stepLogsCol().orderBy('day', descending: false);
}
