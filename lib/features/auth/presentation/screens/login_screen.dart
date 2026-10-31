import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/widgets/auth_scaffold.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:campus_companion/features/auth/presentation/screens/register_screen.dart';
import 'package:campus_companion/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:campus_companion/features/home/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = context.read<AuthProvider>().takeSessionEndedMessage();
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.trim(), _password);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } else if (auth.pendingVerificationEmail != null) {
      Navigator.pushNamed(
        context,
        VerifyEmailScreen.routeName,
        arguments: VerifyEmailArgs(auth.pendingVerificationEmail!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to see your announcements and tasks.',
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onSaved: (v) => _email = v ?? '',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                onSaved: (v) => _password = v ?? '',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter password' : null,
              ),
            ],
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
              : const Text('Login'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, ForgotPasswordScreen.routeName),
          child: const Text('Forgot password?'),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            RegisterScreen.routeName,
          ),
          child: const Text('Create an account'),
        ),
      ],
    );
  }
}
