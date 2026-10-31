import 'package:flutter/material.dart';

import 'package:campus_companion/features/settings/domain/settings_repository.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._repository);

  final SettingsRepository _repository;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    _mode = await _repository.loadThemeMode();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _repository.saveThemeMode(mode);
  }
}
