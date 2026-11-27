import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jusqua_nous/app/theme.dart';
import 'package:jusqua_nous/core/application/providers.dart';
import 'package:jusqua_nous/core/data/local_wedding_repository.dart';
import 'package:jusqua_nous/features/attentions/application/attention_providers.dart';
import 'package:jusqua_nous/features/attentions/data/attention_repository.dart';
import 'package:jusqua_nous/features/attentions/domain/attention.dart';
import 'package:jusqua_nous/features/attentions/presentation/attention_creation_form.dart';
import 'package:jusqua_nous/features/attentions/presentation/attention_widgets.dart';

class FakeAttentionRepository extends AttentionRepository {
  FakeAttentionRepository()
    : super(
        SupabaseClient(
          'https://example.invalid',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final List<Map<String, dynamic>> attempts = [];
  Completer<void>? hold;
  bool failOnce = false;
  @override
  Future<void> offer(Map<String, dynamic> params) async {
    attempts.add(Map.of(params));
    if (hold != null) await hold!.future;
    if (failOnce) {
      failOnce = false;
      throw Exception('Response lost');
    }
  }
}

void main() {
  test(
    'templates and role-specific actions remain consistent with RPC contracts',
    () {
      expect(AttentionTemplate.all.length, 3);
      AttentionVoucher v(String status, {String awaiting = 'a'}) =>
          AttentionVoucher({
            'sender_id': 'a',
            'recipient_id': 'b',
            'status': status,
            'awaiting_id': awaiting,
          });
      expect(v('offered').actionsFor('b'), ['open']);
      expect(v('opened').actionsFor('a'), ['cancel']);
      expect(v('opened').actionsFor('b'), ['request']);
      expect(
        v('requested').actionsFor('a'),
        containsAll(['accept', 'propose', 'later', 'complete']),
      );
      expect(v('requested').actionsFor('b'), contains('withdraw'));
      expect(
        v('requested', awaiting: 'b').actionsFor('a'),
        isNot(contains('accept')),
      );
      expect(v('requested', awaiting: 'b').actionsFor('b'), contains('accept'));
      expect(v('scheduled').actionsFor('a'), ['complete']);
      expect(v('completed').actionsFor('b'), ['undo']);
      expect(v('cancelled').actionsFor('b'), isEmpty);
      for (final state in [
        'offered',
        'opened',
        'requested',
        'scheduled',
        'completed',
      ]) {
        expect(v(state).actionsFor('outsider'), isEmpty);
      }
    },
  );
  Future<void> start(
    WidgetTester tester,
    FakeAttentionRepository fake, {
    AttentionTemplate? template,
  }) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attentionRepositoryProvider.overrideWithValue(fake),
          preferencesProvider.overrideWithValue(prefs),
          repositoryProvider.overrideWithValue(LocalWeddingRepository(prefs)),
        ],
        child: MaterialApp(
          theme: weddingTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.5),
              disableAnimations: true,
            ),
            child: AttentionCreationForm(
              template: template,
              recipientId: 'b',
              recipientName: 'Alyssa',
              senderName: 'Faris',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'custom creation validates fields and renders a live preview at narrow width',
    (tester) async {
      final fake = FakeAttentionRepository();
      await start(tester, fake);
      await tester.ensureVisible(find.text('Offrir cette attention'));
      await tester.tap(find.text('Offrir cette attention'));
      await tester.pumpAndSettle();
      expect(fake.attempts, isEmpty);
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.at(0));
      await tester.enterText(fields.at(0), 'Une balade à deux');
      await tester.ensureVisible(fields.at(1));
      await tester.enterText(fields.at(1), 'Le long de la mer.');
      await tester.ensureVisible(fields.at(2));
      await tester.enterText(fields.at(2), 'Juste toi et moi.');
      await tester.pumpAndSettle();
      final card = tester.widget<AttentionVoucherCard>(
        find.byType(AttentionVoucherCard),
      );
      expect(card.voucher.text('title'), 'Une balade à deux');
      expect(card.voucher.text('personal_message'), 'Juste toi et moi.');
      fake.hold = Completer<void>();
      await tester.ensureVisible(find.text('Offrir cette attention'));
      await tester.tap(find.text('Offrir cette attention'));
      await tester.pump();
      expect(fake.attempts.single['p_template'], null);
      expect(fake.attempts.single['p_recipient'], 'b');
      expect(tester.takeException(), isNull);
      fake.hold!.complete();
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'template send prevents double submission and retries with same immutable id',
    (tester) async {
      final fake = FakeAttentionRepository()
        ..hold = Completer<void>()
        ..failOnce = true;
      await start(tester, fake, template: AttentionTemplate.all.first);
      await tester.ensureVisible(find.text('Offrir cette attention'));
      await tester.tap(find.text('Offrir cette attention'));
      await tester.pump();
      await tester.tap(find.text('Envoi en cours…'));
      await tester.pump();
      expect(fake.attempts.length, 1);
      fake.hold!.complete();
      await tester.pumpAndSettle();
      expect(fake.attempts.first['p_template'], 'massage');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Réessayer l’envoi'));
      await tester.tap(find.text('Réessayer l’envoi'));
      await tester.pumpAndSettle();
      expect(fake.attempts.length, 2);
      expect(fake.attempts[0], fake.attempts[1]);
      expect(tester.takeException(), isNull);
    },
  );
}
