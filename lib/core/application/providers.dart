import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entry.dart';
import '../domain/wedding_repository.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final repositoryProvider = Provider<WeddingRepository>(
  (ref) => throw UnimplementedError(),
);
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});
final entriesProvider = AsyncNotifierProvider<EntriesController, List<Entry>>(
  EntriesController.new,
);

class EntriesController extends AsyncNotifier<List<Entry>> {
  Future<void> _tail = Future.value();
  @override
  Future<List<Entry>> build() => ref.watch(repositoryProvider).load();
  Future<void> _enqueue(Future<void> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.catchError((Object _) {});
    return next;
  }

  Future<void> _load() async {
    final result = await ref.read(repositoryProvider).load();
    if (ref.mounted) state = AsyncData(result);
  }

  Future<void> refresh() => _enqueue(_load);
  Future<void> save(Entry entry) => _enqueue(() async {
    await ref.read(repositoryProvider).save(entry);
    if (ref.mounted) await _load();
  });
  Future<void> delete(Entry entry) => _enqueue(() async {
    await ref.read(repositoryProvider).delete(entry);
    if (ref.mounted) await _load();
  });
}

class Settings {
  final String firstName, secondName, heroPhoto, phase;
  final List<String> heroPhotos;
  final bool demo, reduceMotion, onboardingDone;
  const Settings({
    this.firstName = 'Alyssa',
    this.secondName = 'Faris',
    this.heroPhoto = 'asset:assets/images/hero.jpg',
    this.heroPhotos = const ['asset:assets/images/hero.jpg'],
    this.phase = 'auto',
    this.demo = false,
    this.reduceMotion = false,
    this.onboardingDone = false,
  });
  Settings copy({
    String? firstName,
    String? secondName,
    String? heroPhoto,
    List<String>? heroPhotos,
    String? phase,
    bool? demo,
    bool? reduceMotion,
    bool? onboardingDone,
  }) => Settings(
    firstName: firstName ?? this.firstName,
    secondName: secondName ?? this.secondName,
    heroPhoto: heroPhoto ?? this.heroPhoto,
    heroPhotos: heroPhotos ?? this.heroPhotos,
    phase: phase ?? this.phase,
    demo: demo ?? this.demo,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    onboardingDone: onboardingDone ?? this.onboardingDone,
  );
}

final settingsProvider = NotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() {
    final p = ref.read(preferencesProvider);
    final savedHeroPhoto =
        p.getString('heroPhoto') ?? 'asset:assets/images/hero.jpg';
    final savedHeroPhotos = p
        .getStringList('heroPhotos')
        ?.map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return Settings(
      firstName: p.getString('firstName') ?? 'Alyssa',
      secondName: p.getString('secondName') ?? 'Faris',
      heroPhoto: savedHeroPhoto,
      heroPhotos: (savedHeroPhotos == null || savedHeroPhotos.isEmpty)
          ? [savedHeroPhoto]
          : savedHeroPhotos,
      phase: p.getString('phase') ?? 'auto',
      demo: p.getBool('demo') ?? false,
      reduceMotion: p.getBool('reduceMotion') ?? false,
      onboardingDone: p.getBool('onboardingDone') ?? false,
    );
  }

  Future<void> save(Settings s) async {
    final p = ref.read(preferencesProvider);
    final results = await Future.wait([
      p.setString('firstName', s.firstName),
      p.setString('secondName', s.secondName),
      p.setString('heroPhoto', s.heroPhoto),
  p.setStringList('heroPhotos', s.heroPhotos),
      p.setString('phase', s.phase),
      p.setBool('demo', s.demo),
      p.setBool('reduceMotion', s.reduceMotion),
      p.setBool('onboardingDone', s.onboardingDone),
    ]);
    if (results.any((ok) => !ok)) {
      throw Exception('Enregistrement des réglages impossible.');
    }
    state = s;
  }
}

final authRevisionProvider = NotifierProvider<AuthRevision, int>(
  AuthRevision.new,
);

class AuthRevision extends Notifier<int> {
  @override
  int build() => 0;
  void changed() => state++;
}
