import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/widgets/empty_state.dart';
import 'package:campus_companion/core/widgets/text_input_dialog.dart';
import 'package:campus_companion/features/admin/presentation/providers/users_provider.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/user_role.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';

enum _UserAction { rename, student, professor, admin, toggleSuspend, delete }

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UsersProvider>().loadUsers();
    });
  }

  Future<void> _rename(AppUser user) async {
    final provider = context.read<UsersProvider>();
    final name = await showTextInputDialog(
      context,
      title: 'Edit display name',
      label: 'Display name',
      confirmLabel: 'Save',
      initialValue: user.displayName ?? '',
      capitalization: TextCapitalization.words,
    );
    if (name != null) {
      await provider.updateUser(user.copyWith(displayName: name));
    }
  }

  Future<void> _delete(AppUser user) async {
    final provider = context.read<UsersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final label = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName!
        : user.email;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          '$label and all of their tasks will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await provider.deleteUser(user.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Account deleted'
              : provider.errorMessage ?? 'Could not delete the account',
        ),
      ),
    );
  }

  Future<void> _onAction(AppUser user, _UserAction action) async {
    final provider = context.read<UsersProvider>();
    switch (action) {
      case _UserAction.rename:
        await _rename(user);
      case _UserAction.student:
        await provider.updateUser(user.copyWith(role: UserRole.student));
      case _UserAction.professor:
        await provider.updateUser(user.copyWith(role: UserRole.professor));
      case _UserAction.admin:
        await provider.updateUser(user.copyWith(role: UserRole.admin));
      case _UserAction.toggleSuspend:
        await provider.updateUser(
          user.copyWith(isSuspended: !user.isSuspended),
        );
      case _UserAction.delete:
        await _delete(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final provider = context.watch<UsersProvider>();
    final currentId = context.select<AuthProvider, String?>(
      (a) => a.currentUser?.id,
    );

    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.users.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: provider.errorMessage!,
        action: TextButton(
          onPressed: provider.loadUsers,
          child: const Text('Retry'),
        ),
      );
    }

    final needle = _query.trim().toLowerCase();
    final users = provider.users.where((u) {
      if (needle.isEmpty) return true;
      return (u.displayName ?? '').toLowerCase().contains(needle) ||
          u.email.toLowerCase().contains(needle);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search users',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off, title: 'No users found')
              : RefreshIndicator(
                  onRefresh: provider.loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelf = user.id == currentId;
                      final name = (user.displayName?.isNotEmpty ?? false)
                          ? user.displayName!
                          : user.email;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: user.isSuspended
                                ? scheme.errorContainer
                                : scheme.primaryContainer,
                            child: Text(name.characters.first.toUpperCase()),
                          ),
                          title: Text(isSelf ? '$name (you)' : name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: [
                                  _Badge(
                                    label: user.role.label,
                                    background: scheme.secondaryContainer,
                                    foreground: scheme.onSecondaryContainer,
                                  ),
                                  if (user.isSuspended)
                                    _Badge(
                                      label: 'Suspended',
                                      background: scheme.errorContainer,
                                      foreground: scheme.onErrorContainer,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: isSelf
                              ? null
                              : PopupMenuButton<_UserAction>(
                                  tooltip: 'Manage user',
                                  onSelected: (a) => _onAction(user, a),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: _UserAction.rename,
                                      child: Text('Edit name'),
                                    ),
                                    const PopupMenuDivider(),
                                    for (final (action, role) in const [
                                      (_UserAction.student, UserRole.student),
                                      (
                                        _UserAction.professor,
                                        UserRole.professor
                                      ),
                                      (_UserAction.admin, UserRole.admin),
                                    ])
                                      CheckedPopupMenuItem(
                                        value: action,
                                        checked: user.role == role,
                                        child: Text('Role: ${role.label}'),
                                      ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: _UserAction.toggleSuspend,
                                      child: Text(
                                        user.isSuspended
                                            ? 'Unsuspend'
                                            : 'Suspend',
                                        style: TextStyle(
                                          color: user.isSuspended
                                              ? null
                                              : scheme.error,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _UserAction.delete,
                                      child: Text(
                                        'Delete account…',
                                        style: TextStyle(color: scheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}
