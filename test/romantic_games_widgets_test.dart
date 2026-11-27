import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/app/theme.dart';
import 'package:jusqua_nous/core/application/providers.dart';
import 'package:jusqua_nous/features/romantic_games/data/game_store.dart';
import 'package:jusqua_nous/features/romantic_games/domain/puzzle_game.dart';
import 'package:jusqua_nous/features/romantic_games/domain/word_theme.dart';
import 'package:jusqua_nous/features/romantic_games/domain/word_search_game.dart';
import 'package:jusqua_nous/features/romantic_games/presentation/puzzle_board.dart';
import 'package:jusqua_nous/features/romantic_games/presentation/puzzle_page.dart';
import 'package:jusqua_nous/features/romantic_games/presentation/word_grid.dart';
import 'package:jusqua_nous/features/romantic_games/presentation/words_page.dart';

void main() {
  testWidgets(
    'Word grid accepts drags and endpoint taps, rejects crooked/outside selections',
    (tester) async {
      final game = WordSearchGame.generate(
        WordTheme.catalog.first,
        random: Random(10),
      );
      final accepted = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: WordGrid(
                  game: game,
                  still: true,
                  onSelection: (path) {
                    final word = game.match(path);
                    if (word != null) accepted.add(word);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      Offset center(int i) =>
          tester.getCenter(find.byKey(ValueKey('letter-$i')));
      final first = game.placements.values.first;
      final drag = await tester.startGesture(center(first.first));
      for (final i in first.skip(1)) {
        await drag.moveTo(center(i));
        await tester.pump();
      }
      await drag.up();
      await tester.pump();
      expect(accepted.length, 1);
      final second = game.placements.values.elementAt(1);
      await tester.tapAt(center(second.first));
      await tester.pump();
      await tester.tapAt(center(second.last));
      await tester.pump();
      expect(accepted.length, 2);
      final third = game.placements.values.elementAt(2);
      final quick = await tester.startGesture(center(third.first));
      await quick.moveTo(center(third.last));
      await quick.up();
      await tester.pump();
      expect(accepted.length, 3);
      final invalid = await tester.startGesture(center(0));
      await invalid.moveTo(center(game.side + 2));
      await invalid.up();
      await tester.pump();
      expect(accepted.length, 3);
      final outside = await tester.startGesture(center(0));
      await outside.moveTo(const Offset(-10, -10));
      await outside.up();
      await tester.pump();
      expect(accepted.length, 3);
      final cancel = await tester.startGesture(center(0));
      await cancel.moveTo(center(3));
      await cancel.cancel();
      await tester.pump();
      expect(accepted.length, 3);
    },
  );
  testWidgets('Puzzle pieces stay aligned at 280 pixels, swaps honor lock', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 300, 400),
      Paint()..color = Colors.green,
    );
    final picture = recorder.endRecording();
    late ui.Image image;
    await tester.runAsync(() async {
      image = await picture.toImage(300, 400);
    });
    picture.dispose();
    final game = PuzzleGame.start(PuzzleLevel.hard, random: Random(2));
    int? selected;
    var locked = false;
    late StateSetter redraw;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: StatefulBuilder(
                builder: (context, setState) {
                  redraw = setState;
                  return PuzzleBoard(
                    game: game,
                    image: image,
                    selected: selected,
                    locked: locked,
                    still: false,
                    onSelect: (i) {
                      setState(() => selected = i);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    final piece = find.byKey(ValueKey('piece-${game.tiles.first}'));
    expect(tester.getSize(piece), const Size(56, 56));
    await tester.tap(piece);
    await tester.pump();
    expect(selected, 0);
    redraw(() {
      locked = true;
      selected = null;
      game.swap(0, 1);
    });
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(piece);
    expect(selected, null);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    image.dispose();
  });
  testWidgets(
    'Small phone and large text: words page saves and resumes exact progress',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance(),
          store = GameStore(await SharedPreferences.getInstance(), 'test');
      final game = WordSearchGame.generate(
        WordTheme.catalog.last,
        random: Random(8),
      );
      game.match(game.placements.values.first);
      await store.saveWords(game);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            gameStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            theme: weddingTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.6),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: WordsPlayPage(theme: game.theme),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
      expect(find.text('1 / 6 mots trouvés'), findsOneWidget);
      final widget = tester.widget<WordGrid>(find.byType(WordGrid));
      expect(widget.game.letters, game.letters);
      expect(widget.game.found, game.found);
      await tester.ensureVisible(find.text('Un petit indice ?'));
      await tester.tap(find.text('Un petit indice ?'));
      await tester.pump();
      expect(tester.widget<WordGrid>(find.byType(WordGrid)).hint, isNotNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'Puzzle finishes, saves records, restarts and cancels preview on exit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance(),
          store = GameStore(await SharedPreferences.getInstance(), 'test');
      final almost = PuzzleGame.restore(PuzzleLevel.easy, {
        'schema': 1,
        'side': 3,
        'tiles': [1, 0, 2, 3, 4, 5, 6, 7, 8],
        'moves': 4,
        'elapsedMs': 12000,
      })!;
      final photo = PuzzlePhoto.catalog.first;
      await store.savePuzzle(photo.id, almost);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            gameStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            theme: weddingTheme(),
            home: PuzzlePlayPage(photo: photo, level: PuzzleLevel.easy),
          ),
        ),
      );
      // Wait on actual decoding rather than fake animation time.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
      expect(find.byType(PuzzleBoard), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('piece-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('piece-0')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text(photo.victory), findsOneWidget);
      expect(
        store.read(store.puzzleKey(photo.id, PuzzleLevel.easy))!['bestMoves'],
        5,
      );
      await tester.ensureVisible(find.text('Rejouer'));
      await tester.tap(find.text('Rejouer'));
      await tester.pump();
      expect(
        tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).game.complete,
        false,
      );
      await tester.ensureVisible(find.text('Voir la photo'));
      await tester.tap(find.text('Voir la photo'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), null);
    },
  );
  testWidgets(
    'Word game can win by vertical drag inside scroll view and replay',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance(),
          store = GameStore(await SharedPreferences.getInstance(), 'test');
      final game = WordSearchGame.generate(
        WordTheme.catalog[1],
        random: Random(9),
      );
      final vertical = game.placements.values.firstWhere(
        (p) => p.first % game.side == p.last % game.side,
      );
      for (final path in game.placements.values) {
        if (path != vertical) game.match(path);
      }
      await store.saveWords(game);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            gameStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            theme: weddingTheme(),
            home: WordsPlayPage(theme: game.theme),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(WordGrid));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey('letter-${vertical.first}'))),
      );
      for (final i in vertical.skip(1)) {
        await gesture.moveTo(
          tester.getCenter(find.byKey(ValueKey('letter-$i'))),
        );
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text(game.theme.finalMessage), findsOneWidget);
      expect(store.read('words.${game.theme.id}')!['completed'], true);
      await tester.ensureVisible(find.text('Rejouer'));
      await tester.tap(find.text('Rejouer'));
      await tester.pumpAndSettle();
      expect(find.text('0 / 6 mots trouvés'), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
