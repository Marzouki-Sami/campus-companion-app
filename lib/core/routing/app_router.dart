import 'package:flutter/material.dart';

import 'package:campus_companion/features/auth/presentation/screens/splash_screen.dart';
import 'package:campus_companion/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_companion/features/auth/presentation/screens/register_screen.dart';
import 'package:campus_companion/features/home/presentation/screens/home_screen.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcements_list_screen.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcement_detail_screen.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcement_edit_screen.dart';
import 'package:campus_companion/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:campus_companion/features/tasks/presentation/screens/tasks_list_screen.dart';
import 'package:campus_companion/features/tasks/presentation/screens/task_edit_screen.dart';
import 'package:campus_companion/features/profile/presentation/screens/profile_screen.dart';

/// Maps route names to screens.
class AppRouter {
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
      case AdminDashboardScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case AnnouncementEditScreen.routeName:
        final args = settings.arguments as AnnouncementEditArgs?;
        return MaterialPageRoute(
          builder: (_) => AnnouncementEditScreen(args: args),
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
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Unknown route')),
          ),
        );
    }
  }
}


