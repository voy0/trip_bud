import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  List<File> _photos = [];
  final Map<String, String> _photoHashesByPath = {};
  final Set<String> _photoHashes = {};
  bool _isLoading = false;
  bool _isDeleteMode = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<Directory> _getTripPhotosDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final tripDir = Directory('${baseDir.path}/trips/${widget.tripId}/photos');
    if (!await tripDir.exists()) {
      await tripDir.create(recursive: true);
    }
    return tripDir;
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final tripDir = await _getTripPhotosDir();
      final files = await tripDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      _photoHashesByPath.clear();
      _photoHashes.clear();
      for (final file in files) {
        try {
          final hash = await _hashFile(file);
          _photoHashesByPath[file.path] = hash;
          _photoHashes.add(hash);
        } catch (e) {
          // Ignore hashing errors for individual files
        }
      }

      if (mounted) {
        setState(() => _photos = files);
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

  Future<String> _hashFile(File file) async {
    final bytes = await file.readAsBytes();
    return sha1.convert(bytes).toString();
  }

  Future<void> _addPhotoFromGallery() async {
    try {
      final photos = await _picker.pickMultiImage();
      if (photos.isEmpty) return;

      await _savePhotos(photos);
    } catch (e) {
      if (!mounted) return;
      // Error picking from gallery - show snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _savePhotos(List<XFile> photos) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final tripDir = await _getTripPhotosDir();
      final savedFiles = <File>[];
      var skipped = 0;

      for (final photo in photos) {
        final sourceFile = File(photo.path);
        final sourceHash = await _hashFile(sourceFile);
        if (_photoHashes.contains(sourceHash)) {
          skipped++;
          continue;
        }

        final name = photo.name.trim().isNotEmpty
            ? photo.name.trim()
            : photo.path.split('/').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name';
        final saved = await sourceFile.copy('${tripDir.path}/$fileName');
        savedFiles.add(saved);
        _photoHashesByPath[saved.path] = sourceHash;
        _photoHashes.add(sourceHash);
      }

      if (mounted) {
        setState(() {
          _photos.addAll(savedFiles);
        });

        if (savedFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).photoUploadedSuccessfully,
              ),
            ),
          );
        }
        if (skipped > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).photosAlreadyAdded),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Error uploading photo - show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).errorUploading} $e'),
        ),
      );
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
                final file = _photos[index];
                if (await file.exists()) {
                  try {
                    final hash = _photoHashesByPath[file.path];
                    if (hash != null) {
                      _photoHashes.remove(hash);
                    }
                  } catch (e) {
                    // Ignore hash cleanup errors
                  }
                  await file.delete();
                }

                if (mounted) {
                  setState(() {
                    _photoHashesByPath.remove(file.path);
                    _photos.removeAt(index);
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).photoDeleted),
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${AppLocalizations.of(context).error}$e'),
                  ),
                );
              }
            },
            child: Text(
              AppLocalizations.of(dialogContext).delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading && _photos.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _photos.isEmpty
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
                  onPressed: _addPhotoFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(AppLocalizations.of(context).addPhoto),
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
            itemCount: _photos.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _addPhotoFromGallery,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: widget.accentColor,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context).addPhoto,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (index == 1) {
                final isDeleteMode = _isDeleteMode;
                return GestureDetector(
                  onTap: () {
                    setState(() => _isDeleteMode = !_isDeleteMode);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDeleteMode
                            ? Colors.red.withValues(alpha: 0.5)
                            : widget.accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDeleteMode
                              ? Icons.check_circle
                              : Icons.delete_outline,
                          color: isDeleteMode ? Colors.red : widget.accentColor,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isDeleteMode
                              ? AppLocalizations.of(context).done
                              : AppLocalizations.of(context).deletePhotos,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final photoIndex = index - 2;
              return GestureDetector(
                onTap: _isDeleteMode ? () => _deletePhoto(photoIndex) : null,
                onLongPress: () => _deletePhoto(photoIndex),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDeleteMode
                          ? Colors.red.withValues(alpha: 0.6)
                          : widget.accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _photos[photoIndex],
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
                        if (_isDeleteMode)
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
