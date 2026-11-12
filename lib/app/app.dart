import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/application/providers.dart';
import '../core/domain/wedding_repository.dart';
import '../core/widgets/shared.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/story/presentation/story_page.dart';
import '../features/letters/presentation/letters_page.dart';
import '../features/surprises/presentation/surprises_page.dart';
import '../features/universe/presentation/universe_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/settings/presentation/settings_page.dart';
import 'theme.dart';
import '../features/together/domain/together_space.dart';
import '../features/together/presentation/together_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    requestFocus: false,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            WeddingShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomePage()),
          GoRoute(path: '/story', builder: (_, _) => const StoryPage()),
          GoRoute(path: '/surprises', builder: (_, _) => const SurprisesPage()),
          GoRoute(path: '/letters', builder: (_, _) => const LettersPage()),
          GoRoute(path: '/universe', builder: (_, _) => const UniversePage()),
          for (final space in TogetherSpace.all)
            GoRoute(
              path: space.path,
              builder: (_, _) => TogetherPage(space: space),
            ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class WeddingApp extends ConsumerWidget {
  const WeddingApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Jusqu’à Nous',
    debugShowCheckedModeBanner: false,
    theme: weddingTheme(),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) => Gate(child: child!),
  );
}

class Gate extends ConsumerStatefulWidget {
  final Widget child;
  const Gate({super.key, required this.child});
  @override
  ConsumerState<Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<Gate> {
  @override
  Widget build(BuildContext context) {
    ref.watch(authRevisionProvider);
    final repo = ref.watch(repositoryProvider);
    if (repo is CloudWeddingRepository && !repo.hasSession) {
      return LoginPage(
        repository: repo,
        onConnected: () {
          ref.invalidate(entriesProvider);
          setState(() {});
        },
      );
    }
    if (!ref.watch(settingsProvider).onboardingDone) {
      return const OnboardingPage();
    }
    return widget.child;
  }
}

class WeddingShell extends ConsumerStatefulWidget {
  final String path;
  final Widget child;
  const WeddingShell({super.key, required this.path, required this.child});
  @override
  ConsumerState<WeddingShell> createState() => _WeddingShellState();
}

class _WeddingShellState extends ConsumerState<WeddingShell>
    with WidgetsBindingObserver {
  Timer? timer;
  String? syncError;
  bool refreshing = false;
  bool active = true;
  static const paths = ['/', '/story', '/surprises', '/letters', '/universe'];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (ref.read(repositoryProvider).isCloud) {
      timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active) refresh();
  }

  Future<void> refresh() async {
    if (refreshing || !mounted || !active) return;
    refreshing = true;
    try {
      await ref.read(entriesProvider.notifier).refresh();
      if (mounted) setState(() => syncError = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => syncError =
              'Je n’arrive pas à mettre notre univers à jour pour le moment.',
        );
      }
    } finally {
      refreshing = false;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(repositoryProvider);
    if (repo is! CloudWeddingRepository) return;
    try {
      await repo.logout();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      ref.invalidate(entriesProvider);
      ref.read(authRevisionProvider.notifier).changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider),
        repo = ref.watch(repositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jusqu’à Nous',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          if (repo.isCloud)
            IconButton(
              tooltip: 'Actualiser',
              onPressed: refresh,
              icon: const Icon(Icons.sync, size: 20),
            ),
          IconButton(
            tooltip: 'Réglages',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined, size: 21),
          ),
          if (repo.isCloud)
            IconButton(
              tooltip: 'Se déconnecter',
              onPressed: logout,
              icon: const Icon(Icons.logout, size: 20),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (syncError != null)
              MaterialBanner(
                content: Text(syncError!),
                actions: [
                  TextButton(
                    onPressed: refresh,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            Expanded(
              child: entries.when(
                data: (_) => RefreshIndicator(
                  onRefresh: refresh,
                  child: KeyedSubtree(
                    key: ValueKey(widget.path),
                    child: widget.child,
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => ref.invalidate(entriesProvider),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.path.startsWith('/universe')
            ? 4
            : widget.path.startsWith('/letters')
            ? 3
            : paths.indexOf(widget.path).clamp(0, 4),
        onDestinationSelected: (i) => context.go(paths[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            label: 'Souvenirs',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Surprises',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            label: 'Lettres',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: 'Univers',
          ),
        ],
      ),
    );
  }
}
