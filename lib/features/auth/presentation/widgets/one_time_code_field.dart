import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A large, centred input for the 6-digit code that arrives by email.
class OneTimeCodeField extends StatelessWidget {
  const OneTimeCodeField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onCompleted,
    this.enabled = true,
  });

  static const length = 6;

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: true,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(length),
      ],
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            letterSpacing: 12,
            fontWeight: FontWeight.w700,
          ),
      decoration: const InputDecoration(
        hintText: '••••••',
        counterText: '',
      ),
      validator: (v) =>
          (v ?? '').length == length ? null : 'Enter the 6-digit code',
      onChanged: (value) {
        if (value.length == length) onCompleted?.call(value);
      },
    );
  }
}
