import 'dart:convert';
import 'dart:math' as math;

import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/geo_distance.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
/// au reste.
abstract interface class StationBrandDirectory {
  Future<List<BrandedLocation>> brandsAround({
    required UserCoordinates center,
    required SearchRadius radius,
  });
}

/// Lit les enseignes relevées dans OpenStreetMap et livrées avec
/// l'application, dans `assets/station_brands.json`.
///
/// Interroger Overpass à chaque rafraîchissement laissait les stations sans
/// nom dès que ce service communautaire flanchait, ce qui arrive souvent. Le
/// relevé embarqué répond tout de suite, hors ligne compris ; il se régénère
/// avec `dart run tool/generate_station_brands.dart`.
class AssetStationBrandDirectory implements StationBrandDirectory {
  AssetStationBrandDirectory({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const String assetPath = 'assets/station_brands.json';

  /// Un degré de latitude vaut environ 111 km partout sur le globe.
  static const double _kmPerLatitudeDegree = 111.32;

  final AssetBundle _bundle;

  /// Lu et décodé une seule fois : près de 12 000 enseignes.
  late final Future<List<BrandedLocation>> _all = _load();

  @override
  Future<List<BrandedLocation>> brandsAround({
    required UserCoordinates center,
    required SearchRadius radius,
  }) async {
    final all = await _all;

    // Un simple cadre suffit à écarter le reste de la France : le
    // rapprochement fin, au mètre, revient ensuite à [BrandMatcher]. La marge
    // garde les enseignes d'une station posée au bord du rayon.
    final reachKm = radius.inKm + BrandMatcher.toleranceInMeters / 1000;
    final latitudeSpan = reachKm / _kmPerLatitudeDegree;
    final longitudeSpan =
        reachKm /
        (_kmPerLatitudeDegree * math.cos(center.latitude * math.pi / 180));

    return [
      for (final location in all)
        if ((location.latitude - center.latitude).abs() <= latitudeSpan &&
            (location.longitude - center.longitude).abs() <= longitudeSpan)
          location,
    ];
  }

  Future<List<BrandedLocation>> _load() async {
    final Map<String, dynamic> body = jsonDecode(
      await _bundle.loadString(assetPath),
    );
    final List<dynamic> stations = body['stations'] ?? [];

    return [
      for (final station in stations.cast<List<dynamic>>())
        BrandedLocation(
          latitude: (station[0] as num).toDouble(),
          longitude: (station[1] as num).toDouble(),
          brand: station[2] as String,
        ),
    ];
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
/// Les deux sources géocodent indépendamment, et une grande surface place
/// parfois ses pompes à 200 m de l'adresse déclarée à l'État. Au-delà de
/// [toleranceInMeters] on considère qu'il s'agit d'une autre station et on préfère ne rien
/// afficher plutôt qu'une marque fausse.
abstract final class BrandMatcher {
  static const double toleranceInMeters = 250;

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
