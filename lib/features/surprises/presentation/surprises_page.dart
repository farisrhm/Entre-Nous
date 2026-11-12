import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/application/providers.dart';
import '../../../core/widgets/shared.dart';
import '../../../app/theme.dart';
import '../../home/domain/wedding_clock.dart';

const surpriseTexts = [
  'Quel est le souvenir de nous deux qui te fait toujours sourire ?',
  'Si je pouvais revivre une journée avec toi, laquelle choisirais-tu ?',
  'J’ai hâte de construire un foyer rempli de douceur avec toi.',
  'Ce soir, choisissons une chanson pour notre prochain slow.',
  'Promesse du jour : ne jamais cesser de te choisir.',
  'Ton rire reste mon endroit préféré.',
  'Un jour de moins à attendre, une vie entière à partager.',
];

class SurprisesPage extends ConsumerWidget {
  const SurprisesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final demo =
        ref.watch(settingsProvider).demo &&
        !ref.watch(repositoryProvider).isCloud;
    final count = demo ? 30 : unlockedSurprises(now);
    return PageBody(
      children: [
        const SectionHeading(
          '30 JOURS · 30 ATTENTIONS',
          'Un jour, une surprise',
          'Parce que l’attente aussi mérite d’être belle.',
        ),
        if (count == 0)
          const Paper(
            color: Palette.cream,
            child: Column(
              children: [
                Icon(Icons.local_florist_outlined, size: 34),
                SizedBox(height: 16),
                Eyebrow('LE CALENDRIER S’ÉVEILLERA LE'),
                SizedBox(height: 12),
                Text(
                  '25 décembre 2026',
                  style: TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 30,
                  ),
                ),
                Text(
                  'En attendant, les enveloppes gardent précieusement leurs secrets.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        if (demo)
          const Text(
            'Toutes nos attentions sont prêtes à être découvertes.',
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 30,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: c.maxWidth > 600 ? 5 : 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .79,
            ),
            itemBuilder: (context, i) {
              final open = i < count;
              return Semantics(
                label:
                    'Surprise ${i + 1}, ${open ? 'disponible' : 'verrouillée'}',
                button: true,
                child: InkWell(
                  onTap: open
                      ? () => showReading(
                          context,
                          'Surprise nº ${i + 1}',
                          surpriseTexts[i % surpriseTexts.length],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: open ? Palette.cream : Palette.forest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Palette.gold.withValues(alpha: .35),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '${i + 1}'.padLeft(2, '0'),
                          style: TextStyle(
                            color: open ? Palette.forest : Palette.ivory,
                            fontFamily: 'Cormorant Garamond',
                            fontSize: 26,
                          ),
                        ),
                        Icon(
                          open
                              ? Icons.mark_email_unread_outlined
                              : Icons.lock_outline,
                          color: Palette.gold,
                          size: 32,
                        ),
                        Text(
                          open ? 'À découvrir' : 'J–${30 - i}',
                          style: TextStyle(
                            fontSize: 10,
                            color: open ? Palette.forest : Palette.ivory,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
