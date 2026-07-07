import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeStore extends ChangeNotifier {
  ThemeStore({
    ThemeMode initialMode = ThemeMode.light,
    SharedPreferences? preferences,
  }) : _mode = initialMode,
       _preferences = preferences;

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences? _preferences;
  ThemeMode _mode;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;

  void toggleDarkMode(bool enabled) {
    unawaited(setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) {
      return;
    }

    _mode = mode;
    await _preferences?.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  static ThemeMode loadMode(SharedPreferences preferences) {
    final stored = preferences.getString(_themeModeKey);
    return ThemeMode.values.byName(stored ?? ThemeMode.light.name);
  }
}
