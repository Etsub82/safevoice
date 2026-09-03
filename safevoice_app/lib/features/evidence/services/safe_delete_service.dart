import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import '../../../core/error/exceptions.dart';

/// Securely removes a file from device storage after a confirmed upload.
/// Implements P16: file must not be accessible after safe delete completes.
///
/// Strategy: single-pass overwrite with cryptographically random bytes, then delete.
/// Single-pass is sufficient for NAND/flash storage (SSD, eMMC) per NIST SP 800-88.
class SafeDeleteService {
  final Random _random = Random.secure();

  /// Overwrites [file] with random bytes, then deletes it.
  /// Throws [StorageException] if the operation fails.
  Future<void> safeDelete(File file) async {
    try {
      if (!await file.exists()) return; // Already gone — no-op

      final length = await file.length();
      if (length > 0) {
        final randomBytes = _generateRandomBytes(length);
        await file.writeAsBytes(randomBytes, flush: true);
      }

      await file.delete();
    } catch (e) {
      throw StorageException('Safe delete failed: $e');
    }
  }

  Uint8List _generateRandomBytes(int count) {
    final bytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }
}
