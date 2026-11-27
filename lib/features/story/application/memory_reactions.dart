import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/application/providers.dart';
import '../../../core/data/supabase_wedding_repository.dart';
import '../data/memory_reaction_store.dart';
import '../domain/memory_reaction.dart';

final memoryReactionStoreProvider = Provider<MemoryReactionStore>((ref) {
  ref.watch(authRevisionProvider);
  final repo = ref.watch(repositoryProvider);
  return repo is SupabaseWeddingRepository
      ? CloudMemoryReactionStore(
          repo.client,
          repo.userId ?? repo.client.auth.currentUser?.id ?? '',
        )
      : LocalMemoryReactionStore(ref.watch(preferencesProvider));
});
final memoryReactionsProvider =
    AsyncNotifierProvider.autoDispose<MemoryReactions, List<MemoryReaction>>(
      MemoryReactions.new,
    );

class MemoryReactions extends AsyncNotifier<List<MemoryReaction>> {
  Future<void> _tail = Future.value();
  Future<void>? _refreshing;
  @override
  Future<List<MemoryReaction>> build() {
    final store = ref.watch(memoryReactionStoreProvider);
    // One shared poll for all visible memories, never one request per card.
    if (store is CloudMemoryReactionStore) {
      final timer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => unawaited(refresh()),
      );
      ref.onDispose(timer.cancel);
    }
    return store.load();
  }

  Future<void> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  Future<void> _refresh() => _queue(() async {
    final store = ref.read(memoryReactionStoreProvider);
    try {
      final rows = await store.load();
      if (ref.mounted &&
          identical(ref.read(memoryReactionStoreProvider), store)) {
        state = AsyncData(rows);
      }
    } catch (e, s) {
      if (ref.mounted &&
          identical(ref.read(memoryReactionStoreProvider), store)) {
        state = AsyncError(e, s);
      }
    }
  });
  Future<void> choose(String id, String? emoji) => _queue(() async {
    final store = ref.read(memoryReactionStoreProvider);
    await store.set(id, emoji);
    // Publish only after the write succeeds. Retrying the same value is idempotent.
    final rows = await store.load();
    if (ref.mounted &&
        identical(ref.read(memoryReactionStoreProvider), store)) {
      state = AsyncData(rows);
    }
  });
  Future<void> _queue(Future<void> Function() action) {
    final result = _tail.then((_) async {
      if (ref.mounted) await action();
    });
    _tail = result.catchError((Object _) {});
    return result;
  }
}
