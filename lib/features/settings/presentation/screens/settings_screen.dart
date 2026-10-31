import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _darkMode ? Colors.grey.shade900 : Colors.white,
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Dark mode (demo only)'),
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
            const ListTile(
              title: Text('Other settings can go here.'),
            ),
          ],
        ),
      ),
    );
  }
}
