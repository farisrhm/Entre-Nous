import 'paris_calendar.dart';

class DailyThought {
  final String text, author, work, reflection;

  /// Verified transcription of the public-domain work, absent for original text.
  final String? source;
  const DailyThought(
    this.text,
    this.reflection, {
    this.author = 'Jusqu’à Nous',
    this.work = 'Pensée originale',
    this.source,
  });
  String get attribution => '$author · $work';
  String get reading =>
      '« $text »\n\n$attribution\n\nUn petit mot pour nous\n$reflection';
}

const _hugo =
    'https://fr.wikisource.org/wiki/Les_Misérables/Tome_4/Livre_05/04';
const _verlaine =
    'https://fr.wikisource.org/wiki/Page:Verlaine_-_La_Bonne_Chanson,_1891.djvu/45';
const _baudelaire =
    'https://fr.wikisource.org/wiki/Les_Fleurs_du_mal/1861/L’Invitation_au_voyage';

/// Ordered, offline collection. Only original texts and public-domain excerpts.
/// Reflections are original app text, never attributed to the quoted writer.
const dailyThoughts = <DailyThought>[
  DailyThought(
    'Quelle grande chose, être aimé ! Quelle chose plus grande encore, aimer !',
    'Je veux apprendre chaque jour à te montrer cet amour, même dans les gestes les plus simples.',
    author: 'Victor Hugo',
    work: 'Les Misérables · IV, V, 4',
    source: _hugo,
  ),
  DailyThought(
    'Le plus beau de ma journée tient parfois dans le simple fait de te la raconter.',
    'Les grandes nouvelles et les petits riens : tout prend une autre couleur quand je peux le partager avec toi.',
  ),
  DailyThought(
    'Je ne compte plus seulement les jours. Je compte les matins que nous aurons ensemble.',
    'Un café encore chaud, une fenêtre ouverte, ta présence. Voilà aussi ce que j’attends de notre avenir.',
  ),
  DailyThought(
    'Nos deux cœurs, exhalant leur tendresse paisible,\nSeront deux rossignols qui chantent dans le soir.',
    'J’aime imaginer une vie où nous saurons nous retrouver, même après les journées les plus bruyantes.',
    author: 'Paul Verlaine',
    work: 'La Bonne Chanson · XVII',
    source: _verlaine,
  ),
  DailyThought(
    'Avec toi, même un jour ordinaire mérite une place dans mes souvenirs.',
    'Il n’y aura pas toujours une occasion à célébrer. Mais il y aura nous, et tant de façons de rendre un mardi précieux.',
  ),
  DailyThought(
    'Je veux connaître les chemins qui te rassurent et les emprunter avec toi.',
    'Aimer, pour nous, ce sera aussi écouter sans se presser et laisser à l’autre la place d’être lui-même.',
  ),
  DailyThought(
    'Songe à la douceur\nD’aller là-bas vivre ensemble !',
    'Notre ailleurs peut être tout près : une maison qui nous ressemble, des habitudes à inventer et de la place pour nos rêves.',
    author: 'Charles Baudelaire',
    work: 'Les Fleurs du mal · L’Invitation au voyage (extrait)',
    source: _baudelaire,
  ),
  DailyThought(
    'Il y a dans ta voix quelque chose qui me donne envie de rentrer.',
    'Où que la journée m’emmène, j’aime savoir qu’au bout, il peut y avoir quelques mots de toi.',
  ),
  DailyThought(
    'La place à côté de moi a déjà ton prénom.',
    'Dans les voyages que j’imagine, dans les repas qui s’éternisent, dans les années à venir : je te fais une place.',
  ),
  DailyThought(
    'L’amour est assez puissant pour charger la nature entière de ses messages.',
    'Aujourd’hui, je pourrais te dire que je t’aime avec une lumière sur le mur, une fleur aperçue ou une photo envoyée sans raison.',
    author: 'Victor Hugo',
    work: 'Les Misérables · IV, V, 4',
    source: _hugo,
  ),
  DailyThought(
    'Je garderai de la douceur pour toi, même les jours où le monde en manque.',
    'Nous n’aurons pas toutes les réponses. Nous pourrons pourtant nous parler avec tendresse et chercher la suite ensemble.',
  ),
  DailyThought(
    'Ton rire est un endroit où j’aimerais rester un peu plus longtemps.',
    'J’espère que notre maison gardera l’écho de toutes les petites choses qui nous font rire, même celles que nous seuls comprenons.',
  ),
  DailyThought(
    'Nous serons fiers parfois et toujours indulgents.',
    'Que notre amour nous laisse le droit d’apprendre, de nous tromper, puis de revenir l’un vers l’autre.',
    author: 'Paul Verlaine',
    work: 'La Bonne Chanson · XVII',
    source: _verlaine,
  ),
  DailyThought(
    'Chaque jour qui passe nous laisse un peu moins à attendre et un peu plus à raconter.',
    'Le chemin jusqu’à nous fait déjà partie de notre histoire. Je veux aussi me souvenir de cette attente.',
  ),
  DailyThought(
    'Je voudrais apprendre par cœur les petites choses qui te rendent heureux.',
    'Une attention juste, ton plat préféré, le bon mot au bon moment : notre amour pourra se cacher dans ces détails.',
  ),
  DailyThought(
    'Ô printemps ! tu es une lettre que je lui écris.',
    'Si je pouvais glisser une saison dans une enveloppe, je choisirais celle qui te fait sourire.',
    author: 'Victor Hugo',
    work: 'Les Misérables · IV, V, 4',
    source: _hugo,
  ),
  DailyThought(
    'Nous aurons des souvenirs dont nous ne connaissons pas encore la lumière.',
    'Des rues où nous n’avons jamais marché, des dimanches encore blancs. J’aime qu’il reste tant de premières fois avec toi.',
  ),
  DailyThought(
    'Ta main dans la mienne, et le chemin devient une invitation.',
    'Nous n’avons pas besoin de savoir exactement où tout mène pour choisir de faire le prochain pas ensemble.',
  ),
  DailyThought(
    'Là, tout n’est qu’ordre et beauté,\nLuxe, calme et volupté.',
    'Notre luxe à nous pourrait être du temps : un soir sans hâte, une promenade, la joie de n’avoir nulle part ailleurs où être.',
    author: 'Charles Baudelaire',
    work: 'Les Fleurs du mal · L’Invitation au voyage',
    source: _baudelaire,
  ),
  DailyThought(
    'Je t’aime aussi dans les silences où nous n’avons rien à prouver.',
    'Parfois, être là suffit. Lire près de toi, regarder la pluie, partager le calme sans chercher à le remplir.',
  ),
  DailyThought(
    'Notre avenir commence dans la façon dont nous prenons soin de nous aujourd’hui.',
    'Un mot patient, un merci sincère, une attention : les fondations de notre foyer se construisent déjà.',
  ),
  DailyThought(
    'S’il n’y avait pas quelqu’un qui aime, le soleil s’éteindrait.',
    'Il y a des jours que ta présence éclaire à elle seule. J’aimerais pouvoir t’offrir la même lumière.',
    author: 'Victor Hugo',
    work: 'Les Misérables · IV, V, 4',
    source: _hugo,
  ),
  DailyThought(
    'Je veux des années avec toi, et du temps pour les savourer.',
    'Ne pas courir à travers notre histoire. Nous arrêter parfois, regarder ce que nous avons construit, et nous en réjouir.',
  ),
  DailyThought(
    'Un jour, nous dirons : tu te souviens, quand nous attendions tout cela ?',
    'Et nous sourirons à ceux que nous étions : impatients, amoureux, déjà en train de devenir nous.',
  ),
  DailyThought(
    'Il y a mille façons de dire je t’aime. Aujourd’hui, je chercherai celle dont tu as besoin.',
    'Peut-être une parole, un peu d’aide, une présence tranquille. Je veux continuer à te découvrir.',
  ),
  DailyThought(
    'Je te choisis dans les grands projets comme dans les petites habitudes.',
    'Partager une vie, ce sera aussi se demander ce qu’on mange, ouvrir les volets et garder le dernier morceau pour l’autre.',
  ),
  DailyThought(
    'J’aime l’idée que nos plus beaux souvenirs n’existent pas encore.',
    'Nous en avons déjà de précieux. Et devant nous, il reste tant de pages où poser nos deux prénoms.',
  ),
  DailyThought(
    'Que notre maison soit un endroit où chacun peut déposer sa fatigue.',
    'Un foyer accueillant pour nos joies, nos doutes et nos rêves. Un lieu où la tendresse trouve toujours une place.',
  ),
  DailyThought(
    'La distance entre deux rendez-vous se mesure aussi en pensées pour toi.',
    'Une chanson, une rue, un parfum : tant de petits détours ramènent ma journée vers toi.',
  ),
  DailyThought(
    'Je ne veux pas seulement vivre de beaux moments avec toi. Je veux savoir les reconnaître.',
    'Nous souvenir de lever les yeux, de nous dire merci, de prendre une photo parfois, et de profiter de l’instant.',
  ),
  DailyThought(
    'Parmi toutes les histoires possibles, ma préférée est celle que nous écrivons ensemble.',
    'Et si je devais tout recommencer, j’aimerais retrouver ton rire, nos conversations et ce moment où nous sommes devenus nous.',
  ),
];

DailyThought dailyThoughtAt(DateTime now) {
  final day = parisCalendarDay(now);
  final offset = day.difference(DateTime.utc(2026, 11, 16)).inDays;
  return dailyThoughts[offset % dailyThoughts.length];
}
