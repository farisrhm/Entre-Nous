import '../../../core/config/wedding_config.dart';

import 'paris_calendar.dart';

class JourneyProgress {
  final int daysRemaining;
  final double progress;
  JourneyProgress._(this.daysRemaining, this.progress);

  factory JourneyProgress.at(DateTime now) {
    final wedding = parisCalendarDay(WeddingConfig.wedding);
    final start = parisCalendarDay(WeddingConfig.journeyStart);
    final today = parisCalendarDay(now);
    final remaining = wedding.difference(today).inDays;
    final total = wedding.difference(start).inDays;
    return JourneyProgress._(
      remaining,
      (1 - remaining / total).clamp(0.0, 1.0),
    );
  }

  bool get together => daysRemaining <= 0;
  String get caption => daysRemaining > 0
      ? 'Encore $daysRemaining ${daysRemaining == 1 ? 'jour' : 'jours'} avant de se dire oui.'
      : daysRemaining == 0
      ? 'Aujourd’hui, nos chemins se rejoignent.'
      : '${-daysRemaining} ${daysRemaining == -1 ? 'jour' : 'jours'} côte à côte depuis notre oui.';
}
