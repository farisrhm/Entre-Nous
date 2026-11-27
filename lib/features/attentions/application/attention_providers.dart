import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/application/providers.dart';
import '../../../core/data/supabase_wedding_repository.dart';
import '../data/attention_repository.dart';
import '../domain/attention.dart';

final attentionRepositoryProvider = Provider<AttentionRepository?>((ref) {
  ref.watch(authRevisionProvider);
  final repo = ref.watch(repositoryProvider);
  return repo is SupabaseWeddingRepository
      ? AttentionRepository(repo.client)
      : null;
});
final attentionsProvider = FutureProvider.autoDispose<List<AttentionVoucher>>((
  ref,
) async {
  final repo = ref.watch(attentionRepositoryProvider);
  if (repo == null) return [];
  return repo.list();
});
final attentionEventsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, id) async {
      // Remote transitions also refresh the corresponding event history.
      ref.watch(
        attentionsProvider.select(
          (value) => value.value?.where((v) => v.id == id).firstOrNull?.version,
        ),
      );
      return ref.watch(attentionRepositoryProvider)?.events(id) ?? [];
    });
