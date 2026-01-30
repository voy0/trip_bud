import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MediaSyncService {
  static final MediaSyncService _instance = MediaSyncService._internal();

  MediaSyncService._internal();

  factory MediaSyncService() {
    return _instance;
  }

  Future<Directory> _getTripPhotosDir(String tripId) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final tripDir = Directory('${baseDir.path}/trips/$tripId/photos');
    if (!await tripDir.exists()) {
      await tripDir.create(recursive: true);
    }
    return tripDir;
  }

  /// Get trip photos from local storage
  Future<List<File>> getTripPhotos(String tripId) async {
    try {
      final tripDir = await _getTripPhotosDir(tripId);
      final files = await tripDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Count photos in trip
  Future<int> countTripPhotos(String tripId) async {
    final urls = await getTripPhotos(tripId);
    return urls.length;
  }
}
