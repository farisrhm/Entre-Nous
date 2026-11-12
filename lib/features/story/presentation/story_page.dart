import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/application/providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/widgets/shared.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../app/theme.dart';
import '../domain/memory_album.dart';
import 'memory_gallery.dart';

class StoryPage extends ConsumerWidget {
  const StoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = (ref.watch(entriesProvider).value ?? [])
        .where((e) => e.kind == EntryKind.memory)
        .toList();
    return PageBody(
      children: [
        const SectionHeading(
          'CHAPITRE I',
          'Notre histoire',
          'Les petits instants qui ont construit notre grand bonheur.',
        ),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AlbumCover(
                    photos: MemoryAlbum.photosOf(e),
                    title: e.text('title'),
                  ),
                ),
                Paper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow(
                        e.text('date').isEmpty
                            ? 'Une date à compléter'
                            : e.text('date'),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        e.text('title'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(e.text('body')),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => editEntry(context, e),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Modifier'),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Supprimer le souvenir',
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
                            icon: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nos plus beaux souvenirs attendent leur place ici.',
              textAlign: TextAlign.center,
            ),
          ),
        Paper(
          color: Palette.cream,
          child: Column(
            children: [
              const Icon(
                Icons.local_florist_outlined,
                color: Palette.gold,
                size: 34,
              ),
              const SizedBox(height: 16),
              const Eyebrow('23 JANVIER 2027'),
              Text(
                'Notre mariage',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Text(
                'Le premier jour de tous nos lendemains.',
                textAlign: TextAlign.center,
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
              kind: EntryKind.memory,
              fields: const {},
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un souvenir'),
        ),
      ],
    );
  }
}
