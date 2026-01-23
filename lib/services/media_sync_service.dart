import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MediaSyncService {
  static final MediaSyncService _instance = MediaSyncService._internal();

  MediaSyncService._internal();

  factory MediaSyncService() {
    return _instance;
  }

  /// Sync photos from device gallery to trip storage
  Future<List<String>> syncTripPhotosFromGallery(String tripId) async {
    try {
      // Get all images from device gallery
      final galleryImages = await _getGalleryImages();

      final uploadedUrls = <String>[];

      for (final imageFile in galleryImages) {
        try {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
          final ref = FirebaseStorage.instance.ref().child(
            'trips/$tripId/$fileName',
          );

          await ref.putFile(File(imageFile.path));
          final url = await ref.getDownloadURL();
          uploadedUrls.add(url);
        } catch (e) {
          // Error uploading gallery image - continue silently
        }
      }

      return uploadedUrls;
    } catch (e) {
      // Error syncing gallery - continue silently
      return [];
    }
  }

  /// Get all images from device gallery
  Future<List<XFile>> _getGalleryImages() async {
    // Note: This would require photo_manager plugin for actual gallery access
    // For now, return empty list as placeholder
    return [];
  }

  /// Get trip photos from Firebase Storage
  Future<List<String>> getTripPhotos(String tripId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('trips/$tripId');
      final list = await ref.listAll();

      final urls = <String>[];
      for (var item in list.items) {
        try {
          urls.add(await item.getDownloadURL());
        } catch (e) {
          // Error getting URL - continue silently
        }
      }

      return urls;
    } catch (e) {
      // Error fetching trip photos - continue silently
      return [];
    }
  }

  /// Count photos in trip
  Future<int> countTripPhotos(String tripId) async {
    final urls = await getTripPhotos(tripId);
    return urls.length;
  }
}
