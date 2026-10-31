import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';
import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';
import 'package:campus_companion/features/admin/presentation/providers/users_provider.dart';
import 'package:campus_companion/core/routing/app_router.dart';
import 'package:campus_companion/features/auth/presentation/screens/splash_screen.dart';
import 'package:campus_companion/firebase_options.dart';

/// Entry point of the Campus Companion app.
///
/// This initializes Firebase and sets up the top-level providers and routing.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: In a real project you may want to pass platform-specific
  // FirebaseOptions here if not using the default files.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CampusCompanionApp());
}

class CampusCompanionApp extends StatelessWidget {
  const CampusCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Campus Companion',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            // Initial route is the splash screen.
            initialRoute: SplashScreen.routeName,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}


