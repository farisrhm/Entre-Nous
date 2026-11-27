import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Calendar progress determines the sand level; animation only moves the grains.
class JourneyHourglass extends StatefulWidget {
  final double progress;
  final bool reduceMotion;
  const JourneyHourglass({
    super.key,
    required this.progress,
    required this.reduceMotion,
  });
  @override
  State<JourneyHourglass> createState() => _JourneyHourglassState();
}

class _JourneyHourglassState extends State<JourneyHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  void _sync() {
    if (widget.reduceMotion || widget.progress <= 0 || widget.progress >= 1) {
      _flow.stop();
    } else {
      _flow.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant JourneyHourglass oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Sablier de notre histoire. ${(widget.progress * 100).round()} pour cent du chemin parcouru.',
    image: true,
    child: RepaintBoundary(
      child: SizedBox(
        width: 210,
        height: 280,
        child: CustomPaint(painter: _HourglassPainter(widget.progress, _flow)),
      ),
    ),
  );
}

class _HourglassPainter extends CustomPainter {
  final double progress;
  final Animation<double> flow;
  _HourglassPainter(this.progress, this.flow) : super(repaint: flow);
  static const gold = Color(0xFFB58A43);
  Paint fill(Color c) => Paint()..color = c;
  Paint line(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 210, size.height / 280);
    final glass = Path()
      ..moveTo(53, 44)
      ..lineTo(157, 44)
      ..cubicTo(169, 90, 133, 117, 109, 138)
      ..quadraticBezierTo(105, 141, 109, 145)
      ..cubicTo(139, 169, 166, 198, 157, 235)
      ..lineTo(53, 235)
      ..cubicTo(44, 198, 71, 169, 101, 145)
      ..quadraticBezierTo(105, 141, 101, 138)
      ..cubicTo(77, 117, 41, 90, 53, 44)
      ..close();
    c.drawOval(
      const Rect.fromLTWH(31, 250, 148, 13),
      fill(const Color(0x148C6941)),
    );
    c.drawPath(glass, fill(const Color(0x45FFFFFF)));
    c.save();
    c.clipPath(glass);
    final p = progress.clamp(0.0, 1.0);
    final sand = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4D79C), Color(0xFFD9AE63), Color(0xFFBD8D43)],
      ).createShader(const Rect.fromLTWH(50, 44, 110, 192));
    // A narrowing upper chamber: square-root height approximates volume.
    final top = 141 - 97 * math.sqrt(1 - p);
    if (p < 1) c.drawRect(Rect.fromLTRB(40, top, 170, 141), sand);
    final bottom = 235 - 72 * math.sqrt(p);
    if (p > 0) {
      c.drawPath(
        Path()
          ..moveTo(40, 235)
          ..lineTo(40, bottom + 17)
          ..quadraticBezierTo(80, bottom + 15, 105, bottom)
          ..quadraticBezierTo(130, bottom + 15, 170, bottom + 17)
          ..lineTo(170, 235)
          ..close(),
        sand,
      );
    }
    if (p > 0 && p < 1) {
      c.drawLine(
        const Offset(105, 141),
        Offset(105, bottom),
        line(const Color(0x80DEB66F), 1),
      );
      for (var i = 0; i < 23; i++) {
        final y = 143 + ((i / 23 + flow.value) % 1) * (bottom - 143);
        c.drawCircle(
          Offset(105 + math.sin(i * 13.0) * 1.4, y),
          i.isEven ? 0.8 : 0.5,
          fill(const Color(0xFFFFDF9F)),
        );
      }
    }
    c.restore();
    c.drawPath(glass, line(const Color(0x99CDBB94), 1));
    for (final x in [61.0, 149.0]) {
      c.drawPath(
        Path()
          ..moveTo(x, 54)
          ..quadraticBezierTo(
            x + (x < 105 ? -8 : 8),
            85,
            x + (x < 105 ? 17 : -17),
            108,
          ),
        line(const Color(0xBFFFFFFF), 2),
      );
    }
    final metal = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF8E652D),
          Color(0xFFE8CF8D),
          Color(0xFFB28A43),
          Color(0xFFF4DDA1),
          Color(0xFF967032),
        ],
        stops: [0, .25, .5, .72, 1],
      ).createShader(const Rect.fromLTWH(33, 0, 144, 280));
    for (final x in [39.0, 164.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 40, 7, 201),
          const Radius.circular(3),
        ),
        metal,
      );
      for (final y in [49.0, 139.0, 232.0]) {
        c.drawOval(
          Rect.fromCenter(center: Offset(x + 3.5, y), width: 14, height: 9),
          metal,
        );
      }
    }
    for (final y in [32.0, 237.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(29, y, 152, 13),
          const Radius.circular(6),
        ),
        metal,
      );
      c.drawLine(
        Offset(38, y + 3),
        Offset(172, y + 3),
        line(const Color(0xAAFFF0C6), 1),
      );
    }
    c.drawOval(const Rect.fromLTWH(91, 24, 28, 8), metal);
    c.drawPath(
      Path()
        ..moveTo(105, 9)
        ..quadraticBezierTo(91, 23, 105, 27)
        ..quadraticBezierTo(119, 23, 105, 9),
      metal,
    );
    // Olive silk ribbon and ivory orange blossoms echo the supplied reference.
    c.drawPath(
      Path()
        ..moveTo(40, 54)
        ..cubicTo(13, 86, 44, 116, 20, 157)
        ..lineTo(36, 148)
        ..cubicTo(52, 113, 27, 88, 47, 55)
        ..close(),
      fill(const Color(0xFF626941)),
    );
    for (final origin in [const Offset(156, 35), const Offset(47, 232)]) {
      for (var i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5;
        final pos = origin + Offset(math.cos(angle) * 9, math.sin(angle) * 9);
        c.drawOval(
          Rect.fromCenter(center: pos, width: 12, height: 17),
          fill(const Color(0xFFF9F2DE)),
        );
      }
      c.drawCircle(origin, 3, fill(gold));
      for (final dx in [-20.0, 20.0]) {
        c.save();
        c.translate(origin.dx + dx, origin.dy + 7);
        c.rotate(dx < 0 ? -.7 : .7);
        c.drawOval(
          const Rect.fromLTWH(-4, -12, 8, 24),
          fill(const Color(0xFF777D54)),
        );
        c.restore();
      }
    }
    final text = TextPainter(
      text: const TextSpan(
        text: 'A & F',
        style: TextStyle(
          fontFamily: 'Cormorant Garamond',
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: Color(0xFF76532A),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(c, Offset(105 - text.width / 2, 252));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter old) =>
      old.progress != progress;
}
