import 'package:flutter/material.dart';
import '../../../core/domain/wedding_repository.dart';
import '../../../core/data/supabase_wedding_repository.dart';
import '../../../core/widgets/shared.dart';

class LoginPage extends StatefulWidget {
  final CloudWeddingRepository repository;
  final VoidCallback onConnected;
  const LoginPage({
    super.key,
    required this.repository,
    required this.onConnected,
  });
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController(), password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.repository.login(username.text.trim(), password.text);
      if (mounted) widget.onConnected();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageBody(
        children: [
          const SizedBox(height: 60),
          const SectionHeading(
            'JUSQU’À NOUS',
            'Rien que nous deux',
            'Retrouvons notre petit univers.',
          ),
          AutofillGroup(
            child: Column(
              children: [
                TextField(
                  controller: username,
                  autofillHints: const [AutofillHints.username],
                  autocorrect: false,
                  enabled: !busy,
                  keyboardType: widget.repository is SupabaseWeddingRepository
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: widget.repository is SupabaseWeddingRepository
                        ? 'Email'
                        : 'Identifiant',
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: password,
                  enabled: !busy,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => busy ? null : login(),
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : login,
            child: Text(busy ? 'Connexion…' : 'Entrer dans notre univers'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Utilise l’un de nos deux comptes.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
