import 'package:flutter_test/flutter_test.dart';
import 'package:jusqua_nous/core/notifications/push_service.dart';

void main() {
  test(
    'push navigation accepts only supported content ids, never arbitrary links',
    () {
      final target = PushTarget.parse({
        'recipientId': 'alyssa',
        'notificationId': 'event',
        'kind': 'dua',
        'entryId': 'dua-1',
      });
      expect(target!.path, '/universe/dua');
      expect(target.recipientId, 'alyssa');
      expect(
        PushTarget.parse({
          'recipientId': 'alyssa',
          'notificationId': 'event',
          'kind': 'memory',
          'entryId': '../../settings',
        }),
        isNull,
      );
      expect(
        PushTarget.parse({
          'recipientId': 'alyssa',
          'notificationId': 'event',
          'kind': 'https://example.com',
          'entryId': '1',
        }),
        isNull,
      );
      expect(PushTarget.parse({}), isNull);
    },
  );
}
