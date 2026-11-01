import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:campus_companion/features/announcements/domain/announcement_image.dart';
import 'package:campus_companion/features/announcements/presentation/widgets/announcement_gallery.dart';

/// Photo section of the announcement form: thumbnails with remove buttons and
/// an add tile. Holds no state itself; the screen owns the two lists.
class PhotoEditor extends StatelessWidget {
  const PhotoEditor({
    super.key,
    required this.stored,
    required this.added,
    required this.onStoredChanged,
    required this.onAddedChanged,
  });

  final List<AnnouncementImage> stored;
  final List<NewImage> added;
  final ValueChanged<List<AnnouncementImage>> onStoredChanged;
  final ValueChanged<List<NewImage>> onAddedChanged;

  int get _count => stored.length + added.length;

  Future<void> _pick(BuildContext context) async {
    final remaining = maxAnnouncementImages - _count;
    if (remaining <= 0) return;
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    try {
      // Shrinking on the device keeps uploads small and fast.
      final files = remaining == 1
          ? [
              await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1600,
                maxHeight: 1600,
                imageQuality: 82,
              ),
            ].whereType<XFile>().toList()
          : await picker.pickMultiImage(
              limit: remaining,
              maxWidth: 1600,
              maxHeight: 1600,
              imageQuality: 82,
            );
      if (files.isEmpty) return;
      final picked = [
        for (final file in files.take(remaining))
          NewImage(name: file.name, bytes: await file.readAsBytes()),
      ];
      onAddedChanged([...added, ...picked]);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open your photos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              '$_count / $maxAnnouncementImages',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < stored.length; i++)
                _Thumb(
                  cover: i == 0,
                  onRemove: () => onStoredChanged([...stored]..removeAt(i)),
                  child: NetworkPhoto(url: stored[i].url, cacheWidth: 300),
                ),
              for (var i = 0; i < added.length; i++)
                _Thumb(
                  cover: stored.isEmpty && i == 0,
                  onRemove: () => onAddedChanged([...added]..removeAt(i)),
                  child: Image.memory(
                    added[i].bytes,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                  ),
                ),
              if (_count < maxAnnouncementImages)
                Semantics(
                  button: true,
                  label: 'Add photos',
                  child: InkWell(
                    onTap: () => _pick(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: scheme.primary),
                          const SizedBox(height: 4),
                          Text('Add', style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_count > 0) ...[
          const SizedBox(height: 6),
          Text(
            'The first photo is the cover.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.child,
    required this.onRemove,
    required this.cover,
  });

  final Widget child;
  final VoidCallback onRemove;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 96,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
            if (cover)
              Positioned(
                left: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Cover',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 2,
              right: 2,
              child: IconButton.filled(
                tooltip: 'Remove photo',
                onPressed: onRemove,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
