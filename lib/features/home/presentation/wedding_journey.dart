import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../domain/journey_progress.dart';
import 'journey_hourglass.dart';

class WeddingJourney extends StatelessWidget {
  final DateTime now;
  final String firstName, secondName;
  final bool reduceMotion;
  const WeddingJourney({
    super.key,
    required this.now,
    required this.firstName,
    required this.secondName,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final journey = JourneyProgress.at(now);
    final still = reduceMotion || MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: Palette.cream.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.gold.withValues(alpha: .4)),
      ),
      child: Column(
        children: [
          const Eyebrow('LE CHEMIN JUSQU’À NOUS'),
          const SizedBox(height: 12),
          Text(
            journey.together
                ? 'Maintenant, ensemble.'
                : 'Chaque jour, un peu plus près.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(journey.caption, textAlign: TextAlign.center),
          Semantics(
            label: '$firstName et $secondName. ${journey.caption}',
            image: true,
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                // One day's step on arrival, never replayed by the clock ticks.
                tween: Tween(
                  begin: math.max(0, journey.progress - .01),
                  end: journey.progress,
                ),
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 1600),
                curve: Curves.easeInOutCubic,
                builder: (context, progress, _) => SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _JourneyPainter(
                      progress,
                      journey.together,
                      firstName,
                      secondName,
                      -journey.daysRemaining,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            '$firstName  ·  $secondName',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          JourneyHourglass(progress: journey.progress, reduceMotion: still),
          const SizedBox(height: 12),
          Text(
            journey.together
                ? 'Notre éternité commence.'
                : 'Chaque grain nous rapproche.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '28 mars 2026 · 23 janvier 2027',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// All scenery uses a fixed, deterministic 320 × 210 illustration space.
/// Scaling the whole scene keeps figures, path widths and floral details in
/// proportion on small phones; wider cards retain an airy central composition.
class _JourneyPainter extends CustomPainter {
  final double progress;
  final bool together;
  final String first, second;
  final int daysTogether;
  _JourneyPainter(
    this.progress,
    this.together,
    this.first,
    this.second,
    this.daysTogether,
  );

  static final _left = Path()
    ..moveTo(25, 163)
    ..cubicTo(66, 190, 84, 164, 99, 149)
    ..cubicTo(115, 133, 130, 139, 147, 142);
  static final _right = Path()
    ..moveTo(295, 163)
    ..cubicTo(254, 190, 236, 164, 221, 149)
    ..cubicTo(205, 133, 190, 139, 173, 142);
  static final _onward = Path()
    ..moveTo(160, 142)
    ..cubicTo(135, 115, 190, 102, 160, 57);
  static final _leftMetric = _left.computeMetrics().first;
  static final _rightMetric = _right.computeMetrics().first;
  static final _onwardMetric = _onward.computeMetrics().first;

  Paint _fill(Color color) => Paint()..color = color;
  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 320, size.height / 210);
    if (scale <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Never enlarge the miniature just because the card is wider.
    final zoom = math.min(scale, 1.0);
    canvas.translate(
      (size.width - 320 * zoom) / 2,
      (size.height - 210 * zoom) / 2,
    );
    canvas.scale(zoom);
    _drawLandscape(canvas);
    _drawGarden(canvas, foreground: false);
    final sharedProgress = (daysTogether / 365).clamp(0.0, .8);
    _drawPath(
      canvas,
      _onward,
      _onwardMetric,
      together ? sharedProgress : 0,
      shared: true,
    );
    _drawPath(canvas, _left, _leftMetric, progress);
    _drawPath(canvas, _right, _rightMetric, progress);
    _drawArch(canvas);
    _drawGarden(canvas, foreground: true);
    if (together) {
      final position = _onwardMetric
          .getTangentForOffset(_onwardMetric.length * sharedProgress)!
          .position;
      _drawCharacter(
        canvas,
        position.translate(-13, 0),
        princess: true,
        facingRight: true,
      );
      _drawCharacter(
        canvas,
        position.translate(13, 0),
        princess: false,
        facingRight: false,
      );
      // Hands meet without shifting the feet away from the shared trail.
      canvas.drawPath(
        Path()
          ..moveTo(position.dx - 6, position.dy - 24)
          ..quadraticBezierTo(
            position.dx,
            position.dy - 19,
            position.dx + 6,
            position.dy - 24,
          ),
        _stroke(Palette.gold, 1.5),
      );
    } else {
      _drawCharacter(
        canvas,
        _leftMetric
            .getTangentForOffset(_leftMetric.length * progress)!
            .position,
        princess: true,
        facingRight: true,
      );
      _drawCharacter(
        canvas,
        _rightMetric
            .getTangentForOffset(_rightMetric.length * progress)!
            .position,
        princess: false,
        facingRight: false,
      );
    }
    canvas.restore();
  }

  void _drawLandscape(Canvas canvas) {
    final glow = const Rect.fromLTWH(60, 5, 200, 165);
    canvas.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.ivory.withValues(alpha: .95),
            Palette.ivory.withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    final far = Path()
      ..moveTo(5, 115)
      ..cubicTo(50, 61, 75, 85, 110, 94)
      ..cubicTo(160, 62, 204, 69, 243, 94)
      ..cubicTo(275, 76, 300, 93, 315, 113)
      ..lineTo(315, 155)
      ..lineTo(5, 155)
      ..close();
    canvas.drawPath(
      far,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Palette.sage.withValues(alpha: .17),
            Palette.sage.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(0, 65, 320, 95)),
    );
    final near = Path()
      ..moveTo(5, 139)
      ..cubicTo(50, 102, 89, 126, 123, 134)
      ..cubicTo(176, 115, 250, 104, 315, 144)
      ..lineTo(315, 179)
      ..quadraticBezierTo(165, 202, 5, 177)
      ..close();
    canvas.drawPath(
      near,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Palette.sage.withValues(alpha: .16),
            Palette.ivory.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(0, 100, 320, 100)),
    );
    // Fine horizon marks and a few warm specks; no random per-frame positions.
    for (final p in const [
      Offset(48, 63),
      Offset(89, 46),
      Offset(224, 42),
      Offset(270, 75),
      Offset(204, 28),
    ]) {
      canvas.drawCircle(p, 1.2, _fill(Palette.gold.withValues(alpha: .55)));
    }
    canvas.drawLine(
      const Offset(83, 46),
      const Offset(95, 46),
      _stroke(Palette.gold.withValues(alpha: .35), .6),
    );
    canvas.drawLine(
      const Offset(89, 40),
      const Offset(89, 52),
      _stroke(Palette.gold.withValues(alpha: .35), .6),
    );
  }

  void _drawPath(
    Canvas canvas,
    Path path,
    PathMetric metric,
    double amount, {
    bool shared = false,
  }) {
    final width = shared ? 32.0 : 15.0;
    canvas.drawPath(
      path,
      _stroke(Palette.brown.withValues(alpha: .07), width + 3),
    );
    canvas.drawPath(
      path,
      _stroke(Palette.gold.withValues(alpha: .26), width + 1),
    );
    canvas.drawPath(
      path,
      _stroke(Palette.ivory.withValues(alpha: .95), width - 1),
    );
    canvas.drawPath(
      path,
      _stroke(Palette.cream.withValues(alpha: .6), width - 5),
    );
    // Subtle stepping stones read as a garden path, not a progress bar.
    for (double distance = 9; distance < metric.length; distance += 12) {
      final tangent = metric.getTangentForOffset(distance)!;
      final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
      final position = tangent.position;
      canvas.drawLine(
        position - normal * (width * .22),
        position + normal * (width * .22),
        _stroke(Palette.gold.withValues(alpha: .24), .65),
      );
    }
    if (amount <= 0) return;
    final traveled = metric.extractPath(
      0.0,
      metric.length * amount.clamp(0.0, 1.0),
    );
    canvas.drawPath(
      traveled,
      _stroke(Palette.gold.withValues(alpha: .18), width - 2),
    );
    canvas.drawPath(traveled, _stroke(Palette.gold.withValues(alpha: .6), 1.8));
    canvas.drawPath(
      traveled,
      _stroke(Palette.ivory.withValues(alpha: .8), .55),
    );
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

  void _drawGarden(Canvas canvas, {required bool foreground}) {
    if (!foreground) {
      for (final bush in const [
        (Offset(35, 131), 20.0),
        (Offset(280, 130), 22.0),
        (Offset(78, 119), 12.0),
        (Offset(238, 121), 14.0),
      ]) {
        for (var i = 0; i < 3; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: bush.$1.translate((i - 1) * 9.0, i == 1 ? -5 : 0),
              width: bush.$2,
              height: bush.$2 * .7,
            ),
            _fill(Palette.sage.withValues(alpha: .2 + i * .04)),
          );
        }
      }
      for (final plant in const [
        (Offset(20, 141), 28.0, -5.0),
        (Offset(54, 133), 25.0, 6.0),
        (Offset(266, 134), 30.0, -7.0),
        (Offset(302, 145), 24.0, 5.0),
      ]) {
        _sprig(canvas, plant.$1, plant.$2, plant.$3, opacity: .65);
      }
      return;
    }
    for (final plant in const [
      (Offset(49, 194), 24.0, -7.0),
      (Offset(83, 190), 18.0, 5.0),
      (Offset(239, 188), 20.0, -5.0),
      (Offset(279, 195), 26.0, 7.0),
    ]) {
      _sprig(canvas, plant.$1, plant.$2, plant.$3);
      _flower(canvas, plant.$1.translate(plant.$3, -plant.$2), 3.2);
    }
    for (final flower in const [
      Offset(61, 186),
      Offset(92, 178),
      Offset(227, 176),
      Offset(262, 185),
      Offset(111, 155),
      Offset(209, 155),
    ]) {
      canvas.drawLine(
        flower,
        flower.translate(-1, 8),
        _stroke(Palette.sage, .6),
      );
      _flower(canvas, flower, 2.4, gold: true);
    }
    for (final p in const [
      Offset(28, 191),
      Offset(104, 193),
      Offset(125, 170),
      Offset(187, 181),
      Offset(215, 195),
      Offset(300, 187),
    ]) {
      _leaf(canvas, p, .8, 3.5, Palette.gold.withValues(alpha: .5));
    }
  }

  void _drawArch(Canvas canvas) {
    const halo = Rect.fromLTWH(96, 30, 128, 128);
    canvas.drawOval(
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.gold.withValues(alpha: together ? .24 : .1),
            Palette.ivory.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );
    canvas.drawOval(
      const Rect.fromLTWH(119, 139, 82, 9),
      _fill(Palette.brown.withValues(alpha: .06)),
    );
    Path arch(double inset) => Path()
      ..moveTo(121 + inset, 144)
      ..lineTo(121 + inset, 91)
      ..cubicTo(
        121 + inset,
        40 + inset,
        199 - inset,
        40 + inset,
        199 - inset,
        91,
      )
      ..lineTo(199 - inset, 144);
    canvas.drawPath(arch(0), _stroke(Palette.brown.withValues(alpha: .5), 2.5));
    canvas.drawPath(arch(0), _stroke(Palette.gold, 1.3));
    canvas.drawPath(arch(5), _stroke(Palette.gold.withValues(alpha: .55), .7));
    // Light voile, intentionally clear through the middle of the arch.
    for (final side in [-1.0, 1.0]) {
      final x = 160 + side * 37;
      final drape = Path()
        ..moveTo(x, 82)
        ..cubicTo(x - side * 8, 107, x + side * 4, 126, x + side * 5, 143)
        ..lineTo(x - side * 4, 143)
        ..cubicTo(x - side * 2, 117, x - side * 11, 102, x - side * 3, 81)
        ..close();
      canvas.drawPath(drape, _fill(Palette.ivory.withValues(alpha: .8)));
      canvas.drawLine(
        Offset(x - side * 3, 111),
        Offset(x + side * 2, 113),
        _stroke(Palette.gold, 1),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, 144), width: 13, height: 3),
          const Radius.circular(1),
        ),
        _fill(Palette.gold.withValues(alpha: .65)),
      );
    }
    for (final plant in const [
      (Offset(123, 112), 32.0, 0.0),
      (Offset(196, 106), 32.0, 0.0),
    ]) {
      _sprig(canvas, plant.$1, plant.$2, plant.$3);
    }
    final top = arch(0).computeMetrics().first;
    for (var i = 0; i < 15; i++) {
      final tangent = top.getTangentForOffset(49 + i * 6.0)!;
      _leaf(
        canvas,
        tangent.position,
        i.isEven ? -.7 : .9,
        8,
        (i.isEven ? Palette.sage : Palette.forest).withValues(alpha: .8),
      );
      if (i % 3 == 0) _flower(canvas, tangent.position.translate(0, -1), 4);
    }
    _flower(canvas, const Offset(124, 97), 4.5);
    _flower(canvas, const Offset(196, 90), 4.5);
    _flower(canvas, const Offset(177, 59), 3, gold: true);
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
  bool shouldRepaint(covariant _JourneyPainter old) =>
      old.progress != progress ||
      old.together != together ||
      old.first != first ||
      old.second != second ||
      old.daysTogether != daysTogether;
}
