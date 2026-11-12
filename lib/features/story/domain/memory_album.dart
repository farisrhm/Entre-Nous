import '../../../core/domain/entry.dart';

/// V1 memories have one `photo`; V2 stores an ordered `photos` array.
/// An explicitly empty array must not bring back a removed legacy photo.
abstract final class MemoryAlbum {
  static const maxPhotos = 8;
  static const maxPhotoBytes = 12000000;
  static const maxEncodedLength = 50000000;

  static List<String> photosOf(Entry entry) {
    final photos = entry.fields['photos'];
    if (photos is List) {
      return photos.whereType<String>().where((p) => p.isNotEmpty).toList();
    }
    final old = entry.text('photo');
    return old.isEmpty ? [] : [old];
  }

  static void validate(List<String> photos, {bool privateStorage = false}) {
    if (photos.length > maxPhotos) {
      throw const FormatException(
        'Un souvenir peut contenir jusqu’à 8 photos.',
      );
    }
    if (!privateStorage &&
        photos.fold<int>(0, (n, p) => n + p.length) > maxEncodedLength) {
      throw const FormatException(
        'Cet album est trop volumineux. Choisis moins de photos ou des images plus légères.',
      );
    }
  }
}
