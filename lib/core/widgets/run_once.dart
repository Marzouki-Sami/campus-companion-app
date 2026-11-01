import 'package:flutter/material.dart';

/// Runs [onRun] once, right after the first frame is shown.
class RunOnce extends StatefulWidget {
  const RunOnce({super.key, required this.onRun, required this.child});

  final VoidCallback onRun;
  final Widget child;

  @override
  State<RunOnce> createState() => _RunOnceState();
}

class _RunOnceState extends State<RunOnce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRun();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
