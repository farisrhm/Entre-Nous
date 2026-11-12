import 'entry.dart';

abstract interface class WeddingRepository {
  bool get isCloud;
  String? get userId;
  List<Member> get members;
  Future<List<Entry>> load();
  Future<void> save(Entry entry);
  Future<void> delete(Entry entry);
}

abstract interface class CloudWeddingRepository implements WeddingRepository {
  bool get hasSession;
  Future<void> restore();
  Future<void> login(String username, String password);
  Future<void> logout();
}
