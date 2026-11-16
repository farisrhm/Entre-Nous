/// Calendar days in France, independent of the phone's time zone and DST.
/// The configured wedding takes place in January (UTC+1).
DateTime parisCalendarDay(DateTime date) {
  final utc = date.toUtc();
  DateTime lastSunday(int month) {
    final end = DateTime.utc(utc.year, month + 1, 0, 1);
    return end.subtract(Duration(days: end.weekday % 7));
  }

  final summer = !utc.isBefore(lastSunday(3)) && utc.isBefore(lastSunday(10));
  final local = utc.add(Duration(hours: summer ? 2 : 1));
  return DateTime.utc(local.year, local.month, local.day);
}
