import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null ? const Text('No user data.') : _ProfileContent(),
      ),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email: ${user.email}'),
          const SizedBox(height: 8),
          Text('Role: ${user.role.label}'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Display Name'),
          ),
          const SizedBox(height: 16),
          if (auth.isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok =
                    await auth.updateDisplayName(_nameController.text.trim());
                messenger.showSnackBar(SnackBar(
                  content: Text(ok ? 'Profile updated' : auth.errorMessage!),
                ));
              },
              child: const Text('Save Changes'),
            ),
        ],
      ),
    );
  }
}
