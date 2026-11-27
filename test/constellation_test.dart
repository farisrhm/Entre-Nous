import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/app/theme.dart';
import 'package:jusqua_nous/core/application/providers.dart';
import 'package:jusqua_nous/core/data/local_wedding_repository.dart';
import 'package:jusqua_nous/core/domain/entry.dart';
import 'package:jusqua_nous/features/constellation/domain/love_sky.dart';
import 'package:jusqua_nous/features/constellation/presentation/constellation_page.dart';

const memory = Entry(
  id: 'memory-1',
  kind: EntryKind.memory,
  fields: {'title': 'Une photographie', 'body': 'Un bel instant'},
);
const letter = Entry(
  id: 'letter-1',
  kind: EntryKind.letter,
  authorId: 'faris',
  fields: {
    'title': 'Pour toi',
    'body': 'SECRET PROTÉGÉ',
    'openAt': '2027-01-23T07:00:00Z',
  },
);
void main() {
  test(
    'Stars preserve position on insert, edit and reorder; only memories and letters',
    () {
      final before = LoveSky.stars([memory, letter]);
      final after = LoveSky.stars([
        letter,
        memory.copy({'title': 'Nouveau titre'}),
        const Entry(id: 'new', kind: EntryKind.memory, fields: {}),
        const Entry(id: 'other', kind: EntryKind.dream, fields: {}),
      ]);
      expect(after.length, 3);
      for (final star in before) {
        final next = after.firstWhere((s) => s.entry.id == star.entry.id);
        expect(next.x, star.x);
        expect(next.y, star.y);
        expect(star.x, inInclusiveRange(70, 1130));
        expect(star.y, inInclusiveRange(70, 1130));
      }
      expect(LoveSky.stars([memory, memory]).length, 1);
    },
  );
  test('Wedding heart appears at Paris midnight and remains afterwards', () {
    expect(
      LoveSky.weddingVisible(DateTime.parse('2027-01-22T22:59:59Z')),
      false,
    );
    expect(
      LoveSky.weddingVisible(DateTime.parse('2027-01-22T23:00:00Z')),
      true,
    );
    expect(LoveSky.weddingVisible(DateTime.utc(2028)), true);
  });
  test('Cloud letter authority cannot be bypassed by date or demo', () {
    final future = DateTime.utc(2028);
    expect(
      LoveSky.canReadLetter(
        letter,
        cloud: true,
        userId: 'alyssa',
        now: future,
        demo: true,
      ),
      false,
    );
    expect(
      LoveSky.canReadLetter(letter, cloud: true, userId: 'faris', now: future),
      true,
    );
    expect(
      LoveSky.canReadLetter(
        letter.copy({'available': true}),
        cloud: true,
        userId: 'alyssa',
        now: future,
      ),
      true,
    );
    expect(
      LoveSky.canReadLetter(
        letter,
        cloud: false,
        userId: null,
        now: DateTime.utc(2026),
      ),
      false,
    );
    expect(
      LoveSky.canReadLetter(letter, cloud: false, userId: null, now: future),
      true,
    );
  });
  testWidgets('Sky allows tapping, dragging from a star, and recentering', (
    tester,
  ) async {
    Entry? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyExplorer(
            stars: LoveSky.stars([memory]),
            wedding: true,
            still: true,
            onStar: (e) => opened = e,
            onWedding: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final star = find.byKey(const ValueKey('star-memory-memory-1'));
    await tester.tap(star);
    expect(opened, memory);
    opened = null;
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final initial = controller.value.clone();
    await tester.drag(star, const Offset(60, 40));
    await tester.pumpAndSettle();
    expect(opened, null);
    expect(controller.value, isNot(initial));
    await tester.tap(find.byTooltip('Recentrer le ciel'));
    await tester.pump();
    expect(controller.value, initial);
    expect(find.byKey(const ValueKey('wedding-star')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Small phone: list opens memories and never renders locked letter body',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'reduceMotion': true,
        LocalWeddingRepository.key: jsonEncode([
          memory.toJson(),
          letter.toJson(),
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            repositoryProvider.overrideWithValue(LocalWeddingRepository(prefs)),
            clockProvider.overrideWith(
              (ref) => Stream.value(DateTime.utc(2026, 11, 27)),
            ),
          ],
          child: MaterialApp(
            theme: weddingTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const ConstellationPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
      expect(find.byKey(const ValueKey('wedding-star')), findsNothing);
      await tester.ensureVisible(find.text('Tous nos astres'));
      await tester.tap(find.text('Tous nos astres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pour toi'));
      await tester.pumpAndSettle();
      expect(find.text('SECRET PROTÉGÉ'), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      Navigator.of(tester.element(find.byIcon(Icons.lock_outline))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tous nos astres'));
      await tester.tap(find.text('Tous nos astres'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Une photographie'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Une photographie'));
      await tester.pumpAndSettle();
      expect(find.text('Un bel instant'), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
