import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum MemoryLevel {
  gentle('Douce rencontre', 'Un premier sourire, trois souvenirs.', 3, 2),
  memories(
    'Nos souvenirs',
    'Six instants à retrouver du bout des doigts.',
    6,
    3,
  ),
  forever('Pour toujours', 'Huit souvenirs, une seule histoire.', 8, 4);

  const MemoryLevel(this.title, this.subtitle, this.pairs, this.columns);
  final String title, subtitle;
  final int pairs, columns;
}

/// A single, local game. No repository, account or network dependency.
class MemoryGame extends ChangeNotifier {
  MemoryGame(this.level, {Random? random}) : _random = random ?? Random() {
    restart();
  }
  static const flipDuration = Duration(milliseconds: 420);
  static const comparisonDuration = Duration(milliseconds: 800);
  static const photos = [
    'assets/images/home_1.jpg',
    'assets/images/home_2.jpg',
    'assets/images/home_3.jpg',
    'assets/images/home_4.jpg',
    'assets/images/home_5.jpg',
    'assets/images/home_6.jpg',
    'assets/images/home_7.jpg',
    'assets/images/home_8.jpg',
    'assets/images/home_9.jpg',
    'assets/images/home_10.jpg',
  ];
  final MemoryLevel level;
  final Random _random;
  List<String> _cards = [];
  List<String> get cards => List.unmodifiable(_cards);
  final Set<int> _matched = {};
  int? _first, _second;
  int moves = 0;
  bool busy = false;
  Timer? _timer;
  bool _disposed = false;
  int get foundPairs => _matched.length ~/ 2;
  bool get complete => foundPairs == level.pairs;
  bool isMatched(int index) => _matched.contains(index);
  bool isVisible(int index) =>
      isMatched(index) || index == _first || index == _second;

  void restart() {
    _timer?.cancel();
    final pool = [...photos]..shuffle(_random);
    final chosen = pool.take(level.pairs);
    _cards = [...chosen, ...chosen]..shuffle(_random);
    _matched.clear();
    _first = _second = null;
    moves = 0;
    busy = false;
    notifyListeners();
  }

  void _later(Duration delay, VoidCallback callback) {
    _timer?.cancel();
    if (delay == Duration.zero) {
      if (!_disposed) callback();
      return;
    }
    _timer = Timer(delay, () {
      if (!_disposed) callback();
    });
  }

  void select(int index, {bool reduceMotion = false}) {
    if (_disposed ||
        busy ||
        complete ||
        index < 0 ||
        index >= _cards.length ||
        isVisible(index)) {
      return;
    }
    final flip = reduceMotion ? Duration.zero : flipDuration;
    busy = true;
    if (_first == null) {
      _first = index;
      notifyListeners();
      _later(flip, () {
        busy = false;
        notifyListeners();
      });
      return;
    }
    _second = index;
    moves++;
    notifyListeners();
    _later(flip, () {
      if (_cards[_first!] == _cards[_second!]) {
        _matched.addAll([_first!, _second!]);
        _first = _second = null;
        busy = false;
        notifyListeners();
      } else {
        // Both photos remain fully visible for 800 ms after the second flip.
        _later(comparisonDuration, () {
          _first = _second = null;
          notifyListeners();
          _later(flip, () {
            busy = false;
            notifyListeners();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
