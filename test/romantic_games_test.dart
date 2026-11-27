import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/features/romantic_games/domain/puzzle_game.dart';
import 'package:jusqua_nous/features/romantic_games/domain/word_theme.dart';
import 'package:jusqua_nous/features/romantic_games/domain/word_search_game.dart';
import 'package:jusqua_nous/features/romantic_games/data/game_store.dart';

void solve(PuzzleGame game) {
  for (var i = 0; i < game.tiles.length; i++) {
    if (game.tiles[i] != i) game.swap(i, game.tiles.indexOf(i));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final level in PuzzleLevel.values) {
    test(
      'Puzzle ${level.side}: permutation, swaps, victory and restoration',
      () {
        final game = PuzzleGame.start(level, random: Random(20));
        expect(game.complete, false);
        expect(
          game.tiles.toSet(),
          List.generate(level.side * level.side, (i) => i).toSet(),
        );
        final first = game.tiles[0], second = game.tiles[1];
        expect(game.swap(0, 1), true);
        expect(game.tiles[0], second);
        expect(game.tiles[1], first);
        expect(game.moves, 1);
        expect(game.swap(0, 0), false);
        expect(game.swap(-1, 0), false);
        expect(game.swap(0, game.tiles.length), false);
        expect(game.moves, 1);
        game.elapsedMs = 23456;
        final restored = PuzzleGame.restore(level, game.toJson())!;
        expect(restored.tiles, game.tiles);
        expect(restored.elapsedMs, 23456);
        expect(restored.moves, 1);
        solve(restored);
        expect(restored.complete, true);
        expect(restored.correct, level.side * level.side);
        expect(restored.swap(0, 1), false);
        final almost = restored.toJson();
        final tiles = almost['tiles'] as List<int>;
        tiles[0] = 1;
        tiles[1] = 0;
        expect(PuzzleGame.restore(level, almost)!.complete, false);
      },
    );
  }
  test('Puzzle rejects damaged or incompatible saves', () {
    final data = PuzzleGame.start(PuzzleLevel.easy).toJson();
    expect(PuzzleGame.restore(PuzzleLevel.hard, data), null);
    expect(
      PuzzleGame.restore(PuzzleLevel.easy, {
        ...data,
        'tiles': List.filled(9, 0),
      }),
      null,
    );
    expect(
      PuzzleGame.restore(PuzzleLevel.easy, {...data, 'elapsedMs': -1}),
      null,
    );
    expect(PuzzleGame.restore(PuzzleLevel.easy, {}), null);
  });
  test('Accents are normalized only in grid data', () {
    expect(gridWord('Étoile'), 'ETOILE');
    expect(gridWord('L’amour'), 'LAMOUR');
    expect(gridWord("C'est nous"), 'CESTNOUS');
    expect(WordTheme.catalog[0].words[2].label, 'Complicité');
  });
  for (final theme in WordTheme.catalog) {
    test('All words solvable for ${theme.title}, including fallback', () {
      for (var seed = 0; seed < 30; seed++) {
        final game = WordSearchGame.generate(
          theme,
          random: Random(seed),
          attempts: seed == 0 ? 0 : 35,
        );
        expect(game.placements.length, theme.words.length);
        for (final word in theme.words) {
          final path = game.placements[word.letters]!;
          expect(path, wordLine(path.first, path.last, game.side));
          expect(path.map((i) => game.letters[i]).join(), word.letters);
          if (!theme.reversed) {
            expect(
              path.last ~/ game.side,
              greaterThanOrEqualTo(path.first ~/ game.side),
            );
            expect(
              path.last % game.side,
              greaterThanOrEqualTo(path.first % game.side),
            );
          }
          expect(game.match(path), word.letters);
          expect(game.match(path), null);
        }
        expect(game.complete, true);
        expect(game.hint, null);
      }
    });
  }
  test(
    'Forward-only levels reject reverse selections; harder accepts them',
    () {
      for (final theme in [WordTheme.catalog.first, WordTheme.catalog.last]) {
        final game = WordSearchGame.generate(theme, random: Random(3));
        final word = theme.words.first.letters, path = game.placements[word]!;
        expect(
          game.match(path.reversed.toList()),
          theme.reversed ? word : null,
        );
      }
    },
  );
  test(
    'Intersections retain every found cell; restored layout and progress exact',
    () {
      final game = WordSearchGame.generate(
        WordTheme.catalog.first,
        random: Random(11),
      );
      final paths = game.placements.values.toList();
      expect(
        paths.expand((p) => p).length,
        greaterThan(paths.expand((p) => p).toSet().length),
      );
      final expected = <int>{};
      for (final p in paths.take(3)) {
        game.match(p);
        expected.addAll(p);
        expect(game.foundCells, expected);
      }
      final restored = WordSearchGame.restore(
        game.theme,
        jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>,
      )!;
      expect(restored.letters, game.letters);
      expect(restored.placements, game.placements);
      expect(restored.found, game.found);
      expect(restored.complete, false);
      for (final p in restored.placements.values) {
        restored.match(p);
      }
      expect(restored.complete, true);
    },
  );
  test('Invalid paths and saves cannot corrupt a grid', () {
    final game = WordSearchGame.generate(
      WordTheme.catalog.first,
      random: Random(2),
    );
    expect(game.match([0, 1, game.side + 1]), null);
    expect(game.match([-1, 0]), null);
    expect(game.match([0, 0]), null);
    expect(wordLine(0, game.side + 2, game.side), isEmpty);
    expect(WordSearchGame.restore(game.theme, {}), null);
    expect(
      WordSearchGame.restore(game.theme, {
        ...game.toJson(),
        'letters': ['!'],
      }),
      null,
    );
    expect(
      WordSearchGame.restore(game.theme, {
        ...game.toJson(),
        'found': {
          'AMOUR': [0, 1],
        },
      }),
      null,
    );
    expect(WordSearchGame.restore(WordTheme.catalog.last, game.toJson()), null);
  });
  test('Queued win, replay and later slower win retain best scores', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = GameStore(prefs, 'faris');
    final win = PuzzleGame.start(PuzzleLevel.easy, random: Random(4));
    solve(win);
    win.elapsedMs = 5000;
    final bestMoves = win.moves;
    final first = store.savePuzzle('photo', win);
    final replay = store.savePuzzle(
      'photo',
      PuzzleGame.start(PuzzleLevel.easy),
    );
    await Future.wait([first, replay]);
    final data = store.read(store.puzzleKey('photo', PuzzleLevel.easy))!;
    expect(data['completed'], true);
    expect(data['bestMs'], 5000);
    expect(data['bestMoves'], bestMoves);
    expect(
      PuzzleGame.restore(
        PuzzleLevel.easy,
        data['game'] as Map<String, dynamic>,
      )!.complete,
      false,
    );
    win.elapsedMs = 20000;
    win.moves = 100;
    await store.savePuzzle('photo', win);
    expect(
      store.read(store.puzzleKey('photo', PuzzleLevel.easy))!['bestMs'],
      5000,
    );
    expect(
      GameStore(
        prefs,
        'alyssa',
      ).read(store.puzzleKey('photo', PuzzleLevel.easy)),
      null,
    );
  });
  test(
    'Word completion survives restart and malformed storage is ignored',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = GameStore(prefs, 'test');
      final game = WordSearchGame.generate(WordTheme.catalog.last);
      for (final p in game.placements.values) {
        game.match(p);
      }
      final win = store.saveWords(game),
          replay = store.saveWords(WordSearchGame.generate(game.theme));
      await Future.wait([win, replay]);
      expect(store.read('words.${game.theme.id}')!['completed'], true);
      await prefs.setString('${store.prefix}broken', '{');
      expect(store.read('broken'), null);
    },
  );
}
