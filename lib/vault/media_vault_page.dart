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
      final list = dir.listSync().whereType<File>().toList();
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
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Pick Image'),
              onTap: () {
                Navigator.pop(context);
                pickMedia(ImageSource.gallery, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Pick Video'),
              onTap: () {
                Navigator.pop(context);
                pickMedia(ImageSource.gallery, isVideo: true);
              },
            ),
          ],
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

    // Attempt to delete the original file
    try {
      final original = File(picked.path);
      if (await original.exists()) {
        await original.delete();
      }
    } catch (e) {
      // Ignore errors if file cannot be deleted (e.g. permission issues on some android versions)
      debugPrint('Error deleting original file: $e');
    }
    
    await loadFiles();
  }

  void _viewMedia(File file) async {
    final isVideo = file.path.contains('vid_');
    
    showDialog(
      context: context,
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1E),
      appBar: AppBar(
        title: const Text('Media Vault'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: _showPickOptions,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: files.length,
                  itemBuilder: (_, i) {
                    final file = files[i];
                    final isVideo = file.path.contains('vid_');
                    return GestureDetector(
                      onTap: () => _viewMedia(file),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D33),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            isVideo ? Icons.play_circle_outline : Icons.image_outlined,
                            color: Colors.white54,
                            size: 32,
                           ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'Vault is Empty',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18),
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
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  widget.onDelete();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          Expanded(
            child: isDecrypting
                ? const Center(child: CircularProgressIndicator())
                : widget.isVideo
                    ? Center(
                        child: _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : const CircularProgressIndicator(),
                      )
                    : Image.file(tempFile!, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
