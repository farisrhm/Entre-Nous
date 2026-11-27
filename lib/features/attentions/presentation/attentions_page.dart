import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/application/providers.dart';
import '../../../core/widgets/shared.dart';
import '../application/attention_providers.dart';
import '../domain/attention.dart';
import 'attention_creation_form.dart';
import 'attention_detail_view.dart';
import 'attention_widgets.dart';

String attentionDate(DateTime date) =>
    DateFormat('d MMMM yyyy · HH:mm', 'fr').format(date);

/// The existing repository does not use Realtime. Poll only while this screen
/// is active, refresh on foreground, and always expose a manual refresh.
class AttentionsPage extends ConsumerStatefulWidget {
  const AttentionsPage({super.key});
  @override
  ConsumerState<AttentionsPage> createState() => _AttentionsPageState();
}

class _AttentionsPageState extends ConsumerState<AttentionsPage>
    with WidgetsBindingObserver {
  Timer? timer;
  int filter = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startPolling();
  }

  void startPolling() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) ref.invalidate(attentionsProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(attentionsProvider);
      startPolling();
    } else {
      timer?.cancel();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> create() async {
    final repo = ref.read(repositoryProvider);
    final partner = repo.members.where((m) => m.id != repo.userId).toList();
    final sender = repo.members.where((m) => m.id == repo.userId).firstOrNull;
    if (partner.length != 1 || sender == null) {
      showError(
        context,
        'Impossible de retrouver votre duo. Actualise l’application.',
      );
      return;
    }
    AttentionTemplate? selected;
    var chosen = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AttentionTemplatePicker(
        onSelected: (t) {
          selected = t;
          chosen = true;
          Navigator.pop(context);
        },
      ),
    );
    if (!mounted || !chosen) return;
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AttentionCreationForm(
          template: selected,
          recipientId: partner.single.id,
          recipientName: partner.single.name,
          senderName: sender.name,
        ),
      ),
    );
    if (mounted && sent == true) {
      setState(() => filter = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ton attention a été offerte avec amour.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final supported = ref.watch(attentionRepositoryProvider) != null;
    final items = ref.watch(attentionsProvider);
    String name(String id) =>
        repo.members.where((m) => m.id == id).firstOrNull?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Les petites attentions'),
        leading: IconButton(
          tooltip: 'Notre univers',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/universe'),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser le carnet',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(attentionsProvider),
          ),
        ],
      ),
      body: !supported
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Connecte l’application à votre espace Supabase pour offrir et recevoir vos attentions.',
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(attentionsProvider);
                try {
                  await ref.read(attentionsProvider.future);
                } catch (_) {
                  // The provider renders an explicit retry state.
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const Eyebrow('DE MOI À TOI'),
                  const SizedBox(height: 10),
                  Text(
                    'Les gestes qui restent.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'De petites promesses de douceur, à vivre quand nous en avons envie.',
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: create,
                    icon: const Icon(Icons.card_giftcard, size: 18),
                    label: const Text('Créer une attention'),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < 3; i++)
                        ChoiceChip(
                          label: Text(
                            ['Pour moi', 'Offerts', 'Nos souvenirs'][i],
                          ),
                          selected: filter == i,
                          onSelected: (_) => setState(() => filter = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration:
                        ref.watch(settingsProvider).reduceMotion ||
                            MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(filter),
                      child: items.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, _) => Column(
                          children: [
                            const Text(
                              'Le carnet n’a pas pu être chargé. Vérifie ta connexion et la configuration Supabase.',
                            ),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(attentionsProvider),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                        data: (all) {
                          final selected = all
                              .where(
                                (v) => filter == 2
                                    ? v.status == 'completed'
                                    : v.status != 'completed' &&
                                          (filter == 0
                                              ? v.recipient == repo.userId
                                              : v.sender == repo.userId),
                              )
                              .toList();
                          if (filter == 2) {
                            selected.sort(
                              (a, b) =>
                                  (b.date('completed_at') ?? DateTime(1970))
                                      .compareTo(
                                        a.date('completed_at') ??
                                            DateTime(1970),
                                      ),
                            );
                          }
                          if (selected.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.local_florist_outlined,
                                    color: Palette.gold,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    filter == 2
                                        ? 'Vos attentions vécues trouveront ici leur place.'
                                        : filter == 0
                                        ? 'Les petites douceurs qui te sont offertes t’attendront ici.'
                                        : 'Le premier geste peut être tout simple.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final v in selected)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 22),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (v.status == 'offered' &&
                                          v.recipient == repo.userId)
                                        AttentionEnvelope(
                                          senderName: name(v.sender),
                                          onTap: () => open(v.id),
                                        )
                                      else
                                        InkWell(
                                          onTap: () => open(v.id),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: AttentionVoucherCard(
                                            voucher: v,
                                            senderName: name(v.sender),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      AttentionStatusIndicator(voucher: v),
                                      if (v.date('completed_at') != null)
                                        Text(
                                          attentionDate(
                                            v.date('completed_at')!,
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      TextButton(
                                        onPressed: () => open(v.id),
                                        child: Text(
                                          v.status == 'offered' &&
                                                  v.recipient == repo.userId
                                              ? 'Ouvrir mon enveloppe'
                                              : 'Voir cette attention',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> open(String id) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AttentionDetailView(id: id)),
    );
    if (mounted) ref.invalidate(attentionsProvider);
  }
}
