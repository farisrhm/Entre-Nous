import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/core/application/providers.dart';
import 'package:jusqua_nous/core/data/local_wedding_repository.dart';
import 'package:jusqua_nous/core/notifications/notification_settings.dart';

void main() {
  testWidgets(
    'local builds explain notification unavailability instead of hiding the section',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(LocalWeddingRepository(prefs)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: NotificationSettingsPanel()),
          ),
        ),
      );
      expect(find.text('Notifications'), findsOneWidget);
      expect(
        find.textContaining('Cette version n’utilise pas'),
        findsOneWidget,
      );
      expect(find.byType(SwitchListTile), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
