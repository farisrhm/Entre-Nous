import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jusqua_nous/core/notifications/push_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late PushService service;
  late Future<http.Response> Function() preferences;
  int calls = 0;
  http.Response response({bool enabled = false}) => http.Response(
    jsonEncode({
      'preferences': {
        'enabled': enabled,
        'thought': true,
        'memory': true,
        'dua': true,
        'letter': true,
      },
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
  setUp(() async {
    calls = 0;
    preferences = () async => response();
    client = SupabaseClient(
      'https://test.supabase.co',
      'public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode({
              'access_token': 'token',
              'refresh_token': 'refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'b52d499a-f6a9-4772-ad91-149d853e36e5',
                'aud': 'authenticated',
                'email': 'test@example.com',
                'created_at': '2026-01-01T00:00:00Z',
                'app_metadata': {},
                'user_metadata': {},
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        calls++;
        return preferences();
      }),
    );
    await client.auth.signInWithPassword(
      email: 'test@example.com',
      password: 'test',
    );
    service = PushService(
      client,
      requestTimeout: const Duration(milliseconds: 80),
    );
  });
  tearDown(() async {
    service.dispose();
    await client.dispose();
  });
  test(
    'disabled preferences display without initializing native Firebase',
    () async {
      await service.refresh();
      expect(service.busy, false);
      expect(service.error, isNull);
      expect(calls, 1);
      expect(service.preferences['enabled'], false);
    },
  );
  test('concurrent refresh calls are coalesced', () async {
    final pending = Completer<http.Response>();
    preferences = () => pending.future;
    final a = service.refresh(), b = service.refresh(), c = service.refresh();
    expect(identical(a, b), true);
    expect(identical(b, c), true);
    pending.complete(response());
    await Future.wait([a, b, c]);
    expect(calls, 1);
    expect(service.busy, false);
  });
  test(
    'a stalled request releases busy, permits retry and ignores late result',
    () async {
      final pending = Completer<http.Response>();
      preferences = () => pending.future;
      await service.refresh();
      expect(service.busy, false);
      expect(service.error, contains('délai dépassé'));
      preferences = () async => response();
      await service.refresh();
      expect(service.error, isNull);
      expect(calls, 2);
      pending.complete(response(enabled: true));
      await Future<void>.delayed(Duration.zero);
      expect(service.preferences['enabled'], false);
      expect(service.busy, false);
    },
  );
}
