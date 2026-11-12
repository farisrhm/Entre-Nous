# TestFlight pour nous deux

TestFlight distribue l’application ; Supabase partage les données. Un compte Apple Developer Program et une fiche App Store Connect sont nécessaires. Une build TestFlight expire au bout de **90 jours**, même pour deux personnes. Prévoir une nouvelle build avant expiration.

## Préparer la build

1. Configurer Supabase et `config/supabase.json` comme indiqué dans `../backend/supabase/README.md` : migrations 001 puis 002, deux membres et trois fonctions.
2. Ouvrir `ios/Runner.xcworkspace` dans Xcode.
3. Sélectionner votre équipe Apple dans Signing & Capabilities. Le bundle identifier initial est `fr.jusquanous.jusquaNous` ; le changer si nécessaire et utiliser la même valeur dans App Store Connect.
4. Tester sur vos iPhone, particulièrement la sélection de photos, la connexion, le stockage Keychain et l’export via la feuille de partage iOS.
5. Créer la fiche de l’app dans App Store Connect et incrémenter le numéro de build à chaque envoi.

```sh
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ipa --release \
  --dart-define-from-file=config/supabase.json \
  --build-name=1.1.0 --build-number=2
```

La version locale se compile sans `--dart-define-from-file`, mais elle **ne partage aucune donnée entre vos téléphones**. Pour une archive via Xcode, compiler/configurer d’abord Flutter avec ces mêmes paramètres : ne pas perdre les dart-defines en changeant de méthode de build.

Le build `flutter build ios --no-codesign` vérifie la compilation sans fournir d’IPA installable. L’archive signée nécessite votre équipe, votre bundle ID et votre provisioning.

## Distribuer

Envoyer l’IPA depuis Transporter ou distribuer l’archive depuis Xcode Organizer vers App Store Connect. Compléter les questions de conformité/chiffrement selon la configuration effectivement utilisée.

- **Toi** : testeur interne si tu as le rôle et l’accès nécessaires dans App Store Connect.
- **Ta copine** : invitation externe par email ; la première build externe passe par TestFlight App Review. Si elle est déjà une utilisatrice App Store Connect éligible avec accès à l’app, elle peut être interne. Inutile de lui donner des droits d’administration uniquement pour installer l’appli.

L’accès à l’app nécessite l’un des deux comptes Supabase. Pour une review externe, fournir à Apple un accès de revue dans un backend **de démonstration séparé**, avec deux comptes de démo et les deux membres attendus dans `couple_members`. Ne pas communiquer vos vrais identifiants ou vos lettres privées à la revue. Cette configuration séparée demande une build de démonstration et une stratégie de sélection du backend avant de distribuer une build connectée à vos données réelles. Le backend courant n’accepte que deux membres ; un troisième compte de revue ajouté au couple bloquerait l’accès à tous. Décider de cette configuration avant la première soumission externe.

La première version partage les pensées dans l’app mais n’envoie pas de notifications push. Aucun certificat APNs n’est nécessaire tant que cette fonction n’est pas ajoutée.

Références : [TestFlight](https://developer.apple.com/testflight/), [tests internes/externes](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/), [distribution iOS Flutter](https://docs.flutter.dev/deployment/ios).
