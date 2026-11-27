import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../domain/journey_progress.dart';
import 'journey_hourglass.dart';
import 'journey_garden.dart';

/// An illuminated garden vignette. All illustration layers share one coordinate
/// space, so the timepiece, paths and couple remain a single scene on any phone.
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF7EF), Color(0xFFF0E9DA)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Palette.gold.withValues(alpha: .35)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              children: [
                const Eyebrow('LE CHEMIN JUSQU’À NOUS'),
                const SizedBox(height: 14),
                Text(
                  journey.together
                      ? 'Maintenant,\nensemble.'
                      : 'Chaque jour,\nun peu plus près.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 32,
                    height: 1.08,
                    letterSpacing: -.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            image: true,
            label: '$firstName et $secondName. ${journey.caption}',
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: math.max(0, journey.progress - .01),
                end: journey.progress,
              ),
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 1600),
              curve: Curves.easeInOutCubic,
              builder: (context, progress, _) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AspectRatio(
                    aspectRatio: 360 / 350,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 360,
                        height: 350,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ExcludeSemantics(
                                child: CustomPaint(
                                  painter: JourneyGardenPainter(
                                    progress: progress,
                                    together: journey.together,
                                    foreground: false,
                                    daysTogether: -journey.daysRemaining,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 108,
                              top: 37,
                              width: 144,
                              height: 192,
                              child: JourneyHourglass(
                                progress: journey.progress,
                                reduceMotion: still,
                              ),
                            ),
                            Positioned.fill(
                              child: ExcludeSemantics(
                                child: CustomPaint(
                                  painter: JourneyGardenPainter(
                                    progress: progress,
                                    together: journey.together,
                                    foreground: true,
                                    daysTogether: -journey.daysRemaining,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                Text(
                  '$firstName  &  $secondName',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 25,
                    height: 1.1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Palette.gold.withValues(alpha: .35),
                        endIndent: 16,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Palette.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Palette.gold.withValues(alpha: .35),
                        indent: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  journey.caption,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.6,
                    color: Palette.forest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  journey.together
                      ? 'Notre éternité commence.'
                      : 'Chaque grain nous rapproche.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: Palette.brown.withValues(alpha: .75),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '28 mars 2026 · 23 janvier 2027',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: .35,
                    color: Palette.forest.withValues(alpha: .65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
