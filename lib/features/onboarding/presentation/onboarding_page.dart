import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';
import '../../../core/widgets/shared.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int step = 0;
  Future<void> finish() async {
    try {
      await ref
          .read(settingsProvider.notifier)
          .save(ref.read(settingsProvider).copy(onboardingDone: true));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final slides = [
      (
        'IL ÉTAIT UNE FOIS…',
        '${s.firstName} & ${s.secondName}',
        'Deux chemins qui ont choisi de n’en faire plus qu’un.',
      ),
      (
        'NOTRE HISTOIRE',
        'Deux cœurs, une seule aventure.',
        'Les plus belles histoires s’écrivent à deux.',
      ),
      (
        'NOTRE GRAND JOUR',
        '23 janvier 2027',
        'Ce jour-là, notre nouvelle histoire commence.',
      ),
      (
        'JUSQU’À NOUS',
        'Bienvenue dans notre petit univers.',
        'Un endroit rien qu’à nous, fait de souvenirs et de demain.',
      ),
    ];
    final slide = slides[step];
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Photo(s.heroPhoto),
          Container(color: Palette.forest.withValues(alpha: .76)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: TextButton(
                            onPressed: finish,
                            child: const Text(
                              'Passer',
                              style: TextStyle(color: Palette.ivory),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        const Icon(
                          Icons.local_florist_outlined,
                          color: Palette.gold,
                          size: 44,
                        ),
                        const SizedBox(height: 50),
                        Eyebrow(slide.$1, color: Palette.gold),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: s.reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 350),
                          child: Text(
                            slide.$2,
                            key: ValueKey(step),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayLarge!
                                .copyWith(color: Palette.ivory),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slide.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Palette.ivory,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (i) => Container(
                              width: i == step ? 28 : 6,
                              height: 6,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: i == step ? Palette.gold : Palette.sage,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.tonal(
                          onPressed: () =>
                              step < 3 ? setState(() => step++) : finish(),
                          child: Text(
                            step == 3
                                ? 'Découvrir notre histoire  →'
                                : 'Continuer  →',
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
