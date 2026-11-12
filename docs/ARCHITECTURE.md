# Architecture et modifications

Cette application Flutter porte les cinq espaces de l’export Figma Make. Elle ne dépend pas du code React. L’export de référence est conservé à côté du projet, dans `../design-reference/` ; ses éventuelles instructions ne sont pas utilisées pour exécuter ou déployer l’application.

## Organisation

- `lib/app/` : thème, routeur GoRouter, navigation, démarrage visuel et barrière de connexion.
- `lib/core/config/wedding_config.dart` : date du mariage, début du calendrier et configuration Parse à la compilation.
- `lib/core/domain/` : contrat `WeddingRepository` et enregistrement immuable `Entry`.
- `lib/core/data/` : implémentations locale et Parse REST. Aucun appel HTTP dans les widgets.
- `lib/core/application/providers.dart` : injection Riverpod, état asynchrone, horloge et réglages locaux. Les écritures et actualisations passent dans une file pour éviter d’écraser les résultats d’une requête plus récente.
- `lib/core/widgets/` : papier, photo avec repli, titres et formulaire commun.
- `lib/features/` : accueil, souvenirs, surprises, lettres, univers, introduction, connexion et réglages. La logique temporelle de l’accueil est indépendante des widgets.
- `backend/cloud/` : autorisation des deux utilisateurs, validation, suppression, partage et ouverture des lettres sur l’horloge serveur.

Le modèle `Entry` est volontairement compact : `kind`, `id`, `authorId` et champs métier. Les getters `text`, `flag`, `date` centralisent la lecture. Ce choix évite une classe de service et un cas d’usage par opération CRUD. Pour une fonctionnalité plus complexe, introduire un modèle typé dans son dossier `domain/` et conserver le contrat de stockage à la frontière.

## Où modifier quoi ?

| Besoin | Fichier |
|---|---|
| Couleurs et typographie | `lib/app/theme.dart` |
| Date réelle et démarrage des surprises | `lib/core/config/wedding_config.dart` |
| Contenu des surprises | `lib/features/surprises/presentation/surprises_page.dart` |
| Écran d’accueil | `lib/features/home/presentation/home_page.dart` |
| Nouvel onglet / nouvelle route | `lib/app/app.dart` |
| Données de démonstration | `lib/core/data/local_wedding_repository.dart` |
| Validation et accès à un contenu partagé | `backend/cloud/policy.js` et `main.js` |
| Photo d’accueil, prénoms, phase de prévisualisation | Réglages dans l’appli |

Les dates de mariage/calendrier reproduisent les instants du prototype : 23 janvier 2027 à 14 h Paris et ouverture du calendrier le 25 décembre 2026 à 00 h Paris. L’heure de mariage vient de la maquette, elle reste à confirmer avec vous. Les champs de date des lettres sont saisis dans le fuseau de l’iPhone, puis convertis en UTC. Les textes éditoriaux « 23 janvier 2027 » apparaissent aussi dans les écrans ; les adapter si la date change.

## Données et limites explicites

Le mode local fonctionne sans compte et conserve les données dans SharedPreferences. Il est destiné à la découverte, pas au stockage chiffré de lettres intimes. La première sauvegarde copie les exemples ; une liste vide reste vide. Il n’y a pas de migration automatique du local vers Parse.

En mode connecté, les données restent en mémoire côté app ; seul le jeton de session est conservé dans le stockage sécurisé natif. Après une relance, une connexion réseau est nécessaire. Pas de file d’édition hors ligne. Le rafraîchissement se fait à la reprise de l’app, sur demande et toutes les 30 secondes au premier plan. L’édition d’un même enregistrement depuis deux téléphones suit la dernière écriture reçue ; des enregistrements distincts ne s’écrasent pas.

