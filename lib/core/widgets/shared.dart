import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/providers.dart';
import '../data/private_photos.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class Photo extends ConsumerWidget {
  final String source;
  final double? height;
  final BoxFit fit;
  const Photo(this.source, {super.key, this.height, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget fallback(BuildContext c, Object e, StackTrace? s) => Container(
      height: height,
      color: Palette.sage,
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_florist_outlined,
        size: 48,
        color: Palette.ivory,
      ),
    );
    if (source.startsWith(PrivatePhotos.prefix)) {
      return ref
          .watch(privatePhotoProvider((source, fit == BoxFit.cover)))
          .when(
            data: (bytes) => Image.memory(
              bytes,
              height: height,
              width: double.infinity,
              fit: fit,
              cacheWidth: fit == BoxFit.cover ? 1200 : null,
              errorBuilder: fallback,
            ),
            loading: () => SizedBox(
              height: height ?? 180,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, stack) => InkWell(
              onTap: () => ref.invalidate(
                privatePhotoProvider((source, fit == BoxFit.cover)),
              ),
              child: fallback(context, e, stack),
            ),
          );
    }
    if (source.startsWith('asset:')) {
      return Image.asset(
        source.substring(6),
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: fallback,
      );
    }
    if (source.startsWith('data:image/')) {
      try {
        return Image.memory(
          base64Decode(source.split(',').last),
          height: height,
          width: double.infinity,
          fit: fit,
          errorBuilder: fallback,
        );
      } catch (_) {
        return fallback(context, Exception(), null);
      }
    }
    if (!source.startsWith('https://')) {
      return fallback(context, Exception(), null);
    }
    return Image.network(
      source,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: fallback,
    );
  }
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 10,
      letterSpacing: 2.3,
      fontWeight: FontWeight.w600,
      color: color ?? Palette.forest,
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  const SectionHeading(this.eyebrow, this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 30),
    child: Column(
      children: [
        Eyebrow(eyebrow),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(subtitle, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        const Text('✦', style: TextStyle(color: Palette.gold, fontSize: 22)),
      ],
    ),
  );
}

class Paper extends StatelessWidget {
  final Widget child;
  final Color? color;
  const Paper({super.key, required this.child, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: color ?? Colors.white.withValues(alpha: .5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Palette.gold.withValues(alpha: .3)),
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    primary: false,
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

Future<void> showReading(BuildContext context, String title, String body) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Palette.ivory,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_florist_outlined,
                color: Palette.gold,
                size: 36,
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Text(body, style: const TextStyle(height: 1.9)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Refermer'),
              ),
            ],
          ),
        ),
      ),
    );
Future<bool> confirmDelete(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Supprimer ce contenu ?'),
    content: const Text('Cette action ne peut pas être annulée.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Garder'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Supprimer'),
      ),
    ],
  ),
).then((value) => value ?? false);
void showError(BuildContext context, Object error) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

// autoDispose releases bytes when no image uses them; session changes invalidate downloads.
final privatePhotoProvider = FutureProvider.autoDispose
    .family<Uint8List, (String, bool)>((ref, request) {
      ref.watch(authRevisionProvider);
      final repository = ref.watch(repositoryProvider);
      if (repository is! PrivatePhotoRepository) {
        throw StateError('Stockage privé indisponible.');
      }
      return (repository as PrivatePhotoRepository).downloadPhoto(
        request.$1,
        thumbnail: request.$2,
      );
    });
