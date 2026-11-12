import '../../../core/domain/entry.dart';

/// Presentation metadata for the four small shared notebooks.
class TogetherSpace {
  final EntryKind kind;
  final String path, eyebrow, title, subtitle, addLabel, emptyText;
  const TogetherSpace({
    required this.kind,
    required this.path,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.addLabel,
    required this.emptyText,
  });
  static const openWhen = TogetherSpace(
    kind: EntryKind.openWhen,
    path: '/letters/open-when',
    eyebrow: 'DES MOTS POUR CHAQUE MOMENT',
    title: 'Ouvre quand…',
    subtitle: 'Une enveloppe, pour le moment où tu en auras besoin.',
    addLabel: 'Préparer une enveloppe',
    emptyText:
        'Un mot pour un jour de doute, un sourire à retrouver… Prépare ta première enveloppe.',
  );
  static const happiness = TogetherSpace(
    kind: EntryKind.happiness,
    path: '/universe/happiness',
    eyebrow: 'LES PETITS RIENS QUI COMPTENT',
    title: 'Notre bocal des petits bonheurs',
    subtitle: 'Gardons une trace de ce qui rend nos jours plus doux.',
    addLabel: 'Glisser un bonheur',
    emptyText:
        'Un fou rire, un café préparé, une balade… Quel petit bonheur veux-tu garder ?',
  );
  static const dua = TogetherSpace(
    kind: EntryKind.dua,
    path: '/universe/dua',
    eyebrow: 'NOTRE FOI À DEUX',
    title: 'Une dou‘a pour toi',
    subtitle: 'Quelques mots personnels, avec toute notre affection.',
    addLabel: 'Écrire une dou‘a',
    emptyText:
        'Pour sa journée, un projet ou un moment difficile : écris une invocation personnelle pour l’autre.',
  );
  static const intention = TogetherSpace(
    kind: EntryKind.intention,
    path: '/universe/intentions',
    eyebrow: 'NOTRE FOYER',
    title: 'Les intentions de notre foyer',
    subtitle: 'Ce que nous souhaitons cultiver, un petit geste à la fois.',
    addLabel: 'Poser une intention',
    emptyText:
        'Quelle place souhaitons-nous donner à la douceur, à la patience ou à l’entraide dans notre foyer ?',
  );
  static const all = [openWhen, happiness, dua, intention];
  bool get hasRecipient => kind == EntryKind.openWhen || kind == EntryKind.dua;
  bool mayEdit(Entry entry, String? userId, bool isCloud) =>
      !isCloud || kind == EntryKind.intention || entry.authorId == userId;
}

const envelopePrompts = [
  'tu as besoin de sourire',
  'je te manque',
  'tu as besoin d’apaisement',
  'une étape importante t’attend',
  'tu veux te rappeler combien je t’aime',
];
const intentionPrompts = [
  'La douceur dans nos paroles',
  'La patience au quotidien',
  'L’entraide dans notre foyer',
  'La gratitude pour ce que nous avons',
  'L’accueil de nos proches',
];
