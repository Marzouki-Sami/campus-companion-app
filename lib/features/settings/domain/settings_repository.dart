import 'package:flutter/material.dart';

abstract interface class SettingsRepository {
  Future<ThemeMode> loadThemeMode();

  Future<void> saveThemeMode(ThemeMode mode);
}
