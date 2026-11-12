import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/widgets/shared.dart';
import '../domain/together_space.dart';
import 'together_page.dart';

class UniverseSpaces extends ConsumerWidget {
  const UniverseSpaces({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).value ?? <Entry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Eyebrow('CE QUI NOUS RAPPROCHE'),
        const SizedBox(height: 18),
        for (final s in [
          TogetherSpace.happiness,
          TogetherSpace.dua,
          TogetherSpace.intention,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Paper(
              color: s.kind == EntryKind.happiness ? Palette.cream : null,
              child: InkWell(
                onTap: () => context.go(s.path),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(spaceIcon(s), color: Palette.forest, size: 30),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              entries.where((e) => e.kind == s.kind).isEmpty
                                  ? s.subtitle
                                  : '${entries.where((e) => e.kind == s.kind).length} moment(s) dans cet espace',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 26),
      ],
    );
  }
}
