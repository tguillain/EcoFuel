// Régénère assets/station_brands.json, les enseignes des stations-service de
// France relevées dans OpenStreetMap.
//
//   dart run tool/generate_station_brands.dart
//
// Le fichier de l'État ne porte aucune marque. Plutôt que d'interroger
// Overpass à chaque rafraîchissement, service communautaire lent, souvent
// indisponible et dont la charte décourage le trafic applicatif, l'application
// embarque ce relevé fait une fois pour toutes. À relancer de temps en temps :
// les changements d'enseigne n'y apparaissent qu'à la régénération.
//
// Les données restent sous licence ODbL : l'application crédite les
// contributeurs OpenStreetMap, et le fichier dérivé doit rester sous la même
// licence.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Instances publiques d'Overpass, essayées dans l'ordre : aucune n'est
/// fiable seule.
const List<String> _endpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

const Duration _timeout = Duration(minutes: 5);

const String _query = '''
[out:json][timeout:300];
area["ISO3166-1"="FR"][admin_level=2]->.fr;
(node[amenity=fuel](area.fr);way[amenity=fuel](area.fr););
out tags center;
''';

const String _outputPath = 'assets/station_brands.json';

/// Cinq décimales situent un point au mètre près, bien en deçà de la
/// tolérance de rapprochement.
const int _coordinateDecimals = 5;

Future<void> main() async {
  final Map<String, dynamic> body = await _fetch();
  final List<dynamic> elements = body['elements'] as List<dynamic>? ?? [];

  final stations = <List<Object>>[];

  for (final element in elements.cast<Map<String, dynamic>>()) {
    final station = _toStation(element);

    if (station != null) {
      stations.add(station);
    }
  }

  // Un ordre stable garde les diffs du fichier lisibles d'une régénération à
  // l'autre.
  stations.sort((a, b) {
    final byLatitude = (a[0] as num).compareTo(b[0] as num);

    return byLatitude != 0 ? byLatitude : (a[1] as num).compareTo(b[1] as num);
  });

  final output = {
    'source': '© les contributeurs OpenStreetMap, sous licence ODbL',
    'generatedAt': DateTime.now().toUtc().toIso8601String().substring(0, 10),
    'stations': stations,
  };

  await File(_outputPath).writeAsString(jsonEncode(output));

  stdout.writeln(
    '${stations.length} enseignes sur ${elements.length} stations '
    'écrites dans $_outputPath',
  );
}

Future<Map<String, dynamic>> _fetch() async {
  for (final endpoint in _endpoints) {
    stdout.writeln('Interroge $endpoint…');

    try {
      final response = await http
          .post(Uri.parse(endpoint), body: {'data': _query})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }

      stderr.writeln('  réponse ${response.statusCode}');
    } on Exception catch (error) {
      stderr.writeln('  échec : $error');
    }
  }

  throw StateError('Aucune instance Overpass n\'a répondu.');
}

/// Même priorité que l'application : la marque, à défaut l'exploitant, à
/// défaut le nom affiché. Un chemin expose ses coordonnées via `center`.
List<Object>? _toStation(Map<String, dynamic> element) {
  final tags = element['tags'] as Map<String, dynamic>?;
  final center = element['center'] as Map<String, dynamic>?;

  final brand = tags?['brand'] ?? tags?['operator'] ?? tags?['name'];
  final latitude = element['lat'] ?? center?['lat'];
  final longitude = element['lon'] ?? center?['lon'];

  if (brand is! String || latitude is! num || longitude is! num) {
    return null;
  }

  return [
    _round(latitude.toDouble()),
    _round(longitude.toDouble()),
    brand.trim(),
  ];
}

double _round(double value) =>
    double.parse(value.toStringAsFixed(_coordinateDecimals));
