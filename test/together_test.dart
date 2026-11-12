import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/app/app.dart';
import 'package:jusqua_nous/core/application/providers.dart';
import 'package:jusqua_nous/core/data/local_wedding_repository.dart';
import 'package:jusqua_nous/core/domain/entry.dart';
import 'package:jusqua_nous/features/story/domain/memory_album.dart';
import 'package:jusqua_nous/features/story/presentation/memory_gallery.dart';
import 'package:jusqua_nous/features/together/domain/together_space.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));
  Future<ProviderContainer> start(
    WidgetTester tester, {
    List<Entry> entries = const [],
    double width = 375,
  }) async {
    tester.view.physicalSize = Size(width, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'onboardingDone': true,
      LocalWeddingRepository.key: jsonEncode(
        entries.map((e) => e.toJson()).toList(),
      ),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          repositoryProvider.overrideWithValue(LocalWeddingRepository(prefs)),
        ],
        child: const WeddingApp(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(WeddingApp)));
  }

  Future<void> fillAndSave(
    WidgetTester tester,
    String title,
    String body,
    String saveLabel, {
    String? action,
  }) async {
    await tester.enterText(find.byKey(const ValueKey('together-title')), title);
    await tester.enterText(find.byKey(const ValueKey('together-body')), body);
    if (action != null) {
      await tester.enterText(
        find.byKey(const ValueKey('together-action')),
        action,
      );
    }
    await tester.ensureVisible(find.text(saveLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(saveLabel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  test('album migration never resurrects a removed legacy photo', () {
    const old = Entry(
      id: 'old',
      kind: EntryKind.memory,
      fields: {'photo': 'old.jpg'},
    );
    expect(MemoryAlbum.photosOf(old), ['old.jpg']);
    expect(MemoryAlbum.photosOf(old.copy({'photos': <String>[]})), isEmpty);
    expect(
      MemoryAlbum.photosOf(
        old.copy({
          'photos': ['second', 'first'],
        }),
      ),
      ['second', 'first'],
    );
    expect(
      () => MemoryAlbum.validate(List.filled(9, 'photo')),
      throwsFormatException,
    );
    expect(
      () => MemoryAlbum.validate(['x' * 50000001]),
      throwsFormatException,
    );
  });
  test('only shared intentions allow the partner to edit a personal note', () {
    for (final s in TogetherSpace.all) {
      final e = Entry(id: '1', kind: s.kind, fields: const {}, authorId: 'a');
      expect(s.mayEdit(e, 'a', true), true);
      expect(s.mayEdit(e, 'f', true), s.kind == EntryKind.intention);
      expect(s.mayEdit(e, null, false), true);
    }
  });
  for (final s in TogetherSpace.all) {
    testWidgets('${s.kind.name}: create at 320px, persist and edit', (
      tester,
    ) async {
      final container = await start(tester, width: 320);
      container.read(routerProvider).go(s.path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(s.addLabel));
      await tester.tap(find.text(s.addLabel));
      await tester.pumpAndSettle();
      final saveLabel = s.kind == EntryKind.openWhen
          ? 'Garder cette enveloppe'
          : s.kind == EntryKind.happiness
          ? 'Glisser dans le bocal'
          : s.kind == EntryKind.dua
          ? 'Partager cette dou‘a'
          : 'Garder cette intention';
      await fillAndSave(
        tester,
        'Notre moment',
        'Quelques mots personnels',
        saveLabel,
        action: s.kind == EntryKind.intention
            ? 'Prendre le temps de s’écouter'
            : null,
      );
      final repository = container.read(repositoryProvider);
      var saved = (await repository.load()).single;
      expect(saved.kind, s.kind);
      expect(saved.text('body'), 'Quelques mots personnels');
      if (s.hasRecipient) expect(saved.text('recipientId'), 'alyssa');
      if (s.kind == EntryKind.intention) {
        expect(saved.text('action'), 'Prendre le temps de s’écouter');
      }
      await tester.ensureVisible(find.text('Modifier'));
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await fillAndSave(
        tester,
        'Notre moment modifié',
        'À garder longtemps',
        saveLabel,
        action: s.kind == EntryKind.intention
            ? 'Écouter sans interrompre'
            : null,
      );
      saved = (await LocalWeddingRepository(
        await SharedPreferences.getInstance(),
      ).load()).single;
      expect(saved.text('title'), 'Notre moment modifié');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('jar draw and gratitude filter select existing notes', (
    tester,
  ) async {
    final container = await start(
      tester,
      entries: const [
        Entry(
          id: 'h1',
          kind: EntryKind.happiness,
          fields: {
            'title': 'Notre balade',
            'body': 'Un moment heureux',
            'date': '2026-11-11',
            'gratitude': true,
          },
        ),
      ],
    );
    container.read(routerProvider).go('/universe/happiness');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Piocher un bonheur'));
    await tester.tap(find.text('Piocher un bonheur'));
    await tester.pumpAndSettle();
    expect(
      find.text('11 novembre 2026\n\nAlhamdulillah\n\nUn moment heureux'),
      findsOneWidget,
    );
    await tester.tap(find.text('Refermer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gratitude'));
    await tester.tap(find.text('Gratitude'));
    await tester.pumpAndSettle();
    expect(find.text('Notre balade'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('album reorder, gallery, and removing every photo persist', (
    tester,
  ) async {
    const first = 'asset:assets/images/story1.jpg',
        second = 'asset:assets/images/story2.jpg';
    final container = await start(
      tester,
      width: 320,
      entries: const [
        Entry(
          id: 'm',
          kind: EntryKind.memory,
          fields: {
            'title': 'Notre album',
            'photo': first,
            'photos': [first, second],
          },
        ),
      ],
    );
    container.read(routerProvider).go('/story');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(AlbumCover));
    await tester.tap(find.byType(AlbumCover));
    await tester.pumpAndSettle();
    expect(find.byType(MemoryGallery), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Photo suivante'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer l’album'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Modifier'));
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Monter la photo 2'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Garder ce souvenir'));
    await tester.tap(find.text('Garder ce souvenir'));
    await tester.pumpAndSettle();
    expect(
      MemoryAlbum.photosOf(
        (await container.read(repositoryProvider).load()).single,
      ),
      [second, first],
    );
    await tester.ensureVisible(find.text('Modifier'));
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retirer la photo 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retirer la photo 1'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Garder ce souvenir'));
    await tester.tap(find.text('Garder ce souvenir'));
    await tester.pumpAndSettle();
    expect(
      MemoryAlbum.photosOf(
        (await container.read(repositoryProvider).load()).single,
      ),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
