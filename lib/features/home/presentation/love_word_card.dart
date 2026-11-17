import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';
import '../domain/love_word.dart';

class LoveWordCard extends StatelessWidget {
  final DateTime now;
  const LoveWordCard({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final word = loveWordAt(now);
    return Paper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Eyebrow('LE MOT DU JOUR · ESPAGNOL')),
          const SizedBox(height: 16),
          Text(
            word.spanish,
            locale: const Locale('es'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(word.french, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Center(child: Container(width: 28, height: 1, color: Palette.gold)),
          const SizedBox(height: 14),
          Text(
            '« ${word.example} »',
            locale: const Locale('es'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
          TextButton(
            onPressed: () => showReading(
              context,
              word.spanish,
              '${word.french}\n\n${word.example}\n\n${word.translation}',
            ),
            child: const Text('Découvrir la traduction  →'),
          ),
        ],
      ),
    );
  }
}
