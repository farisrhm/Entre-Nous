# Les jeux de notre histoire

Deux jeux locaux sont disponibles dans **Univers → Nos jeux à deux**, aux côtés du Memory :

- **Puzzle de nos souvenirs** : échanges de pièces, 3 × 3 / 4 × 4 / 5 × 5, aperçu de trois secondes, chronomètre actif uniquement au premier plan, compte des mouvements, révélation de la photo complète.
- **Les Mots de notre histoire** : quatre thèmes, mots horizontaux/verticaux/diagonaux, directions inversées pour les deux thèmes avancés, sélection par glissement ou deux touches, indices, messages par mot et victoire.

Aucun déploiement Supabase, aucune migration, aucun secret requis. Installer le nouveau build suffit. Les parties et les photos importées restent sur l'appareil ; elles ne se synchronisent pas entre Alyssa et Faris. Désinstaller l'app peut supprimer ces données locales.

## Organisation

Dans `lib/features/romantic_games/` :

- `domain/puzzle_game.dart` : modèle de photo, difficultés et moteur de permutation indépendant de Flutter.
- `domain/word_theme.dart` : données des thèmes et normalisation des accents.
- `domain/word_search_game.dart` : placement borné, stratégie de secours garantie, reconnaissance des sélections, restauration validée.
- `data/game_store.dart` : SharedPreferences, schéma versionné, clés par utilisateur et difficulté, écritures séquentielles, records conservés après une nouvelle partie.
- `data/puzzle_photos.dart` : import/normalisation et suppression des copies dans le répertoire privé de l'application.
- `presentation/puzzle_board.dart` : rendu des fragments à partir d'une image décodée une seule fois et échanges animés.
- `presentation/word_grid.dart` : gestes, sélection des extrémités accessible, indices et intersections.
- `presentation/puzzle_page.dart`, `words_page.dart` : choix, partie et cycle de vie.
- `presentation/game_widgets.dart` : révélations et particules dorées communes, avec réduction des animations.

Intégration : sélection commune `/universe/games`, puis routes `/universe/puzzle` et `/universe/words` dans `lib/app/app.dart`, cartes dans `lib/features/together/presentation/universe_spaces.dart`.

## Ajouter des photographies

Depuis le jeu, **Ajouter ma photo** ouvre la photothèque via `image_picker`, déjà présent. L'utilisateur peut donner un titre. La copie est normalisée en PNG, avec une largeur maximale de 1 200 px et sans agrandissement. L'original reste intact ; retirer une photo du jeu supprime uniquement cette copie.

Pour les photos intégrées, compléter `PuzzlePhoto.catalog` :

```dart
PuzzlePhoto(
  'identifiant-stable',
  'Un titre choisi par nous',
  'assets/images/ma_photo.jpg',
  victory: 'Un message personnel.',
)
```

Déclarer l'asset dans `pubspec.yaml` si son dossier n'est pas déjà inclus. Ne pas changer un identifiant existant pour une autre image : la progression des pièces est liée à cet identifiant.

Le plateau utilise un **cadrage carré centré commun à toutes les pièces**, sans déformation. L'aperçu montre ce cadrage ; la victoire révèle la photo complète à son ratio original. Aucun découpage par IA, aucun envoi réseau.

## Personnaliser les grilles

Ajouter un `WordTheme` dans `WordTheme.catalog`. Fournir `id`, `title`, `description`, `words` (`StoryWord` contient libellé et message), `finalMessage` et `reversed` (false : doux ; true : avancé, huit directions).

Les accents sont conservés dans les textes et retirés uniquement dans les cases. Les mots normalisés doivent être distincts, composés de 2 à 24 lettres A–Z ; un thème contient 1 à 24 mots. Pour garder des lettres confortables sur téléphone, privilégier 6 à 8 mots courts, comme dans les thèmes inclus.

La signature des mots/directions invalide automatiquement une ancienne grille incompatible. Les identifiants versionnés permettent également de créer une nouvelle grille sans écraser l'historique d'une autre.

## Persistance et limites

- Préfixe `romantic-games.v1.<utilisateur>.`, séparé des données existantes.
- Puzzle : permutation, mouvements, temps écoulé, terminé au moins une fois, meilleur temps, minimum de mouvements par photo/difficulté.
- Mots : lettres exactes, placements, sélections trouvées, terminé au moins une fois.
- Une sauvegarde invalide relance une partie saine. Les échecs d'écriture et les images indisponibles proposent une nouvelle tentative.
- Les préférences restent une sauvegarde légère locale : fermeture forcée du système au moment précis d'une écriture ou désinstallation ne garantissent pas la conservation du dernier geste.
- Pas de glisser-déposer pour le puzzle : sélection puis échange, volontairement fiable sur écran tactile.

`path_provider` 2.1.6 est désormais une dépendance directe pour les photos privées ; cette version était déjà installée comme dépendance transitive. Aucun moteur de jeu ni backend supplémentaire.

## Validation

Tests : `test/romantic_games_test.dart` et `test/romantic_games_widgets_test.dart`.

```sh
flutter analyze
flutter test --concurrency=1
```

Le mode séquentiel limite l'espace temporaire nécessaire sur ce Mac. Les tests couvrent les trois difficultés, les sauvegardes invalides, les records après écritures successives, 120 générations de grilles dont les stratégies de secours, les intersections, les directions inversées, les gestes (y compris annulés/hors grille), les victoires/reprises et un écran 320 × 568 avec texte agrandi. Une vérification sur deux téléphones physiques reste utile avant distribution ; les tests Flutter ne remplacent pas le sélecteur natif de photos.
