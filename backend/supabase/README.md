# Supabase — espace privé à deux

Le client utilise deux comptes Auth distincts, une connexion par personne puis une session mémorisée. Aucun mot de passe ne doit figurer dans les `dart-define`. Cette version retire une fois les anciennes sessions du compte partagé. Si un mot de passe partagé a déjà été distribué dans une build, le changer et révoquer ses sessions depuis Supabase Auth.

## Déploiement sur votre projet existant

1. Dans SQL Editor, appliquer `migrations/001_init_wedding.sql` si elle n'a jamais été appliquée, puis **`migrations/002_private_storage_atomic.sql`**. La seconde ferme la vue de debug, crée le bucket privé `wedding-photos` (20 Mio par objet) et les opérations atomiques. Elle conserve les entrées existantes. Chaque migration ne doit être appliquée qu'une fois via le suivi des migrations.
2. Le script `configure_members.sql` contient les deux UUID fournis : renseigner `first_name` avec le prénom confirmé, puis l’exécuter. Il refuse de supprimer silencieusement un ancien membre. Associer exactement vos deux UUID Auth à `couple_id = 'couple'` dans `public.couple_members`, avec les bons `display_name`. Vérifier les lignes existantes avant toute modification ; ne pas conserver le compte partagé comme troisième membre. Ne pas supprimer d'utilisateur Auth possédant des souvenirs : la FK supprimerait ses entrées en cascade.
3. Déployer **ensemble** `wedding-list`, `wedding-save`, `wedding-delete`, en incluant leurs imports `_shared`. Les variables serveur `SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` sont utilisées uniquement dans les fonctions. Ne jamais copier la service-role key dans Flutter.
4. Le fichier `config.toml` désactive la vérification JWT historique de la passerelle pour supporter les clés de signature asymétriques ; chaque fonction vérifie explicitement le JWT par `auth.getUser(token)` puis l'appartenance au couple **avant** toute opération privilégiée. Ne pas supprimer cette vérification.
5. Compiler les deux apps avec `config/supabase.json` : `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `WEDDING_CLOUD_MODE=auto` ou `supabase`. Aucun email/mot de passe n'est nécessaire dans ce fichier.

Avec le CLI officiel, depuis le dossier Flutter (remplacer PROJECT_REF par la référence du projet) :

```sh
supabase functions deploy wedding-list --workdir backend --project-ref PROJECT_REF
supabase functions deploy wedding-save --workdir backend --project-ref PROJECT_REF
supabase functions deploy wedding-delete --workdir backend --project-ref PROJECT_REF
flutter run --dart-define-from-file=config/supabase.json
```

L'app affiche un écran récupérable si son initialisation échoue. Une connexion refusée par les règles du couple est retirée localement, afin de ne pas laisser de session inutilisable.

## Photos : originaux privés et miniatures

Les nouvelles photos ne sont plus redimensionnées ni recompressées par le picker en mode Supabase. Les octets JPEG/PNG/WebP fournis par iOS sont téléversés tels quels (20 Mio maximum), avec une miniature PNG de 800 pixels de large. Le sélecteur iOS peut lui-même convertir certains formats ; les fichiers HEIC non convertis ne sont pas acceptés. Huit photos maximum par souvenir.

La base contient des références `storage:wedding-photos/USER_UUID/IDENTIFIANT.jpeg`, jamais de lien public. La liste affiche la miniature ; la galerie plein écran télécharge l'original avec le JWT courant. Les transferts sont séquentiels afin de ne pas garder huit originaux en mémoire. Le téléchargement complet des originaux n'est plus répété à chaque synchronisation.

Les règles autorisent la lecture aux deux membres et l'insertion uniquement dans le dossier de l'utilisateur courant. Les clients ne peuvent ni écraser ni supprimer un fichier déjà partagé. Les politiques restrictives protègent aussi ce bucket si d'anciennes politiques Storage permissives existent. Les photos importées puis abandonnées et celles retirées d'un album restent donc dans Storage : prévoir un nettoyage administrateur des objets non référencés (après délai de grâce), et sauvegarder le bucket séparément du JSON. Aucun nettoyage destructif automatique n'est exécuté.

Les anciennes photos base64 restent lisibles. Elles passent dans Storage lors de la prochaine sauvegarde de leur souvenir ; aucune migration destructive en masse. On ne peut pas restaurer la définition déjà perdue par une ancienne compression. Réimporter l'original si nécessaire. Les anciennes builds (`schemaVersion < 3`) ne reçoivent pas les souvenirs utilisant Storage et ne peuvent pas écraser leurs photos : mettre à jour les deux appareils.

## Contrôles et limites

- Les deux comptes voient le même souvenir, mais restent des auteurs distincts.
- Les auteurs seuls modifient leurs lettres/dou‘as/bonheurs ; rêves, souvenirs et intentions restent partagés.
- Les lettres futures ne renvoient pas leur corps au destinataire, même via l'export JSON.
- Les tables d'entrées restent inaccessibles directement ; aucune lecture de la vue de debug n'est accordée aux clients.
- Les sauvegardes/suppressions verrouillent leur clé dans une transaction. Le contrôle d'auteur et l'écriture s'exécutent ensemble, et l'auteur existant n'est jamais remplacé.
- La liste est paginée côté fonction, sans troncature silencieuse à 1 000 entrées. Les anciennes images inline peuvent encore rendre la réponse volumineuse jusqu'à leur migration.
- L'export JSON contient des références Storage, pas une sauvegarde des originaux.
- Les contenus éventuellement écrits sous l'ancien compte partagé gardent leur auteur ; réattribution uniquement après examen manuel des données.

Tests (sans accès à la base distante) :

```sh
flutter test
cd backend/supabase
deno task check
deno task test
# Installer @electric-sql/pglite dans un dossier d'outillage, puis :
PGLITE_MODULE=/chemin/node_modules/@electric-sql/pglite/dist/index.js node tests/security.mjs
```

Le test SQL utilise un PostgreSQL embarqué et des tables Auth/Storage minimales : il vérifie les migrations, la RLS et les RPC, pas le service Storage hébergé ni une charge concurrente multi-connexion. Avant TestFlight, vérifier les opérations photo et une lettre différée sur deux sessions réelles. Rien dans ces scripts ne déploie ni ne modifie automatiquement le projet distant.
