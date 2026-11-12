import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'private_photos.dart';
import '../../features/story/domain/memory_album.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entry.dart';
import '../domain/wedding_repository.dart';

/// Uses Supabase Auth + Edge Functions.
class SupabaseWeddingRepository
    implements CloudWeddingRepository, PrivatePhotoRepository {
  final SupabaseClient client;
  String? _userId;
  List<Member> _members = const [];

  SupabaseWeddingRepository(this.client);

  @override
  bool get isCloud => true;

  @override
  String? get userId => _userId;

  @override
  List<Member> get members => List.unmodifiable(_members);

  @override
  bool get hasSession => client.auth.currentSession != null;

  @override
  Future<void> restore() async {
    _userId = client.auth.currentUser?.id;
  }

  @override
  Future<void> login(String username, String password) async {
    final email = _normalizeEmail(username);
    await client.auth.signInWithPassword(email: email, password: password);
    try {
      await load();
    } catch (_) {
      try {
        await client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // The SDK removes the local session before attempting remote revocation.
      }
      _userId = null;
      _members = const [];
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } finally {
      _userId = null;
      _members = const [];
    }
  }

  @override
  Future<List<Entry>> load() async {
    final result = await client.functions.invoke(
      'wedding-list',
      body: {'schemaVersion': 3},
    );
    final data = _extractMap(result.data);
    _userId = data['userId'] as String;
    _members = (data['members'] as List)
        .map((m) => Member(m['id'] as String, m['name'] as String))
        .toList();
    return (data['entries'] as List)
        .map((e) => Entry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> save(Entry entry) async {
    if (entry.kind == EntryKind.memory) {
      final photos = <String>[];
      for (final source in MemoryAlbum.photosOf(entry)) {
        photos.add(
          source.startsWith('data:image/')
              ? await _uploadPhoto(source)
              : source,
        );
      }
      entry = entry.copy({'photos': photos, 'photo': photos.firstOrNull ?? ''});
    }
    await client.functions.invoke(
      'wedding-save',
      body: {...entry.toJson(), 'schemaVersion': 3},
    );
  }

  @override
  Future<void> delete(Entry entry) async {
    await client.functions.invoke(
      'wedding-delete',
      body: {'id': entry.id, 'kind': entry.kind.name},
    );
  }

  Future<String> _uploadPhoto(String source) async {
    final match = RegExp(
      r'^data:image/(jpeg|png|webp);base64,',
    ).firstMatch(source);
    if (match == null) throw Exception('Photo invalide.');
    return uploadPhoto(
      base64Decode(source.substring(match.end)),
      match.group(1)!,
    );
  }

  Future<String> uploadPhoto(Uint8List bytes, String mime) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null || !['jpeg', 'png', 'webp'].contains(mime)) {
      throw Exception('Photo ou session invalide.');
    }
    if (bytes.isEmpty || bytes.length > PrivatePhotos.maxBytes) {
      throw Exception('Chaque photo doit peser au maximum 20 Mio.');
    }
    // Decode only the preview at reduced size; upload original bytes unchanged.
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 800,
      allowUpscaling: false,
    );
    late Uint8List thumbnail;
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null) throw Exception('Aperçu impossible.');
        thumbnail = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final path = '$uid/$id.$mime';
    await client.storage
        .from(PrivatePhotos.bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$mime', upsert: false),
        );
    await client.storage
        .from(PrivatePhotos.bucket)
        .uploadBinary(
          '$uid/$id.thumb.png',
          thumbnail,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: false,
          ),
        );
    return '${PrivatePhotos.prefix}$path';
  }

  @override
  Future<Uint8List> downloadPhoto(
    String source, {
    bool thumbnail = false,
  }) async {
    var path = PrivatePhotos.path(source);
    if (thumbnail) {
      path = '${path.substring(0, path.lastIndexOf('.'))}.thumb.png';
    }
    return client.storage.from(PrivatePhotos.bucket).download(path);
  }

  static String _normalizeEmail(String username) {
    final value = username.trim();
    if (value.isEmpty) {
      throw Exception('Identifiant requis.');
    }
    if (value.contains('@')) return value;
    throw Exception('Utilise ton email Supabase pour te connecter.');
  }

  static Map<String, dynamic> _extractMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('Réponse serveur invalide.');
  }
}
