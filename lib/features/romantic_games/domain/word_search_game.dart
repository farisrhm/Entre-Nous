import 'dart:math';
import 'word_theme.dart';

/// Inclusive cells along a straight, contiguous horizontal/vertical/diagonal line.
List<int> wordLine(int start, int end, int side) {
  if (start < 0 || end < 0 || start >= side * side || end >= side * side) {
    return [];
  }
  final dr = end ~/ side - start ~/ side, dc = end % side - start % side;
  if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return [];
  return List.generate(
    max(dr.abs(), dc.abs()) + 1,
    (i) => (start ~/ side + i * dr.sign) * side + start % side + i * dc.sign,
  );
}

class WordSearchGame {
  final WordTheme theme;
  final int side;
  final List<String> letters;
  final Map<String, List<int>> placements;
  final Map<String, List<int>> _found;
  WordSearchGame._(
    this.theme,
    this.side,
    List<String> letters,
    Map<String, List<int>> placements,
    Map<String, List<int>> found,
  ) : letters = List.unmodifiable(letters),
      placements = Map.unmodifiable(
        placements.map((k, v) => MapEntry(k, List<int>.unmodifiable(v))),
      ),
      _found = found;
  Set<String> get found => Set.unmodifiable(_found.keys);
  Set<int> get foundCells => _found.values.expand((p) => p).toSet();
  bool get complete => found.length == theme.words.length;
  factory WordSearchGame.generate(
    WordTheme theme, {
    Random? random,
    int attempts = 35,
  }) {
    final rng = random ?? Random();
    final words = theme.words.map((w) => w.letters).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (words.isEmpty ||
        words.length > 24 ||
        words.toSet().length != words.length ||
        words.any((w) => !RegExp(r'^[A-Z]{2,24}$').hasMatch(w))) {
      throw ArgumentError(
        'La grille doit contenir de 1 à 24 mots distincts de 2 à 24 lettres.',
      );
    }
    final size = max(
      words.first.length,
      max(7, sqrt(words.fold<int>(0, (n, w) => n + w.length) * 1.6).ceil()),
    );
    final directions = [
      (0, 1),
      (1, 0),
      (1, 1),
      if (theme.reversed) ...[(0, -1), (-1, 0), (-1, -1), (1, -1), (-1, 1)],
    ];
    for (var attempt = 0; attempt < attempts; attempt++) {
      final cells = List.filled(size * size, '');
      final placed = <String, List<int>>{};
      for (final word in words) {
        final options = <List<int>>[];
        for (var start = 0; start < cells.length; start++) {
          for (final (dr, dc) in directions) {
            final er = start ~/ size + dr * (word.length - 1),
                ec = start % size + dc * (word.length - 1);
            if (er < 0 || ec < 0 || er >= size || ec >= size) continue;
            final path = List.generate(
              word.length,
              (i) => (start ~/ size + dr * i) * size + start % size + dc * i,
            );
            if (path.indexed.every(
              (e) => cells[e.$2].isEmpty || cells[e.$2] == word[e.$1],
            )) {
              options.add(path);
            }
          }
        }
        if (options.isEmpty) break;
        options.shuffle(rng);
        // Prefer compatible intersections; retain randomized placement on ties.
        options.sort(
          (a, b) => b
              .where((i) => cells[i].isNotEmpty)
              .length
              .compareTo(a.where((i) => cells[i].isNotEmpty).length),
        );
        final path = options.first;
        placed[word] = path;
        for (var i = 0; i < word.length; i++) {
          cells[path[i]] = word[i];
        }
      }
      if (placed.length == words.length) {
        return WordSearchGame._(theme, size, _fill(cells, rng), placed, {});
      }
    }
    // Guaranteed bounded fallback: one word per row, no placement failures.
    final n = max(size, words.length);
    final cells = List.filled(n * n, '');
    final placed = <String, List<int>>{};
    final rows = List.generate(n, (i) => i)..shuffle(rng);
    for (var i = 0; i < words.length; i++) {
      final word = words[i], reverse = theme.reversed && rng.nextBool();
      final offset = rng.nextInt(n - word.length + 1);
      final path = List.generate(
        word.length,
        (j) => rows[i] * n + offset + (reverse ? word.length - 1 - j : j),
      );
      placed[word] = path;
      for (var j = 0; j < word.length; j++) {
        cells[path[j]] = word[j];
      }
    }
    return WordSearchGame._(theme, n, _fill(cells, rng), placed, {});
  }
  static List<String> _fill(List<String> cells, Random rng) => cells
      .map((s) => s.isEmpty ? String.fromCharCode(65 + rng.nextInt(26)) : s)
      .toList();
  String? match(List<int> path) {
    if (path.isEmpty ||
        path.length < 2 ||
        path.any((i) => i < 0 || i >= letters.length)) {
      return null;
    }
    if (!_same(path, wordLine(path.first, path.last, side))) return null;
    final text = path.map((i) => letters[i]).join();
    for (final word in theme.words) {
      if (found.contains(word.letters)) continue;
      if (text == word.letters ||
          (theme.reversed && text.split('').reversed.join() == word.letters)) {
        _found[word.letters] = List.of(path);
        return word.letters;
      }
    }
    return null;
  }

  int? get hint => theme.words
      .where((w) => !found.contains(w.letters))
      .map((w) => placements[w.letters]!.first)
      .firstOrNull;
  Map<String, dynamic> toJson() => {
    'schema': 1,
    'signature': theme.signature,
    'side': side,
    'letters': letters,
    'placements': placements,
    'found': _found.map((k, v) => MapEntry(k, List.of(v))),
  };
  static bool _same(List<int> a, List<int> b) =>
      a.length == b.length && a.indexed.every((e) => e.$2 == b[e.$1]);
  static WordSearchGame? restore(WordTheme theme, Map<String, dynamic>? json) {
    try {
      if (json == null ||
          json['schema'] != 1 ||
          json['signature'] != theme.signature) {
        return null;
      }
      final n = json['side'] as int,
          letters = List<String>.from(json['letters'] as List);
      if (n < 2 ||
          n > 32 ||
          letters.length != n * n ||
          letters.any((s) => !RegExp(r'^[A-Z]$').hasMatch(s))) {
        return null;
      }
      final paths = (json['placements'] as Map).map(
        (k, v) => MapEntry(k as String, List<int>.from(v as List)),
      );
      if (paths.length != theme.words.length) return null;
      for (final w in theme.words) {
        final p = paths[w.letters];
        if (p == null || p.isEmpty || !_same(p, wordLine(p.first, p.last, n))) {
          return null;
        }
        if (p.map((i) => letters[i]).join() != w.letters) return null;
        if (!theme.reversed &&
            (p.last ~/ n < p.first ~/ n || p.last % n < p.first % n)) {
          return null;
        }
      }
      final game = WordSearchGame._(theme, n, letters, paths, {});
      for (final e in (json['found'] as Map).entries) {
        if (game.match(List<int>.from(e.value as List)) != e.key) return null;
      }
      return game;
    } catch (_) {
      return null;
    }
  }
}
