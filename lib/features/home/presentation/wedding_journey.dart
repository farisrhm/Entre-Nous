import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../domain/journey_progress.dart';

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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final milestone in const [
                (
                  100,
                  'Le début du chemin',
                  'Cent jours pour rêver à la vie que nous allons construire.',
                ),
                (
                  50,
                  'À mi-chemin',
                  'La distance se réduit. Et notre histoire grandit.',
                ),
                (
                  30,
                  'Un dernier mois',
                  'Bientôt, tous ces petits pas deviendront notre grand oui.',
                ),
                (
                  7,
                  'Tout près de toi',
                  'Plus qu’une semaine avant de prendre ta main pour la suite.',
                ),
                (0, 'Notre grand jour', 'Jusqu’à nous. Maintenant, ensemble.'),
              ])
                ActionChip(
                  avatar: Icon(
                    journey.daysRemaining <= milestone.$1
                        ? Icons.favorite
                        : Icons.lock_outline,
                    size: 14,
                    color: Palette.forest,
                  ),
                  label: Text(
                    milestone.$1 == 0 ? 'Notre oui' : 'J−${milestone.$1}',
                  ),
                  onPressed: () => showReading(
                    context,
                    milestone.$2,
                    journey.daysRemaining <= milestone.$1
                        ? milestone.$3
                        : 'Ce petit mot vous attend à J−${milestone.$1}. Encore ${journey.daysRemaining - milestone.$1} jours de chemin.',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            journey.together
                ? 'Un même chemin, une vie à partager.'
                : 'Touchez une étape pour découvrir son petit mot.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

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

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, 130);
    final left = Path()
      ..moveTo(25, 155)
      ..cubicTo(w * .22, 205, w * .28, 105, center.dx, center.dy);
    final right = Path()
      ..moveTo(w - 25, 155)
      ..cubicTo(w * .78, 205, w * .72, 105, center.dx, center.dy);
    final onward = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(w * .38, 85, w * .65, 60, w * .5, 18);
    final trail = Paint()
      ..color = Palette.gold.withValues(alpha: .25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    for (final path in [left, right, onward]) {
      canvas.drawPath(path, trail);
    }
    for (final path in [left, right]) {
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        Paint()
          ..color = Palette.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    // Botanical details along the path.
    final leaf = Paint()..color = Palette.sage.withValues(alpha: .65);
    for (final x in [.13, .31, .7, .88]) {
      final base = Offset(w * x, 106 + math.sin(x * 15) * 15);
      canvas.drawLine(
        base,
        base.translate(0, -22),
        Paint()
          ..color = Palette.sage
          ..strokeWidth = 1.3,
      );
      canvas.drawOval(
        Rect.fromCenter(center: base.translate(-4, -13), width: 9, height: 5),
        leaf,
      );
      canvas.drawOval(
        Rect.fromCenter(center: base.translate(4, -20), width: 9, height: 5),
        leaf,
      );
    }
    final arch = Path()
      ..moveTo(center.dx - 27, 133)
      ..lineTo(center.dx - 27, 95)
      ..cubicTo(center.dx - 27, 57, center.dx + 27, 57, center.dx + 27, 95)
      ..lineTo(center.dx + 27, 133);
    canvas.drawPath(
      arch,
      Paint()
        ..color = Palette.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(center.dx - 23 + i * 11.5, 77 - math.sin(i / 4 * math.pi) * 8),
        4,
        Paint()..color = i.isEven ? Palette.gold : Palette.sage,
      );
    }
    if (together) {
      // Progress gently along the shared path over the first married year.
      final metric = onward.computeMetrics().first;
      final position = metric
          .getTangentForOffset(
            metric.length * (daysTogether / 365).clamp(0, .8),
          )!
          .position;
      _person(canvas, position.translate(-15, 0), first, true);
      _person(canvas, position.translate(15, 0), second, false);
      canvas.drawLine(
        position.translate(-8, -6),
        position.translate(8, -6),
        Paint()
          ..color = Palette.forest
          ..strokeWidth = 2,
      );
    } else {
      for (final item in [(left, first, true), (right, second, false)]) {
        final metric = item.$1.computeMetrics().first;
        final point = metric
            .getTangentForOffset(metric.length * progress)!
            .position;
        _person(
          canvas,
          point.translate(item.$3 ? -12 * progress : 12 * progress, 0),
          item.$2,
          item.$3,
        );
      }
    }
  }

  void _person(Canvas canvas, Offset feet, String name, bool facingRight) {
    final color = facingRight ? Palette.forest : Palette.brown;
    final body = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(
      Rect.fromCenter(center: feet.translate(0, 3), width: 22, height: 5),
      Paint()..color = Palette.forest.withValues(alpha: .12),
    );
    canvas.drawLine(feet.translate(-4, 0), feet.translate(0, -15), body);
    canvas.drawLine(feet.translate(4, 0), feet.translate(0, -15), body);
    canvas.drawLine(
      feet.translate(0, -14),
      feet.translate(0, -28),
      body..strokeWidth = 7,
    );
    canvas.drawCircle(feet.translate(0, -37), 8, Paint()..color = color);
    canvas.drawCircle(
      feet.translate(facingRight ? 4 : -4, -38),
      1.4,
      Paint()..color = Palette.ivory,
    );
    final label = TextPainter(
      text: TextSpan(
        text: name.characters.firstOrNull ?? '♡',
        style: const TextStyle(
          fontSize: 12,
          color: Palette.forest,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, feet.translate(-label.width / 2, 10));
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter old) =>
      old.progress != progress ||
      old.together != together ||
      old.first != first ||
      old.second != second ||
      old.daysTogether != daysTogether;
}
