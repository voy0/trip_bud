import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:trip_bud/l10n/app_localizations.dart';

class GalleryGridView extends StatefulWidget {
  final String tripId;
  final Color accentColor;

  const GalleryGridView({
    super.key,
    required this.tripId,
    this.accentColor = const Color.fromARGB(255, 0, 200, 120),
  });

  @override
  State<GalleryGridView> createState() => _GalleryGridViewState();
}

class _GalleryGridViewState extends State<GalleryGridView> {
  final ImagePicker _picker = ImagePicker();
  List<String> photoUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'trips/${widget.tripId}',
      );
      final list = await ref.listAll();

      final urls = <String>[];
      for (var item in list.items) {
        try {
          urls.add(await item.getDownloadURL());
        } catch (e) {
          // Error getting download URL - continue silently
        }
      }

      if (mounted) {
        setState(() => photoUrls = urls);
      }
    } catch (e) {
      if (!mounted) return;
      // Error loading photos - show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).errorLoadingPhotos} $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addPhotoFromCamera() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;

      await _uploadPhoto(File(photo.path));
    } catch (e) {
      if (!mounted) return;
      // Error picking from camera - show snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _uploadPhoto(File photo) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'trips/${widget.tripId}/$fileName',
      );

      await ref.putFile(photo);
      final url = await ref.getDownloadURL();

      if (mounted) {
        setState(() {
          photoUrls.add(url);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Error uploading photo - show snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePhoto(int index) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext).deletePhoto),
        content: Text(AppLocalizations.of(dialogContext).areYouSureDeletePhoto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                // Extract path from URL to delete from Firebase
                final fileName =
                    'trips/${widget.tripId}/${DateTime.now().millisecondsSinceEpoch}';
                await FirebaseStorage.instance.ref(fileName).delete();

                if (mounted) {
                  setState(() {
                    photoUrls.removeAt(index);
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).photoDeleted)),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(AppLocalizations.of(dialogContext).delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading && photoUrls.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : photoUrls.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).noPhotosYet,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _addPhotoFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(AppLocalizations.of(context).takePhoto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onLongPress: () => _deletePhoto(index),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
  }
}
