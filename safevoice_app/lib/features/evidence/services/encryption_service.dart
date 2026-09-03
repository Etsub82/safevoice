import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import '../../../core/error/exceptions.dart';

/// On-device AES-256-GCM file encryption.
/// Implements P15: ciphertext transmitted must not equal plaintext.
class EncryptionService {
  /// Encrypts [sourceFile] and writes ciphertext to a temp file.
  /// Returns the encrypted [File] and the ephemeral [enc.Key] used.
  /// The key is ephemeral — only kept in memory for the upload session.
  Future<EncryptedFileResult> encryptFile(File sourceFile) async {
    try {
      final plainBytes = await sourceFile.readAsBytes();

      // Generate ephemeral AES-256 key and random IV
      final key = enc.Key.fromSecureRandom(32); // 256 bits
      final iv = enc.IV.fromSecureRandom(16); // 128-bit IV

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

      // Prepend IV (16 bytes) + ciphertext so the backend can decrypt
      final combined = Uint8List(16 + encrypted.bytes.length);
      combined.setRange(0, 16, iv.bytes);
      combined.setRange(16, combined.length, encrypted.bytes);

      final tempDir = await getTemporaryDirectory();
      final encFile = File('${tempDir.path}/${sourceFile.uri.pathSegments.last}.enc');
      await encFile.writeAsBytes(combined, flush: true);

      return EncryptedFileResult(file: encFile, key: key, iv: iv);
    } catch (e) {
      throw EncryptionException('Failed to encrypt file: $e');
    }
  }
}

class EncryptedFileResult {
  final File file;
  final enc.Key key;
  final enc.IV iv;

  const EncryptedFileResult({
    required this.file,
    required this.key,
    required this.iv,
  });
}
