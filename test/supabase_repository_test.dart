import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jusqua_nous/core/data/supabase_wedding_repository.dart';
import 'package:jusqua_nous/core/data/private_photos.dart';
import 'package:jusqua_nous/core/domain/entry.dart';
import 'package:jusqua_nous/main.dart';

const uid = 'b52d499a-f6a9-4772-ad91-149d853e36e5';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SupabaseWeddingRepository repository;
  late List<http.Request> requests;
  bool denyMembership = false;
  setUp(() {
    requests = [];
    denyMembership = false;
    client = SupabaseClient(
      'https://test.supabase.co',
      'public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        dynamic body = {};
        if (path == '/auth/v1/token') {
          body = {
            'access_token': 'test-token',
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': uid,
              'aud': 'authenticated',
              'email': 'person@example.com',
              'created_at': '2026-01-01T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          };
        } else if (path == '/functions/v1/wedding-list') {
          if (denyMembership) {
            return http.Response(
              '{"error":"Accès refusé"}',
              403,
              headers: {'content-type': 'application/json'},
            );
          }
          body = {
            'userId': uid,
            'members': [
              {'id': uid, 'name': 'Alyssa'},
              {'id': '86828ab6-34fb-4956-b54c-607d945cb445', 'name': 'Faris'},
            ],
            'entries': [],
          };
        } else if (path.startsWith('/storage/v1/object/') &&
            request.method == 'POST') {
          body = {'Key': path.substring('/storage/v1/object/'.length)};
        } else if (path.startsWith('/storage/v1/object/') &&
            request.method == 'GET') {
          return http.Response.bytes([255, 216, 255, 1], 200);
        }
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    repository = SupabaseWeddingRepository(client);
  });
  tearDown(() async => client.dispose());

  test(
    'restore never signs in with shared credentials or needs network',
    () async {
      await repository.restore();
      expect(requests, isEmpty);
      expect(repository.hasSession, isFalse);
    },
  );
  test('rejected membership removes the authenticated session', () async {
    denyMembership = true;
    await expectLater(
      repository.login('person@example.com', 'password'),
      throwsA(isA<FunctionException>()),
    );
    expect(repository.hasSession, isFalse);
    expect(repository.userId, isNull);
  });
  test(
    'upload keeps original bytes and saves only a private reference',
    () async {
      await repository.login('person@example.com', 'password');
  final original = await File('assets/images/home_1.jpg').readAsBytes();
      final source = await repository.uploadPhoto(original, 'jpeg');
      expect(PrivatePhotos.path(source), startsWith('$uid/'));
      final upload = requests.singleWhere(
        (r) =>
            r.url.path.startsWith('/storage/v1/object/') &&
            r.method == 'POST' &&
            !r.url.path.endsWith('.thumb.png'),
      );
      expect(
        latin1.decode(upload.bodyBytes),
        contains(latin1.decode(original)),
      );
      expect(upload.headers['x-upsert'], 'false');
      await repository.save(
        Entry(
          id: 'album',
          kind: EntryKind.memory,
          fields: {
            'title': 'Album',
            'photos': [source],
          },
        ),
      );
      final save = jsonDecode(requests.last.body) as Map;
      expect(save['schemaVersion'], 3);
      expect(save['fields']['photos'], [source]);
      expect(requests.last.body, isNot(contains('base64')));
      expect(
        await repository.downloadPhoto(source),
        orderedEquals([255, 216, 255, 1]),
      );
      expect(requests.last.headers['Authorization'], 'Bearer test-token');
      await repository.downloadPhoto(source, thumbnail: true);
      expect(requests.last.url.path, endsWith('.thumb.png'));
    },
  );
  test('legacy inline photo migrates when the memory is edited', () async {
    await repository.login('person@example.com', 'password');
  final oldBytes = await File('assets/images/home_1.jpg').readAsBytes();
    await repository.save(
      Entry(
        id: 'old',
        kind: EntryKind.memory,
        fields: {
          'title': 'Old',
          'photo': 'data:image/jpeg;base64,${base64Encode(oldBytes)}',
        },
      ),
    );
    final body = jsonDecode(requests.last.body) as Map;
    expect(body['fields']['photo'], startsWith(PrivatePhotos.prefix));
  });
  test(
    'invalid private paths cannot redirect authenticated downloads',
    () async {
      await expectLater(
        () => repository.downloadPhoto('${PrivatePhotos.prefix}../../other'),
        throwsFormatException,
      );
    },
  );
  testWidgets('startup error renders retry and then the app', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      StartupGate(
        load: () async {
          if (calls++ == 0) throw Exception('offline');
          return const MaterialApp(home: Text('Ready'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
  });
}
