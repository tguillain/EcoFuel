# CLAUDE.md

EcoFuel : application Flutter qui compare les prix des carburants autour de
l'utilisateur (liste, carte, fiche station). Prix : API data.economie.gouv.fr ;
enseignes : OpenStreetMap (Overpass) ; itinéraires : OSRM.

## Stack

- Flutter / Dart (SDK `^3.13`), Material, `google_fonts`
- `http` pour les API, `geolocator` pour la position
- `flutter_map` + `latlong2` pour la carte (tuiles OpenStreetMap)
- Tests : `flutter_test` uniquement

## Installer, lancer, tester

```bash
flutter pub get
flutter run -d chrome --dart-define=FIXED_LATITUDE=47.2184 --dart-define=FIXED_LONGITUDE=-1.5536
flutter analyze
flutter test
```

Sans `--dart-define`, l'app interroge le vrai GPS. Les configurations de
lancement VS Code sont dans `.vscode/launch.json`.

## Conventions

- Code par fonctionnalité sous `lib/<fonctionnalité>/` (`enum/`, `model/`,
  `service/`, `widget/`, `formatter/`) ; les tests reprennent la même
  arborescence sous `test/`.
- Commentaires et libellés en français.
- Fichiers de moins de 300 lignes : sortir un widget ou un helper dans son
  propre fichier plutôt que de laisser grossir un fichier.
- Le code passe `flutter analyze` sans avertissement et `dart format`.

## Commits

Message en français, au présent, commençant par un verbe : « Ajoute la vue
carte des stations », « Retire E85 et GPLc de la liste des carburants ».
Corps optionnel qui explique le pourquoi. Le trunk est `main` ; on travaille
sur des branches `feature/...` fusionnées par pull request GitHub.
