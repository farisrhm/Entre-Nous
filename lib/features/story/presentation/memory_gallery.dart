import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';

Future<void> showMemoryGallery(
  BuildContext context,
  List<String> photos,
  String title, {
  int initialIndex = 0,
}) {
  if (photos.isEmpty) return Future.value();
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => MemoryGallery(
        photos: photos,
        title: title,
        initialIndex: initialIndex,
      ),
    ),
  );
}

class MemoryGallery extends StatefulWidget {
  final List<String> photos;
  final String title;
  final int initialIndex;
  const MemoryGallery({
    super.key,
    required this.photos,
    required this.title,
    this.initialIndex = 0,
  });
  @override
  State<MemoryGallery> createState() => _MemoryGalleryState();
}

class _MemoryGalleryState extends State<MemoryGallery> {
  late final PageController controller;
  late int index;
  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    controller = PageController(initialPage: index);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.forest,
    appBar: AppBar(
      backgroundColor: Palette.forest,
      leading: IconButton(
        tooltip: 'Fermer l’album',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      foregroundColor: Palette.ivory,
      title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Photo(widget.photos[i], fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Photo précédente',
                color: Palette.ivory,
                onPressed: index == 0
                    ? null
                    : () => controller.jumpToPage(index - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  '${index + 1} / ${widget.photos.length}',
                  style: const TextStyle(color: Palette.ivory),
                ),
              ),
              IconButton(
                tooltip: 'Photo suivante',
                color: Palette.ivory,
                onPressed: index == widget.photos.length - 1
                    ? null
                    : () => controller.jumpToPage(index + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Fais défiler · pince pour agrandir',
              style: TextStyle(color: Palette.ivory, fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

class AlbumCover extends StatefulWidget {
  final List<String> photos;
  final String title;
  const AlbumCover({super.key, required this.photos, required this.title});
  @override
  State<AlbumCover> createState() => _AlbumCoverState();
}

class _AlbumCoverState extends State<AlbumCover> {
  int index = 0;
  @override
  void didUpdateWidget(covariant AlbumCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.photos, widget.photos)) index = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) return const Photo('', height: 230);
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            key: ValueKey(Object.hashAll(widget.photos)),
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (_, i) => Semantics(
              label: 'Ouvrir la photo ${i + 1} de ${widget.title}',
              button: true,
              child: GestureDetector(
                onTap: () => showMemoryGallery(
                  context,
                  widget.photos,
                  widget.title,
                  initialIndex: i,
                ),
                child: Photo(widget.photos[i], height: 280),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Palette.forest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${index + 1} / ${widget.photos.length}',
                  style: const TextStyle(color: Palette.ivory, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
