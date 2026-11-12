import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/application/providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/widgets/shared.dart';
import '../domain/together_space.dart';

Future<void> editTogetherEntry(
  BuildContext context,
  TogetherSpace space, {
  Entry? entry,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => TogetherEditor(space: space, entry: entry),
);

class TogetherEditor extends ConsumerStatefulWidget {
  final TogetherSpace space;
  final Entry? entry;
  const TogetherEditor({super.key, required this.space, this.entry});
  @override
  ConsumerState<TogetherEditor> createState() => _TogetherEditorState();
}

class _TogetherEditorState extends ConsumerState<TogetherEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, body, action;
  late final String id;
  String? recipientId;
  late DateTime date;
  bool gratitude = false, busy = false;
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    id = e?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    title = TextEditingController(text: e?.text('title') ?? '');
    body = TextEditingController(text: e?.text('body') ?? '');
    action = TextEditingController(text: e?.text('action') ?? '');
    date = e?.date('date') ?? DateTime.now();
    gratitude = e?.flag('gratitude') ?? false;
    final repo = ref.read(repositoryProvider);
    recipientId = e?.text('recipientId');
    if (recipientId == null || recipientId!.isEmpty) {
      recipientId = repo.members
          .where((m) => m.id != repo.userId)
          .firstOrNull
          ?.id;
    }
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    action.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final s = widget.space, repo = ref.read(repositoryProvider);
      final fields = <String, dynamic>{
        'title': title.text.trim(),
        'body': body.text.trim(),
      };
      if (s.hasRecipient) {
        final member = repo.members
            .where((m) => m.id == recipientId)
            .firstOrNull;
        if (member == null) throw Exception('Choisis un destinataire.');
        fields.addAll({'recipientId': member.id, 'recipient': member.name});
      }
      if (s.kind == EntryKind.happiness) {
        fields.addAll({
          'date': DateFormat('yyyy-MM-dd').format(date),
          'gratitude': gratitude,
        });
      }
      if (s.kind == EntryKind.intention) fields['action'] = action.text.trim();
      fields['createdAt'] = widget.entry?.text('createdAt').isNotEmpty == true
          ? widget.entry!.text('createdAt')
          : DateTime.now().toUtc().toIso8601String();
      await ref
          .read(entriesProvider.notifier)
          .save(
            Entry(
              id: id,
              kind: s.kind,
              fields: fields,
              authorId: widget.entry?.authorId ?? repo.userId,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.space, kind = s.kind;
    final members = ref.watch(repositoryProvider).members;
    final prompt = kind == EntryKind.openWhen
        ? envelopePrompts
        : kind == EntryKind.intention
        ? intentionPrompts
        : <String>[];
    return PopScope(
      canPop: !busy,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 32,
        ),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.entry == null ? s.addLabel : 'Modifier ce moment',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              if (kind == EntryKind.dua)
                const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'Une invocation écrite avec le cœur, pour accompagner l’autre avec douceur.',
                  ),
                ),
              if (prompt.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final text in prompt)
                      ActionChip(
                        label: Text(text),
                        onPressed: busy
                            ? null
                            : () => setState(() => title.text = text),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              if (s.hasRecipient) ...[
                DropdownButtonFormField<String>(
                  initialValue: members.any((m) => m.id == recipientId)
                      ? recipientId
                      : null,
                  decoration: const InputDecoration(labelText: 'Pour'),
                  items: [
                    for (final m in members)
                      DropdownMenuItem(value: m.id, child: Text(m.name)),
                  ],
                  onChanged: busy
                      ? null
                      : (v) => setState(() => recipientId = v),
                  validator: (v) =>
                      v == null ? 'Choisis un destinataire' : null,
                ),
                const SizedBox(height: 18),
              ],
              TextFormField(
                key: const ValueKey('together-title'),
                controller: title,
                enabled: !busy,
                maxLength: 160,
                decoration: InputDecoration(
                  labelText: kind == EntryKind.openWhen
                      ? 'Ouvre quand…'
                      : kind == EntryKind.happiness
                      ? 'Ce petit moment'
                      : kind == EntryKind.intention
                      ? 'Ce que nous voulons cultiver'
                      : 'Une pensée pour…',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Ajoute quelques mots' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('together-body'),
                controller: body,
                enabled: !busy,
                minLines: 4,
                maxLines: 8,
                maxLength: 20000,
                decoration: InputDecoration(
                  labelText: kind == EntryKind.dua
                      ? 'Mon invocation personnelle'
                      : kind == EntryKind.openWhen
                      ? 'Mes mots pour toi'
                      : kind == EntryKind.intention
                      ? 'Pourquoi cela compte pour nous (facultatif)'
                      : 'Ce que je veux en garder (facultatif)',
                ),
                validator: (v) => s.hasRecipient && (v ?? '').trim().isEmpty
                    ? 'Écris ton message'
                    : null,
              ),
              if (kind == EntryKind.intention) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('together-action'),
                  controller: action,
                  enabled: !busy,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Un geste concret à essayer',
                    hintText:
                        'Par exemple : prendre le temps de s’écouter le soir.',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Choisissez un petit geste concret'
                      : null,
                ),
              ],
              if (kind == EntryKind.happiness) ...[
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (picked != null && mounted) {
                            setState(() => date = picked);
                          }
                        },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormat('dd MMMM yyyy', 'fr').format(date)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Un moment de gratitude'),
                  subtitle: const Text('Alhamdulillah pour ce petit bonheur.'),
                  value: gratitude,
                  onChanged: busy ? null : (v) => setState(() => gratitude = v),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(
                  busy
                      ? 'Enregistrement…'
                      : kind == EntryKind.openWhen
                      ? 'Garder cette enveloppe'
                      : kind == EntryKind.happiness
                      ? 'Glisser dans le bocal'
                      : kind == EntryKind.dua
                      ? 'Partager cette dou‘a'
                      : 'Garder cette intention',
                ),
              ),
              if (s.hasRecipient)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    'Un message tendre, gardé dans notre univers.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
