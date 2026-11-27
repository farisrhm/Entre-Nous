import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../domain/puzzle_game.dart';

class PuzzleBoard extends StatelessWidget {
  final PuzzleGame game;
  final ui.Image image;
  final int? selected;
  final bool locked, still;
  final ValueChanged<int> onSelect;
  const PuzzleBoard({
    super.key,
    required this.game,
    required this.image,
    required this.selected,
    required this.locked,
    required this.still,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cell = box.maxWidth / game.level.side;
      return SizedBox(
        height: box.maxWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              for (final id in game.tiles)
                AnimatedPositioned(
                  key: ValueKey('piece-$id'),
                  duration: still
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  left: game.tiles.indexOf(id) % game.level.side * cell,
                  top: game.tiles.indexOf(id) ~/ game.level.side * cell,
                  width: cell,
                  height: cell,
                  child: Semantics(
                    button: true,
                    selected: selected == game.tiles.indexOf(id),
                    label:
                        'Pièce ${id + 1}, case ${game.tiles.indexOf(id) + 1}',
                    child: GestureDetector(
                      onTap: locked
                          ? null
                          : () => onSelect(game.tiles.indexOf(id)),
                      child: CustomPaint(
                        painter: _PiecePainter(image, id, game.level.side),
                        foregroundPainter: _PieceBorder(
                          selected == game.tiles.indexOf(id),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _PiecePainter extends CustomPainter {
  final ui.Image image;
  final int id, side;
  _PiecePainter(this.image, this.id, this.side);
  @override
  void paint(Canvas canvas, Size size) {
    // One shared square crop for every fragment. Never independently fit pieces.
    final edge = math.min(image.width, image.height).toDouble();
    final unit = edge / side;
    final source = Rect.fromLTWH(
      (image.width - edge) / 2 + (id % side) * unit,
      (image.height - edge) / 2 + (id ~/ side) * unit,
      unit,
      unit,
    );
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) =>
      old.image != image || old.id != id || old.side != side;
}

class _PieceBorder extends CustomPainter {
  final bool selected;
  _PieceBorder(this.selected);
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    (Offset.zero & size).deflate(selected ? 1.5 : .4),
    Paint()
      ..color = (selected ? Palette.gold : Palette.ivory.withValues(alpha: .45))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (selected ? 3 : .8),
  );
  @override
  bool shouldRepaint(covariant _PieceBorder old) => old.selected != selected;
}