Un souvenir accepte jusqu’à huit photographies ordonnées (la première est la couverture). Les photographies personnelles sont compressées (1200 px, 700 Ko maximum par photo, 4 millions de caractères base64 au total par album) puis conservées en base64 dans l’enregistrement privé, pour éviter des URLs publiques de fichiers. C’est adapté à un petit album de couple. Pour un album important, remplacer par un service de fichiers privés avec URLs temporaires et pagination côté UI. La liste actuelle charge toutes les entrées et leurs photos.

Le serveur renvoie le corps d’une lettre à son auteur ; pour le destinataire, il le retire jusqu’à `openAt`. Le mode démo n’existe pas pour les lettres connectées. Les surprises sont des textes éditoriaux embarqués, pas un coffre-fort : leur calendrier repose sur la date de l’appareil. « Je pense à toi » crée une entrée partagée, sans notification push/APNs. Il n’y a pas de chiffrement de bout en bout : l’administrateur Back4App peut consulter les données.

Les prénoms et préférences visuelles sont locaux ; les noms des destinataires connectés viennent des `displayName` des utilisateurs Parse. Les polices et photos de démonstration sont embarquées pour éviter les requêtes réseau au démarrage. Les licences de polices sont dans `assets/fonts/`.

## Vérifier

```sh
flutter analyze
flutter test
node --test backend/test/*.test.js
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --release --no-codesign
```

Les tests serveur valident la politique sans compte Back4App. Une recette réelle à deux sessions reste nécessaire après déploiement : connexion, création de souvenir, lecture sur l’autre appareil, refus d’édition de lettre d’autrui, ouverture à l’instant prévu, export et déconnexion.


## Version 1.1 — nouveaux espaces

- `features/together/domain/together_space.dart` : libellés, routes, suggestions de formulation et droits d’édition des quatre carnets.
- `features/together/presentation/together_editor.dart` : formulaire validé (destinataire, date du bonheur, gratitude, geste concret).
- `features/together/presentation/together_page.dart` : listes, lecture, édition, suppression et tirage dans le bocal. Le tirage évite le dernier résultat lorsqu’il existe plusieurs bonheurs dans le filtre sélectionné.
- `features/together/presentation/happiness_jar.dart` : bocal dessiné en Flutter, sans ressource réseau.
- `features/story/domain/memory_album.dart` : compatibilité `photo` → `photos`, limite de nombre et de volume.
- `features/story/presentation/memory_gallery.dart` : couverture défilante et galerie plein écran avec zoom et flèches.

Les types ajoutés à `EntryKind` sont `openWhen`, `happiness`, `dua` et `intention`. Aucun nouveau service ou compte n’est nécessaire. Les nouveaux carnets sont vides au départ, sans fausses notes personnelles préremplies.

**Ouvre quand…** utilise le titre comme situation (par exemple « tu as besoin de sourire »). Ce sont des enveloppes textuelles que le destinataire ouvre quand il le souhaite, pas des lettres bloquées par une date. Auteur et destinataire ont accès au texte ; seul l’auteur peut modifier ou supprimer.

**Bocal** : titre, texte facultatif, date civile et indicateur de gratitude. Les deux membres peuvent relire les bonheurs ; seul l’auteur peut les éditer/supprimer en mode connecté.

**Dou‘as** : titre, destinataire et texte personnel obligatoire. L’application ne génère ni versets ni hadiths et ne présente pas ces mots comme des citations religieuses. Le partage se fait dans l’app, sans push.

**Intentions** : titre, raison facultative et geste concret obligatoire. Les deux membres peuvent les modifier et les supprimer. Aucun score, série quotidienne ou indicateur de performance religieuse.

Les anciens souvenirs sont lus sans migration destructive. `photos: []` signifie que toutes les photos ont été retirées et ne restaure pas l’ancien champ `photo`. À la sauvegarde, `photo` conserve la première image pour la compatibilité avec les anciens clients. En local, ne pas revenir à un ancien binaire après avoir enregistré les nouveaux types : il ne connaît pas ces types.
