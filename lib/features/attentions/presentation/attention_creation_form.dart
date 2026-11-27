import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/shared.dart';
import '../application/attention_providers.dart';
import '../domain/attention.dart';
import 'attention_widgets.dart';

class AttentionCreationForm extends ConsumerStatefulWidget {
  final AttentionTemplate? template;
  final String recipientId, recipientName, senderName;
  const AttentionCreationForm({
    super.key,
    this.template,
    required this.recipientId,
    required this.recipientName,
    required this.senderName,
  });
  @override
  ConsumerState<AttentionCreationForm> createState() =>
      _AttentionCreationFormState();
}

class _AttentionCreationFormState extends ConsumerState<AttentionCreationForm> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.template?.title ?? '');
  late final description = TextEditingController(
    text: widget.template?.description ?? '',
  );
  final message = TextEditingController();
  late String icon = widget.template?.icon ?? 'heart',
      theme = widget.template?.theme ?? 'cream';
  final id = attentionId();
  Map<String, dynamic>? submission;
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || !form.currentState!.validate()) return;
    submission ??= {
      'p_id': id,
      'p_recipient': widget.recipientId,
      'p_title': title.text.trim(),
      'p_description': description.text.trim(),
      'p_message': message.text.trim(),
      'p_icon': icon,
      'p_theme': theme,
      'p_template': widget.template?.key,
    };
    setState(() => busy = true);
    try {
      final repo = ref.read(attentionRepositoryProvider);
      if (repo == null) throw StateError('Supabase required');
      await repo.offer(submission!);
      if (!mounted) return;
      ref.invalidate(attentionsProvider);
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        showError(
          context,
          'Envoi non confirmé. Réessaie : le même bon sera utilisé, sans doublon. Tu peux aussi fermer puis actualiser le carnet.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = busy || submission != null;
    final preview = AttentionVoucher({
      'title': title.text,
      'description': description.text,
      'personal_message': message.text,
      'icon_key': icon,
      'theme_key': theme,
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une attention')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pour ${widget.recipientName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Un cadeau libre, sans date d’expiration ni obligation.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: title,
                  enabled: !locked,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Le titre du bon',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (s) => s == null || s.trim().isEmpty
                      ? 'Donne un titre à ton attention.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: description,
                  enabled: !locked,
                  maxLength: 400,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'La description',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (s) => s == null || s.trim().isEmpty
                      ? 'Décris ce que tu aimerais offrir.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: message,
                  enabled: !locked,
                  maxLength: 800,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Ton petit mot (facultatif)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                const Text('Un petit symbole'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final key in attentionIcons.keys)
                      ChoiceChip(
                        label: Icon(
                          attentionIcons[key],
                          size: 20,
                          semanticLabel: key,
                        ),
                        selected: icon == key,
                        onSelected: locked
                            ? null
                            : (_) => setState(() => icon = key),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('La couleur du papier'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final item in const [
                      ('cream', 'Crème'),
                      ('sage', 'Sauge'),
                      ('forest', 'Forêt'),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: theme == item.$1,
                        onSelected: locked
                            ? null
                            : (_) => setState(() => theme = item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const Eyebrow('UN APERÇU DE TON CADEAU'),
                const SizedBox(height: 12),
                AttentionVoucherCard(
                  voucher: preview,
                  senderName: widget.senderName,
                ),
                const SizedBox(height: 24),
                if (submission != null && !busy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Le contenu reste conservé pour réessayer le même envoi en toute sécurité.',
                    ),
                  ),
                FilledButton(
                  onPressed: busy ? null : send,
                  child: Text(
                    busy
                        ? 'Envoi en cours…'
                        : submission == null
                        ? 'Offrir cette attention'
                        : 'Réessayer l’envoi',
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AttentionTemplatePicker extends StatelessWidget {
  final ValueChanged<AttentionTemplate?> onSelected;
  const AttentionTemplatePicker({super.key, required this.onSelected});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Une douceur à offrir',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          for (final t in AttentionTemplate.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: () => onSelected(t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Icon(attentionIcons[t.icon]),
                      const SizedBox(width: 14),
                      Expanded(child: Text(t.title)),
                    ],
                  ),
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () => onSelected(null),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Créer une attention personnalisée'),
          ),
        ],
      ),
    ),
  );
}
