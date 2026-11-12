import 'dart:typed_data';

/// Opaque references are persisted; signed/public URLs and credentials are not.
abstract interface class PrivatePhotoRepository {
  Future<Uint8List> downloadPhoto(String source, {bool thumbnail = false});
}

abstract final class PrivatePhotos {
  static const prefix = 'storage:wedding-photos/';
  static const bucket = 'wedding-photos';
  static const maxBytes = 20 * 1024 * 1024;
  static final _path = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{32}\.(jpeg|png|webp)$',
  );
  static String path(String source) {
    if (!source.startsWith(prefix)) {
      throw const FormatException('Photo invalide.');
    }
    final value = source.substring(prefix.length);
    if (!_path.hasMatch(value)) throw const FormatException('Photo invalide.');
    return value;
  }
}
