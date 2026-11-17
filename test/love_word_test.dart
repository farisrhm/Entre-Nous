import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jusqua_nous/features/home/domain/love_word.dart';
import 'package:jusqua_nous/features/home/presentation/love_word_card.dart';

void main() {
  test(
    '31 unique complete words rotate at Paris midnight, including summer',
    () {
      expect(loveWords.length, 31);
      expect(loveWords.map((w) => w.spanish).toSet().length, 31);
      final start = DateTime.utc(2026, 11, 17, 12);
      for (var i = 0; i < 31; i++) {
        final word = loveWordAt(start.add(Duration(days: i)));
        expect(word, same(loveWords[i]));
        expect(word.french, isNotEmpty);
        expect(word.example, isNotEmpty);
        expect(word.translation, isNotEmpty);
      }
      expect(
        loveWordAt(start.add(const Duration(days: 31))),
        same(loveWords.first),
      );
      for (final midnight in [
        DateTime.utc(2026, 11, 17, 23),
        DateTime.utc(2027, 7, 17, 22),
      ]) {
        expect(
          loveWordAt(midnight),
          isNot(
            same(loveWordAt(midnight.subtract(const Duration(seconds: 1)))),
          ),
        );
        expect(loveWordAt(midnight.toLocal()), same(loveWordAt(midnight)));
      }
    },
  );
  testWidgets('word and translated example remain readable on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LoveWordCard(now: DateTime.utc(2026, 11, 17, 12)),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('El cariño'), findsOneWidget);
    expect(find.text('L’affection, la tendresse'), findsOneWidget);
    await tester.ensureVisible(find.text('Découvrir la traduction  →'));
    await tester.tap(find.text('Découvrir la traduction  →'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Je te le dis avec toute mon affection.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
