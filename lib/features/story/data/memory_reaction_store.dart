import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/memory_reaction.dart';

abstract interface class MemoryReactionStore {
  String get userId;
  Future<List<MemoryReaction>> load();
  Future<void> set(String memoryId, String? emoji);
}

class CloudMemoryReactionStore implements MemoryReactionStore {
  final SupabaseClient client;
  @override
  final String userId;
  CloudMemoryReactionStore(this.client, this.userId);
  @override
  Future<List<MemoryReaction>> load() async {
    final rows = await client
        .from('memory_reactions')
        .select('entry_key,user_id,emoji')
        .timeout(const Duration(seconds: 12));
    return rows.map(MemoryReaction.fromJson).toList();
  }

  @override
  Future<void> set(String memoryId, String? emoji) async {
    if (emoji != null && !ReactionEmoji.valid(emoji)) {
      throw const FormatException('Choisis un seul emoji.');
    }
    await client
        .rpc(
          'set_memory_reaction',
          params: {'p_memory_id': memoryId, 'p_emoji': emoji},
        )
        .timeout(const Duration(seconds: 12));
  }
}

class LocalMemoryReactionStore implements MemoryReactionStore {
  final SharedPreferences prefs;
  static const key = 'memory-reactions.v1';
  LocalMemoryReactionStore(this.prefs);
  @override
  String get userId => 'local';
  @override
  Future<List<MemoryReaction>> load() async {
    try {
      final data = jsonDecode(prefs.getString(key) ?? '{}') as Map;
      return [
        for (final e in data.entries)
          if (e.key is String &&
              e.value is String &&
              ReactionEmoji.valid(e.value as String))
            MemoryReaction(e.key as String, userId, e.value as String),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> set(String memoryId, String? emoji) async {
    if (emoji != null && !ReactionEmoji.valid(emoji)) {
      throw const FormatException('Choisis un seul emoji.');
    }
    final values = {for (final r in await load()) r.memoryId: r.emoji};
    if (emoji == null) {
      values.remove(memoryId);
    } else {
      values[memoryId] = emoji;
    }
    if (!await prefs.setString(key, jsonEncode(values))) {
      throw StateError('Réaction non enregistrée');
    }
  }
}
