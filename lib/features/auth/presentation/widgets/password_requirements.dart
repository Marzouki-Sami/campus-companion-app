import 'package:flutter/material.dart';

import 'package:campus_companion/features/auth/domain/password_policy.dart';

/// A live checklist and strength bar shown under a "new password" field.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strength = PasswordPolicy.strength(password);
    final (label, color) = switch (strength) {
      0 => ('', scheme.outlineVariant),
      < 0.5 => ('Weak', scheme.error),
      < 0.85 => ('Fair', Colors.orange),
      < 1 => ('Good', Colors.lightGreen),
      _ => ('Strong', Colors.green),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength,
                  minHeight: 6,
                  color: color,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final rule in PasswordRule.values)
          _RuleRow(
            label: rule.label,
            met: PasswordPolicy.satisfies(rule, password),
          ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: met ? Colors.green : scheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: met ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
