import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/announcements_list_screen.dart';
import '../screens/announcement_detail_screen.dart';
import '../screens/tasks_list_screen.dart';
import '../screens/task_edit_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

/// Central place for all named routes used in the app.
class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case LoginScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RegisterScreen.routeName:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case HomeScreen.routeName:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AnnouncementsListScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AnnouncementsListScreen());
      case AnnouncementDetailScreen.routeName:
        final args = settings.arguments as AnnouncementDetailArgs;
        return MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(args: args),
        );
      case TasksListScreen.routeName:
        return MaterialPageRoute(builder: (_) => const TasksListScreen());
      case TaskEditScreen.routeName:
        final args = settings.arguments as TaskEditArgs?;
        return MaterialPageRoute(
          builder: (_) => TaskEditScreen(args: args),
        );
      case ProfileScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case SettingsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Unknown route')),
          ),
        );
    }
  }
}


