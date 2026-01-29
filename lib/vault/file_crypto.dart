import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FileCrypto {
  static const _secure = FlutterSecureStorage();
  static const _keyName = 'file_aes_key';

  static Future<Key> _getKey() async {
    String? stored = await _secure.read(key: _keyName);
    if (stored == null) {
      final key = Key.fromSecureRandom(32);
      await _secure.write(key: _keyName, value: key.base64);
      return key;
    }
    return Key.fromBase64(stored);
  }

  static Future<File> encryptFile(File input, File output) async {
    final key = await _getKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));

    final bytes = await input.readAsBytes();
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    // Prepend IV to the encrypted bytes (16 bytes)
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);

    return output.writeAsBytes(combined, flush: true);
  }

  static Future<File> decryptFile(File input, File output) async {
    final key = await _getKey();
    final encrypter = Encrypter(AES(key));

    final bytes = await input.readAsBytes();
    
    // Extract IV from the first 16 bytes
    final ivBytes = bytes.sublist(0, 16);
    final encryptedBytes = bytes.sublist(16);
    
    final iv = IV(Uint8List.fromList(ivBytes));
    final decrypted = encrypter.decryptBytes(Encrypted(Uint8List.fromList(encryptedBytes)), iv: iv);

    return output.writeAsBytes(decrypted, flush: true);
  }

  static Future<Uint8List> decryptToBytes(File input) async {
    final key = await _getKey();
    final encrypter = Encrypter(AES(key));

    final bytes = await input.readAsBytes();
    
    // Extract IV from the first 16 bytes
    final ivBytes = bytes.sublist(0, 16);
    final encryptedBytes = bytes.sublist(16);
    
    final iv = IV(Uint8List.fromList(ivBytes));
    return Uint8List.fromList(encrypter.decryptBytes(Encrypted(Uint8List.fromList(encryptedBytes)), iv: iv));
  }

  static Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
