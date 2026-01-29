import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'file_manager.dart';
import 'file_crypto.dart';

class MediaVaultPage extends StatefulWidget {
  const MediaVaultPage({super.key});

  @override
  State<MediaVaultPage> createState() => _MediaVaultPageState();
}

class _MediaVaultPageState extends State<MediaVaultPage> {
  List<File> files = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    setState(() => isLoading = true);
    final dir = await FileManager.getVaultDir();
    if (await dir.exists()) {
      final list = dir.listSync().whereType<File>().where((f) {
        final name = f.path.split(Platform.pathSeparator).last;
        return name.startsWith('img_') || name.startsWith('vid_');
      }).toList();
      // Sort by name (timestamp) descending
      list.sort((a, b) => b.path.compareTo(a.path));
      setState(() {
        files = list;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showPickOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF232327),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Text('Add Media', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.image_rounded, color: Colors.blueAccent),
                title: const Text('Pick Image', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  pickMedia(ImageSource.gallery, isVideo: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_rounded, color: Colors.purpleAccent),
                title: const Text('Pick Video', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  pickMedia(ImageSource.gallery, isVideo: true);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pickMedia(ImageSource source, {required bool isVideo}) async {
    final picker = ImagePicker();
    final XFile? picked = isVideo
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);

    if (picked == null) return;

    final vault = await FileManager.getVaultDir();
    final prefix = isVideo ? 'vid' : 'img';
    final encryptedFile = File(
      '${vault.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.bin',
    );

    await FileCrypto.encryptFile(
      File(picked.path),
      encryptedFile,
    );

    try {
      final original = File(picked.path);
      if (await original.exists()) {
        await original.delete();
      }
    } catch (e) {
      debugPrint('Error deleting original file: $e');
    }
    
    await loadFiles();
  }

  void _viewMedia(File file) async {
    final isVideo = file.path.contains('vid_');
    
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => _MediaPreviewDialog(
        file: file, 
        isVideo: isVideo, 
        onDelete: () {
          FileCrypto.deleteFile(file);
          loadFiles();
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Media Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20),
        actions: [
          if (files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              onPressed: _showPickOptions,
            )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? _buildEmptyState(isDark)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: files.length,
                  itemBuilder: (_, i) {
                    final file = files[i];
                    final isVideo = file.path.contains('vid_');
                    
                    return GestureDetector(
                      onTap: () => _viewMedia(file),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF232327) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: isVideo 
                                ? Container(
                                    color: Colors.black87,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_filled_rounded,
                                        color: Colors.white54,
                                        size: 40,
                                       ),
                                    ),
                                  )
                                : FutureBuilder<Uint8List>(
                                    future: FileCrypto.decryptToBytes(file),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white24),
                                        );
                                      }
                                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                    },
                                  ),
                            ),
                            if (isVideo)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.photo_library_rounded, size: 64, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          const SizedBox(height: 24),
          Text(
            'Gallery is empty',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Encrypt and hide your private media.',
            style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showPickOptions,
            icon: const Icon(Icons.add),
            label: const Text('Add Media'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPreviewDialog extends StatefulWidget {
  final File file;
  final bool isVideo;
  final VoidCallback onDelete;

  const _MediaPreviewDialog({
    required this.file,
    required this.isVideo,
    required this.onDelete,
  });

  @override
  State<_MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<_MediaPreviewDialog> {
  bool isDecrypting = true;
  File? tempFile;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _decrypt();
  }

  Future<void> _decrypt() async {
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/temp_decrypted_${DateTime.now().millisecondsSinceEpoch}');
    await FileCrypto.decryptFile(widget.file, out);
    
    if (mounted) {
      if (widget.isVideo) {
        _videoController = VideoPlayerController.file(out)
          ..initialize().then((_) {
            setState(() {
              isDecrypting = false;
            });
            _videoController?.play();
            _videoController?.setLooping(true);
          });
      } else {
        setState(() {
          tempFile = out;
          isDecrypting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    tempFile?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: isDecrypting
                ? const CircularProgressIndicator(color: Colors.white)
                : widget.isVideo
                    ? _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator(color: Colors.white)
                    : InteractiveViewer(
                        child: Image.file(tempFile!, fit: BoxFit.contain),
                      ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.onDelete();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
