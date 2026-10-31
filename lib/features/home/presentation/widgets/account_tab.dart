import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_companion/features/profile/presentation/screens/profile_screen.dart';
import 'package:campus_companion/features/settings/presentation/screens/settings_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await auth.logout();
    navigator.pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = context.watch<AuthProvider>().currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? 'Guest');
    final initial = displayName.characters.first.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                initial,
                style: theme.textTheme.headlineLarge
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (user != null) ...[
            const SizedBox(height: 4),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Center(
              child: Chip(
                label: Text(user.role.label),
                avatar: const Icon(Icons.verified_user_outlined, size: 18),
                side: BorderSide.none,
                backgroundColor: scheme.secondaryContainer,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
          if (user?.role.isAdmin ?? false)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin dashboard'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushNamed(context, AdminDashboardScreen.routeName),
            ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text('Log out', style: TextStyle(color: scheme.error)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
