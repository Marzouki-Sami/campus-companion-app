import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/widgets/auth_scaffold.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/auth/presentation/screens/reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final email = _email.text.trim();
    final ok = await auth.requestPasswordReset(email);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(
        context,
        ResetPasswordScreen.routeName,
        arguments: ResetPasswordArgs(email),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Could not send a code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);

    return AuthScaffold(
      showBackButton: true,
      title: 'Forgot your password?',
      subtitle: 'Enter your email and we will send you a code to reset it.',
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _submit(),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Please enter email';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Send code'),
        ),
      ],
    );
  }
}
