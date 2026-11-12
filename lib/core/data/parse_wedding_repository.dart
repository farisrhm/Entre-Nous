import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/wedding_config.dart';
import '../domain/entry.dart';
import '../domain/wedding_repository.dart';

/// Uses Parse REST + Cloud Code. No master key is ever included in the app.
class ParseWeddingRepository implements CloudWeddingRepository {
  final http.Client client;
  final FlutterSecureStorage storage;
  String? _token, _userId;
  List<Member> _members = [];
  ParseWeddingRepository({
    http.Client? client,
    this.storage = const FlutterSecureStorage(),
  }) : client = client ?? http.Client();
  @override
  bool get isCloud => true;
  @override
  String? get userId => _userId;
  @override
  List<Member> get members => List.unmodifiable(_members);
  Future<dynamic> _request(String path, Map<String, dynamic> body) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Parse-Application-Id': WeddingConfig.appId,
      'X-Parse-Client-Key': WeddingConfig.clientKey,
    };
    if (_token != null) {
      headers['X-Parse-Session-Token'] = _token!;
    }
    final response = await client
        .post(
          Uri.parse('${WeddingConfig.server}/$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || data.containsKey('error')) {
      if (data['code'] == 209) {
        throw Exception('Session expirée. Déconnecte-toi puis reconnecte-toi.');
      }
      throw Exception(
        data['error'] ?? 'Connexion impossible (${response.statusCode}).',
      );
    }
    return data;
  }

  @override
  Future<void> restore() async {
    _token = await storage.read(key: 'parse.session');
  }

  @override
  Future<void> login(String username, String password) async {
    // POST avoids putting passwords in URLs and proxy logs.
    final data = await _request('login', {
      'username': username,
      'password': password,
    });
    _token = data['sessionToken'] as String;
    try {
      await load();
      await storage.write(key: 'parse.session', value: _token);
    } catch (_) {
      _token = null;
      _userId = null;
      _members = [];
      rethrow;
    }
  }

  @override
  bool get hasSession => _token != null;

  @override
  Future<void> logout() async {
    try {
      if (_token != null) await _request('logout', {});
    } finally {
      _token = null;
      _userId = null;
      _members = [];
      await storage.delete(key: 'parse.session');
    }
  }

  @override
  Future<List<Entry>> load() async {
    final result =
        (await _request('functions/weddingList', {
              'schemaVersion': 2,
            }))['result']
            as Map;
    _userId = result['userId'] as String;
    _members = (result['members'] as List)
        .map((m) => Member(m['id'] as String, m['name'] as String))
        .toList();
    return (result['entries'] as List)
        .map((e) => Entry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> save(Entry entry) async {
    await _request('functions/weddingSave', {
      ...entry.toJson(),
      'schemaVersion': 2,
    });
  }

  @override
  Future<void> delete(Entry entry) async {
    await _request('functions/weddingDelete', {
      'id': entry.id,
      'kind': entry.kind.name,
    });
  }
}
