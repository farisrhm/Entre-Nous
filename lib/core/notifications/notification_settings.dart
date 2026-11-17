import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'push_service.dart';

class NotificationSettingsPanel extends ConsumerStatefulWidget {
  const NotificationSettingsPanel({super.key});
  @override
  ConsumerState<NotificationSettingsPanel> createState() =>
      _NotificationSettingsPanelState();
}

class _NotificationSettingsPanelState
    extends ConsumerState<NotificationSettingsPanel> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(pushServiceProvider)?.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(pushServiceProvider);
    if (service == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          Text(
            'Nos petites attentions',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text(
            'Retrouve ses pensées et ses nouveaux mots sur ton téléphone. Ces réglages sont enregistrés immédiatement pour ton compte.',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Recevoir les notifications'),
            value: service.preferences['enabled']!,
            onChanged: service.busy ? null : service.setEnabled,
          ),
          if (service.preferences['enabled']!)
            for (final item in const [
              ('thought', 'Je pense à toi'),
              ('memory', 'Nouveaux souvenirs'),
              ('dua', 'Dou‘as pour moi'),
              ('letter', 'Lettres et ouvertures'),
            ])
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.$2),
                value: service.preferences[item.$1]!,
                onChanged: service.busy
                    ? null
                    : (value) => service.setCategory(item.$1, value),
              ),
          if (service.busy) const LinearProgressIndicator(),
          if (service.error != null) ...[
            Text(
              service.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: service.busy ? null : service.refresh,
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}
