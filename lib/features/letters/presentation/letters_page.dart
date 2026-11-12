import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/application/providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/widgets/shared.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../app/theme.dart';

class LettersPage extends ConsumerWidget {
  const LettersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final demo = ref.watch(settingsProvider).demo && !repo.isCloud;
    final entries = (ref.watch(entriesProvider).value ?? []).where(
      (e) => e.kind == EntryKind.letter,
    );
    return PageBody(
      children: [
        const SectionHeading(
          'NOS LETTRES SECRÈTES',
          'Les mots que je te garde',
          'Certaines paroles méritent d’attendre leur moment.',
        ),
        Paper(
          color: Palette.cream,
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                color: Palette.gold,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Ouvre quand…',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Text(
                'Des mots pour les moments où tu en as besoin.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => context.go('/letters/open-when'),
                child: const Text('Découvrir nos enveloppes  →'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => editEntry(
            context,
            Entry(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              kind: EntryKind.letter,
              fields: const {},
            ),
          ),
          icon: const Icon(Icons.edit_note),
          label: const Text('Écrire une lettre'),
        ),
        const SizedBox(height: 28),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Une page blanche, mille choses à se dire.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final e in entries)
          Builder(
            builder: (context) {
              final author = repo.isCloud && e.authorId == repo.userId;
              final date = e.date('openAt');
              final unlocked = repo.isCloud
                  ? e.flag('available')
                  : demo || (date != null && !now.isBefore(date));
              final available = unlocked || author;
              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Paper(
                  color: Palette.cream,
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Palette.forest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_outline,
                          color: Palette.gold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Eyebrow('POUR ${e.text('recipient')}'),
                      const SizedBox(height: 12),
                      Text(
                        e.text('title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        unlocked
                            ? 'Cette lettre t’attend.'
                            : 'À ouvrir le ${date == null ? '…' : DateFormat('dd MMMM yyyy à HH:mm', 'fr').format(date.toLocal())}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: available
                            ? () => showReading(
                                context,
                                e.text('title'),
                                e.text('body'),
                              )
                            : null,
                        icon: Icon(
                          available ? Icons.mail_outline : Icons.lock_outline,
                        ),
                        label: Text(
                          author && !unlocked
                              ? 'Relire ma lettre'
                              : unlocked
                              ? 'Ouvrir'
                              : 'Encore un peu de patience',
                        ),
                      ),
                      if (!repo.isCloud || author)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () => editEntry(context, e),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Modifier'),
                            ),
                            IconButton(
                              tooltip: 'Supprimer la lettre',
                              onPressed: () async {
                                if (await confirmDelete(context)) {
                                  try {
                                    await ref
                                        .read(entriesProvider.notifier)
                                        .delete(e);
                                  } catch (error) {
                                    if (context.mounted) {
                                      showError(context, error);
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        const Text(
          'Chaque lettre s’ouvre au moment qu’on a choisi, pour garder toute sa magie.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
