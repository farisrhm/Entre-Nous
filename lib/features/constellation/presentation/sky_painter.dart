import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/domain/entry.dart';
import '../domain/love_sky.dart';

const skyNight = Color(0xFF091E1D);
const skyLetter = Color(0xFFCEDFD9);

class SkyPainter extends CustomPainter {
  final List<SkyStar> stars;
  final bool wedding;
  final Animation<double>? shimmer;
  SkyPainter({required this.stars, required this.wedding, this.shimmer})
    : super(repaint: shimmer);
  static final dust = List.generate(160, (i) {
    final r = math.Random(i * 47 + 9);
    return (
      Offset(r.nextDouble() * 1200, r.nextDouble() * 1200),
      r.nextDouble() * 1.2 + .5,
    );
  });
  static final heart = List.generate(20, (i) {
    final t = i / 20 * math.pi * 2;
    return Offset(
      600 + math.pow(math.sin(t), 3) * 94,
      590 -
          (13 * math.cos(t) -
                  5 * math.cos(2 * t) -
                  2 * math.cos(3 * t) -
                  math.cos(4 * t)) *
              6,
    );
  });
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1200, size.height / 1200);
    final pulse = .78 + .22 * math.sin((shimmer?.value ?? .25) * math.pi * 2);
    for (final (p, r) in dust) {
      canvas.drawCircle(
        p,
        r,
        Paint()..color = Palette.ivory.withValues(alpha: .16 + r * .12),
      );
    }
    // A sparse, deterministic connection to the nearest preceding star.
    for (var i = 1; i < stars.length; i++) {
      final p = Offset(stars[i].x, stars[i].y);
      Offset? nearest;
      var distance = 210.0;
      for (var j = 0; j < i; j++) {
        final q = Offset(stars[j].x, stars[j].y);
        final d = (p - q).distance;
        if (d < distance) {
          distance = d;
          nearest = q;
        }
      }
      if (nearest != null) {
        canvas.drawLine(
          p,
          nearest,
          Paint()
            ..color = Palette.gold.withValues(alpha: .16)
            ..strokeWidth = 1,
        );
      }
    }
    for (final star in stars) {
      _star(
        canvas,
        Offset(star.x, star.y),
        star.entry.kind == EntryKind.memory ? Palette.gold : skyLetter,
        pulse,
      );
    }
    if (wedding) {
      final path = Path()..addPolygon(heart, true);
      canvas.drawPath(
        path,
        Paint()
          ..color = Palette.gold.withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      for (final point in heart) {
        _star(canvas, point, Palette.gold, pulse, small: true);
      }
    }
    canvas.restore();
  }

  void _star(
    Canvas canvas,
    Offset point,
    Color color,
    double pulse, {
    bool small = false,
  }) {
    final radius = small ? 12.0 : 23.0;
    canvas.drawCircle(
      point,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .35 * pulse),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: point, radius: radius)),
    );
    canvas.drawCircle(
      point,
      small ? 2 : 3.5,
      Paint()..color = Color.lerp(color, Colors.white, .45)!,
    );
    final ray = small ? 5.0 : 9.0;
    final paint = Paint()
      ..color = color.withValues(alpha: .7)
      ..strokeWidth = .8;
    canvas.drawLine(point - Offset(ray, 0), point + Offset(ray, 0), paint);
    canvas.drawLine(point - Offset(0, ray), point + Offset(0, ray), paint);
  }

  @override
  bool shouldRepaint(covariant SkyPainter old) =>
      old.stars != stars || old.wedding != wedding || old.shimmer != shimmer;
}
