import 'dart:math';

enum PuzzleLevel {
  easy('Facile', 3),
  medium('Intermédiaire', 4),
  hard('Difficile', 5);

  const PuzzleLevel(this.label, this.side);
  final String label;
  final int side;
}

class PuzzlePhoto {
  final String id, title, source, victory;
  const PuzzlePhoto(
    this.id,
    this.title,
    this.source, {
    this.victory = 'Un souvenir de plus que nous gardons précieusement. ❤️',
  });
  bool get isAsset => source.startsWith('assets/');
  // Neutral titles: these photos already belong to the app; no invented events.
  static const catalog = [
    PuzzlePhoto(
      'photo-1',
      'Notre photographie n° 1',
      'assets/images/home_1.jpg',
    ),
    PuzzlePhoto(
      'photo-2',
      'Notre photographie n° 2',
      'assets/images/home_2.jpg',
    ),
    PuzzlePhoto(
      'photo-3',
      'Notre photographie n° 3',
      'assets/images/home_3.jpg',
    ),
    PuzzlePhoto(
      'photo-4',
      'Notre photographie n° 4',
      'assets/images/home_4.jpg',
    ),
  ];
}

/// Arbitrary swaps, not a sliding puzzle: every permutation is solvable.
class PuzzleGame {
  final PuzzleLevel level;
  List<int> _tiles;
  int moves;
  int elapsedMs;
  PuzzleGame._(this.level, this._tiles, this.moves, this.elapsedMs);
  factory PuzzleGame.start(PuzzleLevel level, {Random? random}) {
    final tiles = List.generate(level.side * level.side, (i) => i)
      ..shuffle(random ?? Random());
    if (tiles.asMap().entries.every((e) => e.key == e.value)) {
      final first = tiles[0];
      tiles[0] = tiles[1];
      tiles[1] = first;
    }
    return PuzzleGame._(level, tiles, 0, 0);
  }
  List<int> get tiles => List.unmodifiable(_tiles);
  int get correct =>
      _tiles.asMap().entries.where((e) => e.key == e.value).length;
  bool get complete => correct == _tiles.length;
  bool swap(int a, int b) {
    if (complete ||
        a == b ||
        a < 0 ||
        b < 0 ||
        a >= _tiles.length ||
        b >= _tiles.length) {
      return false;
    }
    final piece = _tiles[a];
    _tiles[a] = _tiles[b];
    _tiles[b] = piece;
    moves++;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'side': level.side,
    'tiles': _tiles.toList(),
    'moves': moves,
    'elapsedMs': elapsedMs,
  };
  static PuzzleGame? restore(PuzzleLevel level, Map<String, dynamic>? data) {
    try {
      if (data == null || data['schema'] != 1 || data['side'] != level.side) {
        return null;
      }
      final tiles = List<int>.from(data['tiles'] as List);
      final moves = data['moves'] as int, elapsed = data['elapsedMs'] as int;
      if (tiles.length != level.side * level.side ||
          tiles.toSet().length != tiles.length ||
          tiles.any((v) => v < 0 || v >= tiles.length) ||
          moves < 0 ||
          elapsed < 0) {
        return null;
      }
      return PuzzleGame._(level, tiles, moves, elapsed);
    } catch (_) {
      return null;
    }
  }
}
