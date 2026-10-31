import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/widgets/auth_scaffold.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_companion/features/auth/presentation/widgets/one_time_code_field.dart';
import 'package:campus_companion/features/auth/presentation/widgets/resend_code_button.dart';
import 'package:campus_companion/features/home/presentation/screens/home_screen.dart';

class VerifyEmailArgs {
  const VerifyEmailArgs(this.email);

  final String email;
}

/// Asks for the 6-digit code emailed after sign-up (or after trying to sign
/// in with an unverified address).
class VerifyEmailScreen extends StatefulWidget {
  static const routeName = '/verify-email';

  const VerifyEmailScreen({super.key, required this.args});

  final VerifyEmailArgs args;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();

  String get _email => widget.args.email;

  @override
  void dispose() {
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(_email, _code.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.routeName,
        (_) => false,
      );
    } else {
      _code.clear();
      // The field is disabled while loading; focus it once it is enabled again.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _codeFocus.requestFocus(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Verification failed')),
      );
    }
  }

  Future<bool> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerification(_email);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Could not send a new code'),
        ),
      );
    }
    return ok;
  }

  void _useAnotherEmail() {
    context.read<AuthProvider>().clearPendingVerification();
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);

    return AuthScaffold(
      title: 'Check your email',
      subtitle: 'We sent a 6-digit code to\n$_email',
      children: [
        Form(
          key: _formKey,
          child: OneTimeCodeField(
            controller: _code,
            focusNode: _codeFocus,
            enabled: !isLoading,
            onCompleted: (_) => _submit(),
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
              : const Text('Verify'),
        ),
        const SizedBox(height: 8),
        ResendCodeButton(onResend: _resend),
        TextButton(
          onPressed: _useAnotherEmail,
          child: const Text('Use a different email'),
        ),
        const SizedBox(height: 16),
        Text(
          'No email? Check your spam folder. If you already have an account '
          'with this address, sign in or reset your password instead.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
