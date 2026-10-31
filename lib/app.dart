import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/routing/app_router.dart';
import 'package:campus_companion/core/theme/app_theme.dart';
import 'package:campus_companion/features/admin/presentation/providers/users_provider.dart';
import 'package:campus_companion/features/announcements/domain/announcement_repository.dart';
import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/auth/presentation/screens/splash_screen.dart';
import 'package:campus_companion/features/categories/domain/category_repository.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';
import 'package:campus_companion/features/tasks/domain/task_repository.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';

/// Repositories the app depends on, injected so they can be replaced in tests.
class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.userRepository,
    required this.taskRepository,
    required this.announcementRepository,
    required this.categoryRepository,
  });

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final TaskRepository taskRepository;
  final AnnouncementRepository announcementRepository;
  final CategoryRepository categoryRepository;
}

class CampusCompanionApp extends StatelessWidget {
  const CampusCompanionApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(dependencies.authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(dependencies.taskRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AnnouncementProvider(dependencies.announcementRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(dependencies.categoryRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(dependencies.userRepository),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Campus Companion',
        theme: AppTheme.light,
        initialRoute: SplashScreen.routeName,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
