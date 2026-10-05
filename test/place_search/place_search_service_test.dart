import 'dart:convert';

import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:ecofuel/place_search/service/place_search_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  /// Réponse réelle du service pour « lyon », réduite à un résultat.
  final Map<String, dynamic> lyon = {
    'type': 'Feature',
    'geometry': {
      'type': 'Point',
      'coordinates': [4.835, 45.758],
    },
    'properties': {
      'label': 'Lyon',
      'context': '69, Rhône, Auvergne-Rhône-Alpes',
      'type': 'municipality',
    },
  };

  group('SearchPlace.fromFeature', () {
    test('lit le nom, le contexte et la position', () {
      final SearchPlace place = SearchPlace.fromFeature(lyon)!;

      expect(place.name, 'Lyon');
      expect(place.context, '69, Rhône, Auvergne-Rhône-Alpes');
      expect(place.latitude, 45.758);
      expect(place.longitude, 4.835);
    });

    test('écarte un résultat sans position', () {
      expect(
        SearchPlace.fromFeature({
          'properties': {'label': 'Nulle part'},
        }),
        isNull,
      );
    });
  });

  group('PlaceSearchService.search', () {
    test('interroge le géocodage et rend les lieux trouvés', () async {
      Uri? requested;

      final service = PlaceSearchService(
        MockClient((request) async {
          requested = request.url;

          return http.Response(
            jsonEncode({
              'features': [lyon],
            }),
            200,
          );
        }),
      );

      final List<SearchPlace> places = await service.search('  lyo ');

      expect(places.single.name, 'Lyon');
      expect(requested!.host, 'data.geopf.fr');
      expect(requested!.queryParameters['q'], 'lyo');
      expect(requested!.queryParameters['autocomplete'], '1');
    });

    test('n\'appelle pas le service pour moins de 3 lettres', () async {
      var called = false;

      final service = PlaceSearchService(
        MockClient((_) async {
          called = true;

          return http.Response('{}', 200);
        }),
      );

      expect(await service.search('ly'), isEmpty);
      expect(called, isFalse);
    });

    test('signale une réponse en erreur', () async {
      final service = PlaceSearchService(
        MockClient((_) async => http.Response('', 503)),
      );

      expect(service.search('lyon'), throwsException);
    });
  });
}
