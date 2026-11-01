import 'dart:typed_data';

/// A photo already stored for an announcement.
class AnnouncementImage {
  const AnnouncementImage({required this.path, required this.url});

  /// Location inside the storage bucket, e.g. `<announcement id>/<name>.jpg`.
  final String path;

  /// Address the image can be displayed from.
  final String url;
}

/// A photo picked on the device that has not been uploaded yet.
class NewImage {
  const NewImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// The most photos one announcement can hold. Also enforced by the database.
const maxAnnouncementImages = 8;
