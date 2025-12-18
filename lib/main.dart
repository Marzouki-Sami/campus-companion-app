import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/announcement_provider.dart';
import 'routes/app_routes.dart';
import 'screens/splash_screen.dart';

/// Entry point of the Campus Companion app.
///
/// This initializes Firebase and sets up the top-level providers and routing.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: In a real project you may want to pass platform-specific
  // FirebaseOptions here if not using the default files.
  await Firebase.initializeApp();

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


