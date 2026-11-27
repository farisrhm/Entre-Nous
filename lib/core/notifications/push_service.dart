import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../application/providers.dart';
import '../data/supabase_wedding_repository.dart';

final pushServiceProvider = Provider<PushService?>((ref) {
  final repository = ref.watch(repositoryProvider);
  if (repository is! SupabaseWeddingRepository ||
      kIsWeb ||
      defaultTargetPlatform != TargetPlatform.iOS) {
    return null;
  }
  final service = PushService(repository.client);
  ref.onDispose(service.dispose);
  return service;
});

class PushTarget {
  final String recipientId, kind, entryId, notificationId;
  const PushTarget(
    this.recipientId,
    this.kind,
    this.entryId,
    this.notificationId,
  );
  static PushTarget? parse(Map<String, dynamic> data) {
    final recipient = data['recipientId'],
        kind = data['kind'],
        entry = data['entryId'],
        id = data['notificationId'];
    if (recipient is! String ||
        id is! String ||
        entry is! String ||
        !['thought', 'memory', 'dua', 'letter', 'voucher'].contains(kind) ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(entry)) {
      return null;
    }
    return PushTarget(recipient, kind as String, entry, id);
  }

  String get path => switch (kind) {
    'memory' => '/story',
    'dua' => '/universe/dua',
    'letter' => '/letters',
    'voucher' => '/universe/attentions',
    _ => '/universe',
  };
}

class PushService extends ChangeNotifier {
  final SupabaseClient client;
  final Duration requestTimeout;
  PushService(this.client, {this.requestTimeout = const Duration(seconds: 12)});
  Map<String, bool> preferences = {
    'enabled': false,
    'thought': true,
    'memory': true,
    'dua': true,
    'letter': true,
    'voucher': true,
  };
  String? error;
  PushTarget? pending;
  bool busy = false;
  bool _disposed = false;
  Future<void>? _initializing;
  Future<void>? _refreshing;
  bool _listening = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Future<void> _tail = Future.value();
  String? _registeredToken;
  String? _registeredUser;
  String? _lastOpened;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<T> _wait<T>(Future<T> future, String step, {Duration? timeout}) =>
      future.timeout(
        timeout ?? requestTimeout,
        onTimeout: () => throw TimeoutException(step),
      );

