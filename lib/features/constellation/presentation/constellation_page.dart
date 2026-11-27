import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/widgets/shared.dart';
import '../../story/domain/memory_album.dart';
import '../../story/presentation/memory_gallery.dart';
import '../../story/presentation/memory_reactions.dart';
import '../domain/love_sky.dart';
import 'sky_painter.dart';

class ConstellationPage extends ConsumerWidget {
  const ConstellationPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(entriesProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: skyNight,
      appBar: AppBar(
        backgroundColor: skyNight,
        foregroundColor: Palette.ivory,
        title: const Text('Notre ciel'),
        leading: IconButton(
          tooltip: 'Retour aux souvenirs',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/story'),
        ),
      ),
      body: SafeArea(
        child: data.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Palette.gold),
          ),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(entriesProvider),
              child: const Text(
                'Retrouver notre ciel',
                style: TextStyle(color: Palette.ivory),
              ),
            ),
          ),
          data: (entries) {
            final stars = LoveSky.stars(entries);
            final wedding = LoveSky.weddingVisible(now);
            return LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          const Eyebrow(
                            'CHAQUE INSTANT, UNE ÉTOILE',
                            color: Palette.gold,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Notre histoire brille ici.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Palette.ivory),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stars.isEmpty
                                ? 'Notre ciel attend son premier souvenir.'
                                : '${stars.length} astre${stars.length > 1 ? 's' : ''} · Une histoire qui grandit',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: skyLetter,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: math.max(280, viewport.maxHeight * .60),
                      child: SkyExplorer(
                        stars: stars,
                        wedding: wedding,
                        still:
                            settings.reduceMotion ||
                            MediaQuery.disableAnimationsOf(context),
                        onStar: (entry) => _open(context, entry),
                        onWedding: () => showReading(
                          context,
                          'Le ciel de notre oui',
                          '23 janvier 2027\n\n${settings.firstName} & ${settings.secondName}\n\nDeux chemins, un même horizon. Ce cœur restera dans notre ciel, avec tous les souvenirs que nous écrirons ensemble.',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      child: Column(
                        children: [
                          const Text(
                            'Fais glisser le ciel · pince pour explorer\nTouche une étoile pour retrouver un instant.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: skyLetter, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            children: [
                              const Text(
                                'Souvenirs',
                                style: TextStyle(
                                  color: Palette.gold,
                                  fontSize: 12,
                                ),
                              ),
                              const Text(
                                'Lettres',
                                style: TextStyle(
                                  color: skyLetter,
                                  fontSize: 12,
                                ),
                              ),
                              TextButton(
                                onPressed: stars.isEmpty
                                    ? null
                                    : () => _list(context, stars),
                                child: const Text(
                                  'Tous nos astres',
                                  style: TextStyle(color: Palette.ivory),
                                ),
                              ),
                            ],
                          ),
                          if (!wedding)
                            const Text(
                              'Une constellation nous attend le 23 janvier 2027.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Palette.gold,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, Entry entry) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _StarReading(id: entry.id, kind: entry.kind),
  );
  void _list(BuildContext context, List<SkyStar> stars) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Tous nos astres',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            for (final star in stars)
              ListTile(
                leading: Icon(
                  star.entry.kind == EntryKind.memory
                      ? Icons.auto_awesome_outlined
                      : Icons.mail_outline,
                ),
                title: Text(
                  star.entry.text('title').isEmpty
                      ? 'Un instant de nous'
                      : star.entry.text('title'),
                ),
                subtitle: Text(
                  star.entry.kind == EntryKind.memory ? 'Souvenir' : 'Lettre',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(context, star.entry);
                },
              ),
          ],
        ),
      );
}

class SkyExplorer extends StatefulWidget {
  final List<SkyStar> stars;
  final bool wedding, still;
  final ValueChanged<Entry> onStar;
  final VoidCallback onWedding;
  const SkyExplorer({
    super.key,
    required this.stars,
    required this.wedding,
    required this.still,
    required this.onStar,
    required this.onWedding,
  });
  @override
  State<SkyExplorer> createState() => _SkyExplorerState();
}

