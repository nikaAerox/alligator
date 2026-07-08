// Manages dark mode and light mode selection. (Saves the theme choice so the app keeps the same theme after restart)

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

  // Returns the current theme mode used by the app.
  ThemeMode get mode => _mode;
  // Returns whether dark mode is currently active.
  bool get isDarkMode => _mode == ThemeMode.dark;

  // Switches between dark mode and light mode.
  void toggleDarkMode(bool enabled) {
    unawaited(setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light));
  }

  // Saves the selected theme mode and updates the UI.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) {
      return;
    }

    _mode = mode;
    await _preferences?.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  // Loads the saved theme mode from app preferences.
  static ThemeMode loadMode(SharedPreferences preferences) {
    final stored = preferences.getString(_themeModeKey);
    return ThemeMode.values.byName(stored ?? ThemeMode.light.name);
  }
}
