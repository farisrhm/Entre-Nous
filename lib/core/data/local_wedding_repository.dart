import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entry.dart';
import '../domain/wedding_repository.dart';

class LocalWeddingRepository implements WeddingRepository {
  final SharedPreferences prefs;
  LocalWeddingRepository(this.prefs);
  static const key = 'wedding.entries.v1';
  @override
  bool get isCloud => false;
  @override
  String? get userId => null;
  @override
  List<Member> get members => const [
    Member('alyssa', 'Alyssa'),
    Member('faris', 'Faris'),
  ];
  @override
  Future<List<Entry>> load() async {
    final raw = prefs.getString(key);
    if (raw == null) return List.of(seedEntries);
    return (jsonDecode(raw) as List)
        .map((e) => Entry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _write(List<Entry> entries) async {
    if (!await prefs.setString(
      key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    )) {
      throw Exception('Impossible de sauvegarder sur cet appareil.');
    }
  }

  @override
  Future<void> save(Entry entry) async {
    final entries = await load();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index < 0) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
    await _write(entries);
  }

  @override
  Future<void> delete(Entry entry) async =>
      _write((await load()).where((e) => e.id != entry.id).toList());
}

final seedEntries = <Entry>[
  const Entry(
    id: 'm1',
    kind: EntryKind.memory,
    fields: {
      'title': 'Notre première rencontre',
      'date': 'Une date à compléter',
      'body':
          'Le premier chapitre de notre histoire. Un instant ordinaire devenu inoubliable.',
      'photo': 'asset:assets/images/story1.jpg',
    },
  ),
  const Entry(
    id: 'm2',
    kind: EntryKind.memory,
    fields: {
      'title': 'Notre premier rendez-vous',
      'date': 'Une date à compléter',
      'body':
          'Des heures à parler comme si le temps avait décidé de nous attendre.',
      'photo': 'asset:assets/images/story2.jpg',
    },
  ),
  const Entry(
    id: 'm3',
    kind: EntryKind.memory,
    fields: {
      'title': 'Le jour où tout a changé',
      'date': 'Une date à compléter',
      'body':
          'Ce moment où nous avons su que notre histoire serait celle d’une vie.',
      'photo': 'asset:assets/images/story3.jpg',
    },
  ),
  const Entry(
    id: 'l1',
    kind: EntryKind.letter,
    fields: {
      'title': 'Pour le matin de notre mariage',
      'recipient': 'Alyssa',
      'recipientId': 'alyssa',
      'openAt': '2027-01-23T07:00:00Z',
      'body':
          'Mon amour,\n\nCe matin, chaque seconde porte ton prénom. Dans quelques heures, je prendrai ta main et nous commencerons le plus beau chapitre de notre histoire.\n\nÀ tout à l’heure, pour toujours.',
    },
  ),
  const Entry(
    id: 'd1',
    kind: EntryKind.dream,
    fields: {'title': 'Notre premier voyage après le mariage', 'done': false},
  ),
  const Entry(
    id: 'd2',
    kind: EntryKind.dream,
    fields: {'title': 'Inventer nos traditions du dimanche', 'done': true},
  ),
  const Entry(
    id: 'd3',
    kind: EntryKind.dream,
    fields: {'title': 'Créer notre premier chez-nous', 'done': false},
  ),
];
