import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/app/app.dart';
import 'package:jusqua_nous/core/application/providers.dart';
import 'package:jusqua_nous/core/data/local_wedding_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));
  Future<void> start(
    WidgetTester tester, {
    bool onboarded = true,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'onboardingDone': onboarded});
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
  }

  testWidgets('onboarding persists completion and opens home', (tester) async {
    await start(tester, onboarded: false);
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text('Accueil'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool('onboardingDone'),
      true,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('five tabs render and adding a dream persists it', (
    tester,
  ) async {
    await start(tester);
    for (final label in ['Souvenirs', 'Surprises', 'Lettres', 'Univers']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(
        scroll.position.pixels,
        0,
        reason: 'Nouvel onglet en haut : $label',
      );
    }
    await tester.scrollUntilVisible(
      find.text('Ajouter un rêve'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ajouter un rêve'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Voir les aurores boréales',
    );
    await tester.tap(find.text('Garder ce souvenir'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final entries = await LocalWeddingRepository(prefs).load();
    expect(
      entries.any((e) => e.text('title') == 'Voir les aurores boréales'),
      true,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('small iPhone home has no overflow', (tester) async {
    await start(tester);
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
