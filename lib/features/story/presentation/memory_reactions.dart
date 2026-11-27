import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';
import '../application/memory_reactions.dart';
import '../domain/memory_reaction.dart';

Future<void> showMemoryReactions(BuildContext context, String memoryId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ReactionPicker(memoryId: memoryId),
    );

class ReactableMemory extends StatelessWidget {
  final String memoryId;
  final Widget child;
  const ReactableMemory({
    super.key,
    required this.memoryId,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => showMemoryReactions(context, memoryId),
        child: child,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: MemoryReactionBar(memoryId: memoryId),
      ),
    ],
  );
}

class MemoryReactionBar extends ConsumerWidget {
  final String memoryId;
  final bool dark;
  const MemoryReactionBar({
    super.key,
    required this.memoryId,
    this.dark = false,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryReactionsProvider);
    final members = ref.watch(repositoryProvider).members;
    final own = ref.watch(memoryReactionStoreProvider).userId;
    final reactions = (state.value ?? [])
        .where((r) => r.memoryId == memoryId)
        .toList();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final emoji in reactions.map((r) => r.emoji).toSet())
          Builder(
            builder: (context) {
              final group = reactions.where((r) => r.emoji == emoji).toList(),
                  mine = group.any((r) => r.userId == own);
              final names = group
                  .map(
                    (r) => r.userId == own
                        ? 'Moi'
                        : members
                                  .where((m) => m.id == r.userId)
                                  .firstOrNull
                                  ?.name ??
                              'Votre moitié',
                  )
                  .join(', ');
              return Tooltip(
                message: names,
                child: ActionChip(
                  side: BorderSide(
                    color: mine
                        ? Palette.gold
                        : Palette.sage.withValues(alpha: .4),
                  ),
                  backgroundColor: mine ? Palette.cream : Palette.ivory,
                  label: Text(
                    '$emoji${group.length > 1 ? ' ${group.length}' : ''}',
                  ),
                  onPressed: () => showMemoryReactions(context, memoryId),
                ),
              );
            },
          ),
        TextButton.icon(
          onPressed: () => showMemoryReactions(context, memoryId),
          icon: Icon(
            Icons.add_reaction_outlined,
            size: 18,
            color: dark ? Palette.gold : null,
          ),
          style: dark
              ? TextButton.styleFrom(foregroundColor: Palette.ivory)
              : null,
          label: Text(
            state.hasError
                ? 'Réactions · réessayer'
                : reactions.isEmpty
                ? 'Réagir'
                : 'Ma réaction',
          ),
        ),
      ],
    );
  }
}

class _ReactionPicker extends ConsumerStatefulWidget {
  final String memoryId;
  const _ReactionPicker({required this.memoryId});
  @override
  ConsumerState<_ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends ConsumerState<_ReactionPicker> {
  final text = TextEditingController();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> choose(String? emoji) async {
    if (saving) return;
    if (emoji != null && !ReactionEmoji.valid(emoji)) {
      setState(
        () => error = 'Choisis un seul emoji avec le clavier, par exemple 🥰.',
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref
          .read(memoryReactionsProvider.notifier)
          .choose(widget.memoryId, emoji);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Ta réaction n’a pas pu être enregistrée. Réessaie dans un instant.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryReactionsProvider),
        uid = ref.watch(memoryReactionStoreProvider).userId;
    final current = (state.value ?? [])
        .where((r) => r.memoryId == widget.memoryId && r.userId == uid)
        .firstOrNull
        ?.emoji;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ce souvenir me fait…',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Une petite émotion, juste entre nous.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in ReactionEmoji.suggestions)
                  Semantics(
                    label: 'Réagir avec $emoji',
                    selected: emoji == current,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: saving ? null : () => choose(emoji),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: emoji == current
                              ? Palette.cream
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: emoji == current
                                ? Palette.gold
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: text,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Un autre emoji',
                hintText: 'Choisis un emoji sur ton clavier',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => choose(value.trim()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: saving ? null : () => choose(text.text.trim()),
              child: Text(saving ? 'Enregistrement…' : 'Envoyer cet emoji'),
            ),
            if (current != null)
              TextButton(
                onPressed: saving ? null : () => choose(null),
                child: const Text('Retirer ma réaction'),
              ),
            if (state.hasError && !saving)
              TextButton(
                onPressed: () =>
                    ref.read(memoryReactionsProvider.notifier).refresh(),
                child: const Text('Recharger les réactions'),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
