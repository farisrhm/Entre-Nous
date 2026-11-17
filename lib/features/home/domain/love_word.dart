import 'paris_calendar.dart';

/// Original example sentences; articles clarify the gender of Spanish nouns.
class LoveWord {
  final String spanish, french, example, translation;
  const LoveWord(this.spanish, this.french, this.example, this.translation);
}

const loveWords = <LoveWord>[
  LoveWord(
    'El cariño',
    'L’affection, la tendresse',
    'Te lo digo con todo mi cariño.',
    'Je te le dis avec toute mon affection.',
  ),
  LoveWord(
    'El abrazo',
    'Le câlin, l’étreinte',
    'Quiero darte un abrazo.',
    'J’ai envie de te faire un câlin.',
  ),
  LoveWord(
    'La ternura',
    'La tendresse',
    'Me miras con ternura.',
    'Tu me regardes avec tendresse.',
  ),
  LoveWord(
    'El beso',
    'Le baiser',
    'Te mando un beso.',
    'Je t’envoie un baiser.',
  ),
  LoveWord(
    'El corazón',
    'Le cœur',
    'Tienes un lugar en mi corazón.',
    'Tu as une place dans mon cœur.',
  ),
  LoveWord(
    'La complicidad',
    'La complicité',
    'Me encanta nuestra complicidad.',
    'J’adore notre complicité.',
  ),
  LoveWord(
    'La confianza',
    'La confiance',
    'Nuestra confianza crece cada día.',
    'Notre confiance grandit chaque jour.',
  ),
  LoveWord(
    'La sonrisa',
    'Le sourire',
    'Tu sonrisa ilumina mi día.',
    'Ton sourire illumine ma journée.',
  ),
  LoveWord(
    'El amor',
    'L’amour',
    'Nuestro amor crece con nosotros.',
    'Notre amour grandit avec nous.',
  ),
  LoveWord(
    'La promesa',
    'La promesse',
    'Quiero cumplir mi promesa.',
    'Je veux tenir ma promesse.',
  ),
  LoveWord(
    'El encuentro',
    'La rencontre',
    'Recuerdo nuestro primer encuentro.',
    'Je me souviens de notre première rencontre.',
  ),
  LoveWord(
    'La caricia',
    'La caresse',
    'Una caricia tuya me tranquiliza.',
    'Une caresse de toi m’apaise.',
  ),
  LoveWord(
    'La alegría',
    'La joie',
    'Qué alegría compartir este día contigo.',
    'Quelle joie de partager cette journée avec toi.',
  ),
  LoveWord(
    'La pareja',
    'Le couple ; le ou la partenaire',
    'Somos una pareja que aprende cada día.',
    'Nous sommes un couple qui apprend chaque jour.',
  ),
  LoveWord(
    'La cita',
    'Le rendez-vous',
    '¿Recuerdas nuestra primera cita?',
    'Tu te souviens de notre premier rendez-vous ?',
  ),
  LoveWord(
    'El hogar',
    'Le foyer, le chez-soi',
    'Quiero construir un hogar contigo.',
    'Je veux construire un foyer avec toi.',
  ),
  LoveWord(
    'La paciencia',
    'La patience',
    'Gracias por tu paciencia y tu cariño.',
    'Merci pour ta patience et ton affection.',
  ),
  LoveWord(
    'La mirada',
    'Le regard',
    'Tu mirada me hace sonreír.',
    'Ton regard me fait sourire.',
  ),
  LoveWord(
    'El compromiso',
    'L’engagement',
    'Nuestro compromiso se cuida cada día.',
    'Notre engagement se cultive chaque jour.',
  ),
  LoveWord(
    'La boda',
    'Le mariage, la cérémonie',
    'Nuestra boda será el comienzo de una nueva etapa.',
    'Notre mariage sera le début d’une nouvelle étape.',
  ),
  LoveWord(
    'La felicidad',
    'Le bonheur',
    'Compartir la vida contigo me llena de felicidad.',
    'Partager la vie avec toi me remplit de bonheur.',
  ),
  LoveWord(
    'El apoyo',
    'Le soutien',
    'Gracias por tu apoyo.',
    'Merci pour ton soutien.',
  ),
  LoveWord(
    'La dulzura',
    'La douceur',
    'Me hablas con tanta dulzura.',
    'Tu me parles avec tant de douceur.',
  ),
  LoveWord(
    'El respeto',
    'Le respect',
    'El respeto es parte de nuestro amor.',
    'Le respect fait partie de notre amour.',
  ),
  LoveWord(
    'La ilusión',
    'L’enthousiasme, l’attente heureuse',
    'Me hace ilusión verte mañana.',
    'Je me réjouis de te voir demain.',
  ),
  LoveWord(
    'La cercanía',
    'La proximité',
    'Tu cercanía me da paz.',
    'Ta proximité m’apporte la paix.',
  ),
  LoveWord(
    'El recuerdo',
    'Le souvenir',
    'Guardo este recuerdo con mucho cariño.',
    'Je garde ce souvenir avec beaucoup de tendresse.',
  ),
  LoveWord(
    'El futuro',
    'L’avenir',
    'Me gusta imaginar nuestro futuro.',
    'J’aime imaginer notre avenir.',
  ),
  LoveWord(
    'La compañía',
    'La compagnie, la présence',
    'Disfruto de tu compañía.',
    'J’apprécie ta présence.',
  ),
  LoveWord(
    'El cuidado',
    'L’attention, le soin',
    'El amor también está en el cuidado de cada día.',
    'L’amour est aussi dans l’attention de chaque jour.',
  ),
  LoveWord(
    'La unión',
    'L’union',
    'Celebramos nuestra unión con alegría.',
    'Nous célébrons notre union avec joie.',
  ),
];

LoveWord loveWordAt(DateTime now) {
  final offset = parisCalendarDay(
    now,
  ).difference(DateTime.utc(2026, 11, 17)).inDays;
  return loveWords[offset % loveWords.length];
}
