# Les petites attentions

## Ce qui est livré

Univers → Les petites attentions : trois modèles immédiats (massage, petit-déjeuner, soirée), création personnalisée avec aperçu, enveloppes, demandes et contre-propositions, réalisation réversible et historique. Aucun bon n’expire. Les comptes et `couple_members` existants sont réutilisés. Aucune donnée de démonstration n'est insérée.

Flutter : `lib/features/attentions/` sépare le modèle et les modèles de bons, le repository Supabase, les providers Riverpod et les widgets. Pour ajouter un modèle, mettre à jour `AttentionTemplate.all` et la contrainte serveur `template_key` via une nouvelle migration. Les messages sont limités côté formulaire et PostgreSQL.

## Déploiement (pas encore exécuté sur la production)

1. Appliquer **une seule fois** `backend/supabase/migrations/005_couple_vouchers.sql` dans le SQL Editor du bon projet Supabase. Les migrations 001 à 004 doivent déjà être présentes. Le script est transactionnel. Ne pas relancer les anciennes migrations et ne pas utiliser de reset.
2. Déployer les deux fonctions modifiées avec leur dépendance partagée :

   ```sh
   cd /Users/alkatraz/Documents/Projet/Wedding/jusqua_nous/backend
   supabase functions deploy wedding-push-device wedding-push-dispatch --remote=ojgbloqpbwqvrptsjjfr --use-api --yes
   ```

   Cette commande correspond au CLI 3 utilisé dans ce projet. Pour un autre CLI, vérifier son aide. La configuration `verify_jwt` demeure inchangée : contrôle utilisateur existant dans device, secret de serveur dans dispatch.
3. Construire la nouvelle application après ces deux étapes. Aucun nouveau secret ni clé privilégiée n’est nécessaire dans Flutter. Les préférences de notification incluent désormais « Bons et petites attentions ».
4. Vérifier avec les deux comptes : offre → ouverture → demande → contre-proposition → acceptation → réalisation → annulation de réalisation. Vérifier un envoi sans date et un retrait de demande. Les alertes restent génériques et n'exposent ni le texte du bon ni son message personnel.

L’ancien client reste compatible. Le worker existant doit être mis à jour avant l’utilisation des bons pour reconnaître les nouveaux événements. La planification cron existante déclenche les notifications (délai habituel jusqu’à une minute, sans garantie de livraison APNs/FCM).

## Sécurité et transitions

Tables `couple_vouchers` et `couple_voucher_events`, RLS activée, aucune écriture directe par `authenticated` ou `anon`. Seuls les participants appartenant encore au couple peuvent lire. Les FK réutilisent l’appartenance existante. Les RPC utilisent `auth.uid()`, un search_path vide, des vérifications de rôle et un verrou de ligne.

- Destinataire : ouvrir, demander, retirer une demande.
- Expéditeur : accepter la demande initiale, proposer une date, choisir plus tard, annuler un bon non demandé.
- Une contre-proposition attend l’acceptation du destinataire.
- Chacun peut confirmer une réalisation demandée/acceptée ou annuler cette confirmation. L’état précédent est restauré.
- Un report rend le bon disponible, sans effacer l’historique.
- Annuler le bon lui-même est explicite et définitif ; il reste consultable avec son statut.

Les versions bloquent les décisions sur un état périmé. Un UUID stable d’offre et un UUID d’opération rendent les retries idempotents. Après un envoi non confirmé, le formulaire conserve le contenu et la même clé. Fermer puis actualiser permet de vérifier si l’envoi a effectivement réussi. Aucune confirmation optimiste de réussite.

L’enveloppe est une présentation : le destinataire est autorisé à lire son bon avant ouverture ; `opened_at` décrit la découverte dans l’app, pas un mécanisme de chiffrement.

## Synchronisation

Le repository existant n'utilise pas Realtime. Le carnet se recharge toutes les 20 secondes pendant que son écran est monté et l’application au premier plan, au retour dans l’app et après une action. L’historique est actualisé lorsque la version du bon change. Bouton Actualiser et pull-to-refresh disponibles. Pas de publication Realtime ni nouvelle dépendance.

## Vérifications locales

```sh
flutter test test/attentions_test.dart
flutter analyze --no-pub
PGLITE_MODULE=/chemin/vers/@electric-sql/pglite/dist/index.js node backend/supabase/tests/vouchers.mjs
# Vérifie la sécurité PostgreSQL dans une base éphémère, sans toucher Supabase.
deno check backend/supabase/functions/wedding-push-device/index.ts backend/supabase/functions/wedding-push-dispatch/index.ts
deno test backend/supabase/tests/push_messages_test.ts
```

Les tests SQL couvrent deux couples, un tiers, la lecture RLS des deux tables, le refus des écritures directes, les rôles, chaque transition, la réalisation réversible, les retries, les versions périmées et l’outbox transactionnelle. Les tests Flutter couvrent les modèles, le formulaire, l’aperçu, les champs obligatoires, les envois concurrents et le retry après perte de réponse.

Le test réel entre deux téléphones et la réception push restent à effectuer après application de la migration et déploiement des fonctions.
