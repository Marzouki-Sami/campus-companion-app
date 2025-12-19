import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/category_provider.dart';
import '../models/announcement.dart';
import '../models/task.dart';
import '../models/category.dart' show AnnouncementCategory;
import 'announcements_list_screen.dart';
import 'tasks_list_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'announcement_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _selectedCategoryId; // For filtering announcements by category
  DateTime? _selectedDateFilter; // For filtering announcements by date

  @override
  void initState() {
    super.initState();
    // Defer provider calls until after build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;
      if (userId != null) {
        context.read<TaskProvider>().loadTasks(userId);
      }
      context.read<AnnouncementProvider>().loadAnnouncements();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildDashboard(),
      const AnnouncementsListScreen(),
      const TasksListScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Show confirmation dialog when back button is pressed
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit Campus Companion?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && mounted) {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Campus Companion')),
        drawer: _buildDrawer(context),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: pages[_currentIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.campaign), label: 'Announcements'),
            BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Tasks'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final announcementProvider = context.watch<AnnouncementProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser?.id;

    // Filter announcements: last month + optional category filter
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    List<Announcement> filteredAnnouncements = announcementProvider.announcements
        .where((a) => a.createdAt.isAfter(oneMonthAgo))
        .toList();

    if (_selectedDateFilter != null) {
      filteredAnnouncements = filteredAnnouncements
          .where((a) => a.createdAt.isAfter(_selectedDateFilter!))
          .toList();
    }

    if (_selectedCategoryId != null) {
      filteredAnnouncements = filteredAnnouncements
          .where((a) => a.categories.contains(_selectedCategoryId))
          .toList();
    }

    // Filter tasks: only not done
    final incompleteTasks = userId != null
        ? taskProvider.tasks.where((t) => !t.isDone).toList()
        : <Task>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // App Description Section
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Campus Companion',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your all-in-one university companion app. Manage announcements, track tasks, and stay organized throughout your academic journey.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Latest Announcements Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Latest Announcements (Last Month)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _showAnnouncementFilters(
                          context, categoryProvider.categories),
                    ),
                  ],
                ),
                if (_selectedCategoryId != null || _selectedDateFilter != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_selectedCategoryId != null)
                        Chip(
                          label: Text(
                                    categoryProvider.categories
                                        .firstWhere((c) => c.id == _selectedCategoryId,
                                            orElse: () => AnnouncementCategory(
                                                id: '', name: 'Unknown', createdAt: DateTime.now()))
                                        .name,
                          ),
                          onDeleted: () => setState(() => _selectedCategoryId = null),
                        ),
                      if (_selectedDateFilter != null)
                        Chip(
                          label: Text(
                            'From ${_selectedDateFilter!.toString().split(' ')[0]}',
                          ),
                          onDeleted: () => setState(() => _selectedDateFilter = null),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                if (announcementProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (filteredAnnouncements.isEmpty)
                  const Text('No announcements in the last month.')
                else
                  ...filteredAnnouncements.take(5).map((a) {
                    return ListTile(
                      title: Text(a.title),
                      subtitle: Text(
                        a.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: a.categories.map((catId) {
                                        final cat = categoryProvider.categories
                                            .firstWhere((c) => c.id == catId,
                                                orElse: () => AnnouncementCategory(
                                                    id: '', name: '', createdAt: DateTime.now()));
                          return Chip(
                            label: Text(cat.name, style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AnnouncementDetailScreen.routeName,
                          arguments: AnnouncementDetailArgs(announcement: a),
                        );
                      },
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Incomplete Tasks Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incomplete Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (userId == null)
                  const Text('Please login to see tasks.')
                else if (taskProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (incompleteTasks.isEmpty)
                  const Text('No incomplete tasks. Great job!')
                else
                  ...incompleteTasks.take(5).map((t) {
                    return ListTile(
                      leading: Checkbox(
                        value: false,
                        onChanged: (_) {
                          final updated = t.copyWith(isDone: true);
                          taskProvider.addOrUpdateTask(userId, updated);
                        },
                      ),
                      title: Text(t.title),
                      subtitle: Text('${t.category}${t.description != null ? ' - ${t.description}' : ''}'),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAnnouncementFilters(BuildContext context, List<AnnouncementCategory> categories) {
    String? tempCategoryId = _selectedCategoryId;
    DateTime? tempDateFilter = _selectedDateFilter;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Filter Announcements'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category filter
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tempCategoryId,
                  decoration: const InputDecoration(labelText: 'Select Category'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map((c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Date filter
                const Text('Date Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        tempDateFilter = date;
                      });
                    }
                  },
                  child: Text(tempDateFilter == null
                      ? 'Select Date'
                      : 'From ${tempDateFilter!.toString().split(' ')[0]}'),
                ),
                if (tempDateFilter != null)
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        tempDateFilter = null;
                      });
                    },
                    child: const Text('Clear Date Filter'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  tempCategoryId = null;
                  tempDateFilter = null;
                });
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Apply filters after dialog closes
                setState(() {
                  _selectedCategoryId = tempCategoryId;
                  _selectedDateFilter = tempDateFilter;
                });
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final role = auth.currentUser?.role ?? 'student';
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.currentUser?.displayName ?? 'Student'),
            accountEmail: Text(auth.currentUser?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('Announcements'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box),
            title: const Text('Tasks'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ProfileScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, SettingsScreen.routeName);
            },
          ),
          if (role == 'admin')
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AdminDashboardScreen.routeName);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  LoginScreen.routeName,
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
