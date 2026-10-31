import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/widgets/empty_state.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcement_detail_screen.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcement_edit_screen.dart';
import 'package:campus_companion/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';

/// Time windows offered by the announcements filter. `null` means any time.
const _timeWindows = <(String, Duration?)>[
  ('Any time', null),
  ('Last 7 days', Duration(days: 7)),
  ('Last 30 days', Duration(days: 30)),
  ('Last 90 days', Duration(days: 90)),
];

class AnnouncementsListScreen extends StatefulWidget {
  static const routeName = '/announcements';

  const AnnouncementsListScreen({super.key});

  @override
  State<AnnouncementsListScreen> createState() =>
      _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  String? _categoryId;
  Duration? _window;
  String _query = '';

  List<Announcement> _filter(List<Announcement> all) {
    final needle = _query.trim().toLowerCase();
    final cutoff = _window == null ? null : DateTime.now().subtract(_window!);

    return all.where((a) {
      if (cutoff != null && a.createdAt.isBefore(cutoff)) return false;
      if (_categoryId != null && !a.categories.contains(_categoryId)) {
        return false;
      }
      if (needle.isEmpty) return true;
      return a.title.toLowerCase().contains(needle) ||
          a.body.toLowerCase().contains(needle);
    }).toList();
  }

  void _clearFilters() => setState(() {
        _categoryId = null;
        _window = null;
        _query = '';
      });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final canEdit = context.select<AuthProvider, bool>(
      (a) => a.currentUser?.role.canManageAnnouncements ?? false,
    );

    final announcements = _filter(provider.announcements);
    final hasFilters =
        _categoryId != null || _window != null || _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          PopupMenuButton<Duration?>(
            tooltip: 'Time range',
            icon: Icon(
              Icons.date_range,
              color: _window != null
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            initialValue: _window,
            onSelected: (v) => setState(() => _window = v),
            itemBuilder: (_) => [
              for (final (label, window) in _timeWindows)
                CheckedPopupMenuItem<Duration?>(
                  value: window,
                  checked: _window == window,
                  child: Text(label),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(
                context,
                AnnouncementEditScreen.routeName,
                arguments: AnnouncementEditArgs(announcement: null),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search announcements',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                  ),
                  for (final c in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (selected) => setState(
                            () => _categoryId = selected ? c.id : null),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.loadAnnouncements();
                if (context.mounted) {
                  await context.read<CategoryProvider>().loadCategories();
                }
              },
              child:
                  _buildBody(provider, announcements, categories, hasFilters),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AnnouncementProvider provider,
    List<Announcement> announcements,
    List categories,
    bool hasFilters,
  ) {
    if (provider.isLoading && provider.announcements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (announcements.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: EmptyState(
              icon: provider.errorMessage != null
                  ? Icons.cloud_off
                  : hasFilters
                      ? Icons.search_off
                      : Icons.campaign_outlined,
              title: provider.errorMessage ??
                  (hasFilters
                      ? 'No matching announcements'
                      : 'No announcements yet'),
              message: provider.errorMessage != null
                  ? 'Pull down to try again.'
                  : hasFilters
                      ? 'Try a different search or clear the filters.'
                      : 'New announcements will appear here.',
              action: hasFilters
                  ? TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear filters'),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final a = announcements[index];
        return AnnouncementCard(
          announcement: a,
          categories: context.read<CategoryProvider>().categories,
          onTap: () => Navigator.pushNamed(
            context,
            AnnouncementDetailScreen.routeName,
            arguments: AnnouncementDetailArgs(announcement: a),
          ),
        );
      },
    );
  }
}
