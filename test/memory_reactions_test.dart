import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/app/theme.dart';
import 'package:jusqua_nous/core/application/providers.dart';
import 'package:jusqua_nous/core/data/local_wedding_repository.dart';
import 'package:jusqua_nous/features/story/application/memory_reactions.dart';
import 'package:jusqua_nous/features/story/data/memory_reaction_store.dart';
import 'package:jusqua_nous/features/story/domain/memory_reaction.dart';
import 'package:jusqua_nous/features/story/presentation/memory_reactions.dart';

class FakeReactions implements MemoryReactionStore {
  @override
  String get userId => 'local';
  List<MemoryReaction> rows = [const MemoryReaction('m1', 'partner', '❤️')];
  bool fail = false;
  int writes = 0;
  @override
  Future<List<MemoryReaction>> load() async => List.of(rows);
  @override
  Future<void> set(String id, String? emoji) async {
    writes++;
    if (fail) throw Exception('Network unavailable');
    rows.removeWhere((r) => r.memoryId == id && r.userId == userId);
    if (emoji != null) rows.add(MemoryReaction(id, userId, emoji));
  }
}

void main() {
  test('One emoji includes skin tones, flags, keycaps and joined families', () {
    for (final value in [
      '❤️',
      '👍🏽',
      '👩‍❤️‍👨',
      '🇩🇿',
      '🇪🇸',
      '1️⃣',
      '🫶🏾',
      '🏳️‍🌈',
    ]) {
      expect(ReactionEmoji.valid(value), true, reason: value);
    }
    for (final value in [
      '',
      'like',
      ' ❤️',
      '❤️ ',
      '❤️🔥',
      '🥰\n',
      'a',
      '123',
      'é',
    ]) {
      expect(ReactionEmoji.valid(value), false, reason: value);
    }
  });
  test(
    'Local replacement/removal persist independently of album data',
    () async {
      SharedPreferences.setMockInitialValues({
        LocalWeddingRepository.key: '[]',
      });
      final prefs = await SharedPreferences.getInstance(),
          store = LocalMemoryReactionStore(
            await SharedPreferences.getInstance(),
          );
      await store.set('m1', '❤️');
      await store.set('m2', '🇪🇸');
      await store.set('m1', '🥰');
      expect((await LocalMemoryReactionStore(prefs).load()).length, 2);
      expect(
        (await store.load()).firstWhere((r) => r.memoryId == 'm1').emoji,
        '🥰',
      );
      await store.set('m1', null);
      expect((await store.load()).single.memoryId, 'm2');
      expect(prefs.getString(LocalWeddingRepository.key), '[]');
      await expectLater(store.set('m1', 'texte'), throwsFormatException);
      await prefs.setString(LocalMemoryReactionStore.key, 'broken');
      expect(await store.load(), isEmpty);
    },
  );
  testWidgets(
    'Long press, choose, group, replace and remove only my reaction',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = FakeReactions();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            repositoryProvider.overrideWithValue(LocalWeddingRepository(prefs)),
            memoryReactionStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            theme: weddingTheme(),
            home: const Scaffold(
              body: ReactableMemory(
                memoryId: 'm1',
                child: SizedBox(
                  height: 200,
                  child: Center(child: Text('Notre souvenir')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Notre souvenir'));
      await tester.pumpAndSettle();
      expect(find.text('Ce souvenir me fait…'), findsOneWidget);
      await tester.tap(find.text('❤️').last);
      await tester.pumpAndSettle();
      expect(find.text('❤️ 2'), findsOneWidget);
      expect(store.rows.length, 2);
      await tester.tap(find.text('Ma réaction'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '🇩🇿');
      await tester.tap(find.text('Envoyer cet emoji'));
      await tester.pumpAndSettle();
      expect(store.rows.singleWhere((r) => r.userId == 'local').emoji, '🇩🇿');
      await tester.tap(find.text('Ma réaction'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer ma réaction'));
      await tester.pumpAndSettle();
      expect(store.rows.single.userId, 'partner');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'Small phone picker rejects text and preserves reactions on failure',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = FakeReactions()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            repositoryProvider.overrideWithValue(LocalWeddingRepository(prefs)),
            memoryReactionStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            theme: weddingTheme(),
            home: const Scaffold(
              body: ReactableMemory(memoryId: 'm1', child: Text('Souvenir')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Souvenir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'bonjour');
      await tester.ensureVisible(find.text('Envoyer cet emoji'));
      await tester.tap(find.text('Envoyer cet emoji'));
      await tester.pumpAndSettle();
      expect(store.writes, 0);
      await tester.enterText(find.byType(TextField), '👍🏽');
      await tester.ensureVisible(find.text('Envoyer cet emoji'));
      await tester.tap(find.text('Envoyer cet emoji'));
      await tester.pumpAndSettle();
      expect(store.writes, 1);
      expect(store.rows.single.userId, 'partner');
      expect(
        find.text(
          'Ta réaction n’a pas pu être enregistrée. Réessaie dans un instant.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
