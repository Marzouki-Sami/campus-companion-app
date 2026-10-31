import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_companion/app.dart';
import 'package:campus_companion/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:campus_companion/features/announcements/data/firestore_announcement_repository.dart';
import 'package:campus_companion/features/auth/data/firebase_auth_repository.dart';
import 'package:campus_companion/features/auth/data/firestore_user_repository.dart';
import 'package:campus_companion/features/categories/data/firestore_category_repository.dart';
import 'package:campus_companion/features/tasks/data/firestore_task_repository.dart';
import 'package:campus_companion/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final userRepository = FirestoreUserRepository(firestore);

  runApp(
    CampusCompanionApp(
      dependencies: AppDependencies(
        authRepository: FirebaseAuthRepository(
          FirebaseAuth.instance,
          userRepository,
        ),
        userRepository: userRepository,
        taskRepository: FirestoreTaskRepository(firestore),
        announcementRepository: FirestoreAnnouncementRepository(firestore),
        categoryRepository: FirestoreCategoryRepository(firestore),
        settingsRepository: SharedPreferencesSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
      ),
    ),
  );
}
