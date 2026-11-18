import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../domain/memory_game.dart';

class MemoryCard extends StatefulWidget {
  final String photo;
  final int number;
  final bool visible, matched, enabled, reduceMotion;
  final VoidCallback onTap;
  const MemoryCard({
    super.key,
    required this.photo,
    required this.number,
    required this.visible,
    required this.matched,
    required this.enabled,
    required this.reduceMotion,
    required this.onTap,
  });
  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: MemoryGame.flipDuration,
    value: widget.visible ? 1 : 0,
  );
  @override
  void didUpdateWidget(covariant MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion) {
      _turn.value = widget.visible ? 1 : 0;
    } else if (oldWidget.visible != widget.visible) {
      widget.visible ? _turn.forward() : _turn.reverse();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    onTap: widget.enabled ? widget.onTap : null,
    button: true,
    enabled: widget.enabled,
    label:
        'Carte ${widget.number}, ${widget.matched
            ? "paire retrouvée"
            : widget.visible
            ? "photo révélée"
            : "face cachée"}',
    child: ExcludeSemantics(
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) {
            final angle =
                Curves.easeInOutCubic.transform(_turn.value) * math.pi;
            final front = angle >= math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0015)
                ..rotateY(angle),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(front ? math.pi : 0),
                child: AnimatedContainer(
                  duration: widget.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(widget.matched ? 2.5 : 1),
                  decoration: BoxDecoration(
                    color: widget.matched
                        ? Palette.gold
                        : Palette.gold.withValues(alpha: .65),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.matched ? Palette.gold : Palette.forest)
                            .withValues(alpha: .12),
                        blurRadius: widget.matched ? 14 : 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: front
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                widget.photo,
                                fit: BoxFit.cover,
                                cacheWidth: 420,
                                errorBuilder: (_, _, _) => const ColoredBox(
                                  color: Palette.cream,
                                  child: Center(
                                    child: Icon(Icons.photo_outlined),
                                  ),
                                ),
                              ),
                              if (widget.matched)
                                Positioned(
                                  right: 5,
                                  bottom: 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Palette.ivory,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Palette.forest,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : const _CardBack(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _CardBack extends StatelessWidget {
  const _CardBack();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Palette.forest,
    child: CustomPaint(
      painter: _BotanicalBack(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'A & F',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Palette.gold,
                fontSize: 25,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BotanicalBack extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = Palette.gold.withValues(alpha: .4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(5),
        const Radius.circular(6),
      ),
      ink,
    );
    for (final lower in [false, true]) {
      canvas.save();
      canvas.translate(
        size.width / 2,
        lower ? size.height * .77 : size.height * .23,
      );
      if (lower) canvas.rotate(math.pi);
      canvas.drawPath(
        Path()
          ..moveTo(-14, 5)
          ..quadraticBezierTo(0, 2, 14, -5),
        ink,
      );
      for (var i = 0; i < 4; i++) {
        final x = -10 + i * 6.0;
        canvas.drawPath(
          Path()
            ..moveTo(x, 3 - i * 1.5)
            ..quadraticBezierTo(x - 6, -8, x + 1, -7)
            ..quadraticBezierTo(x + 4, -2, x, 3 - i * 1.5),
          ink,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
