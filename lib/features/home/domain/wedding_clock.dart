import '../../../core/config/wedding_config.dart';

enum WeddingPhase { before, week, day, after }

WeddingPhase phaseAt(DateTime now) {
  if (!now.isBefore(WeddingConfig.dayEnd)) return WeddingPhase.after;
  if (!now.isBefore(WeddingConfig.wedding)) return WeddingPhase.day;
  if (WeddingConfig.wedding.difference(now) <= const Duration(days: 7)) {
    return WeddingPhase.week;
  }
  return WeddingPhase.before;
}

Duration countdownAt(DateTime now, WeddingPhase phase) {
  if (phase == WeddingPhase.day) return Duration.zero;
  final delta = phase == WeddingPhase.after
      ? now.difference(WeddingConfig.wedding)
      : WeddingConfig.wedding.difference(now);
  return delta.isNegative ? Duration.zero : delta;
}

int unlockedSurprises(DateTime now) => now.isBefore(WeddingConfig.calendarStart)
    ? 0
    : (now.difference(WeddingConfig.calendarStart).inDays + 1).clamp(0, 30);
