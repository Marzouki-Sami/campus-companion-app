import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/settings/domain/settings_repository.dart';
import 'package:campus_companion/features/settings/presentation/providers/theme_provider.dart';

class _MemorySettings implements SettingsRepository {
  ThemeMode stored = ThemeMode.system;

  @override
  Future<ThemeMode> loadThemeMode() async => stored;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async => stored = mode;
}

void main() {
  test('loads the persisted theme mode', () async {
    final repository = _MemorySettings()..stored = ThemeMode.dark;
    final provider = ThemeProvider(repository);

    await provider.load();

    expect(provider.mode, ThemeMode.dark);
  });

  test('setMode notifies listeners and persists the choice', () async {
    final repository = _MemorySettings();
    final provider = ThemeProvider(repository);
    var notified = 0;
    provider.addListener(() => notified++);

    await provider.setMode(ThemeMode.dark);
    await provider.setMode(ThemeMode.dark);

    expect(provider.mode, ThemeMode.dark);
    expect(repository.stored, ThemeMode.dark);
    expect(notified, 1);
  });
}
