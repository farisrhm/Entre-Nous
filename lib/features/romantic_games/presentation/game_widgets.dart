import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

String gameTime(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class GameVictory extends StatelessWidget {
  final String message;
  final bool still, compact;
  final Widget child;
  const GameVictory({
    super.key,
    required this.message,
    required this.still,
    this.compact = false,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: still ? Duration.zero : const Duration(milliseconds: 1400),
    builder: (context, value, _) => CustomPaint(
      painter: _GoldenDust(still ? 1 : value),
      child: Opacity(
        opacity: still ? 1 : (value * 3).clamp(0, 1),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 12 : 22),
          decoration: BoxDecoration(
            color: Palette.cream.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Palette.gold.withValues(alpha: .65)),
          ),
          child: Column(
            children: [
              if (!compact)
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: Palette.gold,
                  size: 24,
                ),
              if (!compact) const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: compact
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SizedBox(height: compact ? 5 : 16),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

class _GoldenDust extends CustomPainter {
  final double progress;
  _GoldenDust(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi * 2 / 16;
      final pos = Offset(
        size.width / 2 + math.cos(angle) * size.width * .48 * progress,
        size.height * .3 + math.sin(angle) * 60 * progress,
      );
      canvas.drawCircle(
        pos,
        1.2,
        Paint()..color = Palette.gold.withValues(alpha: (1 - progress) * .8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenDust old) => old.progress != progress;
}
