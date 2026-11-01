import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/announcements/data/announcement_json.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';
import 'package:campus_companion/features/categories/data/category_json.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart';
import 'package:campus_companion/features/tasks/data/task_json.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';

void main() {
  test('an announcement survives a JSON round trip', () {
    final original = Announcement(
      id: 'a1',
      title: 'Open day',
      body: 'Come along',
      createdAt: DateTime.utc(2030, 5, 1, 10).toLocal(),
      categories: const ['c1', 'c2'],
      images: const [AnnouncementImage(path: 'a1/x.jpg', url: 'https://f/x')],
      eventStart: DateTime.utc(2030, 6, 1, 9).toLocal(),
      eventEnd: DateTime.utc(2030, 6, 1, 12).toLocal(),
      location: 'Main hall',
      isPinned: true,
    );

    final copy = announcementsFromJson(announcementsToJson([original])).single;

    expect(copy.id, original.id);
    expect(copy.title, original.title);
    expect(copy.createdAt, original.createdAt);
    expect(copy.categories, original.categories);
    expect(copy.images.single.url, 'https://f/x');
    expect(copy.eventStart, original.eventStart);
    expect(copy.eventEnd, original.eventEnd);
    expect(copy.location, 'Main hall');
    expect(copy.isPinned, isTrue);
  });

  test('a plain announcement keeps its empty fields empty', () {
    final copy = announcementsFromJson(
      announcementsToJson([
        Announcement(id: 'a', title: 't', body: 'b', createdAt: DateTime(2030)),
      ]),
    ).single;

    expect(copy.isEvent, isFalse);
    expect(copy.images, isEmpty);
    expect(copy.isPinned, isFalse);
  });

  test('a task survives a JSON round trip', () {
    final original = Task(
      id: 't1',
      title: 'Essay',
      description: 'Chapter 3',
      dueDate: DateTime.utc(2030, 6, 20).toLocal(),
      isDone: true,
      remindDaysBefore: 2,
    );

    final copy = tasksFromJson(tasksToJson([original])).single;

    expect(copy.title, 'Essay');
    expect(copy.description, 'Chapter 3');
    expect(copy.dueDate, original.dueDate);
    expect(copy.isDone, isTrue);
    expect(copy.remindDaysBefore, 2);
  });

  test('a category survives a JSON round trip', () {
    final original = AnnouncementCategory(
      id: 'c1',
      name: 'Exams',
      createdAt: DateTime.utc(2030).toLocal(),
    );

    final copy = categoriesFromJson(categoriesToJson([original])).single;

    expect(copy.name, 'Exams');
    expect(copy.createdAt, original.createdAt);
  });
}
