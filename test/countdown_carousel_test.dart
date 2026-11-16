import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/core/application/providers.dart';
import 'package:jusqua_nous/features/home/presentation/countdown_carousel.dart';

void main() {
  testWidgets('swipe persists view, restores it and counts after wedding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    Widget app(bool after) => ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        home: Scaffold(
          body: ColoredBox(
            color: Colors.black,
            child: CountdownCarousel(
              duration: const Duration(days: 15, seconds: 10),
              after: after,
              reduceMotion: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(false));
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 semaines'), findsOneWidget);
    expect(find.text('1 jour avant notre oui'), findsOneWidget);
    expect(preferences.getInt(CountdownCarousel.preferenceKey), 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(find.text('1 jour depuis notre oui'), findsOneWidget);
    await tester.tap(find.byTooltip('Respirations'));
    await tester.pumpAndSettle();
    expect(find.text('respirations depuis notre oui'), findsOneWidget);
    expect(preferences.getInt(CountdownCarousel.preferenceKey), 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all views fit narrow screen with large text and zero duration', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      CountdownCarousel.preferenceKey: 99,
    });
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(26),
                child: CountdownCarousel(duration: Duration.zero, after: true),
              ),
            ),
          ),
        ),
      ),
    );
    for (final title in [
      'Décompte',
      'Semaines',
      'Heures',
      'Secondes',
      'Respirations',
    ]) {
      await tester.tap(find.byTooltip(title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('≈ 0'), findsOneWidget);
  });
}