class _SkyExplorerState extends State<SkyExplorer>
    with SingleTickerProviderStateMixin {
  final transform = TransformationController();
  late final AnimationController shimmer;
  Size? viewport;
  @override
  void initState() {
    super.initState();
    shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _animate();
  }

  void _animate() {
    if (widget.still) {
      shimmer.stop();
    } else {
      shimmer.repeat();
    }
  }

  @override
  void didUpdateWidget(SkyExplorer old) {
    super.didUpdateWidget(old);
    if (old.still != widget.still) _animate();
  }

  void center(Size size) {
    final scale = math.min(size.width, size.height) / 1120;
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (size.width - 1200 * scale) / 2,
        (size.height - 1200 * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  void dispose() {
    shimmer.dispose();
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = box.biggest;
      if (viewport != size) {
        viewport = size;
        center(size);
      }
      return ClipRect(
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: .9,
                    colors: [Color(0xFF193F37), skyNight],
                  ),
                ),
              ),
            ),
            InteractiveViewer(
              transformationController: transform,
              constrained: false,
              minScale: .1,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(300),
              child: SizedBox(
                width: 1200,
                height: 1200,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: SkyPainter(
                            stars: widget.stars,
                            wedding: widget.wedding,
                            shimmer: widget.still ? null : shimmer,
                          ),
                        ),
                      ),
                    ),
                    // Constant-size screen targets remain usable even when the sky is zoomed out.
                    AnimatedBuilder(
                      animation: transform,
                      builder: (context, _) => Stack(
                        children: [
                          for (final star in widget.stars)
                            _target(
                              Offset(star.x, star.y),
                              star.entry.text('title').isEmpty
                                  ? 'Ouvrir cet astre'
                                  : star.entry.text('title'),
                              () => widget.onStar(star.entry),
                              key: ValueKey(
                                'star-${star.entry.kind.name}-${star.entry.id}',
                              ),
                            ),
                          if (widget.wedding)
                            _target(
                              const Offset(600, 590),
                              'Notre constellation du 23 janvier',
                              widget.onWedding,
                              key: const ValueKey('wedding-star'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                tooltip: 'Recentrer le ciel',
                onPressed: () => center(size),
                icon: const Icon(
                  Icons.center_focus_strong_outlined,
                  color: Palette.gold,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  Widget _target(
    Offset point,
    String label,
    VoidCallback action, {
    required Key key,
  }) {
    final screen = point;
    final targetSize = 48 / transform.value.getMaxScaleOnAxis();
    return Positioned(
      left: screen.dx - targetSize / 2,
      top: screen.dy - targetSize / 2,
      width: targetSize,
      height: targetSize,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          key: key,
          behavior: HitTestBehavior.opaque,
          onTap: action,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _StarReading extends ConsumerWidget {
  final String id;
  final EntryKind kind;
  const _StarReading({required this.id, required this.kind});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = (ref.watch(entriesProvider).value ?? <Entry>[])
        .where((e) => e.id == id && e.kind == kind)
        .firstOrNull;
    if (entry == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Cet astre n’est plus disponible.'),
      );
    }
    final repo = ref.watch(repositoryProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final readable =
        kind == EntryKind.memory ||
        LoveSky.canReadLetter(
          entry,
          cloud: repo.isCloud,
          userId: repo.userId,
          now: now,
          demo: ref.watch(settingsProvider).demo,
        );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: GestureDetector(
        onLongPress: kind == EntryKind.memory
            ? () => showMemoryReactions(context, entry.id)
            : null,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Eyebrow(
                kind == EntryKind.memory
                    ? 'UNE ÉTOILE DE NOTRE HISTOIRE'
                    : 'DES MOTS DANS NOTRE CIEL',
              ),
              const SizedBox(height: 14),
              Text(
                entry.text('title'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (kind == EntryKind.memory &&
                  MemoryAlbum.photosOf(entry).isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AlbumCover(
                    photos: MemoryAlbum.photosOf(entry),
                    title: entry.text('title'),
                    memoryId: entry.id,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (kind == EntryKind.memory)
                MemoryReactionBar(memoryId: entry.id),
              if (readable)
                SelectableText(entry.text('body'))
              else
                const Column(
                  children: [
                    Icon(Icons.lock_outline, color: Palette.gold),
                    SizedBox(height: 12),
                    Text(
                      'Cette étoile garde encore son secret.\nTa lettre s’ouvrira au moment choisi.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
