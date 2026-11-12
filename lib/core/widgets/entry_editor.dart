import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../application/providers.dart';
import '../domain/entry.dart';
import '../data/supabase_wedding_repository.dart';
import '../data/private_photos.dart';
import 'shared.dart';
import '../../features/story/domain/memory_album.dart';

Future<void> editEntry(BuildContext context, Entry entry) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => EntryEditor(entry: entry),
    );

class EntryEditor extends ConsumerStatefulWidget {
  final Entry entry;
  const EntryEditor({super.key, required this.entry});
  @override
  ConsumerState<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends ConsumerState<EntryEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, body, date;
  late String recipientId;
  late List<String> photos;
  bool picking = false;
  DateTime? openAt;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    title = TextEditingController(text: e.text('title'));
    body = TextEditingController(text: e.text('body'));
    date = TextEditingController(text: e.text('date'));
    photos = MemoryAlbum.photosOf(e);
    recipientId = e.text('recipientId');
    openAt = e.date('openAt')?.toLocal();
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    date.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    if (picking || photos.length >= MemoryAlbum.maxPhotos) return;
    setState(() => picking = true);
    try {
      final originals =
          ref.read(repositoryProvider) is SupabaseWeddingRepository;
      final files = await ImagePicker().pickMultiImage(
        maxWidth: originals ? null : 1200,
        maxHeight: originals ? null : 1200,
        imageQuality: originals ? null : 70,
        limit: MemoryAlbum.maxPhotos - photos.length,
      );
      final additions = <String>[];
      for (final file in files) {
        if (await file.length() > PrivatePhotos.maxBytes) {
          throw Exception('Chaque photo doit peser au maximum 20 Mio.');
        }
        final bytes = await file.readAsBytes();
        final mime = bytes.length > 3 && bytes[0] == 0xff && bytes[1] == 0xd8
            ? 'jpeg'
            : bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50
            ? 'png'
            : bytes.length > 12 &&
                  String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
                  String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP'
            ? 'webp'
            : null;
        if (mime == null) {
          throw Exception('Choisis des photos JPEG, PNG ou WebP.');
        }
        if (originals) {
          final repository =
              ref.read(repositoryProvider) as SupabaseWeddingRepository;
          additions.add(await repository.uploadPhoto(bytes, mime));
        } else {
          additions.add('data:image/$mime;base64,${base64Encode(bytes)}');
        }
      }
      final next = [...photos, ...additions];
      MemoryAlbum.validate(next, privateStorage: originals);
      if (mounted) setState(() => photos = next);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  void movePhoto(int from, int to) {
    setState(() {
      final item = photos.removeAt(from);
      photos.insert(to, item);
    });
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: openAt ?? DateTime(2027, 1, 23),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(openAt ?? DateTime(2027, 1, 23, 8)),
    );
    if (time != null && mounted) {
      setState(
        () => openAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final repo = ref.read(repositoryProvider);
    if (widget.entry.kind == EntryKind.letter &&
        (openAt == null || recipientId.isEmpty)) {
      showError(context, 'Choisis une date et un destinataire.');
      return;
    }
    setState(() => busy = true);
    try {
      final fields = <String, dynamic>{
        'title': title.text.trim(),
        'body': body.text.trim(),
      };
      if (widget.entry.kind == EntryKind.memory) {
        MemoryAlbum.validate(
          photos,
          privateStorage: repo is SupabaseWeddingRepository,
        );
        fields.addAll({
          'date': date.text.trim(),
          'photos': List<String>.of(photos),
          'photo': photos.firstOrNull ?? '',
        });
      }
      if (widget.entry.kind == EntryKind.letter) {
        fields.addAll({
          'openAt': openAt!.toUtc().toIso8601String(),
          'recipientId': recipientId,
          'recipient': repo.members.firstWhere((m) => m.id == recipientId).name,
        });
      }
      await ref.read(entriesProvider.notifier).save(widget.entry.copy(fields));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.entry.kind == EntryKind.memory,
        letter = widget.entry.kind == EntryKind.letter;
    final members = ref.watch(repositoryProvider).members;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 30,
      ),
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              memory
                  ? 'Un précieux souvenir'
                  : letter
                  ? 'Quelques mots pour toi'
                  : 'Notre petit univers',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            if (memory) ...[
              const Text(
                'La première photo est la couverture. Utilise les flèches pour changer l’ordre.',
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < photos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 68,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Photo(photos[i], height: 68),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(i == 0 ? 'Couverture' : 'Photo ${i + 1}'),
                      ),
                      IconButton(
                        tooltip: 'Monter la photo ${i + 1}',
                        onPressed: busy || picking || i == 0
                            ? null
                            : () => movePhoto(i, i - 1),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                      ),
                      IconButton(
                        tooltip: 'Descendre la photo ${i + 1}',
                        onPressed: busy || picking || i == photos.length - 1
                            ? null
                            : () => movePhoto(i, i + 1),
                        icon: const Icon(Icons.arrow_downward, size: 18),
                      ),
                      IconButton(
                        tooltip: 'Retirer la photo ${i + 1}',
                        onPressed: busy || picking
                            ? null
                            : () => setState(() => photos.removeAt(i)),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed:
                    busy || picking || photos.length >= MemoryAlbum.maxPhotos
                    ? null
                    : pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  picking
                      ? 'Importation…'
                      : 'Ajouter des photos (${photos.length}/8)',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: title,
              maxLength: 160,
              decoration: InputDecoration(
                labelText: memory || letter ? 'Titre' : 'Notre rêve',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Ajoute un titre' : null,
            ),
            const SizedBox(height: 16),
            if (memory) ...[
              TextFormField(
                controller: date,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Une date chère à nos cœurs',
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (letter) ...[
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
                    : (v) => setState(() => recipientId = v ?? ''),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: busy ? null : chooseDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  openAt == null
                      ? 'Choisir la date d’ouverture'
                      : DateFormat(
                          'dd MMMM yyyy à HH:mm',
                          'fr',
                        ).format(openAt!),
                ),
              ),
              const Text(
                'Heure locale de cet appareil, enregistrée en UTC.',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 16),
            ],
            if (memory || letter) ...[
              TextFormField(
                controller: body,
                minLines: 4,
                maxLines: 10,
                maxLength: 20000,
                decoration: InputDecoration(
                  labelText: letter ? 'Mon amour…' : 'Notre souvenir',
                ),
                validator: (v) => letter && (v ?? '').trim().isEmpty
                    ? 'Écris quelques mots'
                    : null,
              ),
              const SizedBox(height: 20),
            ],
            FilledButton(
              onPressed: busy || picking ? null : save,
              child: Text(
                busy
                    ? 'Enregistrement…'
                    : letter
                    ? 'Sceller cette lettre'
                    : 'Garder ce souvenir',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
