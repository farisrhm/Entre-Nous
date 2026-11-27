import 'dart:math';

String attentionId() {
  final r = Random.secure();
  final bytes = List.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class AttentionTemplate {
  final String key, title, description, icon, theme;
  const AttentionTemplate(
    this.key,
    this.title,
    this.description,
    this.icon,
    this.theme,
  );
  static const all = [
    AttentionTemplate(
      'massage',
      'Bon pour un massage',
      '30 minutes de détente, rien que pour toi.',
      'heart',
      'cream',
    ),
    AttentionTemplate(
      'breakfast',
      'Petit-déjeuner au lit',
      'Reste sous la couette, je m’occupe de tout.',
      'coffee',
      'sage',
    ),
    AttentionTemplate(
      'evening',
      'Une soirée à ton image',
      'Tu choisis le programme, j’organise tout.',
      'moon',
      'forest',
    ),
  ];
}

class AttentionVoucher {
  final Map<String, dynamic> data;
  AttentionVoucher(Map<String, dynamic> data) : data = Map.unmodifiable(data);
  String text(String key) => data[key] as String? ?? '';
  String get id => text('id');
  String get sender => text('sender_id');
  String get recipient => text('recipient_id');
  String get status => text('status');
  int get version => data['version'] as int? ?? 0;
  DateTime? date(String key) => DateTime.tryParse(text(key))?.toLocal();
  String get statusLabel =>
      const {
        'offered': 'À découvrir',
        'opened': 'Disponible',
        'requested': 'En attente',
        'scheduled': 'Moment accepté',
        'completed': 'Réalisée',
        'cancelled': 'Annulée',
      }[status] ??
      status;
  List<String> actionsFor(String user) {
    if (user != sender && user != recipient) return [];
    return [
      if (user == recipient && status == 'offered') 'open',
      if (user == recipient && status == 'opened') 'request',
      if (user == recipient && status == 'requested') 'withdraw',
      if (status == 'requested' && user == text('awaiting_id')) 'accept',
      if (user == sender && status == 'requested') ...['propose', 'later'],
      if (['requested', 'scheduled'].contains(status)) 'complete',
      if (status == 'completed') 'undo',
      if (user == sender && ['offered', 'opened'].contains(status)) 'cancel',
    ];
  }
}

const attentionActions = {
  'open': 'Découvrir mon attention',
  'request': 'J’aimerais utiliser ce bon',
  'withdraw': 'Retirer ma demande',
  'accept': 'Accepter ce moment',
  'propose': 'Proposer un autre moment',
  'later': 'Choisir plus tard',
  'complete': 'Marquer comme réalisée',
  'undo': 'Annuler la réalisation',
  'cancel': 'Annuler ce bon',
};
const attentionEvents = {
  'offer': 'Attention offerte',
  'open': 'Enveloppe découverte',
  'request': 'Utilisation demandée',
  'withdraw': 'Demande retirée',
  'accept': 'Moment accepté',
  'propose': 'Autre moment proposé',
  'later': 'Moment à choisir plus tard',
  'complete': 'Attention réalisée',
  'undo': 'Réalisation annulée',
  'cancel': 'Bon annulé',
};
