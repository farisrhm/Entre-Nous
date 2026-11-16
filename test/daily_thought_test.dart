import 'package:flutter_test/flutter_test.dart';
import 'package:jusqua_nous/features/home/domain/daily_thought.dart';

void main() {
  test('daily collection is unique, attributed, and cycles after 31 days', () {
    expect(dailyThoughts.length, 31);
    expect(dailyThoughts.map((t) => t.text).toSet().length, 31);
    final start = DateTime.utc(2026, 11, 16, 12);
    for (var i = 0; i < 31; i++) {
      final thought = dailyThoughtAt(start.add(Duration(days: i)));
      expect(thought, same(dailyThoughts[i]));
      expect(thought.reflection, isNotEmpty);
      if (thought.author != 'Jusqu’à Nous') {
        expect(Uri.parse(thought.source!).host, 'fr.wikisource.org');
      }
    }
    expect(
      dailyThoughtAt(start.add(const Duration(days: 31))),
      same(dailyThoughts.first),
    );
  });
  test(
    'changes at Paris midnight in winter and summer, not at device midnight',
    () {
      for (final boundary in [
        DateTime.utc(2026, 11, 16, 23),
        DateTime.utc(2027, 6, 16, 22),
      ]) {
        final before = dailyThoughtAt(
          boundary.subtract(const Duration(seconds: 1)),
        );
        final after = dailyThoughtAt(boundary);
        expect(before, isNot(same(after)));
        expect(
          dailyThoughtAt(boundary.add(const Duration(hours: 15))),
          same(after),
        );
        expect(dailyThoughtAt(boundary.toLocal()), same(after));
      }
      expect(() => dailyThoughtAt(DateTime.utc(2020)), returnsNormally);
    },
  );
}
