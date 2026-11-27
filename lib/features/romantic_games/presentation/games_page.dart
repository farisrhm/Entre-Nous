import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/shared.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Nos jeux à deux'),
      leading: IconButton(
        tooltip: 'Retour à notre univers',
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/universe'),
      ),
    ),
    body: SafeArea(
      child: PageBody(
        children: [
          const SectionHeading(
            'UNE PARENTHÈSE À DEUX',
            'Un peu de jeu,\nbeaucoup de nous.',
            'Retrouver nos photos, assembler un souvenir ou chercher les mots qui nous ressemblent.',
          ),
          for (final game in const [
            (
              'Notre Memory',
              'Un petit coffret de photos. Des paires à retrouver.',
              Icons.style_outlined,
              '/universe/memory',
            ),
            (
              'Puzzle de nos souvenirs',
              'Reconstitue nos plus beaux instants, pièce après pièce.',
              Icons.extension_outlined,
              '/universe/puzzle',
            ),
            (
              'Les Mots de notre histoire',
              'Retrouve les mots qui nous ressemblent.',
              Icons.grid_on_outlined,
              '/universe/words',
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Paper(
                color: Palette.cream,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(game.$3, color: Palette.forest, size: 28),
                  title: Text(
                    game.$1,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(game.$2, style: const TextStyle(fontSize: 12)),
                  ),
                  trailing: const Icon(Icons.arrow_forward, size: 18),
                  onTap: () => context.push(game.$4),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
