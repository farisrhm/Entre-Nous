import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import '../domain/puzzle_game.dart';
import 'game_store.dart';

/// Only app-private files, never the cloud photo repository.
class PuzzlePhotos {
  final GameStore store;
  PuzzlePhotos(this.store);
  Future<Directory> get directory async {
    final root = await getApplicationSupportDirectory();
    final safeOwner = store.owner.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return Directory(
      '${root.path}/romantic-games/$safeOwner',
    ).create(recursive: true);
  }

  Future<List<PuzzlePhoto>> load() async {
    final dir = await directory;
    final entries = store.read('photos')?['items'];
    if (entries is! List) return [];
    return [
      for (final e in entries)
        if (e is Map &&
            e['id'] is String &&
            RegExp(r'^personal-[0-9a-f-]+$').hasMatch(e['id'] as String) &&
            e['title'] is String)
          PuzzlePhoto(
            e['id'] as String,
            e['title'] as String,
            '${dir.path}/${e['id']}.png',
          ),
    ];
  }

  Future<PuzzlePhoto> add(Uint8List bytes, String title) async {
    if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
      throw StateError('Choisis une photo de moins de 20 Mo.');
    }
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 1200,
      allowUpscaling: false,
    );
    late Uint8List normalized;
    try {
      final frame = await codec.getNextFrame();
      try {
        final png = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (png == null) throw StateError('Photo illisible');
        normalized = png.buffer.asUint8List();
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
    final dir = await directory;
    final id =
        'personal-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${Random.secure().nextInt(1 << 32).toRadixString(16)}';
    final file = File('${dir.path}/$id.png');
    await file.writeAsBytes(normalized, flush: true);
    final old = await load();
    try {
      await store.write('photos', {
        'items': [
          for (final p in old) {'id': p.id, 'title': p.title},
          {
            'id': id,
            'title': title.trim().isEmpty ? 'Ma photographie' : title.trim(),
          },
        ],
      });
    } catch (_) {
      await file.delete();
      rethrow;
    }
    return PuzzlePhoto(
      id,
      title.trim().isEmpty ? 'Ma photographie' : title.trim(),
      file.path,
    );
  }

  Future<void> remove(PuzzlePhoto photo) async {
    if (photo.isAsset) return;
    final old = await load();
    await store.write('photos', {
      'items': [
        for (final p in old)
          if (p.id != photo.id) {'id': p.id, 'title': p.title},
      ],
    });
    final file = File(photo.source);
    if (await file.exists()) await file.delete();
  }
}
