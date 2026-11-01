import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcements_list_screen.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';
import 'package:campus_companion/features/home/presentation/widgets/account_tab.dart';
import 'package:campus_companion/features/home/presentation/widgets/dashboard_tab.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';
import 'package:campus_companion/features/tasks/presentation/screens/tasks_list_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _homeTab = 0;
  static const _announcementsTab = 1;
  static const _tasksTab = 2;

  int _index = _homeTab;

  String? _tasksLoadedFor;

  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Provider calls notify listeners, so they must not run during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().loadAnnouncements();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The profile resolves asynchronously after a cold start, so tasks are
    // loaded as soon as the signed-in user becomes known.
    final auth = context.watch<AuthProvider>();
    _leaveIfSignedOut(auth);
    final userId = auth.currentUser?.id;
    if (userId != null && userId != _tasksLoadedFor) {
      _tasksLoadedFor = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<TaskProvider>().loadTasks(userId);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().refreshProfile();
    }
  }

  /// Leaves the signed-in area as soon as the session has ended, whether the
  /// user logged out or an admin suspended the account.
  void _leaveIfSignedOut(AuthProvider auth) {
    if (_leaving || auth.isLoggedIn || auth.currentUser != null) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (_) => false,
      );
    });
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final unread =
        context.select<AnnouncementProvider, int>((p) => p.unreadCount);

    return PopScope(
      canPop: _index == _homeTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(_homeTab);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            DashboardTab(
              onSeeAllTasks: () => _select(_tasksTab),
              onSeeAllAnnouncements: () => _select(_announcementsTab),
            ),
            const AnnouncementsListScreen(),
            const TasksListScreen(),
            const AccountTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: _UnreadBadge(
                count: unread,
                child: const Icon(Icons.campaign_outlined),
              ),
              selectedIcon: _UnreadBadge(
                count: unread,
                child: const Icon(Icons.campaign),
              ),
              label: 'News',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

/// A small count on the News tab icon; hidden when everything is read.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
