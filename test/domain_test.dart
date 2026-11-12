import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jusqua_nous/core/config/wedding_config.dart';
import 'package:jusqua_nous/core/data/local_wedding_repository.dart';
import 'package:jusqua_nous/core/domain/entry.dart';
import 'package:jusqua_nous/features/home/domain/wedding_clock.dart';

void main() {
  test('phase and calendar boundaries use absolute instants', () {
    expect(
      phaseAt(
        WeddingConfig.wedding.subtract(const Duration(days: 7, seconds: 1)),
      ),
      WeddingPhase.before,
    );
    expect(
      phaseAt(WeddingConfig.wedding.subtract(const Duration(days: 7))),
      WeddingPhase.week,
    );
    expect(phaseAt(WeddingConfig.wedding), WeddingPhase.day);
    expect(phaseAt(WeddingConfig.dayEnd), WeddingPhase.after);
    expect(
      unlockedSurprises(
        WeddingConfig.calendarStart.subtract(const Duration(seconds: 1)),
      ),
      0,
    );
    expect(unlockedSurprises(WeddingConfig.calendarStart), 1);
    expect(
      unlockedSurprises(
        WeddingConfig.calendarStart.add(const Duration(days: 40)),
      ),
      30,
    );
    expect(
      countdownAt(
        WeddingConfig.wedding.subtract(const Duration(seconds: 1)),
        WeddingPhase.after,
      ),
      Duration.zero,
    );
  });
  test(
    'entries survive repository recreation and deletion does not restore demos',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = LocalWeddingRepository(prefs);
      final initial = await repository.load();
      await repository.save(
        const Entry(
          id: 'test',
          kind: EntryKind.dream,
          fields: {'title': 'Notre rêve', 'done': false},
        ),
      );
      final recreated = LocalWeddingRepository(prefs);
      expect((await recreated.load()).length, initial.length + 1);
      await recreated.save(
        const Entry(
          id: 'test',
          kind: EntryKind.dream,
          fields: {'title': 'Notre rêve', 'done': true},
        ),
      );
      expect(
        (await recreated.load())
            .where((e) => e.id == 'test')
            .single
            .flag('done'),
        true,
      );
      for (final e in await recreated.load()) {
        await recreated.delete(e);
      }
      expect(await LocalWeddingRepository(prefs).load(), isEmpty);
    },
  );
}
