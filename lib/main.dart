import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/app.dart';
import 'package:campus_companion/core/config/app_config.dart';
import 'package:campus_companion/core/offline/local_cache.dart';
import 'package:campus_companion/core/offline/offline_state.dart';
import 'package:campus_companion/core/presentation/config_error_screen.dart';
import 'package:campus_companion/features/announcements/data/caching_announcement_repository.dart';
import 'package:campus_companion/features/announcements/data/supabase_announcement_repository.dart';
import 'package:campus_companion/features/auth/data/hibp_breach_checker.dart';
import 'package:campus_companion/features/auth/data/caching_user_repository.dart';
import 'package:campus_companion/features/auth/data/supabase_auth_repository.dart';
import 'package:campus_companion/features/auth/data/supabase_user_repository.dart';
import 'package:campus_companion/features/auth/data/turnstile_captcha_solver.dart';
import 'package:campus_companion/features/auth/domain/captcha_solver.dart';
import 'package:campus_companion/features/categories/data/caching_category_repository.dart';
import 'package:campus_companion/features/categories/data/supabase_category_repository.dart';
import 'package:campus_companion/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:campus_companion/features/tasks/data/caching_task_repository.dart';
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
    // No automatic retries: when the network is down the saved data should
    // appear at once instead of after several backoffs. Pull-to-refresh retries.
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
  );
  final client = Supabase.instance.client;
  final prefs = await SharedPreferences.getInstance();
  final cache = SharedPreferencesCache(prefs);
  final offline = OfflineState();
  final userRepository = CachingUserRepository(
    SupabaseUserRepository(client),
    cache,
    offline,
  );
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
        taskRepository: CachingTaskRepository(
          SupabaseTaskRepository(client),
          cache,
          offline,
        ),
        announcementRepository: CachingAnnouncementRepository(
          SupabaseAnnouncementRepository(client),
          cache,
          offline,
        ),
        categoryRepository: CachingCategoryRepository(
          SupabaseCategoryRepository(client),
          cache,
          offline,
        ),
        settingsRepository: SharedPreferencesSettingsRepository(prefs),
        localCache: cache,
        offlineState: offline,
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
