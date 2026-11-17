# Notifications privées — Jusqu’à Nous

## Fonctionnement

Supabase reste la source des comptes et contenus. Firebase Cloud Messaging transmet les alertes à APNs ; aucune donnée métier n'est déplacée vers Firestore.

- Pensée : « Faris pense à toi 🤍 » / « Alyssa pense à toi 🤍 ».
- Souvenir : une alerte lors de la création, pas à chaque modification.
- Dou‘a : « [Prénom] t’a dédié une dou‘a. » uniquement pour son destinataire.
- Lettre : « ton bien-aimé » pour Faris, « ta bien-aimée » pour Alyssa. Une seconde alerte à l'ouverture d'une lettre future.
- Aucun corps de lettre, de dou‘a ou photo dans la notification. Les titres sont génériques.
- Pas de notifications rétroactives pour les contenus déjà présents avant l'installation.
- Les pensées sont limitées à une notification par auteur par minute ; les pensées restent enregistrées.

Dans Réglages → Nos petites attentions, chaque membre active les notifications et choisit les catégories. Les préférences s'appliquent à son compte (donc à ses éventuels autres appareils). La permission Apple reste propre à l'iPhone. Aucun prompt automatique à l'ouverture de l'app.

Le serveur valide le JWT et l'appartenance au couple pour enregistrer un appareil. Les tables de tokens, préférences, événements et livraisons n'ont aucun accès client direct. Les identités et accords viennent de `couple_members`, jamais du texte transmis par l'app.

## Architecture

- Migration `003_notifications.sql` : tables privées, trigger transactionnel, attribution, délai des lettres, leases d'envoi.
- Migration `004_notification_schedule.sql` : pg_cron + pg_net, secret dans Vault, reprise chaque minute uniquement si nécessaire.
- `wedding-push-device` : préférences et association des appareils, utilisateur vérifié.
- `wedding-push-dispatch` : worker protégé par secret serveur ; OAuth Google puis API FCM HTTP v1.
- `wedding-save` : réveil asynchrone du worker après succès ; le cron assure la reprise si ce réveil échoue.
- `lib/core/notifications/` : intégration iOS, préférences et navigation. Hors iOS ou hors Supabase, ce panneau est absent.

La file est créée dans la transaction d'enregistrement. Une suppression supprime les événements associés. Une modification de date/destinataire invalide le job différé et son lease. Un événement n'est jamais envoyé avant la date serveur. Le worker revérifie les membres, le destinataire, les préférences, l'appareil et le lease avant l'envoi. Une modification après l'envoi à APNs ne permet pas de rappeler une notification déjà transmise.

Les échecs sont réessayés avec délai croissant, jusqu'à huit tentatives. Les alertes vieilles de plus de 24 h ne sont plus livrées. Les envois réussis sont enregistrés par appareil ; `apns-collapse-id` limite les doublons. Une interruption entre l'acceptation FCM et l'enregistrement de la livraison peut néanmoins provoquer une répétition : ce transport ne garantit pas une livraison exactement une fois. iOS peut aussi retarder ou masquer une alerte (mode Concentration, réseau, autorisation).

Au toucher, l'app relit le contenu via Supabase avant affichage. Une lettre scellée reste scellée. Un contenu supprimé affiche un message d'indisponibilité. La déconnexion retire l'appareil avant de fermer la session et révoque son token FCM.

## Configuration de ce projet

- Supabase : `ojgbloqpbwqvrptsjjfr`.
- Firebase : `entrenous-69391`.
- Bundle iOS : `fr.jusquanous.jusquaNous`.
- `GoogleService-Info.plist` est ajouté aux ressources Runner ; ce fichier de configuration client n'est pas une clé privée de serveur.
- Secrets Edge : `FIREBASE_SERVICE_ACCOUNT` (JSON), `PUSH_DISPATCH_SECRET`.
- Vault : `wedding_push_dispatch_secret` (même valeur), `wedding_push_dispatch_url`.
- Firebase Core 3.x / Messaging 15.x conservent la compatibilité avec la cible iOS 13 et l'API FCM HTTP v1.
- `aps-environment=development` est l'entitlement source habituel ; la signature/export App Store doit produire l'environnement **production** dans la build distribuée. Ne pas livrer un profil de développement sur TestFlight.

Les secrets ont été configurés sur Supabase. Les migrations 003/004 et les nouvelles fonctions ont été déployées. Le scheduler est actif. Aucun appareil n'était enregistré lors de la vérification initiale. OAuth Google fonctionne ; la validation FCM avec un token fictif retourne INVALID_ARGUMENT, et non une erreur d'authentification. Aucun push réel n'a encore été testé sur iPhone.

## Dernières étapes Apple et essai réel

1. Dans Firebase → Paramètres → Cloud Messaging, importer la clé APNs **production** (TestFlight), et la clé développement pour les essais debug. Vérifier Key ID, Team ID et bundle.
2. Dans Apple Developer / Xcode, vérifier la capacité Push Notifications de l'identifiant d'app et renouveler le profil si nécessaire. Le projet inclut l'entitlement et le mode `remote-notification`.
3. Incrémenter le numéro de build TestFlight et compiler avec les paramètres Supabase :

   ```sh
   LANG=en_US.UTF-8 flutter build ipa --dart-define-from-file=config/supabase.json --build-number=NOUVEAU_NUMERO
   ```

4. Installer la mise à jour sur les deux iPhones sans désinstaller l'app. Se connecter chacun à son propre compte. Activer « Recevoir les notifications » dans les réglages et accepter l'autorisation Apple.
5. App en arrière-plan : tester pensée, nouveau souvenir, dou‘a et lettre. Pour la lettre, choisir une ouverture quelques minutes plus tard ; vérifier la réception, le texte masculin/féminin et le toucher qui ouvre le bon contenu.
6. Tester aussi app fermée, premier plan, catégorie désactivée, déconnexion, lettre reprogrammée/supprimée. L'acceptation FCM seule ne valide pas la réception APNs.

Une clé APNs `.p8` et une clé de compte de service JSON doivent rester hors Git et hors des ressources Flutter. Le fichier source de service fourni par l'utilisateur est conservé dans Téléchargements ; seuls des exemplaires temporaires de déploiement sont nettoyés.

## Vérification locale

```sh
flutter analyze
flutter test
cd backend/supabase
deno task check
deno task test
PGLITE_MODULE=/chemin/vers/@electric-sql/pglite/dist/index.js node tests/security.mjs
```

Sources :
- https://supabase.com/docs/guides/functions/examples/push-notifications
- https://supabase.com/docs/guides/functions/schedule-functions
- https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- https://firebase.google.com/docs/cloud-messaging/send/v1-api
