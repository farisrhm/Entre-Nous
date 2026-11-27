import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/application/providers.dart';
import '../../../core/widgets/shared.dart';
import '../application/attention_providers.dart';
import '../domain/attention.dart';
import 'attention_widgets.dart';

class AttentionDetailView extends ConsumerStatefulWidget {
  final String id;
  const AttentionDetailView({super.key, required this.id});
  @override
  ConsumerState<AttentionDetailView> createState() =>
      _AttentionDetailViewState();
}

class _AttentionDetailViewState extends ConsumerState<AttentionDetailView> {
  bool busy = false;
  bool autoOpened = false;
  Map<String, dynamic>? pending;
  Future<void> action(AttentionVoucher v, String action) async {
    if (busy || pending != null) return;
    setState(() => busy = true);
    try {
      final input = action == 'open'
          ? const _ActionInput('', null)
          : await showModalBottomSheet<_ActionInput>(
              context: context,
              isScrollControlled: true,
              builder: (_) => _ActionSheet(action: action),
            );
      if (!mounted || input == null) return;
      pending = {
        'p_id': v.id,
        'p_operation': attentionId(),
        'p_version': v.version,
        'p_action': action,
        'p_note': input.note,
        'p_date': input.date?.toUtc().toIso8601String(),
      };
      await submit();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit() async {
    if (pending == null) return;
    try {
      final repo = ref.read(attentionRepositoryProvider);
      if (repo == null) throw StateError('Supabase required');
      await repo.act(pending!);
      if (!mounted) return;
      final done = pending!['p_action'];
      pending = null;
      ref.invalidate(attentionsProvider);
      ref.invalidate(attentionEventsProvider(widget.id));
      if (done == 'complete') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une douceur de plus dans vos souvenirs.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        showError(
          context,
          'Action non confirmée : connexion interrompue ou bon modifié depuis l’autre téléphone. Réessaie, ou actualise avant de choisir à nouveau.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final state = ref.watch(attentionsProvider);
    final still =
        ref.watch(settingsProvider).reduceMotion ||
        MediaQuery.disableAnimationsOf(context);
    String name(String id) =>
        repo.members.where((m) => m.id == id).firstOrNull?.name ?? '';
    String date(DateTime d) =>
        DateFormat('d MMMM yyyy · HH:mm', 'fr').format(d);
    return Scaffold(
      appBar: AppBar(title: const Text('Une attention pour nous')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(attentionsProvider),
            child: const Text('Réessayer le chargement'),
          ),
        ),
        data: (items) {
          final v = items.where((v) => v.id == widget.id).firstOrNull;
          if (v == null) {
            return const Center(
              child: Text('Cette attention n’est plus disponible.'),
            );
          }
          final sealed = v.status == 'offered' && v.recipient == repo.userId;
          if (sealed && !autoOpened) {
            autoOpened = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) action(v, 'open');
            });
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: still
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(sizeFactor: animation, child: child),
                  ),
                  child: sealed
                      ? AttentionEnvelope(
                          key: const ValueKey('envelope'),
                          senderName: name(v.sender),
                          onTap: busy || pending != null
                              ? null
                              : () => action(v, 'open'),
                        )
                      : AttentionVoucherCard(
                          key: const ValueKey('voucher'),
                          voucher: v,
                          senderName: name(v.sender),
                        ),
                ),
                const SizedBox(height: 16),
                AttentionStatusIndicator(voucher: v),
                if (!sealed) ...[
                  if (v.date('proposed_for') != null && v.status == 'requested')
                    Text('Moment proposé : ${date(v.date('proposed_for')!)}'),
                  if (v.status == 'requested')
                    Text(
                      v.text('awaiting_id') == repo.userId
                          ? 'Ta réponse est attendue.'
                          : 'En attendant la réponse de ton partenaire.',
                    ),
                  if (v.status == 'scheduled')
                    Text(
                      v.date('scheduled_for') == null
                          ? 'Un moment accepté, à organiser à votre rythme.'
                          : 'Votre moment : ${date(v.date('scheduled_for')!)}',
                    ),
                  if (v.date('completed_at') != null)
                    Text('Vécue le ${date(v.date('completed_at')!)}'),
                ],
                const SizedBox(height: 20),
                if (busy)
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (pending != null && !busy) ...[
                  const Text('La dernière action n’est pas encore confirmée.'),
                  TextButton(
                    onPressed: () async {
                      setState(() => busy = true);
                      await submit();
                      if (mounted) setState(() => busy = false);
                    },
                    child: const Text('Réessayer la même action'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => pending = null);
                      ref.invalidate(attentionsProvider);
                      ref.invalidate(attentionEventsProvider(widget.id));
                    },
                    child: const Text('Actualiser le statut'),
                  ),
                ] else
                  for (final key in v.actionsFor(repo.userId ?? ''))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        onPressed: busy ? null : () => action(v, key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            attentionActions[key]!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 18),
                const Text(
                  'Un cadeau, jamais une obligation. Prenez le temps qui vous ressemble.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                if (!sealed) ...[
                  const SizedBox(height: 28),
                  const Eyebrow('LE FIL DE CETTE ATTENTION'),
                  const SizedBox(height: 12),
                  ref
                      .watch(attentionEventsProvider(widget.id))
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => TextButton(
                          onPressed: () => ref.invalidate(
                            attentionEventsProvider(widget.id),
                          ),
                          child: const Text('Recharger l’historique'),
                        ),
                        data: (events) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final e in events)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attentionEvents[e['action']] ??
                                          e['action'] as String,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      [
                                        name(e['actor_id'] as String),
                                        if (DateTime.tryParse(
                                              e['created_at'] as String? ?? '',
                                            )
                                            case final d?)
                                          date(d.toLocal()),
                                      ].where((s) => s.isNotEmpty).join(' · '),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    if ((e['note'] as String? ?? '').isNotEmpty)
                                      Text(e['note'] as String),
                                    if (DateTime.tryParse(
                                          e['proposed_for'] as String? ?? '',
                                        )
                                        case final d?)
                                      Text(
                                        'Moment proposé : ${date(d.toLocal())}',
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionInput {
  final String note;
  final DateTime? date;
  const _ActionInput(this.note, this.date);
}

class _ActionSheet extends StatefulWidget {
  final String action;
  const _ActionSheet({required this.action});
  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet> {
  final note = TextEditingController();
  DateTime? moment;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: moment ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (!mounted || day == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        moment ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (!mounted || time == null) return;
    final candidate = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    if (candidate.isBefore(DateTime.now())) {
      showError(context, 'Choisis un moment à venir.');
      return;
    }
    setState(() => moment = candidate);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        24,
        22,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            attentionActions[widget.action]!,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          if (widget.action == 'complete')
            const Text(
              'Cette attention a-t-elle bien été vécue ? Vous pourrez annuler cette confirmation en cas d’erreur.',
            ),
          if (widget.action == 'undo')
            const Text(
              'Le bon retrouvera son état précédent. Son historique sera conservé.',
            ),
          if (widget.action == 'cancel')
            const Text(
              'Ce bon restera visible comme annulé. Cette action ne pourra pas être inversée.',
            ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLength: 800,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Un petit mot (facultatif)',
            ),
          ),
          if (['request', 'propose'].contains(widget.action)) ...[
            TextButton.icon(
              onPressed: pick,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(
                moment == null
                    ? 'Proposer un moment${widget.action == 'request' ? ' (facultatif)' : ''}'
                    : DateFormat('d MMMM yyyy · HH:mm', 'fr').format(moment!),
              ),
            ),
            if (moment != null)
              TextButton(
                onPressed: () => setState(() => moment = null),
                child: const Text('Sans date'),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.action == 'propose' && moment == null
                ? null
                : () => Navigator.pop(
                    context,
                    _ActionInput(note.text.trim(), moment),
                  ),
            child: const Text('Confirmer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    ),
  );
}
