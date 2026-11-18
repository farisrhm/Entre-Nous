import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jusqua_nous/features/home/domain/journey_progress.dart';
import 'package:jusqua_nous/features/home/presentation/wedding_journey.dart';

void main() {
  test(
    'calendar progression is stable across devices and meets at French midnight',
    () {
      expect(JourneyProgress.at(DateTime.utc(2026, 3, 28)).progress, 0);
      expect(
        JourneyProgress.at(DateTime.utc(2026, 8, 25, 12)).progress,
        closeTo(150 / 301, 1e-10),
      );
      expect(
        JourneyProgress.at(
          DateTime.parse('2027-01-22T22:59:59Z'),
        ).daysRemaining,
        1,
      );
      expect(
        JourneyProgress.at(
          DateTime.parse('2027-01-23T00:00:00+01:00'),
        ).together,
        true,
      );
      expect(
        JourneyProgress.at(DateTime.utc(2027, 1, 24, 12)).daysRemaining,
        -1,
      );
      expect(JourneyProgress.at(DateTime.utc(2028)).progress, 1);
    },
  );
  testWidgets(
    'narrow screen, large text and hourglass before and after wedding',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final now in [
        DateTime.utc(2026, 11, 15),
        DateTime.utc(2027, 1, 23, 12),
        DateTime.utc(2027, 2, 1),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.8),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: WeddingJourney(
                    now: now,
                    firstName: 'Alyssa',
                    secondName: 'Faris',
                    reduceMotion: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('J−50'), findsNothing);
        expect(find.text('28 mars 2026 · 23 janvier 2027'), findsOneWidget);
      }
    },
  );
}
