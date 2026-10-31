import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart'
    show AnnouncementCategory;
import 'package:campus_companion/features/announcements/presentation/screens/announcement_detail_screen.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcement_edit_screen.dart';

class AnnouncementsListScreen extends StatefulWidget {
  static const routeName = '/announcements';

  const AnnouncementsListScreen({super.key});

  @override
  State<AnnouncementsListScreen> createState() =>
      _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  String? _selectedCategoryId;
  DateTime? _selectedDateFilter;
  String _searchQuery = '';
  final bool _searchStartsWith = true;

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadCategories();
  }

  List<Announcement> _getFilteredAnnouncements(List<Announcement> all) {
    var filtered = List<Announcement>.from(all);

    if (_selectedDateFilter != null) {
      filtered = filtered
          .where((a) => a.createdAt.isAfter(_selectedDateFilter!))
          .toList();
    }

    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((a) => a.categories.contains(_selectedCategoryId))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        final title = a.title.toLowerCase();
        final body = a.body.toLowerCase();
        final matches = _searchStartsWith
            ? title.startsWith(query) || body.startsWith(query)
            : title.contains(query) || body.contains(query);
        return matches;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final auth = context.watch<AuthProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final bool canEditAnnouncements =
        auth.currentUser?.role.canManageAnnouncements ?? false;

    final filteredAnnouncements =
        _getFilteredAnnouncements(provider.announcements);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context, categoryProvider.categories),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search announcements...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAnnouncements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (provider.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  provider.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            const Text('No announcements found.'),
                            if (_selectedCategoryId != null ||
                                _selectedDateFilter != null ||
                                _searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCategoryId = null;
                                    _selectedDateFilter = null;
                                    _searchQuery = '';
                                  });
                                },
                                child: const Text('Clear Filters'),
                              ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Active filters display
                          if (_selectedCategoryId != null ||
                              _selectedDateFilter != null ||
                              _searchQuery.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              color: Colors.grey.shade200,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  if (_selectedCategoryId != null)
                                    Chip(
                                      label: Text(
                                        categoryProvider.categories
                                            .firstWhere(
                                              (c) =>
                                                  c.id == _selectedCategoryId,
                                              orElse: () =>
                                                  AnnouncementCategory(
                                                      id: '',
                                                      name: 'Unknown',
                                                      createdAt:
                                                          DateTime.now()),
                                            )
                                            .name,
                                      ),
                                      onDeleted: () => setState(
                                          () => _selectedCategoryId = null),
                                    ),
                                  if (_selectedDateFilter != null)
                                    Chip(
                                      label: Text(
                                        'From ${_selectedDateFilter!.toString().split(' ')[0]}',
                                      ),
                                      onDeleted: () => setState(
                                          () => _selectedDateFilter = null),
                                    ),
                                  if (_searchQuery.isNotEmpty)
                                    Chip(
                                      label: Text(
                                        _searchStartsWith
                                            ? 'Starts with: $_searchQuery'
                                            : 'Contains: $_searchQuery',
                                      ),
                                      onDeleted: () =>
                                          setState(() => _searchQuery = ''),
                                    ),
                                ],
                              ),
                            ),
                          // Announcements list
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredAnnouncements.length,
                              itemBuilder: (context, index) {
                                final a = filteredAnnouncements[index];
                                return Hero(
                                  tag: 'announcement_${a.id}',
                                  child: Card(
                                    child: ListTile(
                                      title: Text(a.title),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (a.categories.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              children:
                                                  a.categories.map((catId) {
                                                final cat = categoryProvider
                                                    .categories
                                                    .firstWhere(
                                                  (c) => c.id == catId,
                                                  orElse: () =>
                                                      AnnouncementCategory(
                                                          id: '',
                                                          name: '',
                                                          createdAt:
                                                              DateTime.now()),
                                                );
                                                return Chip(
                                                  label: Text(cat.name,
                                                      style: const TextStyle(
                                                          fontSize: 10)),
                                                  padding: EdgeInsets.zero,
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Text(
                                        '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AnnouncementDetailScreen.routeName,
                                          arguments: AnnouncementDetailArgs(
                                              announcement: a),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: canEditAnnouncements
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AnnouncementEditScreen.routeName,
                  arguments: AnnouncementEditArgs(announcement: null),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showFilters(
      BuildContext context, List<AnnouncementCategory> categories) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Announcements'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Category:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Select Category'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Date Filter:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDateFilter = date);
                  }
                },
                child: Text(_selectedDateFilter == null
                    ? 'Select Date'
                    : 'From ${_selectedDateFilter!.toString().split(' ')[0]}'),
              ),
              if (_selectedDateFilter != null)
                TextButton(
                  onPressed: () => setState(() => _selectedDateFilter = null),
                  child: const Text('Clear Date Filter'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategoryId = null;
                _selectedDateFilter = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
