import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/application/providers.dart';
import '../../../core/widgets/shared.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController first, second;
  late Settings value;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    value = ref.read(settingsProvider);
    first = TextEditingController(text: value.firstName);
    second = TextEditingController(text: value.secondName);
  }

  @override
  void dispose() {
    first.dispose();
    second.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (first.text.trim().isEmpty || second.text.trim().isEmpty) {
      showError(context, 'Les deux prénoms sont nécessaires.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(settingsProvider.notifier)
          .save(
            value.copy(
              firstName: first.text.trim(),
              secondName: second.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Notre espace')),
      body: PageBody(
        children: [
          const SectionHeading(
            'PERSONNALISATION',
            'À notre image',
            'Les petits détails qui font notre univers.',
          ),
          TextField(
            controller: first,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Premier prénom'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: second,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Second prénom'),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Réduire les mouvements'),
            value: value.reduceMotion,
            onChanged: (v) =>
                setState(() => value = value.copy(reduceMotion: v)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Enregistrement…' : 'Enregistrer les réglages'),
          ),
        ],
      ),
    );
  }
}
