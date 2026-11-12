# Un backend pour deux personnes

Créer **une application Backend as a Service / Parse dans Back4App**, dédiée à Jusqu’à Nous. Aucun tenant par personne : deux lignes `_User`, un rôle `couple`, une classe `WeddingEntry`.

## 1. Comptes et permissions

Dans le dashboard Back4App :

1. Créer les deux utilisateurs `_User` avec un `username`, un mot de passe différent pour chacun, et un champ String `displayName` (`Alyssa` / `Faris`). Conserver les mots de passe dans votre gestionnaire, pas dans le projet.
2. Créer un rôle `_Role` nommé exactement `couple` et ajouter les deux utilisateurs dans sa relation `users`. Il doit contenir exactement deux utilisateurs. Mettre son ACL privée (ni lecture ni écriture publiques).
3. Restreindre les permissions de classe `_Role` aux opérations administrateur/master : pas de création, modification ou lecture client. Désactiver les inscriptions publiques et la création de classes par les clients. Pour `_User`, supprimer la lecture publique et la recherche publique ; l’authentification par identifiant/mot de passe doit rester fonctionnelle. Utiliser le dashboard pour administrer les comptes.
4. Créer `WeddingEntry` avec les champs String `key`, `entryId`, `kind`, `authorId` et Object `fields`. Refuser **toutes** les opérations client directes (find, get, count, create, update, delete, addField). Les Cloud Functions utilisent la master key uniquement sur le serveur.
5. Ajouter un index **unique** sur `key` dans la base, via les outils d’indexation Back4App disponibles pour l’application. Cela évite les doublons si deux requêtes de création du même identifiant arrivent simultanément. Chaque clé est `kind:id`.

Cette application est dédiée à vous deux : ne pas déployer ces restrictions de rôles sur un backend partagé avec une autre application.

## 2. Cloud Code

Déployer **les deux fichiers** `backend/cloud/main.js` et `backend/cloud/policy.js` dans le dossier `cloud` de Back4App. Le point d’entrée est `main.js`. Aucun package npm supplémentaire n’est nécessaire : Parse est fourni par le runtime.

Fonctions exposées :

- `weddingList` : vérifie le rôle, renvoie les deux membres et filtre les lettres selon l’utilisateur et l’heure serveur.
- `weddingSave` : valide les champs ; l’auteur uniquement peut modifier lettres, promesses et pensées ; souvenirs et rêves sont partagés.
- `weddingDelete` : applique les mêmes règles de propriété.

Les triggers refusent aussi les lectures/écritures REST directes sur `WeddingEntry` et les modifications client des rôles. Tous les objets sont créés avec une ACL privée.

## 3. Configuration Flutter

Copier le fichier exemple :

```sh
cp config/parse.example.json config/parse.json
```

Renseigner `PARSE_APP_ID` et `PARSE_CLIENT_KEY` depuis les paramètres de votre application Back4App. Conserver `PARSE_SERVER_URL` à `https://parseapi.back4app.com` sauf serveur personnalisé. **Jamais de master key dans Flutter.** Les clés client identifient l’app, elles ne remplacent ni les sessions ni les permissions serveur.

```sh
flutter run --dart-define-from-file=config/parse.json
```

Sans ces deux clés, l’application démarre en mode local avec un bandeau explicite. Le mode connecté démarre sur l’écran de connexion et ne copie pas les exemples locaux. Le fichier `config/parse.json` est ignoré par Git.

## 4. Recette sur deux sessions

- Se connecter avec les deux comptes. Un compte hors du rôle doit recevoir un refus.
- Créer un souvenir sur A ; actualiser B ; vérifier le texte et la photo.
- Créer une lettre de A à B ouvrable dans deux minutes. B voit le titre mais ne reçoit pas `body`, même dans son export JSON. B ne peut ni modifier ni supprimer cette lettre.
- Modifier l’heure du téléphone B : cela ne doit pas révéler la lettre. À l’heure serveur prévue, actualiser B et vérifier l’ouverture.
- Tester la reconnexion après redémarrage, puis la déconnexion et la connexion de l’autre compte sur le même appareil.
- Vérifier que les requêtes REST directes sur `WeddingEntry` échouent, même avec une session valide.

Sans application Back4App configurée, ces points ne peuvent pas être certifiés depuis le projet seul. Les tests de politique sont exécutables localement avec `node --test backend/test/*.test.js`.

Documentation : [Back4App et Flutter](https://www.back4app.com/docs/flutter/parse-sdk/parse-flutter-sdk), [Parse Cloud Code](https://docs.parseplatform.org/cloudcode/guide/), [permissions Parse](https://docs.parseplatform.org/rest/guide/#security).


## Mise à jour vers 1.1

Redéployer **ensemble** `backend/cloud/main.js` et `backend/cloud/policy.js`, puis installer la version Flutter 1.1 sur les deux appareils. La classe `WeddingEntry` et le rôle `couple` restent identiques ; il n’y a pas de suppression ou réinitialisation des données.

Le client passe `schemaVersion: 2` à `weddingList` et `weddingSave`. Les anciens clients connectés ne reçoivent pas les nouveaux types qu’ils ne savent pas lire ; une ancienne application ne peut pas modifier un album contenant plusieurs photos. Les ACL privées et les règles des lettres différées restent inchangées.

Recette supplémentaire sur deux comptes :

1. Créer une enveloppe « Ouvre quand… » et une dou‘a de A vers B. Vérifier leur lecture par B et le refus d’édition/suppression par B, y compris en appelant les fonctions directement.
2. Créer un bonheur sur A, le retrouver dans le bocal sur B et le filtrer par gratitude. B ne peut pas le modifier.
3. Créer une intention sur A, modifier son geste concret sur B, puis actualiser A.
4. Importer plusieurs photos sur A, les réordonner, les ouvrir sur B. Retirer toutes les photos et vérifier que l’ancienne couverture ne réapparaît pas.
5. Vérifier la conservation des entrées après redémarrage, ainsi que l’export JSON des nouveaux contenus.

Les albums sont conservés dans les enregistrements privés : huit photos maximum, 950 000 caractères par photo et 4 000 000 de caractères pour le tableau complet. Le champ de couverture `photo` est également conservé pour compatibilité. Vérifier les limites de taille des requêtes de votre instance Back4App lors de la recette. L’album entier est chargé à chaque actualisation : pour une grande photothèque, prévoir un stockage privé paginé.
