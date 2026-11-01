import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/offline/offline_state.dart';

/// A slim notice shown while the screens display saved data.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.select<OfflineState, bool>((s) => s.isOffline);
    if (!offline) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "You're offline. Showing saved data.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
