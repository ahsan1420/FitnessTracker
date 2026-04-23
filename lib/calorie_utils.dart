double caloriesBurned({
  required double met,
  required double weightKg,
  required int durationMin,
}) {
  final hours = durationMin / 60.0;
  return met * weightKg * hours;
}

const Map<String, double> exerciseMet = {
  'Walking': 3.5,
  'Running': 9.8,
  'Cycling': 7.5,
  'Jump Rope': 12.3,
  'HIIT': 10.0,
  'Push Ups': 8.0,
  'Squats': 5.0,
  'Yoga': 2.5,
  'Strength Training': 6.0,
};

