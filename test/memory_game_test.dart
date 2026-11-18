import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jusqua_nous/app/theme.dart';
import 'package:jusqua_nous/features/memory/domain/memory_game.dart';
import 'package:jusqua_nous/features/memory/presentation/memory_page.dart';
import 'package:jusqua_nous/features/memory/presentation/memory_card.dart';

void main() {
  test('each difficulty contains exactly two copies of each photo', () {
    for (final level in MemoryLevel.values) {
      final game = MemoryGame(level, random: Random(8));
      expect(game.cards.length, level.pairs * 2);
      expect(game.cards.toSet().length, level.pairs);
      for (final photo in game.cards.toSet()) {
        expect(game.cards.where((p) => p == photo).length, 2);
      }
      final before = [...game.cards];
      game.restart();
      expect(game.cards, isNot(before));
      game.dispose();
    }
  });

  testWidgets(
    'locks flips and comparisons, rejects duplicate and matched taps',
    (tester) async {
      final game = MemoryGame(MemoryLevel.memories, random: Random(3));
      addTearDown(game.dispose);
      final partner = game.cards.lastIndexOf(game.cards[0]);
      final other = game.cards.indexWhere((p) => p != game.cards[0]);
      game.select(0);
      game.select(other);
      expect(game.isVisible(other), false);
      await tester.pump(MemoryGame.flipDuration);
      game.select(0);
      expect(game.moves, 0);
      game.select(other);
      await tester.pump(MemoryGame.flipDuration);
      game.select(partner);
      expect(game.isVisible(partner), false);
      expect(game.isVisible(other), true);
      await tester.pump(MemoryGame.comparisonDuration);
      expect(game.isVisible(0), false);
      expect(game.busy, true);
      await tester.pump(MemoryGame.flipDuration);
      expect(game.busy, false);
      game.select(0);
      await tester.pump(MemoryGame.flipDuration);
      game.select(partner);
      await tester.pump(MemoryGame.flipDuration);
      expect(game.foundPairs, 1);
      game.select(0);
      expect(game.busy, false);
      expect(game.moves, 2);
    },
  );

  testWidgets(
    'restart and disposal cancel delayed actions; all pairs finish game',
    (tester) async {
      final game = MemoryGame(MemoryLevel.gentle, random: Random(5));
      game.select(0);
      await tester.pump(MemoryGame.flipDuration);
      game.select(game.cards.indexWhere((p) => p != game.cards[0]));
      await tester.pump(MemoryGame.flipDuration);
      game.restart();
      await tester.pump(const Duration(seconds: 2));
      expect(game.moves, 0);
      expect(game.busy, false);
      for (final photo in game.cards.toSet()) {
        game.select(game.cards.indexOf(photo), reduceMotion: true);
        await tester.pump();
        game.select(game.cards.lastIndexOf(photo), reduceMotion: true);
        await tester.pump();
      }
      expect(game.complete, true);
      expect(game.moves, 3);
      game.restart();
      game.select(0);
      game.dispose();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    },
  );

  for (final level in MemoryLevel.values) {
    testWidgets(
      '${level.title} fits narrow phones with large text and reduced motion',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: weddingTheme(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.8),
                disableAnimations: true,
              ),
              child: const MemoryPage(),
            ),
          ),
        );
        await tester.ensureVisible(find.text(level.title));
        await tester.tap(find.text(level.title));
        await tester.pumpAndSettle();
        expect(find.byType(MemoryCard), findsNWidgets(level.pairs * 2));
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Recommencer'));
        await tester.tap(find.text('Recommencer'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
