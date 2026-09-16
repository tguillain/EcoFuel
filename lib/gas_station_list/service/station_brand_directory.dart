import 'dart:convert';

import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/geo_distance.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Enseigne relevée à un point donné.
class BrandedLocation {
  const BrandedLocation({
    required this.brand,
    required this.latitude,
    required this.longitude,
  });

  final String brand;
  final double latitude;
  final double longitude;
}

/// Source des enseignes de stations. Le fichier de l'État ne porte aucune
/// marque : elle vient d'ailleurs, et doit pouvoir être remplacée sans toucher
/// au reste — par un jeu de données embarqué le jour où Overpass ne suffira
/// plus.
abstract interface class StationBrandDirectory {
  Future<List<BrandedLocation>> brandsAround({
    required UserCoordinates center,
    required SearchRadius radius,
  });
}

/// Interroge l'API Overpass d'OpenStreetMap.
///
/// Overpass est un service communautaire gratuit dont la charte d'usage
/// décourage le trafic applicatif : cette implémentation convient au
/// développement, pas à une mise en production.
class OverpassStationBrandDirectory implements StationBrandDirectory {
  const OverpassStationBrandDirectory();

  static const String _endpoint = 'https://overpass-api.de/api/interpreter';
  static const Duration _timeout = Duration(seconds: 12);

  @override
  Future<List<BrandedLocation>> brandsAround({
    required UserCoordinates center,
    required SearchRadius radius,
  }) async {
    final around =
        'around:${radius.inKm * 1000},${center.latitude},${center.longitude}';
    final query =
        '[out:json][timeout:25];'
        '(node($around)[amenity=fuel];way($around)[amenity=fuel];);'
        'out tags center;';

    final response = await http
        .post(Uri.parse(_endpoint), body: {'data': query})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Erreur Overpass : ${response.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> elements = body['elements'] ?? [];

    return elements
        .map((element) => _toBrandedLocation(element as Map<String, dynamic>))
        .nonNulls
        .toList();
  }

  /// Un nœud porte ses coordonnées directement, un chemin les expose via
  /// `center` grâce au `out center` de la requête.
  static BrandedLocation? _toBrandedLocation(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>?;
    final center = element['center'] as Map<String, dynamic>?;

    final brand =
        tags?['brand'] ?? tags?['operator'] ?? tags?['name'] as Object?;
    final latitude = _toDouble(element['lat'] ?? center?['lat']);
    final longitude = _toDouble(element['lon'] ?? center?['lon']);

    if (brand == null || latitude == null || longitude == null) {
      return null;
    }

    return BrandedLocation(
      brand: brand.toString(),
      latitude: latitude,
      longitude: longitude,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return null;
  }
}

/// Aucune enseigne : les stations retombent sur leur adresse. Sert de repli en
/// test et quand l'enrichissement est désactivé.
class EmptyStationBrandDirectory implements StationBrandDirectory {
  const EmptyStationBrandDirectory();

  @override
  Future<List<BrandedLocation>> brandsAround({
    required UserCoordinates center,
    required SearchRadius radius,
  }) async => const [];
}

/// Rapproche une station de l'enseigne relevée la plus proche.
///
/// Les deux sources géocodent indépendamment : au-delà de [toleranceInMeters]
/// on considère qu'il s'agit d'une autre station et on préfère ne rien
/// afficher plutôt qu'une marque fausse.
abstract final class BrandMatcher {
  static const double toleranceInMeters = 150;

  static String? nearestBrand(
    List<BrandedLocation> brands, {
    required double latitude,
    required double longitude,
  }) {
    String? closestBrand;
    var closestDistance = toleranceInMeters;

    for (final candidate in brands) {
      final distance = GeoDistance.betweenInMeters(
        latitudeA: latitude,
        longitudeA: longitude,
        latitudeB: candidate.latitude,
        longitudeB: candidate.longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestBrand = candidate.brand;
      }
    }

    return closestBrand;
  }
}

/// Journalise sans interrompre : l'enseigne est un enrichissement, son échec
/// ne doit jamais priver l'utilisateur des prix.
void debugReportBrandFailure(Object error) {
  debugPrint('Enseignes indisponibles : $error');
}
