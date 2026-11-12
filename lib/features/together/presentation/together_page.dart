import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/widgets/shared.dart';
import '../domain/together_space.dart';
import 'happiness_jar.dart';
import 'together_editor.dart';

IconData spaceIcon(TogetherSpace s) => switch (s.kind) {
  EntryKind.openWhen => Icons.mark_email_unread_outlined,
  EntryKind.happiness => Icons.wb_sunny_outlined,
  EntryKind.dua => Icons.nights_stay_outlined,
  _ => Icons.home_outlined,
};

class TogetherPage extends ConsumerStatefulWidget {
  final TogetherSpace space;
  const TogetherPage({super.key, required this.space});
  @override
  ConsumerState<TogetherPage> createState() => _TogetherPageState();
}

class _TogetherPageState extends ConsumerState<TogetherPage> {
  bool gratitudeOnly = false;
  String? lastDrawId;
  final deleting = <String>{};
  Future<void> remove(Entry e) async {
    if (!await confirmDelete(context) || !mounted) return;
    setState(() => deleting.add(e.id));
    try {
      await ref.read(entriesProvider.notifier).delete(e);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => deleting.remove(e.id));
    }
  }

  Future<void> read(Entry e) async {
    final s = widget.space;
    final prefix = s.kind == EntryKind.openWhen
        ? 'Ouvre quand ${e.text('title')}'
        : e.text('title');
    final date = e.date('date');
    final detail = [
      if (s.hasRecipient) 'Pour ${e.text('recipient')}',
      if (date != null) DateFormat('dd MMMM yyyy', 'fr').format(date),
      if (e.flag('gratitude')) 'Alhamdulillah',
      if (s.kind == EntryKind.dua) 'Invocation personnelle',
      e.text('body'),
      if (s.kind == EntryKind.intention)
        'Notre petit geste : ${e.text('action')}',
    ].where((v) => v.isNotEmpty).join('\n\n');
    await showReading(context, prefix, detail);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.space, repo = ref.watch(repositoryProvider);
    final all = (ref.watch(entriesProvider).value ?? <Entry>[])
        .where((e) => e.kind == s.kind)
        .toList()
        .reversed
        .toList();
    final entries = all
        .where((e) => !gratitudeOnly || e.flag('gratitude'))
        .toList();
    return PageBody(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go(
              s.kind == EntryKind.openWhen ? '/letters' : '/universe',
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(
              s.kind == EntryKind.openWhen ? 'Nos lettres' : 'Notre univers',
            ),
          ),
        ),
        SectionHeading(s.eyebrow, s.title, s.subtitle),
        if (s.kind == EntryKind.happiness) ...[
          Paper(
            color: Palette.cream,
            child: Column(
              children: [
                HappinessJar(count: all.length),
                Text(
                  all.isEmpty
                      ? 'Tout commence par un petit bonheur.'
                      : '${all.length} petit${all.length == 1 ? '' : 's'} bonheur${all.length == 1 ? '' : 's'} à retrouver',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: entries.isEmpty
                      ? null
                      : () {
                          final candidates = entries.length > 1
                              ? entries
                                    .where((e) => e.id != lastDrawId)
                                    .toList()
                              : entries;
                          final e =
                              candidates[Random().nextInt(candidates.length)];
                          lastDrawId = e.id;
                          read(e);
                        },
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Piocher un bonheur'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tous les bonheurs'),
                selected: !gratitudeOnly,
                onSelected: (_) => setState(() => gratitudeOnly = false),
              ),
              ChoiceChip(
                label: const Text('Gratitude'),
                selected: gratitudeOnly,
                onSelected: (_) => setState(() => gratitudeOnly = true),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        if (s.kind == EntryKind.dua)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'Des invocations écrites avec le cœur, pour se porter dans la douceur.',
              textAlign: TextAlign.center,
            ),
          ),
        if (s.kind == EntryKind.openWhen)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'Chaque enveloppe attend son moment, puis peut être relue autant de fois que voulu.',
              textAlign: TextAlign.center,
            ),
          ),
        FilledButton.icon(
          onPressed: () => editTogetherEntry(context, s),
          icon: const Icon(Icons.add),
          label: Text(s.addLabel),
        ),
        const SizedBox(height: 26),
        if (entries.isEmpty)
          Paper(
            child: Column(
              children: [
                Icon(spaceIcon(s), size: 38, color: Palette.gold),
                const SizedBox(height: 18),
                Text(
                  gratitudeOnly && all.isNotEmpty
                      ? 'Aucun moment de gratitude pour l’instant.'
                      : s.emptyText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Paper(
              color: s.kind == EntryKind.openWhen ? Palette.cream : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(spaceIcon(s), color: Palette.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.hasRecipient
                              ? 'Pour ${e.text('recipient')}'
                              : s.kind == EntryKind.happiness
                              ? (e.flag('gratitude')
                                    ? 'Alhamdulillah · ${_date(e)}'
                                    : _date(e))
                              : 'À cultiver ensemble',
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: .6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.kind == EntryKind.openWhen
                        ? 'Ouvre quand ${e.text('title')}'
                        : e.text('title'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  if (s.kind != EntryKind.openWhen && e.text('body').isNotEmpty)
                    Text(
                      e.text('body'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (s.kind == EntryKind.intention) ...[
                    const SizedBox(height: 12),
                    const Eyebrow('NOTRE PETIT GESTE'),
                    const SizedBox(height: 8),
                    Text(e.text('action')),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => read(e),
                        icon: Icon(
                          s.kind == EntryKind.openWhen
                              ? Icons.mail_outline
                              : Icons.menu_book_outlined,
                          size: 17,
                        ),
                        label: Text(
                          s.kind == EntryKind.openWhen
                              ? 'Ouvrir l’enveloppe'
                              : 'Relire',
                        ),
                      ),
                      if (s.mayEdit(e, repo.userId, repo.isCloud)) ...[
                        TextButton(
                          onPressed: deleting.contains(e.id)
                              ? null
                              : () => editTogetherEntry(context, s, entry: e),
                          child: const Text('Modifier'),
                        ),
                        IconButton(
                          tooltip: 'Supprimer ce moment',
                          onPressed: deleting.contains(e.id)
                              ? null
                              : () => remove(e),
                          icon: const Icon(Icons.delete_outline, size: 19),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _date(Entry e) => e.date('date') == null
      ? 'Un petit bonheur'
      : DateFormat('dd MMMM yyyy', 'fr').format(e.date('date')!);
}
