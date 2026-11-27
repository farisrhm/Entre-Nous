String gridWord(String text) {
  var result = text
      .trim()
      .toUpperCase()
      .replaceAll('Œ', 'OE')
      .replaceAll('Æ', 'AE');
  for (final entry in {
    'ÀÁÂÃÄÅ': 'A',
    'ÈÉÊË': 'E',
    'ÌÍÎÏ': 'I',
    'ÒÓÔÕÖ': 'O',
    'ÙÚÛÜ': 'U',
    'Ç': 'C',
    'Ñ': 'N',
    'ÝŸ': 'Y',
  }.entries) {
    for (final char in entry.key.split('')) {
      result = result.replaceAll(char, entry.value);
    }
  }
  return result.replaceAll(RegExp(r'[\s’\x27-]'), '');
}

class StoryWord {
  final String label, message;
  const StoryWord(this.label, this.message);
  String get letters => gridWord(label);
}

class WordTheme {
  final String id, title, description, finalMessage;
  final List<StoryWord> words;
  final bool reversed;
  const WordTheme({
    required this.id,
    required this.title,
    required this.description,
    required this.words,
    this.reversed = false,
    this.finalMessage = 'Parmi tous les mots du monde, mon préféré reste NOUS.',
  });
  String get signature =>
      '${reversed ? 1 : 0}:${words.map((w) => w.letters).join('|')}';
  static const catalog = [
    WordTheme(
      id: 'our-story-v1',
      title: 'Notre histoire',
      description: 'Les mots qui nous rapprochent.',
      words: [
        StoryWord('Amour', 'Un tout petit mot pour un sentiment immense.'),
        StoryWord('Sourire', 'Celui que j’aime retrouver chaque jour.'),
        StoryWord(
          'Complicité',
          'Nos regards se comprennent parfois sans un mot.',
        ),
        StoryWord(
          'Tendresse',
          'Dans les petites attentions se cachent les plus belles choses.',
        ),
        StoryWord(
          'Bonheur',
          'Il se glisse dans nos instants les plus simples.',
        ),
        StoryWord('Promesse', 'Prendre soin de ce que nous construisons.'),
        StoryWord('Ensemble', 'C’est mon mot préféré quand il parle de nous.'),
        StoryWord('Mariage', 'Une belle page à écrire à deux.'),
      ],
    ),
    WordTheme(
      id: 'small-joys-v1',
      title: 'Nos petits bonheurs',
      description: 'Les douceurs du quotidien.',
      words: [
        StoryWord('Rire', 'Un éclat de joie à partager.'),
        StoryWord('Câlin', 'Un endroit doux où se retrouver.'),
        StoryWord('Pause', 'Quelques minutes, rien que pour nous.'),
        StoryWord('Bisou', 'Une petite façon de dire beaucoup.'),
        StoryWord('Douceur', 'Faire une place à la tendresse.'),
        StoryWord('Joie', 'La laisser grandir, tout simplement.'),
      ],
    ),
    WordTheme(
      id: 'our-dreams-v1',
      title: 'Nos rêves',
      description: 'Des envies à lire dans tous les sens.',
      reversed: true,
      words: [
        StoryWord('Voyage', 'Il reste tant de chemins à découvrir.'),
        StoryWord('Maison', 'Un lieu à remplir de notre douceur.'),
        StoryWord('Horizon', 'Regarder demain côte à côte.'),
        StoryWord('Aventure', 'Oser écrire la suite ensemble.'),
        StoryWord('Étoile', 'Garder une petite lumière pour nos rêves.'),
        StoryWord('Avenir', 'L’imaginer avec toi.'),
      ],
    ),
    WordTheme(
      id: 'wedding-day-v1',
      title: 'Jusqu’au grand jour',
      description: 'Les mots d’un nouveau chapitre.',
      reversed: true,
      words: [
        StoryWord('Alliance', 'Un cercle pour raconter notre lien.'),
        StoryWord('Oui', 'Trois lettres pour ouvrir une vie.'),
        StoryWord('Fleurs', 'Un peu de beauté pour ce qui commence.'),
        StoryWord('Danse', 'Trouver notre rythme à deux.'),
        StoryWord('Émotion', 'Accueillir ce qui fait battre nos cœurs.'),
        StoryWord('Nous', 'Notre plus joli commencement.'),
      ],
    ),
  ];
}
