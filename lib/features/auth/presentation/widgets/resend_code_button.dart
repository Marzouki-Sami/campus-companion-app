import 'dart:async';

import 'package:flutter/material.dart';

/// "Resend code" that stays disabled for a minute after each send, matching
/// the server's email rate limit.
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({
    super.key,
    required this.onResend,
    this.cooldown = const Duration(seconds: 60),
  });

  /// Sends the code. Returns whether it was sent.
  final Future<bool> Function() onResend;
  final Duration cooldown;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    // A code was just sent to reach this screen.
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    final messenger = ScaffoldMessenger.of(context);
    _startCooldown();
    final sent = await widget.onResend();
    if (sent) {
      messenger.showSnackBar(const SnackBar(content: Text('New code sent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _secondsLeft > 0;
    return TextButton(
      onPressed: waiting ? null : _resend,
      child: Text(waiting ? 'Resend code in ${_secondsLeft}s' : 'Resend code'),
    );
  }
}
