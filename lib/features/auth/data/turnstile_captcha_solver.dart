import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/routing/root_navigator.dart';
import 'package:campus_companion/features/auth/domain/captcha_solver.dart';

/// Shows a Cloudflare Turnstile challenge in a dialog and returns its token.
///
/// The site key is public by design. The matching secret key lives only in
/// the Supabase project, which verifies every token.
class TurnstileCaptchaSolver implements CaptchaSolver {
  TurnstileCaptchaSolver(this.siteKey)
      : assert(_validKey.hasMatch(siteKey), 'Invalid Turnstile site key');

  final String siteKey;

  static final _validKey = RegExp(r'^[A-Za-z0-9_-]+$');

  @override
  bool get isEnabled => true;

  @override
  Future<String?> solve() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      throw const AppException('Could not start the security check.');
    }
    final token = await showDialog<String>(
      context: context,
      builder: (_) => _ChallengeDialog(siteKey: siteKey),
    );
    if (token == null) {
      throw const AppException('Security check cancelled. Please try again.');
    }
    return token;
  }
}

class _ChallengeDialog extends StatefulWidget {
  const _ChallengeDialog({required this.siteKey});

  final String siteKey;

  @override
  State<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<_ChallengeDialog> {
  late final WebViewController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'Captcha',
        onMessageReceived: (message) {
          if (!mounted) return;
          if (message.message.startsWith('error:')) {
            setState(() => _failed = true);
          } else {
            Navigator.of(context).pop(message.message);
          }
        },
      )
      ..loadHtmlString(_page(widget.siteKey), baseUrl: 'https://localhost');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick security check'),
      content: SizedBox(
        height: 150,
        child: _failed
            ? const Center(
                child: Text(
                  'The check could not load. Check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

String _page(String siteKey) => '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>html,body{margin:0;height:100%;display:flex;align-items:center;justify-content:center;background:transparent}</style>
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=ready" async defer></script>
</head>
<body>
<div id="widget"></div>
<script>
function ready() {
  turnstile.render('#widget', {
    sitekey: '$siteKey',
    size: 'compact',
    callback: function (token) { Captcha.postMessage(token); },
    'error-callback': function () { Captcha.postMessage('error:widget'); }
  });
}
</script>
</body>
</html>
''';
