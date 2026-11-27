import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../domain/memory_game.dart';
import 'memory_card.dart';

class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});
  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  MemoryGame? _game;
  int _round = 0;
  void _start(MemoryLevel level) {
    _game?.dispose();
    setState(() {
      _game = MemoryGame(level);
      _round++;
    });
  }

  void _chooseLevel() {
    _game?.dispose();
    setState(() {
      _game = null;
    });
  }

  @override
  void dispose() {
    _game?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour aux jeux',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/universe/games');
            }
          },
        ),
        title: const Text('Notre Memory'),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final game = _game;
            if (game == null) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: _Keepsake()),
                        const SizedBox(height: 24),
                        const Center(
                          child: Eyebrow('UN PETIT COFFRET DE NOUS'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nos instants,\nà retrouver.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Retourne deux cartes. Retrouve les mêmes photos, et laisse nos souvenirs se rejoindre.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        for (final level in MemoryLevel.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Palette.cream.withValues(alpha: .6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Palette.gold.withValues(alpha: .5),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _start(level),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              level.title,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${level.pairs} paires · ${level.pairs * 2} cartes',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              level.subtitle,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.arrow_forward, size: 19),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Juste le plaisir de se retrouver. Sans chronomètre.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListenableBuilder(
              listenable: game,
              builder: (context, _) {
                final width = math.min(constraints.maxWidth - 32, 480.0);
                // Keep 3:4 cards and comfortable touch targets. Short screens scroll
                // instead of compressing photos or clipping controls at large text sizes.
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Center(
                    child: SizedBox(
                      width: width,
                      child: Column(
                        children: [
                          const Eyebrow('NOTRE MEMORY'),
                          const SizedBox(height: 8),
                          Text(
                            game.level.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              '${game.foundPairs} / ${game.level.pairs} paires retrouvées · ${game.moves} ${game.moves == 1 ? "essai" : "essais"}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 22),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: game.cards.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: game.level.columns,
                                  childAspectRatio: 3 / 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemBuilder: (context, i) => MemoryCard(
                              key: ValueKey('memory-$_round-$i'),
                              photo: game.cards[i],
                              number: i + 1,
                              visible: game.isVisible(i),
                              matched: game.isMatched(i),
                              enabled:
                                  !game.busy &&
                                  !game.isVisible(i) &&
                                  !game.complete,
                              reduceMotion: still,
                              onTap: () => game.select(i, reduceMotion: still),
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (game.complete)
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Palette.cream,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Palette.gold.withValues(alpha: .6),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.favorite_border,
                                      color: Palette.forest,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tous nos instants réunis.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${game.level.pairs} souvenirs retrouvés en ${game.moves} essais.\nEt tant d’autres à écrire ensemble.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: () => _start(game.level),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Recommencer'),
                              ),
                              TextButton(
                                onPressed: _chooseLevel,
                                child: const Text('Changer de niveau'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Keepsake extends StatelessWidget {
  const _Keepsake();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 135,
    width: 160,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -.16,
          child: Container(
            width: 86,
            height: 114,
            decoration: BoxDecoration(
              color: Palette.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.gold),
            ),
          ),
        ),
        Transform.rotate(
          angle: .1,
          child: Container(
            width: 86,
            height: 114,
            decoration: BoxDecoration(
              color: Palette.forest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.gold),
              boxShadow: [
                BoxShadow(
                  color: Palette.forest.withValues(alpha: .13),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'A & F',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Palette.gold),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
