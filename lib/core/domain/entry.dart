/// Small, immutable records shared by the local and Parse repositories.
/// Each record is saved separately: editing a dream never overwrites an album.
enum EntryKind {
  memory,
  letter,
  dream,
  promise,
  thought,
  openWhen,
  happiness,
  dua,
  intention,
}

class Entry {
  final String id;
  final EntryKind kind;
  final Map<String, dynamic> fields;
  final String? authorId;
  const Entry({
    required this.id,
    required this.kind,
    required this.fields,
    this.authorId,
  });
  String text(String key) => fields[key] as String? ?? '';
  bool flag(String key) => fields[key] == true;
  DateTime? date(String key) => DateTime.tryParse(text(key));
  Entry copy(Map<String, dynamic> changes) => Entry(
    id: id,
    kind: kind,
    fields: {...fields, ...changes},
    authorId: authorId,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'fields': fields,
    'authorId': authorId,
  };
  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
    id: j['id'] as String,
    kind: EntryKind.values.byName(j['kind'] as String),
    fields: Map<String, dynamic>.from(j['fields'] as Map),
    authorId: j['authorId'] as String?,
  );
}

class Member {
  final String id, name;
  const Member(this.id, this.name);
}
