import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/application/providers.dart';
import '../../../core/widgets/shared.dart';
import '../../../app/theme.dart';
import '../domain/wedding_clock.dart';
import '../domain/daily_thought.dart';
import 'wedding_journey.dart';
import 'countdown_carousel.dart';
import 'love_word_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _dailyPhotos = <String>[
    'asset:assets/images/home_1.jpg',
    'asset:assets/images/home_2.jpg',
    'asset:assets/images/home_3.jpg',
    'asset:assets/images/home_4.jpg',
    'asset:assets/images/home_5.jpg',
    'asset:assets/images/home_6.jpg',
    'asset:assets/images/home_7.jpg',
  ];

  static const _dailyBottomPhotos = <String>[
    'asset:assets/images/bottom_1.jpg',
    'asset:assets/images/bottom_2.jpg',
    'asset:assets/images/bottom_3.jpg',
    'asset:assets/images/bottom_4.jpg',
    'asset:assets/images/bottom_5.jpg',
    'asset:assets/images/bottom_6.jpg',
    'asset:assets/images/bottom_7.jpg',
  ];

  String _heroForDay(DateTime now) {
    final localDay = DateTime(now.year, now.month, now.day);
    final dayIndex =
        localDay.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return _dailyPhotos[dayIndex % _dailyPhotos.length];
  }

  String _bottomForDay(DateTime now) {
    final localDay = DateTime(now.year, now.month, now.day);
    final dayIndex =
        localDay.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return _dailyBottomPhotos[dayIndex % _dailyBottomPhotos.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final thought = dailyThoughtAt(now);
    final heroOfDay = _heroForDay(now);
    final bottomOfDay = _bottomForDay(now);
    final phase = s.phase == 'auto'
        ? phaseAt(now)
        : WeddingPhase.values.byName(s.phase);
    final count = countdownAt(now, phase);
    final after = phase == WeddingPhase.after, day = phase == WeddingPhase.day;
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height:
                math.max(740, MediaQuery.sizeOf(context).height * .74) *
                MediaQuery.textScalerOf(context).scale(1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Photo(heroOfDay),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x40243B32), Color(0xEE162C23)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${s.firstName.characters.first} — ${s.secondName.characters.first}',
                            style: const TextStyle(
                              color: Palette.ivory,
                              letterSpacing: 3,
                            ),
                          ),
                          const Icon(
                            Icons.local_florist_outlined,
                            color: Palette.gold,
                          ),
                          const Text(
                            '23·01·27',
                            style: TextStyle(
                              color: Palette.ivory,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (phase == WeddingPhase.week)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 22),
                          child: Text(
                            'Plus que quelques jours avant notre plus beau chapitre',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Palette.gold),
                          ),
                        ),
                      Eyebrow(
                        after
                            ? 'NOTRE HISTOIRE CONTINUE'
                            : 'LE DÉBUT DE NOTRE PLUS BELLE AVENTURE',
                        color: Palette.ivory,
                      ),
                      const SizedBox(height: 26),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          day
                              ? 'Ça y est,\nmon amour.'
                              : '${s.firstName.toUpperCase()}\n& ${s.secondName.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge!
                              .copyWith(color: Palette.ivory, fontSize: 48),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        day
                            ? 'Aujourd’hui, nous nous disons oui.'
                            : after
                            ? 'Depuis notre oui'
                            : '23 JANVIER 2027',
                        style: const TextStyle(
                          color: Palette.ivory,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (!day)
                        CountdownCarousel(
                          duration: count,
                          after: after,
                          reduceMotion: s.reduceMotion,
                        ),
                      const SizedBox(height: 26),
                      Text(
                        day
                            ? 'Pour toujours commence ici.'
                            : after
                            ? 'Notre plus belle aventure ne fait que commencer.'
                            : 'Encore un peu de patience, mon amour.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cormorant Garamond',
                          fontStyle: FontStyle.italic,
                          color: Palette.ivory,
                          fontSize: 21,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Palette.ivory,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Eyebrow('01   —   LA PENSÉE DU JOUR'),
                    const SizedBox(height: 20),
                    Paper(
                      color: Palette.cream,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_florist_outlined,
                            color: Palette.gold,
                            size: 32,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '« ${thought.text} »',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            thought.attribution,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: () => showReading(
                              context,
                              'La pensée du jour',
                              thought.reading,
                            ),
                            child: const Text('Découvrir  →'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    LoveWordCard(now: now),
                    const SizedBox(height: 28),
                    WeddingJourney(
                      now: now,
                      firstName: s.firstName,
                      secondName: s.secondName,
                      reduceMotion: s.reduceMotion,
                    ),
                    const SectionHeading(
                      'RIEN QU’À NOUS',
                      'Que veux-tu faire\naujourd’hui ?',
                      'Des mots, des souvenirs, des petits bonheurs.',
                    ),
                    for (final item in [
                      (Icons.mail_outline, 'Écrire une lettre', '/letters'),
                      (
                        Icons.photo_camera_outlined,
                        'Ajouter un souvenir',
                        '/story',
                      ),
                      (
                        Icons.auto_awesome_outlined,
                        'Notre surprise',
                        '/surprises',
                      ),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Paper(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(item.$1, color: Palette.forest),
                            title: Text(
                              item.$2,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            trailing: const Icon(Icons.arrow_forward, size: 20),
                            onTap: () => context.go(item.$3),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Photo(bottomOfDay, height: 280),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Un jour de moins à attendre,\nune vie entière à partager.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
