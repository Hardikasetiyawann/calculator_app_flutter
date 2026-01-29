import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'file_crypto.dart';
import 'file_manager.dart';
import 'package:path/path.dart' as path;

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<File> files = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    setState(() => isLoading = true);
    try {
      final dir = await FileManager.getVaultDir();
      if (await dir.exists()) {
        final List<File> list = [];
        await for (final entity in dir.list()) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            if (fileName.startsWith('doc_')) {
              list.add(entity);
            }
          }
        }
        list.sort((a, b) => b.path.compareTo(a.path));
        setState(() {
          files = list;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;
      final originalName = result.files.single.name;
      
      final vault = await FileManager.getVaultDir();
      final sanitizedName = originalName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final encryptedFile = File(
        '${vault.path}/doc_${DateTime.now().millisecondsSinceEpoch}_$sanitizedName.bin',
      );

      await FileCrypto.encryptFile(
        File(originalPath),
        encryptedFile,
      );

      try {
        final original = File(originalPath);
        if (await original.exists()) {
           await original.delete();
        }
      } catch (e) {
        debugPrint('Could not delete original: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }

      await loadFiles();
    }
  }

   Future<void> _openDocument(File file) async {
    try {
      final name = path.basename(file.path);
      String originalName = name;
      if (name.startsWith('doc_')) {
        final parts = name.split('_');
        if (parts.length > 2) {
          originalName = parts.sublist(2).join('_');
          if (originalName.endsWith('.bin')) {
            originalName = originalName.substring(0, originalName.length - 4);
          }
        }
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$originalName');

      await FileCrypto.decryptFile(file, tempFile);
      await OpenFilex.open(tempFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20),
        actions: [
          if (files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              onPressed: _pickFile,
            )
        ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : files.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final name = path.basename(file.path);
                
                String displayName = name;
                String ext = '';
                if (name.startsWith('doc_')) {
                   final parts = name.split('_');
                   if (parts.length > 2) {
                     displayName = parts.sublist(2).join('_');
                     if (displayName.endsWith('.bin')) {
                       displayName = displayName.substring(0, displayName.length - 4);
                     }
                     if (displayName.contains('.')) {
                       ext = displayName.split('.').last.toUpperCase();
                     }
                   }
                }

                return _buildDocumentTile(context, file, displayName, ext, isDark);
              },
            ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, File file, String name, String ext, bool isDark) {
    Color badgeColor = Colors.grey;
    if (ext == 'PDF') badgeColor = Colors.redAccent;
    else if (['DOC', 'DOCX'].contains(ext)) badgeColor = Colors.blueAccent;
    else if (['XLS', 'XLSX'].contains(ext)) badgeColor = Colors.greenAccent;
    else if (ext == 'TXT') badgeColor = Colors.amberAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232327) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_rounded, color: badgeColor, size: 24),
              if (ext.isNotEmpty)
                Text(
                  ext,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          name, 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _getFileSize(file),
          style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
          onSelected: (val) {
            if (val == 'delete') {
              FileCrypto.deleteFile(file);
              loadFiles();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openDocument(file),
      ),
    );
  }

  String _getFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
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
            child: Icon(Icons.folder_copy_rounded, size: 64, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          const SizedBox(height: 24),
          Text(
            'No documents yet',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your important files encrypted here.',
            style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.add),
            label: const Text('Add Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
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
