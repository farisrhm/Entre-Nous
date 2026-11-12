import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/config/wedding_config.dart';
import 'core/application/providers.dart';
import 'core/data/local_wedding_repository.dart';
import 'core/data/parse_wedding_repository.dart';
import 'core/data/supabase_wedding_repository.dart';
import 'core/domain/wedding_repository.dart';

Future<Widget> buildApplication() async {
  await initializeDateFormatting('fr');
  final prefs = await SharedPreferences.getInstance();
  final WeddingRepository repository;
  if (WeddingConfig.supabaseEnabled) {
    if (!_supabaseInitialized) {
      await Supabase.initialize(
        url: WeddingConfig.supabaseUrl,
        publishableKey: WeddingConfig.supabasePublishableKey,
      );
      _supabaseInitialized = true;
    }
    // Retire any session created by the old shared credential build, once.
    if (!(prefs.getBool('supabase.individual-auth.v1') ?? false)) {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      await prefs.setBool('supabase.individual-auth.v1', true);
    }
    final supabase = SupabaseWeddingRepository(Supabase.instance.client);
    await supabase.restore();
    repository = supabase;
  } else if (WeddingConfig.parseEnabled) {
    final parse = ParseWeddingRepository();
    await parse.restore();
    repository = parse;
  } else {
    repository = LocalWeddingRepository(prefs);
  }
  return ProviderScope(
    overrides: [
      preferencesProvider.overrideWithValue(prefs),
      repositoryProvider.overrideWithValue(repository),
    ],
    child: const WeddingApp(),
  );
}

bool _supabaseInitialized = false;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(StartupGate(load: buildApplication));
}

class StartupGate extends StatefulWidget {
  final Future<Widget> Function() load;
  const StartupGate({super.key, required this.load});
  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<Widget> pending = widget.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: pending,
    builder: (context, snapshot) {
      if (snapshot.hasData) return snapshot.data!;
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Notre espace ne peut pas encore s’ouvrir. Vérifie la connexion puis réessaie.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => setState(() {
                            pending = widget.load();
                          }),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
