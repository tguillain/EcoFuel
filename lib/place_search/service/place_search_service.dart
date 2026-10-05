import 'dart:convert';

import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:http/http.dart' as http;

/// Cherche une commune ou une adresse en France.
///
/// Passe par le service de géocodage de la Géoplateforme de l'IGN, successeur
/// de l'API Adresse : gratuit, sans clé, et ouvert aux appels depuis un
/// navigateur.
class PlaceSearchService {
  /// [_client] n'existe que pour les tests ; sans lui, `http` fait foi.
  const PlaceSearchService([this._client]);

  static const String _endpoint = 'https://data.geopf.fr/geocodage/search';
  static const int _resultLimit = 6;
  static const Duration _timeout = Duration(seconds: 8);

  /// En deçà, la recherche renverrait n'importe quelle commune commençant par
  /// ces lettres : le service les refuse d'ailleurs.
  static const int minQueryLength = 3;

  final http.Client? _client;

  Future<List<SearchPlace>> search(String query) async {
    final String text = query.trim();

    if (text.length < minQueryLength) {
      return const [];
    }

    final Uri uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': text,
        'limit': '$_resultLimit',
        // Accepte un mot tapé à moitié : « lyo » trouve déjà Lyon.
        'autocomplete': '1',
      },
    );

    final http.Response response = await (_client?.get(uri) ?? http.get(uri))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Recherche de lieu impossible (${response.statusCode}).');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> features = body['features'] ?? [];

    return features
        .map(
          (feature) => SearchPlace.fromFeature(feature as Map<String, dynamic>),
        )
        .nonNulls
        .toList();
  }
}
