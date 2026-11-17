import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/providers.dart';
import '../domain/entry.dart';
import '../widgets/shared.dart';
import '../../features/story/domain/memory_album.dart';
import '../../features/story/presentation/memory_gallery.dart';
import 'push_service.dart';

/// Mounted only after authentication and onboarding; payloads never grant access.
class NotificationBridge extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouter router;
  const NotificationBridge({
    super.key,
    required this.child,
    required this.router,
  });
  @override
  ConsumerState<NotificationBridge> createState() => _NotificationBridgeState();
}

class _NotificationBridgeState extends ConsumerState<NotificationBridge>
    with WidgetsBindingObserver {
  PushService? service;
  bool opening = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    service = ref.read(pushServiceProvider);
    service?.addListener(changed);
    unawaited(service?.refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => changed());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(service?.refresh());
  }

  void changed() {
    if (!mounted || opening || service?.pending == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(open());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> open() async {
    final target = service?.pending;
    if (target == null || opening) return;
    if (target.recipientId != ref.read(repositoryProvider).userId) {
      service?.consume();
      return;
    }
    opening = true;
    service?.consume();
    try {
      await ref.read(entriesProvider.notifier).refresh();
      if (!mounted ||
          target.recipientId != ref.read(repositoryProvider).userId) {
        return;
      }
      final entry = (ref.read(entriesProvider).value ?? <Entry>[])
          .where((e) => e.id == target.entryId && e.kind.name == target.kind)
          .firstOrNull;
      if (entry == null) {
        showError(context, 'Ce contenu n’est plus disponible.');
        return;
      }
      // The fresh server response decides if a letter can be read.
      final router = widget.router;
      router.go(target.path);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final navigatorContext =
          router.routerDelegate.navigatorKey.currentContext;
      if (navigatorContext == null || !navigatorContext.mounted) return;
      if (entry.kind == EntryKind.memory &&
          MemoryAlbum.photosOf(entry).isNotEmpty) {
        await showMemoryGallery(
          navigatorContext,
          MemoryAlbum.photosOf(entry),
          entry.text('title'),
        );
      } else if (entry.kind == EntryKind.letter && !entry.flag('available')) {
        await showReading(
          navigatorContext,
          'Une lettre t’attend',
          'Elle restera scellée jusqu’à sa date d’ouverture.',
        );
      } else {
        await showReading(
          navigatorContext,
          entry.kind == EntryKind.thought
              ? 'Une pensée pour toi'
              : entry.text('title'),
          entry.kind == EntryKind.thought
              ? 'Une petite pensée, juste pour toi.'
              : entry.text('body'),
        );
      }
    } catch (_) {
      if (mounted) {
        showError(
          context,
          'Impossible d’ouvrir cette attention. Retrouve-la dans son espace et réessaie après actualisation.',
        );
      }
    } finally {
      opening = false;
      if (mounted) changed();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
  @override
  void dispose() {
    service?.removeListener(changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
