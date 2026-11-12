import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/application/providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/widgets/shared.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../app/theme.dart';
import '../../together/presentation/universe_spaces.dart';

class UniversePage extends ConsumerStatefulWidget {
  const UniversePage({super.key});
  @override
  ConsumerState<UniversePage> createState() => _UniversePageState();
}

class _UniversePageState extends ConsumerState<UniversePage> {
  bool sending = false;
  Future<void> save(Entry e) async {
    try {
      await ref.read(entriesProvider.notifier).save(e);
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  Future<void> promise(Entry? entry, String name, String memberId) async {
    final controller = TextEditingController(text: entry?.text('body') ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Les promesses de $name'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          maxLength: 20000,
          decoration: const InputDecoration(hintText: 'Je te promets…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    // The dialog may still animate out with its controller attached.
    if (result != null) {
      await save(
        Entry(
          id: entry?.id ?? 'promise-$memberId',
          kind: EntryKind.promise,
          fields: {'title': name, 'body': result},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider),
        entries = ref.watch(entriesProvider).value ?? <Entry>[];
    final dreams = entries.where((e) => e.kind == EntryKind.dream),
        thoughts = entries.where((e) => e.kind == EntryKind.thought).toList();
    return PageBody(
      children: [
        const SectionHeading(
          'NOTRE REFUGE',
          'Notre petit univers',
          'Nos souvenirs d’hier, nos rêves de demain.',
        ),
        const UniverseSpaces(),
        const Eyebrow('NOS PROMESSES'),
        const SizedBox(height: 18),
        for (final member in repo.members)
          Builder(
            builder: (context) {
              final found = entries
                  .where(
                    (e) =>
                        e.kind == EntryKind.promise &&
                        e.id == 'promise-${member.id}',
                  )
                  .firstOrNull;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Paper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('LES PROMESSES DE'),
                      Text(
                        member.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(found?.text('body') ?? 'Je te promets…'),
                      if (!repo.isCloud || member.id == repo.userId)
                        TextButton(
                          onPressed: () =>
                              promise(found, member.name, member.id),
                          child: const Text('Écrire mes promesses'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SectionHeading(
          'NOS RÊVES À DEUX',
          'Une vie entière\nà imaginer.',
          'Les grandes aventures commencent par une envie.',
        ),
        for (final e in dreams)
          Card(
            elevation: 0,
            color: Palette.cream,
            child: ListTile(
              leading: Checkbox(
                value: e.flag('done'),
                onChanged: (v) => save(e.copy({'done': v ?? false})),
              ),
              title: Text(
                e.text('title'),
                style: TextStyle(
                  decoration: e.flag('done')
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              onTap: () => editEntry(context, e),
              trailing: IconButton(
                tooltip: 'Supprimer le rêve',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () async {
                  if (await confirmDelete(context)) {
                    try {
                      await ref.read(entriesProvider.notifier).delete(e);
                    } catch (error) {
                      if (context.mounted) showError(context, error);
                    }
                  }
                },
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () => editEntry(
            context,
            Entry(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              kind: EntryKind.dream,
              fields: const {'done': false},
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un rêve'),
        ),
        const SizedBox(height: 32),
        Paper(
          color: Palette.forest,
          child: Column(
            children: [
              const Eyebrow('JUSTE COMME ÇA', color: Palette.ivory),
              const SizedBox(height: 22),
              const Icon(Icons.favorite, color: Palette.gold, size: 56),
              const SizedBox(height: 24),
              Text(
                'Une petite pensée,\njuste pour toi.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium!.copyWith(color: Palette.ivory),
              ),
              const SizedBox(height: 22),
              FilledButton.tonal(
                onPressed: sending
                    ? null
                    : () async {
                        setState(() => sending = true);
                        try {
                          if (repo.isCloud) {
                            await ref
                                .read(entriesProvider.notifier)
                                .save(
                                  Entry(
                                    id: DateTime.now().microsecondsSinceEpoch
                                        .toString(),
                                    kind: EntryKind.thought,
                                    fields: {
                                      'title': 'Je pense à toi',
                                      'sentAt': DateTime.now()
                                          .toUtc()
                                          .toIso8601String(),
                                    },
                                  ),
                                );
                          }
                          if (context.mounted) {
                            await showReading(
                              context,
                              'Je pense à toi',
                              'Ta pensée est déposée avec amour dans notre espace.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        } finally {
                          if (mounted) setState(() => sending = false);
                        }
                      },
                child: Text(sending ? 'Envoi…' : 'Je pense à toi  ♡'),
              ),
              const SizedBox(height: 16),
              Text(
                'Un petit mot d’amour, déposé rien que pour nous.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.ivory, fontSize: 11),
              ),
            ],
          ),
        ),
        if (thoughts.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Eyebrow('NOS DERNIÈRES PENSÉES'),
          for (final e in thoughts.reversed.take(5))
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text(
                repo.members
                        .where((m) => m.id == e.authorId)
                        .firstOrNull
                        ?.name ??
                    'Nous',
              ),
              subtitle: Text(
                e.date('sentAt') == null
                    ? 'Je pense à toi'
                    : DateFormat(
                        'dd MMM à HH:mm',
                        'fr',
                      ).format(e.date('sentAt')!.toLocal()),
              ),
            ),
        ],
      ],
    );
  }
}
