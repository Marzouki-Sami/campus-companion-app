import 'package:flutter/material.dart';

import 'package:campus_companion/core/utils/date_format.dart';

/// Event section of the announcement form: a switch that reveals start, end
/// and place. Holds no state; the screen owns the values.
class EventFields extends StatelessWidget {
  const EventFields({
    super.key,
    required this.isEvent,
    required this.start,
    required this.end,
    required this.location,
    required this.errorText,
    required this.onToggle,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final bool isEvent;
  final DateTime? start;
  final DateTime? end;
  final TextEditingController location;
  final String? errorText;
  final ValueChanged<bool> onToggle;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;

  Future<DateTime?> _pick(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('This is an event', style: theme.textTheme.titleSmall),
          subtitle: const Text('Add a date, time and place'),
          value: isEvent,
          onChanged: onToggle,
        ),
        if (isEvent) ...[
          const SizedBox(height: 8),
          _PickerTile(
            icon: Icons.event_outlined,
            label: 'Starts',
            value: start == null ? null : formatEventWhen(start!, null),
            onTap: () async {
              final picked = await _pick(
                context,
                start ?? _defaultStart(),
              );
              if (picked != null) onStartChanged(picked);
            },
          ),
          const SizedBox(height: 16),
          _PickerTile(
            icon: Icons.event_available_outlined,
            label: 'Ends (optional)',
            value: end == null ? null : formatEventWhen(end!, null),
            onClear: end == null ? null : () => onEndChanged(null),
            onTap: () async {
              final base = start ?? _defaultStart();
              final picked = await _pick(
                context,
                end ?? base.add(const Duration(hours: 2)),
              );
              if (picked != null) onEndChanged(picked);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: location,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Place (optional)',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                errorText!,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
        ],
      ],
    );
  }

  static DateTime _defaultStart() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear == null
              ? const Icon(Icons.edit_calendar_outlined)
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          value ?? 'Choose date and time',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value == null ? scheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
