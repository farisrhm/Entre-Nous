import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// One 360 × 350 garden. Paths, people and the hourglass share its perspective.
class JourneyGardenPainter extends CustomPainter {
  final double progress;
  final bool together, foreground;
  final int daysTogether;
  const JourneyGardenPainter({
    required this.progress,
    required this.together,
    required this.foreground,
    required this.daysTogether,
  });
  static final left = Path()
    ..moveTo(35, 302)
    ..cubicTo(72, 326, 103, 290, 162, 278);
  static final right = Path()
    ..moveTo(325, 302)
    ..cubicTo(288, 326, 257, 290, 198, 278);
  static final leftMetric = left.computeMetrics().first;
  static final rightMetric = right.computeMetrics().first;
  Paint _fill(Color color) => Paint()..color = color;
  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 350);
    if (foreground) {
      _people(canvas);
      _foreground(canvas);
    } else {
      _setting(canvas);
      _paths(canvas);
    }
    canvas.restore();
  }

  void _setting(Canvas c) {
    const light = Rect.fromLTWH(20, 0, 320, 330);
    c.drawOval(
      light,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF5E5BF).withValues(alpha: .62),
            Palette.ivory.withValues(alpha: 0),
          ],
        ).createShader(light),
    );
    Path arch(double inset) => Path()
      ..moveTo(61 + inset, 281)
      ..lineTo(61 + inset, 131)
      ..cubicTo(61 + inset, 70 + inset, 105, 24 + inset, 180, 24 + inset)
      ..cubicTo(255, 24 + inset, 299 - inset, 70 + inset, 299 - inset, 131)
      ..lineTo(299 - inset, 281);
    final niche = Path.from(arch(0))..close();
    c.drawPath(
      niche,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x72FFFBF0), Color(0x10C5B88D)],
        ).createShader(const Rect.fromLTWH(60, 24, 240, 270)),
    );
    c.drawPath(arch(0), _stroke(Palette.gold.withValues(alpha: .48), .85));
    c.drawPath(arch(7), _stroke(Palette.gold.withValues(alpha: .20), .65));
    // Mist-soft hills keep the scene grounded without competing with the glass.
    final hill = Path()
      ..moveTo(32, 238)
      ..cubicTo(82, 201, 105, 227, 145, 217)
      ..cubicTo(200, 193, 252, 213, 328, 235)
      ..lineTo(328, 287)
      ..lineTo(32, 287)
      ..close();
    c.drawPath(
      hill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Palette.sage.withValues(alpha: .13),
            Palette.ivory.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(30, 190, 300, 100)),
    );
    c.drawOval(
      const Rect.fromLTWH(45, 241, 270, 72),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.sage.withValues(alpha: .12),
            Palette.sage.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(45, 241, 270, 72)),
    );
    // A low limestone plinth: the timepiece belongs to the garden, not a second card.
    c.drawOval(
      const Rect.fromLTWH(111, 219, 138, 24),
      _fill(Palette.brown.withValues(alpha: .055)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(117, 219, 126, 12),
        const Radius.circular(6),
      ),
      _fill(const Color(0xFFE7DCC4)),
    );
    c.drawOval(
      const Rect.fromLTWH(117, 210, 126, 20),
      _fill(const Color(0xFFF6EEDD)),
    );
    c.drawArc(
      const Rect.fromLTWH(117, 210, 126, 20),
      0,
      math.pi,
      false,
      _stroke(Palette.gold.withValues(alpha: .45), .8),
    );
    for (final plant in const [
      (Offset(53, 270), 68.0, 12.0),
      (Offset(310, 277), 83.0, -17.0),
      (Offset(286, 118), 55.0, -22.0),
    ]) {
      _sprig(c, plant.$1, plant.$2, plant.$3, opacity: .32);
    }
    _flower(c, const Offset(269, 78), 5.8);
    _flower(c, const Offset(286, 96), 3.5);
    for (final point in const [
      Offset(111, 90),
      Offset(246, 154),
      Offset(94, 176),
      Offset(230, 65),
      Offset(209, 23),
    ]) {
      c.drawCircle(point, 1.1, _fill(Palette.gold.withValues(alpha: .55)));
    }
    _spark(c, const Offset(180, 12), 5, .7);
    _spark(c, const Offset(258, 185), 3, .35);
  }

  void _paths(Canvas c) {
    for (final path in [left, right]) {
      c.drawPath(path, _stroke(Palette.gold.withValues(alpha: .14), 15));
      c.drawPath(path, _stroke(const Color(0xFFF8F2E5), 12));
      final metric = path.computeMetrics().first;
      c.drawPath(
        metric.extractPath(0, metric.length * progress),
        _stroke(Palette.gold.withValues(alpha: .35), .85),
      );
      for (double d = 12; d < metric.length; d += 20) {
        final tangent = metric.getTangentForOffset(d)!;
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
        c.drawLine(
          tangent.position - normal * 3,
          tangent.position + normal * 3,
          _stroke(Palette.gold.withValues(alpha: .16), .65),
        );
      }
    }
    c.drawPath(
      Path()
        ..moveTo(180, 278)
        ..quadraticBezierTo(171, 250, 180, 235),
      _stroke(Palette.gold.withValues(alpha: .18), .9),
    );
  }

  void _people(Canvas c) {
    if (together) {
      final onward = (daysTogether / 365).clamp(0.0, .8) * 20;
      final center = Offset(180, 278 - onward);
      _drawCharacter(
        c,
        center.translate(-13, 0),
        princess: true,
        facingRight: true,
      );
      _drawCharacter(
        c,
        center.translate(13, 0),
        princess: false,
        facingRight: false,
      );
      c.drawPath(
        Path()
          ..moveTo(center.dx - 6, center.dy - 24)
          ..quadraticBezierTo(
            center.dx,
            center.dy - 19,
            center.dx + 6,
            center.dy - 24,
          ),
        _stroke(Palette.gold, 1.3),
      );
    } else {
      _drawCharacter(
        c,
        leftMetric.getTangentForOffset(leftMetric.length * progress)!.position,
        princess: true,
        facingRight: true,
      );
      _drawCharacter(
        c,
        rightMetric
            .getTangentForOffset(rightMetric.length * progress)!
            .position,
        princess: false,
        facingRight: false,
      );
    }
  }

  void _foreground(Canvas c) {
    _sprig(c, const Offset(51, 327), 44, 12, opacity: .72);
    _sprig(c, const Offset(33, 314), 28, -4, opacity: .45);
    _sprig(c, const Offset(305, 320), 38, -12, opacity: .65);
    _sprig(c, const Offset(322, 309), 23, 3, opacity: .4);
    _flower(c, const Offset(64, 289), 5.1);
    _flower(c, const Offset(47, 308), 3.2);
    _flower(c, const Offset(296, 289), 4.5);
    _flower(c, const Offset(312, 305), 2.8, gold: true);
    for (final point in const [
      Offset(83, 319),
      Offset(106, 306),
      Offset(262, 307),
      Offset(277, 323),
    ]) {
      _leaf(c, point, .8, 4, Palette.gold.withValues(alpha: .36));
    }
  }

  void _spark(Canvas c, Offset point, double radius, double opacity) {
    final r = radius;
    final star = Path()
      ..moveTo(point.dx, point.dy - r)
      ..quadraticBezierTo(
        point.dx + r * .12,
        point.dy - r * .12,
        point.dx + r,
        point.dy,
      )
      ..quadraticBezierTo(
        point.dx + r * .12,
        point.dy + r * .12,
        point.dx,
        point.dy + r,
      )
      ..quadraticBezierTo(
        point.dx - r * .12,
        point.dy + r * .12,
        point.dx - r,
        point.dy,
      )
      ..quadraticBezierTo(
        point.dx - r * .12,
        point.dy - r * .12,
        point.dx,
        point.dy - r,
      )
      ..close();
    c.drawPath(star, _fill(Palette.gold.withValues(alpha: opacity)));
  }

  void _leaf(
    Canvas canvas,
    Offset origin,
    double angle,
    double length,
    Color color,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    final shape = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        -length * .55,
        -length * .5,
        -length * .25,
        -length * .9,
        0,
        -length,
      )
      ..cubicTo(length * .5, -length * .65, length * .4, -length * .2, 0, 0);
    canvas.drawPath(shape, _fill(color));
    canvas.drawLine(
      Offset.zero,
      Offset(0, -length * .8),
      _stroke(Palette.ivory.withValues(alpha: .4), .45),
    );
    canvas.restore();
  }

  void _sprig(
    Canvas canvas,
    Offset base,
    double height,
    double lean, {
    double opacity = 1,
  }) {
    final top = base.translate(lean, -height);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx + lean * .2,
          base.dy - height * .6,
          top.dx,
          top.dy,
        ),
      _stroke(Palette.forest.withValues(alpha: opacity * .4), .7),
    );
    for (var i = 1; i < 5; i++) {
      final t = i / 5;
      final root = base.translate(lean * t * t, -height * t);
      _leaf(
        canvas,
        root,
        i.isEven ? -.85 : .85,
        height * .28,
        (i.isEven ? Palette.sage : Palette.forest).withValues(
          alpha: opacity * .65,
        ),
      );
    }
  }

  void _flower(
    Canvas canvas,
    Offset center,
    double radius, {
    bool gold = false,
  }) {
    final color = gold ? Palette.gold : Palette.ivory;
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5;
      canvas.drawOval(
        Rect.fromCenter(
          center:
              center + Offset(math.cos(angle), math.sin(angle)) * radius * .52,
          width: radius * 1.05,
          height: radius * 1.05,
        ),
        _fill(color),
      );
    }
    canvas.drawCircle(
      center,
      radius * .28,
      _fill(gold ? Palette.ivory : Palette.gold),
    );
  }

  void _drawCharacter(
    Canvas canvas,
    Offset feet, {
    required bool princess,
    required bool facingRight,
  }) {
    canvas.save();
    canvas.translate(feet.dx, feet.dy);
    canvas.drawOval(
      const Rect.fromLTWH(-11, -1, 22, 4),
      _fill(Palette.brown.withValues(alpha: .12)),
    );
    canvas.scale(facingRight ? 1 : -1, 1);
    final skin = princess ? const Color(0xFFC79873) : const Color(0xFF70442F);
    if (princess) {
      final hair = Path()
        ..moveTo(-6, -47)
        ..cubicTo(-17, -48, -13, -30, -16, -25)
        ..quadraticBezierTo(-6, -26, -2, -34)
        ..close();
      canvas.drawPath(hair, _fill(Palette.brown));
      final veil = Path()
        ..moveTo(-6, -48)
        ..cubicTo(-12, -41, -12, -20, -20, -7)
        ..quadraticBezierTo(-12, -5, -8, -11)
        ..lineTo(-1, -41)
        ..close();
      canvas.drawPath(veil, _fill(Palette.ivory.withValues(alpha: .78)));
      canvas.drawPath(veil, _stroke(Palette.gold.withValues(alpha: .4), .6));
      final dress = Path()
        ..moveTo(-6, -34)
        ..quadraticBezierTo(0, -31, 5, -33)
        ..lineTo(4, -25)
        ..cubicTo(5, -18, 8, -8, 12, 0)
        ..quadraticBezierTo(0, 3, -13, 0)
        ..cubicTo(-10, -10, -6, -19, -6, -26)
        ..close();
      canvas.drawPath(
        dress,
        Paint()
          ..shader = const LinearGradient(
            colors: [Palette.cream, Palette.ivory, Palette.cream],
          ).createShader(const Rect.fromLTWH(-13, -34, 25, 36)),
      );
      canvas.drawPath(dress, _stroke(Palette.gold.withValues(alpha: .65), .65));
      for (final x in [-6.0, 0.0, 6.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x * .3, -23)
            ..quadraticBezierTo(x * .6, -10, x, -2),
          _stroke(Palette.gold.withValues(alpha: .3), .55),
        );
      }
      canvas.drawLine(
        const Offset(-5, -25),
        const Offset(4, -25),
        _stroke(Palette.gold, 1),
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(-7, -33)
          ..quadraticBezierTo(-12, -24, -10, -10)
          ..lineTo(2, -15)
          ..lineTo(5, -31)
          ..close(),
        _fill(Palette.sage),
      );
      for (final x in [-4.0, 3.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 2, -18)
            ..lineTo(x + 2, -18)
            ..lineTo(x + 2, -2)
            ..lineTo(x - 2, -2)
            ..close(),
          _fill(Palette.forest),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 2, -3, 7, 3),
            const Radius.circular(1),
          ),
          _fill(Palette.brown),
        );
      }
      final coat = Path()
        ..moveTo(-7, -33)
        ..quadraticBezierTo(0, -36, 7, -31)
        ..lineTo(6, -16)
        ..quadraticBezierTo(0, -13, -7, -16)
        ..close();
      canvas.drawPath(coat, _fill(Palette.forest));
      canvas.drawPath(
        Path()
          ..moveTo(-2, -33)
          ..lineTo(2, -24)
          ..lineTo(4, -33),
        _stroke(Palette.ivory, 1),
      );
      canvas.drawLine(
        const Offset(-6, -17),
        const Offset(5, -17),
        _stroke(Palette.gold, .8),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(2, -24 + i * 3.0), .65, _fill(Palette.gold));
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-1, -38, 4, 6),
        const Radius.circular(1),
      ),
      _fill(skin),
    );
    final face = Path()
      ..moveTo(-5, -47)
      ..quadraticBezierTo(3, -52, 7, -45)
      ..lineTo(7, -42)
      ..lineTo(9, -40)
      ..lineTo(6, -39)
      ..quadraticBezierTo(5, -34, 0, -36)
      ..quadraticBezierTo(-7, -38, -5, -47)
      ..close();
    canvas.drawPath(face, _fill(skin));
    canvas.drawPath(
      Path()
        ..moveTo(-5, -38)
        ..cubicTo(-10, -42, -7, -51, 0, -51)
        ..quadraticBezierTo(7, -51, 7, -45)
        ..quadraticBezierTo(2, -47, -3, -43)
        ..close(),
      _fill(Palette.brown),
    );
    canvas.drawCircle(const Offset(5, -42), .7, _fill(Palette.brown));
    if (princess) {
      canvas.drawPath(
        Path()
          ..moveTo(-6, -49)
          ..lineTo(-5, -53)
          ..lineTo(-2, -51)
          ..lineTo(0, -55)
          ..lineTo(2, -51)
          ..lineTo(5, -53)
          ..lineTo(5, -49),
        _stroke(Palette.gold, 1),
      );
      canvas.drawCircle(const Offset(-1, -39), 1, _fill(Palette.gold));
    } else {
      // Short, textured curls and a softly outlined beard for Faris.
      for (var i = 0; i < 7; i++) {
        canvas.drawCircle(
          Offset(-5 + i * 1.8, -49 - math.sin(i * .5)),
          2.1,
          _fill(const Color(0xFF261D19)),
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(-2, -39)
          ..quadraticBezierTo(3, -35, 6, -39),
        _stroke(const Color(0xFF39251D), 1.4),
      );
    }
    final arm = Path()
      ..moveTo(5, -31)
      ..quadraticBezierTo(8, -26, 8, -23)
      ..lineTo(12, -22);
    canvas.drawPath(arm, _stroke(princess ? Palette.cream : Palette.forest, 3));
    canvas.drawCircle(const Offset(12, -22), 1.5, _fill(skin));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant JourneyGardenPainter old) =>
      old.progress != progress ||
      old.together != together ||
      old.foreground != foreground ||
      old.daysTogether != daysTogether;
}
