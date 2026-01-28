import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileManager {
  static Future<Directory> getVaultDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final vault = Directory('${dir.path}/.storage');
    if (!await vault.exists()) {
      await vault.create(recursive: true);
    }
    return vault;
  }
}
