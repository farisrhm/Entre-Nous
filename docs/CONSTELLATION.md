# Notre ciel

Accès : **Souvenirs → Explorer notre constellation** (`/story/sky`).

Chaque souvenir et chaque lettre fournis par le dépôt existant deviennent un astre. Les données ne sont ni copiées ni modifiées : ajouts, modifications et suppressions se reflètent lors de la mise à jour de `entriesProvider`.

- Position déterministe calculée à partir du type et de l'identifiant : ajouter un souvenir ne déplace pas les précédents.
- Ciel déplaçable et zoomable, recentrage, zones tactiles conservant 48 points à l'écran, liste alternative « Tous nos astres ».
- Souvenirs dorés, lettres claires, scintillement discret désactivé avec la réduction des animations.
- Les albums utilisent la galerie existante, avec toutes leurs photos et les mêmes accès au stockage privé.
- Les lettres suivent les mêmes règles que la page Lettres : en cloud, disponibilité accordée par le serveur ou lecture par leur auteur. Le mode démonstration et la date du téléphone ne contournent pas ce contrôle.
- Le cœur central apparaît à partir du 23 janvier 2027, à minuit heure de Paris, puis reste visible. Sa date dérive de `WeddingConfig.wedding`.

Fichiers : `lib/features/constellation/domain/love_sky.dart` (positions et règles), `presentation/sky_painter.dart` (rendu), `presentation/constellation_page.dart` (exploration et lecture), `test/constellation_test.dart`.

Aucune dépendance ni migration Supabase supplémentaire. Les photos distantes gardent les contraintes réseau de la galerie existante. Le fond décoratif contient aussi de petites étoiles non interactives ; seuls les astres lumineux représentent vos contenus.
