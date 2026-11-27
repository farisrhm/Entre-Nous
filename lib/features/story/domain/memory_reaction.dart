import 'package:flutter/widgets.dart' show StringCharacters;

class MemoryReaction {
  final String memoryId, userId, emoji;
  const MemoryReaction(this.memoryId, this.userId, this.emoji);
  factory MemoryReaction.fromJson(Map<String, dynamic> json) => MemoryReaction(
    (json['entry_key'] as String).substring('memory:'.length),
    json['user_id'] as String,
    json['emoji'] as String,
  );
}

abstract final class ReactionEmoji {
  static const suggestions = [
    '❤️',
    '🥰',
    '😍',
    '😂',
    '🥹',
    '😘',
    '🔥',
    '✨',
    '🤍',
    '🫶',
    '👍',
    '💕',
  ];
  static bool valid(String text) {
    if (text.isEmpty ||
        text != text.trim() ||
        text.characters.length != 1 ||
        text.runes.length > 32) {
      return false;
    }
    return text.runes.any(
      (r) =>
          (r >= 0x1f000 && r <= 0x1faff) ||
          (r >= 0x2300 && r <= 0x27ff) ||
          (r >= 0x2b00 && r <= 0x2bff) ||
          (r >= 0x2194 && r <= 0x21ff) ||
          [
            0xa9,
            0xae,
            0x203c,
            0x2049,
            0x2122,
            0x2139,
            0x20e3,
            0x3030,
            0x303d,
            0x3297,
            0x3299,
          ].contains(r),
    );
  }
}
