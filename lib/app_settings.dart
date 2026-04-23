import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _darkModeKey = 'darkMode';

  AppSettings._(this._prefs) {
    _darkMode = _prefs.getBool(_darkModeKey) ?? true;
  }

  final SharedPreferences _prefs;
  late bool _darkMode;

  bool get darkMode => _darkMode;

  set darkMode(bool value) {
    if (_darkMode == value) return;
    _darkMode = value;
    _prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs);
  }
}

