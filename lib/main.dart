import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/app.dart';
import 'package:campus_companion/core/config/app_config.dart';
import 'package:campus_companion/core/presentation/config_error_screen.dart';
import 'package:campus_companion/features/announcements/data/supabase_announcement_repository.dart';
import 'package:campus_companion/features/auth/data/hibp_breach_checker.dart';
import 'package:campus_companion/features/auth/data/supabase_auth_repository.dart';
import 'package:campus_companion/features/auth/data/supabase_user_repository.dart';
import 'package:campus_companion/features/auth/data/turnstile_captcha_solver.dart';
import 'package:campus_companion/features/auth/domain/captcha_solver.dart';
import 'package:campus_companion/features/categories/data/supabase_category_repository.dart';
import 'package:campus_companion/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:campus_companion/features/tasks/data/local_reminder_service.dart';
import 'package:campus_companion/features/tasks/data/supabase_task_repository.dart';
import 'package:campus_companion/features/tasks/domain/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    runApp(const ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  final client = Supabase.instance.client;
  final userRepository = SupabaseUserRepository(client);
  final CaptchaSolver captcha = AppConfig.turnstileSiteKey.isEmpty
      ? const NoCaptcha()
      : TurnstileCaptchaSolver(AppConfig.turnstileSiteKey);

  final ReminderService reminders = await _createReminders();

  runApp(
    CampusCompanionApp(
      dependencies: AppDependencies(
        authRepository: SupabaseAuthRepository(
          client,
          userRepository,
          captcha: captcha,
        ),
        userRepository: userRepository,
        taskRepository: SupabaseTaskRepository(client),
        announcementRepository: SupabaseAnnouncementRepository(client),
        categoryRepository: SupabaseCategoryRepository(client),
        settingsRepository: SharedPreferencesSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
        passwordBreachChecker: HibpBreachChecker(),
        reminderService: reminders,
      ),
    ),
  );
}

/// Reminders are optional: if notifications cannot start, the app still works.
Future<ReminderService> _createReminders() async {
  try {
    return await LocalReminderService.create();
  } catch (_) {
    return const NoReminders();
  }
}
