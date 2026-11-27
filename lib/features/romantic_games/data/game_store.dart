import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/application/providers.dart';
import '../domain/puzzle_game.dart';
import '../domain/word_search_game.dart';

final gameStoreProvider = Provider<GameStore>((ref) {
  ref.watch(authRevisionProvider);
  final owner = ref.watch(repositoryProvider).userId ?? 'local';
  return GameStore(ref.watch(preferencesProvider), owner);
});

/// Versioned, per-account local saves. Serial writes prevent older snapshots
/// overwriting a more recent move during navigation/lifecycle callbacks.
class GameStore {
  final SharedPreferences prefs;
  final String owner;
  GameStore(this.prefs, this.owner);
  String get prefix => 'romantic-games.v1.$owner.';
  Future<void> _tail = Future.value();
  Map<String, dynamic>? read(String key) {
    try {
      final raw = prefs.getString('$prefix$key');
      return raw == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Map<String, dynamic> data) {
    final encoded = jsonEncode(data);
    final result = _tail.then((_) async {
      if (!await prefs.setString('$prefix$key', encoded)) {
        throw StateError('Sauvegarde locale impossible');
      }
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  String puzzleKey(String id, PuzzleLevel level) => 'puzzle.$id.${level.side}';
  Future<void> _merge(
    String key,
    Map<String, dynamic> Function(Map<String, dynamic>) update,
  ) {
    final result = _tail.then((_) async {
      final data = update(read(key) ?? {});
      if (!await prefs.setString('$prefix$key', jsonEncode(data))) {
        throw StateError('Sauvegarde locale impossible');
      }
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<void> savePuzzle(String id, PuzzleGame game) {
    final snapshot = game.toJson(),
        complete = game.complete,
        ms = game.elapsedMs,
        moves = game.moves;
    return _merge(
      puzzleKey(id, game.level),
      (previous) => {
        'game': snapshot,
        'completed': previous['completed'] == true || complete,
        if (complete)
          'bestMs': min(
            ms,
            previous['bestMs'] is int ? previous['bestMs'] as int : ms,
          )
        else if (previous['bestMs'] is int)
          'bestMs': previous['bestMs'],
        if (complete)
          'bestMoves': min(
            moves,
            previous['bestMoves'] is int ? previous['bestMoves'] as int : moves,
          )
        else if (previous['bestMoves'] is int)
          'bestMoves': previous['bestMoves'],
      },
    );
  }

  Future<void> saveWords(WordSearchGame game) {
    final snapshot = game.toJson(), complete = game.complete;
    return _merge(
      'words.${game.theme.id}',
      (previous) => {
        'game': snapshot,
        'completed': previous['completed'] == true || complete,
      },
    );
  }
}
