import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:campus_companion/features/tasks/domain/reminder_plan.dart';
import 'package:campus_companion/features/tasks/domain/reminder_service.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';

/// Reminders as on-device notifications, so they work offline and need no
/// server. Scheduling is inexact (within a few minutes) which avoids the
/// special "exact alarm" permission.
class LocalReminderService implements ReminderService {
  LocalReminderService._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channel = AndroidNotificationDetails(
    'task_reminders',
    'Task reminders',
    channelDescription: 'Reminders for tasks that are about to be due',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<LocalReminderService> create() async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Falls back to UTC; reminders still fire, just at a shifted hour.
    }

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    return LocalReminderService._(plugin);
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> sync(List<Task> tasks) async {
    await _plugin.cancelAllPendingNotifications();
    for (final reminder in planReminders(tasks, now: DateTime.now())) {
      final task = reminder.task;
      await _plugin.zonedSchedule(
        id: task.id.hashCode & 0x7fffffff,
        title: task.title,
        body: reminderBody(task.remindDaysBefore!),
        scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (e) {
      debugPrint('Could not cancel reminders: $e');
    }
  }
}
