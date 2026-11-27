import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../domain/word_search_game.dart';

/// A single gesture surface keeps a drag stable across cell boundaries.
/// Two taps (or accessibility actions) also select the endpoints of a word.
class WordGrid extends StatefulWidget {
  final WordSearchGame game;
  final ValueChanged<List<int>> onSelection;
  final int? hint;
  final bool still;
  const WordGrid({
    super.key,
    required this.game,
    required this.onSelection,
    this.hint,
    this.still = false,
  });
  @override
  State<WordGrid> createState() => _WordGridState();
}

class _WordGridState extends State<WordGrid> {
  int? anchor, pendingStart;
  bool dragging = false;
  List<int> selection = [];
  @override
  void didUpdateWidget(WordGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      anchor = null;
      selection = [];
    }
  }

  int? cell(Offset p, double extent) {
    if (p.dx < 0 || p.dy < 0 || p.dx >= extent || p.dy >= extent) return null;
    return (p.dy / (extent / widget.game.side)).floor() * widget.game.side +
        (p.dx / (extent / widget.game.side)).floor();
  }

  void start(int? i) {
    if (widget.game.complete) return;
    setState(() {
      anchor = i;
      selection = i == null ? [] : [i];
    });
  }

  void extend(int? i) {
    if (anchor == null) return;
    setState(
      () => selection = i == null ? [] : wordLine(anchor!, i, widget.game.side),
    );
  }

  void finish() {
    final path = List<int>.of(selection);
    setState(() {
      anchor = null;
      selection = [];
    });
    if (path.length > 1) widget.onSelection(path);
  }

  void tap(int i) {
    if (widget.game.complete) return;
    if (anchor == null) {
      start(i);
    } else {
      extend(i);
      finish();
    }
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.maxWidth,
            side = widget.game.side,
            found = widget.game.foundCells;
        return GestureDetector(
          key: const ValueKey('word-grid-gestures'),
          behavior: HitTestBehavior.opaque,
          onPanDown: widget.game.complete
              ? null
              : (d) {
                  pendingStart = cell(d.localPosition, extent);
                  setState(
                    () =>
                        selection = pendingStart == null ? [] : [pendingStart!],
                  );
                },
          onPanStart: widget.game.complete
              ? null
              : (d) {
                  dragging = true;
                  start(pendingStart);
                  extend(cell(d.localPosition, extent));
                },
          onTapUp: widget.game.complete
              ? null
              : (d) {
                  final i = cell(d.localPosition, extent);
                  if (i != null) tap(i);
                },
          onPanUpdate: widget.game.complete
              ? null
              : (d) => extend(cell(d.localPosition, extent)),
          onPanEnd: widget.game.complete
              ? null
              : (_) {
                  dragging = false;
                  finish();
                },
          onPanCancel: () => setState(() {
            if (dragging) anchor = null;
            dragging = false;
            selection = anchor == null ? [] : [anchor!];
          }),
          child: Container(
            decoration: BoxDecoration(
              color: Palette.cream.withValues(alpha: .4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Palette.gold.withValues(alpha: .55)),
            ),
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                for (var i = 0; i < side * side; i++)
                  Positioned(
                    left: i % side * extent / side,
                    top: i ~/ side * extent / side,
                    width: extent / side,
                    height: extent / side,
                    child: Semantics(
                      button: !widget.game.complete,
                      label:
                          '${widget.game.letters[i]}, ligne ${i ~/ side + 1}, colonne ${i % side + 1}',
                      selected: selection.contains(i) || found.contains(i),
                      onTap: () => tap(i),
                      child: AnimatedContainer(
                        key: ValueKey('letter-$i'),
                        duration: widget.still
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: selection.contains(i)
                              ? Palette.gold
                              : found.contains(i)
                              ? Palette.forest
                              : widget.hint == i
                              ? Palette.gold.withValues(alpha: .6)
                              : Colors.transparent,
                          border: Border.all(
                            color: widget.hint == i
                                ? Palette.gold
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.game.letters[i],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      found.contains(i) &&
                                          !selection.contains(i)
                                      ? Palette.ivory
                                      : Palette.forest,
                                ),
                              ),
                            ),
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
    ),
  );
}
