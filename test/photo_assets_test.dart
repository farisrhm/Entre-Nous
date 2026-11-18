import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all home and memory photos are genuine JPEGs decodable by Flutter',
    () async {
      for (final group in ['home', 'bottom']) {
        for (var index = 1; index <= 10; index++) {
          final path = 'assets/images/${group}_$index.jpg';
          final bytes = await File(path).readAsBytes();
          expect(bytes.take(3), [
            0xff,
            0xd8,
            0xff,
          ], reason: '$path must not be a renamed HEIC');
          final ui.Codec codec;
        try {
          codec = await ui.instantiateImageCodec(bytes, targetWidth: 420);
        } catch (error) {
          fail('$path: $error');
        }
          try {
            final frame = await codec.getNextFrame();
            expect(frame.image.width, greaterThan(0), reason: path);
            expect(frame.image.height, greaterThan(0), reason: path);
            frame.image.dispose();
          } finally {
            codec.dispose();
          }
        }
      }
    },
  );
}
