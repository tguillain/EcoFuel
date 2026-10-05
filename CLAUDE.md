# CLAUDE.md

EcoFuel est une application Flutter qui liste les stations-service proches de
l'utilisateur et compare leurs prix.

## Stack

- Flutter, Dart `^3.13.3`, Material 3 ; police via `google_fonts`.
- Données : API ouverte « prix des carburants en France — flux instantané v2 »
  de `data.economie.gouv.fr`, appelée avec `http`. Les enseignes viennent
  d'Overpass (OpenStreetMap). Aucune clé d'API.
- Position : `geolocator`, derrière l'interface `UserLocator`.
- État : `StatefulWidget` + `setState`, sans bibliothèque de gestion d'état.
- Lint : `flutter_lints` (`analysis_options.yaml`).

## Organisation

Un dossier par fonctionnalité sous `lib/`, découpé en `enum/`, `formatter/`,
`model/`, `service/` et `widget/` (voir `lib/gas_station_list/`). Le transverse
vit dans `lib/config/` et `lib/theme/`. Les tests reprennent la même
arborescence sous `test/`.

Les services prennent leurs dépendances par le constructeur (`UserLocator`,
`StationBrandDirectory`) pour pouvoir être remplacés par des doublures en test.

## Lancer

```bash
flutter pub get
flutter run
```

Sans `--dart-define`, l'app utilise le vrai GPS. Pour figer la position :

```bash
flutter run --dart-define=FIXED_LATITUDE=47.2184 --dart-define=FIXED_LONGITUDE=-1.5536
```

ou copier `env/location.example.json` en `env/location.json` (ignoré par git)
et lancer avec `--dart-define-from-file=env/location.json`. Les configurations
VS Code de `.vscode/launch.json` couvrent ces trois cas.

`AppConfig` ne lit que des valeurs publiques : n'y ajoutez jamais de secret, un
`--dart-define` reste extractible du binaire.

## Vérifier

```bash
dart format .
flutter analyze
flutter test
```

Les tests n'appellent ni le réseau ni le GPS : ils injectent un faux
`GasStationService` et construisent leurs stations avec
`test/gas_station_list/gas_station_fixture.dart`.

## Conventions

- Code (identifiants) en anglais ; commentaires, libellés et noms de tests en
  français.
- Messages de commit en français, à l'indicatif présent, sans préfixe
  (« Ajoute la fiche station… », « Retire E85… »).
- Une branche `feature/<sujet>` par évolution, mergée dans `main` par pull
  request sur GitHub.
- Fins de ligne LF imposées par `.gitattributes`.
