import 'package:flutter/material.dart';
import 'media_vault_page.dart';

class StoragePage extends StatelessWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Documents'),
            subtitle: const Text('Internal files'),
            onTap: () {
              // Future feature
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Media'),
            subtitle: const Text('Images & videos'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MediaVaultPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Notes'),
            subtitle: const Text('Text storage'),
            onTap: () {
              // Future feature
            },
          ),
        ],
      ),
    );
  }
}