  Future<void> _initialize() =>
      _initializing ??= _initializeFirebase().catchError((Object e) {
        _initializing = null;
        throw e;
      });
  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await _wait(Firebase.initializeApp(), 'Initialisation Firebase');
    }
    if (_disposed) return;
    await _wait(
      FirebaseMessaging.instance.setAutoInitEnabled(false),
      'Configuration Firebase',
    );
    await _wait(
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: false,
        sound: true,
      ),
      'Configuration des alertes iOS',
    );
    if (_disposed || _listening) return;
    _listening = true;
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen(_opened));
    _subscriptions.add(
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (token != _registeredToken) unawaited(refresh());
      }),
    );
    _subscriptions.add(
      client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedOut) {
          pending = null;
          _notify();
        }
        unawaited(refresh());
      }),
    );
    // An optional launch notification must never block permission controls.
    unawaited(
      _wait(
            FirebaseMessaging.instance.getInitialMessage(),
            'Notification de démarrage',
          )
          .then((initial) {
            if (!_disposed && initial != null) _opened(initial);
          })
          .catchError((Object _) {}),
    );
  }

  void _opened(RemoteMessage message) {
    final target = PushTarget.parse(message.data);
    if (target == null || target.notificationId == _lastOpened) return;
    _lastOpened = target.notificationId;
    pending = target;
    _notify();
  }

  void consume() {
    pending = null;
  }

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    final result = await _wait(
      client.functions.invoke('wedding-push-device', body: body),
      'Connexion au service de notifications',
    );
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> _loadPreferences() async {
    final result = await _call({'action': 'preferences'});
    preferences = Map<String, bool>.from(result['preferences'] as Map);
  }

  Future<void> _savePreferences(Map<String, bool> value) async {
    final result = await _call({'action': 'preferences', 'preferences': value});
    preferences = Map<String, bool>.from(result['preferences'] as Map);
  }

  Future<void> _run(Future<void> Function() action) {
    final next = _tail.then((_) async {
      if (_disposed) return;
      busy = true;
      error = null;
      _notify();
      try {
        await action();
      } on TimeoutException catch (e) {
        error =
            '${e.message} : délai dépassé. Le chargement a été arrêté. Réessaie dans un instant.';
      } catch (_) {
        error =
            'Notifications indisponibles. Vérifie ta connexion et les autorisations dans les réglages de l’iPhone, puis réessaie.';
      } finally {
        busy = false;
        _notify();
      }
    });
    _tail = next;
    return next;
  }

  Future<void> refresh() =>
      _refreshing ??= _run(_refresh).whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    final user = client.auth.currentUser?.id;
    if (user == null) {
      if (Firebase.apps.isNotEmpty) {
        await _wait(
          FirebaseMessaging.instance.deleteToken(),
          'Suppression du jeton',
        );
      }
      _registeredToken = null;
      _registeredUser = null;
      return;
    }
    if (_registeredUser != null && _registeredUser != user) {
      await _wait(
        FirebaseMessaging.instance.deleteToken(),
        'Changement de compte',
      );
      _registeredToken = null;
      _registeredUser = null;
    }
    // Do not wait for Firebase/APNs merely to display the disabled switch.
    await _loadPreferences();
    if (_disposed || client.auth.currentUser?.id != user) return;
    if (preferences['enabled'] != true) {
      if (_registeredToken != null) await _unregister();
      return;
    }
    await _initialize();
    if (_disposed || client.auth.currentUser?.id != user) return;
    final settings = await _wait(
      FirebaseMessaging.instance.getNotificationSettings(),
      'Autorisation iOS',
    );
    if (_allowed(settings)) {
      await _register(user);
    } else if (_registeredToken != null) {
      await _unregister();
    }
  }

  bool _allowed(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
  Future<void> _register(String user) async {
    final messaging = FirebaseMessaging.instance;
    // APNs must be available before requesting an FCM token on iOS.
    String? apns = await _wait(
      messaging.getAPNSToken(),
      'Enregistrement Apple APNs',
    );
    for (var i = 0; apns == null && i < 3; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      apns = await _wait(messaging.getAPNSToken(), 'Enregistrement Apple APNs');
    }
    if (apns == null) throw StateError('APNs is not ready');
    final token = await _wait(messaging.getToken(), 'Enregistrement Firebase');
    if (client.auth.currentUser?.id != user || _disposed) return;
    if (token == null) throw StateError('FCM token unavailable');
    if (_registeredToken == token && _registeredUser == user) return;
    await _call({'action': 'register', 'token': token});
    if (_registeredToken != null && _registeredToken != token) {
      await _call({'action': 'unregister', 'token': _registeredToken});
    }
    _registeredToken = token;
    _registeredUser = user;
  }

  Future<void> _unregister() async {
    if (_registeredToken != null &&
        client.auth.currentUser?.id == _registeredUser) {
      await _call({'action': 'unregister', 'token': _registeredToken});
    }
    await _wait(
      FirebaseMessaging.instance.deleteToken(),
      'Suppression du jeton',
    );
    _registeredToken = null;
    _registeredUser = null;
  }

  Future<void> setEnabled(bool enabled) => _run(() async {
    await _initialize();
    final user = client.auth.currentUser?.id;
    if (user == null) throw StateError('Sign in first');
    await _loadPreferences();
    if (enabled) {
      final settings = await _wait(
        FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: false,
          sound: true,
        ),
        'Autorisation iOS',
        timeout: const Duration(minutes: 1),
      );
      if (!_allowed(settings)) throw StateError('Permission denied');
      await _register(user);
      if (client.auth.currentUser?.id != user) return;
      await _savePreferences({...preferences, 'enabled': true});
    } else {
      await _savePreferences({...preferences, 'enabled': false});
      await _unregister();
    }
  });
  Future<void> setCategory(String category, bool enabled) => _run(() async {
    if (!['thought', 'memory', 'dua', 'letter', 'voucher'].contains(category)) {
      return;
    }
    await _loadPreferences();
    await _savePreferences({...preferences, category: enabled});
  });

  /// Called before Supabase logout, while unregister still has a valid JWT.
  Future<void> disconnect() async {
    await _tail;
    pending = null;
    if (Firebase.apps.isEmpty) return;
    try {
      await _unregister();
    } catch (_) {
      // Revoking the FCM token also prevents alerts if the server is offline.
      await _wait(
        FirebaseMessaging.instance.deleteToken(),
        'Suppression du jeton',
      );
      _registeredToken = null;
      _registeredUser = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
