import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';

/// Each unit describes the same duration; breaths are an illustrative estimate.
class CountdownCarousel extends ConsumerStatefulWidget {
  final Duration duration;
  final bool after;
  final bool reduceMotion;
  const CountdownCarousel({
    super.key,
    required this.duration,
    required this.after,
    this.reduceMotion = false,
  });

  static const preferenceKey = 'countdown.view.v1';
  @override
  ConsumerState<CountdownCarousel> createState() => _CountdownCarouselState();
}

class _CountdownCarouselState extends ConsumerState<CountdownCarousel>
    with SingleTickerProviderStateMixin {
  static const labels = [
    'Décompte',
    'Semaines',
    'Heures',
    'Secondes',
    'Respirations',
  ];
  late final PageController pages;
  late final AnimationController breath;
  late int selected;
  bool still = false;
  Future<void> pendingSave = Future.value();

  @override
  void initState() {
    super.initState();
    selected =
        (ref
                    .read(preferencesProvider)
                    .getInt(CountdownCarousel.preferenceKey) ??
                0)
            .clamp(0, 4);
    pages = PageController(initialPage: selected);
    breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateMotion();
  }

  @override
  void didUpdateWidget(covariant CountdownCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateMotion();
  }

  void updateMotion() {
    still = widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    if (!still && selected == 4) {
      if (!breath.isAnimating) breath.repeat(reverse: true);
    } else {
      breath.stop();
      breath.value = 0;
    }
  }

  void changed(int index) {
    setState(() => selected = index);
    updateMotion();
    final preferences = ref.read(preferencesProvider);
    // Serialize writes so a rapid swipe always persists the latest choice.
    pendingSave = pendingSave
        .then((_) async {
          final saved = await preferences.setInt(
            CountdownCarousel.preferenceKey,
            index,
          );
          if (!saved) throw StateError('Preference not saved');
        })
        .catchError((Object _) {
          if (mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text(
                  'Cette vue ne pourra pas être mémorisée pour la prochaine ouverture.',
                ),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    pages.dispose();
    breath.dispose();
    super.dispose();
  }

  Widget number(String value, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 37,
            height: 1.1,
            color: Palette.ivory,
          ),
        ),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            height: 1.2,
            color: Palette.ivory,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final duration = widget.duration.isNegative
        ? Duration.zero
        : widget.duration;
    final format = NumberFormat.decimalPattern('fr');
    final suffix = widget.after ? 'depuis notre oui' : 'avant notre oui';
    final weeks = duration.inDays ~/ 7;
    final days = duration.inDays % 7;
    final breaths =
        duration.inSeconds ~/ 5; // 12 breaths/minute, not a measurement.
    final height = 96 * MediaQuery.textScalerOf(context).scale(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: PageView(
            controller: pages,
            onPageChanged: changed,
            children: [
              Center(
                child: Row(
                  children: [
                    for (final part in [
                      (duration.inDays, 'Jours'),
                      (duration.inHours % 24, 'Heures'),
                      (duration.inMinutes % 60, 'Minutes'),
                      (duration.inSeconds % 60, 'Secondes'),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: number('${part.$1}'.padLeft(2, '0'), part.$2),
                        ),
                      ),
                  ],
                ),
              ),
              Center(
                child: number(
                  '$weeks ${weeks == 1 ? 'semaine' : 'semaines'}',
                  '$days ${days == 1 ? 'jour' : 'jours'} $suffix',
                ),
              ),
              Center(
                child: number(
                  format.format(duration.inHours),
                  '${duration.inHours == 1 ? 'heure' : 'heures'} $suffix',
                ),
              ),
              Center(
                child: number(
                  format.format(duration.inSeconds),
                  '${duration.inSeconds == 1 ? 'seconde' : 'secondes'} $suffix',
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: breath,
                      builder: (_, child) => Opacity(
                        opacity: .85 + breath.value * .15,
                        child: child,
                      ),
                      child: number(
                        '≈ ${format.format(breaths)}',
                        'respirations $suffix',
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < labels.length; i++)
              Semantics(
                selected: selected == i,
                button: true,
                label: 'Afficher ${labels[i]}',
                child: Tooltip(
                  message: labels[i],
                  child: InkResponse(
                    onTap: () {
                      if (still) {
                        pages.jumpToPage(i);
                      } else {
                        pages.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: SizedBox(
                      width: 28,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: selected == i ? 4 : 3,
                          height: selected == i ? 4 : 3,
                          decoration: BoxDecoration(
                            color: selected == i
                                ? Palette.gold
                                : Palette.ivory.withValues(alpha: .25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
