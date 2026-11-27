import 'dart:math' as math;
import '../../../core/domain/entry.dart';
import '../../../core/config/wedding_config.dart';
import '../../home/domain/paris_calendar.dart';

class SkyStar {
  final Entry entry;
  final double x, y;
  const SkyStar(this.entry, this.x, this.y);
}

/// Stable coordinates depend only on identity, never on list order or title.
/// The central clearing is reserved for the wedding constellation.
abstract final class LoveSky {
  static const extent = 1200.0;
  static int _hash(String text) {
    var value = 2166136261;
    for (final unit in text.codeUnits) {
      value = ((value ^ unit) * 16777619) & 0xffffffff;
    }
    // Avalanche the bits so neighbouring IDs (m1, m2, …) do not cluster.
    value = ((value ^ (value >>> 16)) * 0x85ebca6b) & 0xffffffff;
    value = ((value ^ (value >>> 13)) * 0xc2b2ae35) & 0xffffffff;
    return (value ^ (value >>> 16)) & 0xffffffff;
  }

  static List<SkyStar> stars(Iterable<Entry> entries) {
    final seen = <String>{};
    return [
      for (final entry in entries)
        if ((entry.kind == EntryKind.memory ||
                entry.kind == EntryKind.letter) &&
            seen.add('${entry.kind.name}:${entry.id}'))
          position(entry),
    ]..sort((a, b) => a.entry.id.compareTo(b.entry.id));
  }

  static SkyStar position(Entry entry) {
    final key = '${entry.kind.name}:${entry.id}';
    final angle = _hash(key) / 0xffffffff * math.pi * 2;
    final radius = 160 + math.sqrt(_hash('$key:radius') / 0xffffffff) * 370;
    return SkyStar(
      entry,
      extent / 2 + math.cos(angle) * radius,
      extent / 2 + math.sin(angle) * radius,
    );
  }

  static bool weddingVisible(DateTime now) =>
      !parisCalendarDay(now).isBefore(parisCalendarDay(WeddingConfig.wedding));
  static bool canReadLetter(
    Entry entry, {
    required bool cloud,
    required String? userId,
    required DateTime now,
    bool demo = false,
  }) {
    if (entry.kind != EntryKind.letter) return false;
    if (cloud) {
      return entry.flag('available') ||
          (userId != null && entry.authorId == userId);
    }
    final opens = entry.date('openAt');
    return demo || (opens != null && !now.isBefore(opens));
  }
}
