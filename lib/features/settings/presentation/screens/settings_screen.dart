import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/settings/presentation/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Appearance'),
            subtitle: Text('Your choice is remembered on this device.'),
          ),
          for (final (mode, label) in const [
            (ThemeMode.system, 'Follow system'),
            (ThemeMode.light, 'Light'),
            (ThemeMode.dark, 'Dark'),
          ])
            ListTile(
              leading: Icon(
                theme.mode == mode
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(label),
              onTap: () => theme.setMode(mode),
            ),
        ],
      ),
    );
  }
}
