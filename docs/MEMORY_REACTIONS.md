# Réactions aux souvenirs

Un appui long sur un souvenir ou sa photo ouvre le sélecteur. Le bouton **Réagir** offre la même action sans appui long. Disponible dans l'album, la galerie plein écran et les souvenirs ouverts depuis Notre ciel.

- Une réaction par personne et par souvenir, remplaçable ou supprimable.
- Douze choix rapides et saisie d'un autre emoji avec le clavier système. Les drapeaux, tons de peau et séquences composées sont conservés.
- Les réactions identiques sont regroupées avec leur nombre. L'infobulle indique les personnes.
- Confirmation après sauvegarde réussie, message d'erreur et nouvelle tentative en cas d'échec. Les requêtes cloud expirent après douze secondes.

## Stockage

`006_memory_reactions.sql` ajoute `memory_reactions` et la RPC `set_memory_reaction`. Migration appliquée au projet EntreNous, puis permissions contrôlées en lecture seule. Aucune autre migration n'a été appliquée durant cette fonctionnalité.

La clé primaire est `(entry_key, user_id)`. L'utilisateur est déterminé par `auth.uid()`, jamais par le client. Seuls les deux membres peuvent lire. Les écritures passent par la RPC : souvenir existant requis, protection par verrou, remplacement atomique de sa propre ligne. La suppression d'un souvenir supprime ses réactions par cascade. Ni le JSON de l'album ni ses photos ne sont réécrits.

Le mode local utilise une clé SharedPreferences séparée. Dans Supabase, un seul chargement partagé pour tous les souvenirs visibles est actualisé toutes les quinze secondes ; les modifications locales sont relues immédiatement. Pas de push notification ajouté pour les réactions.

## Code et vérifications

- `lib/features/story/domain/memory_reaction.dart` : modèle et validation d'un emoji composé unique côté app.
- `lib/features/story/data/memory_reaction_store.dart` : stockage local / Supabase.
- `lib/features/story/application/memory_reactions.dart` : état partagé, sauvegardes séquentielles, actualisation regroupée.
- `lib/features/story/presentation/memory_reactions.dart` : appui long, badges et sélecteur.
- `test/memory_reactions_test.dart` : choix, remplacement, retrait, regroupement, erreurs, petits écrans et emojis composés.
- `backend/supabase/tests/reactions.mjs` : PostgreSQL temporaire via PGlite, droits, isolation entre partenaires, absence d'altération des albums, cascade et migration réexécutable.

Validation : 70 tests Flutter réussis, `flutter analyze` sans problème, tests PostgreSQL réussis. Il reste à installer le nouveau build sur les téléphones pour une vérification réelle du clavier emoji et de la synchronisation entre appareils. Aucune nouvelle dépendance de l'application.
