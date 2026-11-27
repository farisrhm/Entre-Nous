import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';
import '../../../core/widgets/shared.dart';
import '../data/game_store.dart';
import '../data/puzzle_photos.dart';
import '../domain/puzzle_game.dart';
import 'game_widgets.dart';
import 'puzzle_board.dart';

class PuzzlePage extends ConsumerStatefulWidget {
  const PuzzlePage({super.key});
  @override
  ConsumerState<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends ConsumerState<PuzzlePage> {
  PuzzleLevel level = PuzzleLevel.easy;
  List<PuzzlePhoto> personal = [];
  bool importing = false;
  String? loadError;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final photos = await PuzzlePhotos(ref.read(gameStoreProvider)).load();
      if (mounted) {
        setState(() {
          personal = photos;
          loadError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => loadError = 'Tes photos locales n’ont pas pu être chargées.',
        );
      }
    }
  }

  Future<void> import() async {
    if (importing) return;
    setState(() => importing = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (photo == null || !mounted) return;
      final label = await showDialog<String>(
        context: context,
        builder: (_) => const _PhotoTitleDialog(),
      );
      if (label == null || !mounted) return;
      await PuzzlePhotos(
        ref.read(gameStoreProvider),
      ).add(await photo.readAsBytes(), label);
      if (mounted) await load();
    } catch (_) {
      if (mounted) {
        showError(
          context,
          'Cette photo ne peut pas être ajoutée. Choisis une image JPEG ou PNG de moins de 20 Mo.',
        );
      }
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  Future<void> play(PuzzlePhoto photo) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzlePlayPage(photo: photo, level: level),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gameStoreProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Le Puzzle de nos souvenirs',
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
            const Eyebrow('LES MORCEAUX DE NOUS'),
            const SizedBox(height: 10),
            Text(
              'Un instant\nà recomposer.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text('Chaque morceau nous rapproche d’un joli souvenir.'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in PuzzleLevel.values)
                  ChoiceChip(
                    label: Text('${l.label} · ${l.side} × ${l.side}'),
                    selected: level == l,
                    onSelected: (_) => setState(() => level = l),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: importing ? null : import,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(importing ? 'Préparation…' : 'Ajouter ma photo'),
            ),
            const Text(
              'Les photos ajoutées et les parties restent sur ce téléphone.',
              style: TextStyle(fontSize: 12),
            ),
            if (loadError != null)
              TextButton(onPressed: load, child: Text('$loadError Réessayer')),
            const SizedBox(height: 20),
            for (final photo in [...PuzzlePhoto.catalog, ...personal])
              Builder(
                builder: (context) {
                  final saved = store.read(store.puzzleKey(photo.id, level));
                  final raw = saved?['game'];
                  final game = PuzzleGame.restore(
                    level,
                    raw is Map ? Map<String, dynamic>.from(raw) : null,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Palette.cream.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Palette.gold.withValues(alpha: .5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 190,
                            child: photo.isAsset
                                ? Image.asset(
                                    photo.source,
                                    fit: BoxFit.cover,
                                    cacheWidth: 750,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Text('Photo indisponible'),
                                    ),
                                  )
                                : Image.file(
                                    File(photo.source),
                                    fit: BoxFit.cover,
                                    cacheWidth: 750,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Text('Photo locale introuvable'),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  photo.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${level.label} · ${level.side * level.side} pièces',
                                ),
                                if (game != null)
                                  Text(
                                    game.complete
                                        ? 'Souvenir reconstitué'
                                        : '${game.correct} / ${game.tiles.length} pièces à leur place',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                if (saved?['bestMs'] is int)
                                  Text(
                                    'Meilleur temps : ${gameTime(saved!['bestMs'] as int)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                if (saved?['bestMoves'] is int)
                                  Text(
                                    'Minimum : ${saved!['bestMoves']} mouvements',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                const SizedBox(height: 10),
                                FilledButton(
                                  onPressed: () => play(photo),
                                  child: Text(
                                    game != null && !game.complete
                                        ? 'Reprendre'
                                        : 'Jouer',
                                  ),
                                ),
                                if (!photo.isAsset)
                                  TextButton(
                                    onPressed: () async {
                                      final yes = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Retirer cette photo du jeu ?',
                                          ),
                                          content: const Text(
                                            'La photo originale de ta photothèque sera conservée.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Garder'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Retirer'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (yes == true) {
                                        try {
                                          await PuzzlePhotos(
                                            store,
                                          ).remove(photo);
                                          if (mounted) await load();
                                        } catch (_) {
                                          if (context.mounted) {
                                            showError(
                                              context,
                                              'Impossible de retirer cette photo.',
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: const Text('Retirer du jeu'),
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
          ],
        ),
      ),
    );
  }
}

class PuzzlePlayPage extends ConsumerStatefulWidget {
  final PuzzlePhoto photo;
  final PuzzleLevel level;
  const PuzzlePlayPage({super.key, required this.photo, required this.level});
  @override
  ConsumerState<PuzzlePlayPage> createState() => _PuzzlePlayPageState();
}

class _PuzzlePlayPageState extends ConsumerState<PuzzlePlayPage>
    with WidgetsBindingObserver {
  late final GameStore store;
  late PuzzleGame game;
  ui.Image? image;
  String? error, saveError;
  int? selected;
  bool swapping = false, preview = false, foreground = true;
  Timer? clockTimer, flipTimer, previewTimer;
  final watch = Stopwatch();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store = ref.read(gameStoreProvider);
    final raw = store.read(
      store.puzzleKey(widget.photo.id, widget.level),
    )?['game'];
    game =
        PuzzleGame.restore(
          widget.level,
          raw is Map ? Map<String, dynamic>.from(raw) : null,
        ) ??
        PuzzleGame.start(widget.level);
    unawaited(loadImage());
    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && watch.isRunning) {
        setState(tick);
        if (game.elapsedMs ~/ 1000 % 5 == 0) unawaited(save());
      }
    });
  }

  void tick() {
    game.elapsedMs += watch.elapsedMilliseconds;
    watch.reset();
  }

  Future<void> loadImage() async {
    setState(() => error = null);
    try {
      final bytes = widget.photo.isAsset
          ? (await rootBundle.load(widget.photo.source)).buffer.asUint8List()
          : await File(widget.photo.source).readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1200,
        allowUpscaling: false,
      );
      late ui.Image decoded;
      try {
        decoded = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      if (!mounted) {
        decoded.dispose();
        return;
      }
      setState(() => image = decoded);
      if (!game.complete && foreground) watch.start();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Cette photographie ne peut pas être ouverte.');
      }
    }
  }

  Future<void> save() async {
    try {
      await store.savePuzzle(widget.photo.id, game);
      if (mounted && saveError != null) setState(() => saveError = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => saveError =
              'La partie n’a pas pu être sauvegardée sur ce téléphone.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground) {
      tick();
      watch.stop();
      unawaited(save());
    } else if (!game.complete && image != null) {
      watch.start();
    }
  }

  void choose(int index, bool still) {
    if (swapping || preview || game.complete) return;
    if (selected == null) {
      setState(() => selected = index);
      return;
    }
    if (selected == index) {
      setState(() => selected = null);
      return;
    }
    tick();
    final first = selected!;
    setState(() {
      game.swap(first, index);
      selected = null;
      swapping = !still;
    });
    if (game.complete) watch.stop();
    unawaited(save());
    flipTimer?.cancel();
    if (!still) {
      flipTimer = Timer(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => swapping = false);
      });
    }
  }

  void reset() {
    flipTimer?.cancel();
    previewTimer?.cancel();
    watch.stop();
    watch.reset();
    setState(() {
      game = PuzzleGame.start(widget.level);
      selected = null;
      swapping = false;
      preview = false;
    });
    if (image != null && foreground) watch.start();
    unawaited(save());
  }

  @override
  void dispose() {
    tick();
    watch.stop();
    unawaited(save());
    clockTimer?.cancel();
    flipTimer?.cancel();
    previewTimer?.cancel();
    image?.dispose();
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
          widget.photo.title,
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
                  const Eyebrow('CHAQUE PIÈCE NOUS RAPPROCHE'),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.level.label} · ${widget.level.side} × ${widget.level.side}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Touche une pièce, puis une autre pour les échanger.',
                  ),
                  const SizedBox(height: 22),
                  if (error != null) ...[
                    Text(error!),
                    TextButton(
                      onPressed: loadImage,
                      child: const Text('Réessayer'),
                    ),
                  ] else if (image == null)
                    const SizedBox(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    AnimatedContainer(
                      duration: still
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: selected != null
                              ? Palette.gold
                              : Palette.gold.withValues(alpha: .35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.gold.withValues(
                              alpha: swapping ? .22 : .06,
                            ),
                            blurRadius: swapping ? 18 : 6,
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: still
                            ? Duration.zero
                            : const Duration(milliseconds: 600),
                        child: game.complete && !swapping
                            ? ClipRRect(
                                key: const ValueKey('completed-photo'),
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio: image!.width / image!.height,
                                  child: RawImage(
                                    image: image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : preview
                            ? AspectRatio(
                                aspectRatio: 1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: RawImage(
                                    image: image,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : PuzzleBoard(
                                game: game,
                                image: image!,
                                selected: selected,
                                locked: swapping,
                                still: still,
                                onSelect: (i) => choose(i, still),
                              ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    '${gameTime(game.elapsedMs)} · ${game.moves} mouvements',
                    textAlign: TextAlign.center,
                  ),
                  if (saveError != null)
                    TextButton(
                      onPressed: save,
                      child: Text('$saveError Réessayer'),
                    ),
                  if (game.complete && !swapping) ...[
                    const SizedBox(height: 18),
                    GameVictory(
                      message: widget.photo.victory,
                      still: still,
                      child: Column(
                        children: [
                          FilledButton(
                            onPressed: reset,
                            child: const Text('Rejouer'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Choisir un autre souvenir'),
                          ),
                          TextButton(
                            onPressed: () => context.go('/universe/games'),
                            child: const Text('Retour aux jeux'),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      children: [
                        TextButton.icon(
                          onPressed: image == null || preview || swapping
                              ? null
                              : () {
                                  setState(() {
                                    preview = true;
                                    selected = null;
                                  });
                                  previewTimer?.cancel();
                                  previewTimer = Timer(
                                    const Duration(seconds: 3),
                                    () {
                                      if (mounted) {
                                        setState(() => preview = false);
                                      }
                                    },
                                  );
                                },
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: Text(
                            preview ? 'Un instant…' : 'Voir la photo',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: reset,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Recommencer'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTitleDialog extends StatefulWidget {
  const _PhotoTitleDialog();
  @override
  State<_PhotoTitleDialog> createState() => _PhotoTitleDialogState();
}

class _PhotoTitleDialogState extends State<_PhotoTitleDialog> {
  final title = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Un nom pour cette photo'),
    content: TextField(
      controller: title,
      maxLength: 60,
      decoration: const InputDecoration(hintText: 'Ma photographie'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, title.text),
        child: const Text('Ajouter'),
      ),
    ],
  );
}
