import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:campus_companion/core/theme/app_theme.dart';
import 'package:campus_companion/core/widgets/auth_scaffold.dart';

/// Shown instead of the app when the Supabase settings are missing, so a fresh
/// clone explains what to do rather than failing with a stack trace.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Companion',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const _ConfigErrorScreen(),
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen();

  static const _command = 'flutter run --dart-define-from-file=env.json';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      title: 'Setup required',
      subtitle: 'This build has no Supabase settings. Copy env.example.json to '
          'env.json, fill in your project URL and publishable key, then run:',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Expanded(
                child: SelectableText(
                  _command,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(const ClipboardData(text: _command));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The README explains how to start a local Supabase in one command.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
