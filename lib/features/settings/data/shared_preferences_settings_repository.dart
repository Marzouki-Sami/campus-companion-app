import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_companion/features/settings/domain/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._prefs);

  static const _themeKey = 'theme_mode';

  final SharedPreferences _prefs;

  @override
  Future<ThemeMode> loadThemeMode() async {
    final stored = _prefs.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
  }
}
