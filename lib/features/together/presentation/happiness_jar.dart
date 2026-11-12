import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// A small vector jar; its paper slips are decoration, not a progress score.
class HappinessJar extends StatelessWidget {
  final int count;
  const HappinessJar({super.key, required this.count});
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '$count petit${count == 1 ? '' : 's'} bonheur${count == 1 ? '' : 's'} conservé${count == 1 ? '' : 's'}',
    child: SizedBox(
      height: 155,
      child: CustomPaint(
        painter: _JarPainter(count),
        size: const Size(180, 155),
      ),
    ),
  );
}

class _JarPainter extends CustomPainter {
  final int count;
  _JarPainter(this.count);
  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final glass = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - 57, 28, 114, 115),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      glass,
      Paint()..color = Palette.ivory.withValues(alpha: .7),
    );
    canvas.drawRRect(
      glass,
      Paint()
        ..color = Palette.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < count.clamp(0, 7); i++) {
      canvas.save();
      canvas.translate(x - 25 + (i % 3) * 24, 118 - (i ~/ 3) * 27);
      canvas.rotate((i.isEven ? 1 : -1) * .18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-17, -10, 34, 20),
          const Radius.circular(3),
        ),
        Paint()..color = i.isEven ? Palette.sage : Palette.gold,
      );
      canvas.drawLine(
        const Offset(-9, -2),
        const Offset(9, -2),
        Paint()
          ..color = Palette.ivory
          ..strokeWidth = 1.5,
      );
      canvas.restore();
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 50, 16, 100, 17),
        const Radius.circular(5),
      ),
      Paint()..color = Palette.forest,
    );
    canvas.drawLine(
      Offset(x - 43, 24),
      Offset(x + 43, 24),
      Paint()
        ..color = Palette.gold
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _JarPainter old) => old.count != count;
}
