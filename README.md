# Jusqu’à Nous — Alyssa & Faris

Application Flutter issue de votre maquette Figma Make, pour votre mariage du 23 janvier 2027. Cinq onglets : accueil et compte à rebours, albums de souvenirs, calendrier de 30 surprises, lettres et enveloppes « Ouvre quand… », univers commun. Univers rassemble le bocal des petits bonheurs, les dou‘as personnelles, les intentions de votre foyer, vos promesses et vos rêves.

## Démarrage local

```sh
flutter pub get
flutter run
```

Sans configuration cloud, le mode local est indiqué dans l’interface. Les exemples, polices et photographies sont embarqués. Les modifications sont conservées sur cet appareil.

## Votre espace commun

Le mode connecté privilégie Supabase (Auth + Edge Functions). Parse Back4App reste disponible en fallback pour les anciens environnements.

### Supabase (par défaut, stockage cloud)

```sh
cp config/supabase.example.json config/supabase.json
# Renseigner SUPABASE_URL + SUPABASE_PUBLISHABLE_KEY
flutter run --dart-define-from-file=config/supabase.json
```

Backend SQL + Edge Functions prêts: `backend/supabase/README.md`.

Chaque personne utilise son propre compte Supabase une fois, puis sa session est mémorisée. Aucun email ni mot de passe n’est embarqué dans la build. Les anciennes sessions partagées sont retirées au premier lancement de cette version. Les originaux photo (JPEG, PNG, WebP, 20 Mio maximum) sont enregistrés dans un bucket privé, avec des miniatures séparées.

### Parse Back4App (fallback)

```sh
cp config/parse.example.json config/parse.json
# Renseigner Application ID + Client Key, jamais la Master Key.
flutter run --dart-define-from-file=config/parse.json --dart-define=WEDDING_CLOUD_MODE=on
```

- [Modifier l’app et comprendre l’architecture](docs/ARCHITECTURE.md)
- [Configurer le backend Back4App](docs/BACK4APP.md)
- [Configurer le backend Supabase](backend/supabase/README.md)
- [Préparer TestFlight](docs/TESTFLIGHT.md)

Stack : Flutter, Riverpod, GoRouter, SharedPreferences en local, stockage sécurisé des sessions natives et API REST Parse. Les écrans sont organisés par fonctionnalité, le thème et l’accès aux données sont centralisés.

## Vérification

```sh
flutter analyze
flutter test
node --test backend/test/*.test.js
```

Le code peut être testé sans backend. Les connexions réelles, l’accès à deux téléphones et la signature TestFlight doivent être vérifiés après configuration des comptes. L’app n’a pas été envoyée à Apple et aucun backend n’a été créé automatiquement.

Les surprises reprennent les sept textes cycliques de la maquette sur 30 cases. Les pensées ne déclenchent pas de push. Les lettres locales ne sont pas chiffrées ; le mode connecté applique l’ouverture côté serveur. Voir le document d’architecture pour les limites de synchronisation et d’album photo.


## Nouveautés 1.1.0+2

- **Souvenirs** : jusqu’à huit photos, couverture, ordre modifiable, galerie plein écran et zoom. Les souvenirs à une seule photo restent compatibles.
- **Lettres → Ouvre quand…** : enveloppes textuelles pour une situation, adressées à l’un des deux membres.
- **Univers → Bocal** : ajouter, dater, modifier, supprimer, filtrer par gratitude et piocher un bonheur.
- **Univers → Une dou‘a pour toi** : invocations personnelles partagées dans l’app.
- **Univers → Intentions** : une valeur et un geste concret, modifiables à deux.

Pour Supabase, appliquer les migrations et redéployer les trois Edge Functions selon `backend/supabase/README.md`. Pour les anciennes installations Parse, utiliser le guide Back4App. Aucun déploiement distant ni envoi TestFlight n’est effectué automatiquement.
