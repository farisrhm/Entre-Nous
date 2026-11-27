import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../domain/attention.dart';

const attentionIcons = <String, IconData>{
  'heart': Icons.favorite_border,
  'coffee': Icons.coffee_outlined,
  'moon': Icons.nightlight_outlined,
  'flower': Icons.local_florist_outlined,
  'gift': Icons.card_giftcard,
};

class AttentionVoucherCard extends StatelessWidget {
  final AttentionVoucher voucher;
  final String senderName;
  const AttentionVoucherCard({
    super.key,
    required this.voucher,
    required this.senderName,
  });
  @override
  Widget build(BuildContext context) {
    final dark = voucher.text('theme_key') == 'forest';
    final ink = dark ? Palette.ivory : Palette.forest;
    final background = switch (voucher.text('theme_key')) {
      'forest' => Palette.forest,
      'sage' => const Color(0xFFDCE3D5),
      _ => Palette.cream,
    };
    return CustomPaint(
      foregroundPainter: _TicketEdge(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Palette.gold.withValues(alpha: .7)),
          boxShadow: [
            BoxShadow(
              color: Palette.brown.withValues(alpha: .05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  attentionIcons[voucher.text('icon_key')] ??
                      Icons.favorite_border,
                  color: dark ? Palette.gold : ink,
                  size: 26,
                ),
                const Spacer(),
                Icon(
                  Icons.spa_outlined,
                  color: Palette.gold.withValues(alpha: .65),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              voucher.text('title'),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: ink),
            ),
            const SizedBox(height: 10),
            Text(voucher.text('description'), style: TextStyle(color: ink)),
            if (voucher.text('personal_message').isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '« ${voucher.text('personal_message')} »',
                style: TextStyle(color: ink, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 24),
            Divider(color: Palette.gold.withValues(alpha: .4)),
            const SizedBox(height: 8),
            Text(
              'OFFERT AVEC AMOUR',
              style: TextStyle(
                color: ink.withValues(alpha: .8),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            if (senderName.isNotEmpty)
              Text(
                senderName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: ink),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketEdge extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Palette.ivory;
    for (final x in [0.0, s.width]) {
      c.drawCircle(Offset(x, s.height * .72), 7, p);
      c.drawArc(
        Rect.fromCircle(center: Offset(x, s.height * .72), radius: 7),
        x == 0 ? -1.5708 : 1.5708,
        3.1416,
        false,
        Paint()
          ..color = Palette.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AttentionEnvelope extends StatelessWidget {
  final String senderName;
  final VoidCallback? onTap;
  const AttentionEnvelope({super.key, required this.senderName, this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: 'Une attention à découvrir de $senderName',
    child: Material(
      color: Palette.forest,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: Palette.gold),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Icon(Icons.mail_outline, color: Palette.gold, size: 42),
              const SizedBox(height: 12),
              Text(
                'Une douceur t’attend',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Palette.ivory),
              ),
              const SizedBox(height: 8),
              Text(
                senderName.isEmpty
                    ? 'Offert avec amour'
                    : 'De $senderName, avec amour',
                style: const TextStyle(color: Palette.ivory),
              ),
              const SizedBox(height: 12),
              const Text(
                'DÉCOUVRIR',
                style: TextStyle(
                  color: Palette.gold,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AttentionStatusIndicator extends StatelessWidget {
  final AttentionVoucher voucher;
  const AttentionStatusIndicator({super.key, required this.voucher});
  @override
  Widget build(BuildContext context) => Text(
    voucher.statusLabel,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Palette.forest,
      fontWeight: FontWeight.w600,
    ),
  );
}
