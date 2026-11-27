import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';
import '../../../core/widgets/shared.dart';
import '../data/game_store.dart';
import '../domain/word_theme.dart';
import '../domain/word_search_game.dart';
import 'game_widgets.dart';
import 'word_grid.dart';

class WordsPage extends ConsumerStatefulWidget {
  const WordsPage({super.key});
  @override
  ConsumerState<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends ConsumerState<WordsPage> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gameStoreProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Les Mots de notre histoire',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 24),
        ),
        leading: IconButton(
          tooltip: 'Retour aux jeux',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/universe/games'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Eyebrow('ENTRE LES LETTRES, NOUS'),
            const SizedBox(height: 12),
            Text(
              'Des mots\nqui nous ressemblent.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text('Certains mots racontent bien plus qu’une histoire.'),
            const SizedBox(height: 26),
            for (final theme in WordTheme.catalog)
              Builder(
                builder: (context) {
                  final saved = store.read('words.${theme.id}'),
                      raw = store.read('words.${theme.id}')?['game'];
                  final game = WordSearchGame.restore(
                    theme,
                    raw is Map ? Map<String, dynamic>.from(raw) : null,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Paper(
                      color: Palette.cream.withValues(alpha: .55),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.grid_on_outlined,
                                color: Palette.gold,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  theme.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(theme.description),
                          const SizedBox(height: 10),
                          Text(
                            '${theme.words.length} mots · ${theme.reversed ? 'Pour explorer · tous les sens' : 'Tout en douceur'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (game != null) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: game.found.length / theme.words.length,
                              backgroundColor: Palette.ivory,
                              color: Palette.sage,
                              minHeight: 3,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${game.found.length} / ${theme.words.length} mots trouvés',
                            ),
                          ],
                          if (saved?['completed'] == true)
                            const Text(
                              'Déjà découverte',
                              style: TextStyle(
                                color: Palette.forest,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WordsPlayPage(theme: theme),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                            child: Text(
                              game != null && !game.complete
                                  ? 'Reprendre notre grille'
                                  : 'Découvrir la grille',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class WordsPlayPage extends ConsumerStatefulWidget {
  final WordTheme theme;
  const WordsPlayPage({super.key, required this.theme});
  @override
  ConsumerState<WordsPlayPage> createState() => _WordsPlayPageState();
}

class _WordsPlayPageState extends ConsumerState<WordsPlayPage>
    with WidgetsBindingObserver {
  late final GameStore store;
  late WordSearchGame game;
  StoryWord? message;
  int? hint;
  Timer? hintTimer;
  String? saveError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store = ref.read(gameStoreProvider);
    final raw = store.read('words.${widget.theme.id}')?['game'];
    game =
        WordSearchGame.restore(
          widget.theme,
          raw is Map ? Map<String, dynamic>.from(raw) : null,
        ) ??
        WordSearchGame.generate(widget.theme);
    unawaited(save());
  }

  Future<void> save() async {
    try {
      await store.saveWords(game);
      if (mounted && saveError != null) setState(() => saveError = null);
    } catch (_) {
      if (mounted) {
        setState(() => saveError = 'La grille n’a pas pu être sauvegardée.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(save());
  }

  void select(List<int> path) {
    if (game.complete) return;
    final word = game.match(path);
    if (word == null) return;
    hintTimer?.cancel();
    setState(() {
      hint = null;
      message = widget.theme.words.firstWhere((w) => w.letters == word);
    });
    unawaited(save());
  }

  void reset() {
    hintTimer?.cancel();
    setState(() {
      game = WordSearchGame.generate(widget.theme);
      message = null;
      hint = null;
    });
    unawaited(save());
  }

  @override
  void dispose() {
    hintTimer?.cancel();
    unawaited(save());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still =
        ref.watch(settingsProvider).reduceMotion ||
        MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.theme.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Eyebrow('LES MOTS DE NOTRE HISTOIRE'),
                  const SizedBox(height: 12),
                  Text(
                    'Retrouvons-nous\nentre les lignes.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: still
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    child: message == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.theme.reversed
                                    ? 'Glisse d’une lettre à l’autre, dans tous les sens.'
                                    : 'Glisse en ligne droite vers la droite, le bas ou en diagonale.',
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Tu peux aussi toucher la première puis la dernière lettre.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          )
                        : GameVictory(
                            key: ValueKey(message!.letters),
                            message: message!.message,
                            still: still,
                            compact: true,
                            child: Text(
                              message!.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Palette.forest,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedOpacity(
                    opacity: game.complete ? .25 : 1,
                    duration: still
                        ? Duration.zero
                        : const Duration(milliseconds: 700),
                    child: WordGrid(
                      game: game,
                      onSelection: select,
                      hint: hint,
                      still: still,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '${game.found.length} / ${widget.theme.words.length} mots trouvés',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      end: game.found.length / widget.theme.words.length,
                    ),
                    duration: still
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    builder: (_, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 3,
                      color: Palette.gold,
                      backgroundColor: Palette.cream,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final word in widget.theme.words)
                        AnimatedContainer(
                          duration: still
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: game.found.contains(word.letters)
                                ? Palette.sage.withValues(alpha: .25)
                                : Palette.cream.withValues(alpha: .6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            word.label,
                            style: TextStyle(
                              decoration: game.found.contains(word.letters)
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: Palette.forest,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (saveError != null)
                    TextButton(
                      onPressed: save,
                      child: Text('$saveError Réessayer'),
                    ),
                  if (!game.complete) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() => hint = game.hint);
                            hintTimer?.cancel();
                            hintTimer = Timer(const Duration(seconds: 2), () {
                              if (mounted) setState(() => hint = null);
                            });
                          },
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: const Text('Un petit indice ?'),
                        ),
                        TextButton(
                          onPressed: reset,
                          child: const Text('Recommencer'),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 22),
                    GameVictory(
                      message: widget.theme.finalMessage,
                      still: still,
                      child: Column(
                        children: [
                          Text(
                            'Alyssa & Faris ❤️',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: reset,
                            child: const Text('Rejouer'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Découvrir une autre grille'),
                          ),
                          TextButton(
                            onPressed: () => context.go('/universe/games'),
                            child: const Text('Retour aux jeux'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
