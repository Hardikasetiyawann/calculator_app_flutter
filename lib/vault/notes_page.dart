import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'file_crypto.dart';
import 'file_manager.dart';
import 'package:path/path.dart' as path;

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<File> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    setState(() => isLoading = true);
    final dir = await FileManager.getVaultDir();
    if (await dir.exists()) {
      final list = dir.listSync().whereType<File>().where((f) {
        return path.basename(f.path).startsWith('note_');
      }).toList();
      list.sort((a, b) => b.path.compareTo(a.path));
      setState(() {
        notes = list;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorPage()),
    );
    loadNotes();
  }

  Future<void> _editNote(File file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(file: file),
      ),
    );
    loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Secured Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20),
        actions: [
          if (notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              onPressed: _addNote,
            )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? _buildEmptyState(isDark)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1, 
                  ),
                  itemCount: notes.length,
                  itemBuilder: (_, i) {
                    final file = notes[i];
                    return _buildNoteTile(file, i, isDark);
                  },
                ),
    );
  }

  Widget _buildNoteTile(File file, int index, bool isDark) {
    // Variety of subtle border colors
    final colors = [
      Colors.amberAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
    ];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => _editNote(file),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232327) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notes_rounded, color: color, size: 16),
            ),
            const Spacer(),
            Text(
              'Secure Note',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(file),
              style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), 
                  fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(File file) {
    try {
      final name = path.basename(file.path);
      final parts = name.split('_');
      if (parts.length > 1) {
        final tsStr = parts[1].split('.')[0];
        final ts = int.tryParse(tsStr);
        if (ts != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(ts);
          final now = DateTime.now();
          if (date.year == now.year && date.month == now.month && date.day == now.day) {
            return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
          }
          return '${date.day}/${date.month}/${date.year}';
        }
      }
    } catch (_) {}
    return 'Unknown date';
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
            child: Icon(Icons.edit_note_rounded, size: 64, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          const SizedBox(height: 24),
          Text(
            'No notes yet',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Write down your private thoughts securely.',
            style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addNote,
            icon: const Icon(Icons.edit),
            label: const Text('Create Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black87,
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

class NoteEditorPage extends StatefulWidget {
  final File? file;
  const NoteEditorPage({super.key, this.file});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.file != null) {
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await FileCrypto.decryptToBytes(widget.file!);
      final content = utf8.decode(bytes);
      _controller.text = content;
    } catch (e) {
      debugPrint('Error loading note: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isLoading = true);

    final vault = await FileManager.getVaultDir();
    File targetFile;
    
    if (widget.file != null) {
      targetFile = widget.file!;
    } else {
      targetFile = File('${vault.path}/note_${DateTime.now().millisecondsSinceEpoch}.txt');
    }

    final tempDir = await Directory.systemTemp.createTemp();
    final tempInput = File('${tempDir.path}/temp_note.txt');
    await tempInput.writeAsString(_controller.text);
    
    await FileCrypto.encryptFile(tempInput, targetFile);
    await tempInput.delete();
    
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
     if (widget.file != null) {
       await FileCrypto.deleteFile(widget.file!);
       if (mounted) Navigator.pop(context);
     }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          if (widget.file != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: _delete,
            ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TextButton(
                onPressed: _save,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amberAccent.withOpacity(0.1),
                  foregroundColor: Colors.amberAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                autofocus: widget.file == null,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87, 
                  fontSize: 18,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
                  border: InputBorder.none,
                ),
              ),
            ),
    );
  }
}
