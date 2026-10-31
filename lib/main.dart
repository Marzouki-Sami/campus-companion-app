import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/app.dart';
import 'package:campus_companion/core/config/app_config.dart';
import 'package:campus_companion/core/presentation/config_error_screen.dart';
import 'package:campus_companion/features/announcements/data/supabase_announcement_repository.dart';
import 'package:campus_companion/features/auth/data/supabase_auth_repository.dart';
import 'package:campus_companion/features/auth/data/supabase_user_repository.dart';
import 'package:campus_companion/features/categories/data/supabase_category_repository.dart';
import 'package:campus_companion/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:campus_companion/features/tasks/data/supabase_task_repository.dart';

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

  runApp(
    CampusCompanionApp(
      dependencies: AppDependencies(
        authRepository: SupabaseAuthRepository(client, userRepository),
        userRepository: userRepository,
        taskRepository: SupabaseTaskRepository(client),
        announcementRepository: SupabaseAnnouncementRepository(client),
        categoryRepository: SupabaseCategoryRepository(client),
        settingsRepository: SharedPreferencesSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
      ),
    ),
  );
}
