import 'dart:convert';

import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/station_brand_directory.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GasStationService {
  /// Les deux dépendances n'existent que pour être remplaçables : en
  /// production le GPS et Overpass suffisent, un [FixedUserLocator] et un
  /// [EmptyStationBrandDirectory] permettent de s'en passer ailleurs.
  const GasStationService([
    this._locator = const GeolocatorUserLocator(),
    this._brands = const OverpassStationBrandDirectory(),
  ]);

  final UserLocator _locator;
  final StationBrandDirectory _brands;

  static const String _baseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/'
      'catalog/datasets/'
      'prix-des-carburants-en-france-flux-instantane-v2/'
      'records';

  static const int _resultLimit = 100;

  Future<UserCoordinates> currentCoordinates() {
    return _locator.currentCoordinates();
  }

  /// [coordinates] permet à la carte de chercher ailleurs qu'à la position de
  /// l'utilisateur ; sans lui, le GPS fait foi.
  Future<List<GasStation>> fetchNearbyStations({
    required SearchRadius radius,
    UserCoordinates? coordinates,
  }) async {
    final center = coordinates ?? await _locator.currentCoordinates();
    final uri = _buildUri(coordinates: center, radius: radius);

    debugPrint('Position : ${center.latitude} / ${center.longitude}');
    debugPrint('Rayon : ${radius.inKm} km');
    debugPrint('URL : $uri');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      debugPrint(response.body);

      throw Exception('Erreur API : ${response.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> results = body['results'] ?? [];
    final brands = await _brandsAround(center, radius);

    // `nonNulls` écarte les enregistrements sans géométrie, que le modèle
    // refuse de construire plutôt que de leur inventer une position.
    final stations = results
        .map((item) => _toGasStation(item as Map<String, dynamic>, brands))
        .nonNulls
        .toList();

    debugPrint('Stations récupérées : ${stations.length}');

    return stations;
  }

  /// L'enseigne est un enrichissement : son indisponibilité ne doit jamais
  /// priver l'utilisateur des prix, les stations retombent alors sur leur
  /// adresse.
  Future<List<BrandedLocation>> _brandsAround(
    UserCoordinates coordinates,
    SearchRadius radius,
  ) async {
    try {
      return await _brands.brandsAround(center: coordinates, radius: radius);
    } catch (error) {
      debugReportBrandFailure(error);

      return const [];
    }
  }

  static GasStation? _toGasStation(
    Map<String, dynamic> item,
    List<BrandedLocation> brands,
  ) {
    final station = GasStation.fromJson(item);

    if (station == null) {
      return null;
    }

    return station.withBrand(
      BrandMatcher.nearestBrand(
        brands,
        latitude: station.latitude,
        longitude: station.longitude,
      ),
    );
  }

  Uri _buildUri({
    required UserCoordinates coordinates,
    required SearchRadius radius,
  }) {
    final point =
        "geom'POINT(${coordinates.longitude} ${coordinates.latitude})'";

    return Uri.parse(_baseUrl).replace(
      queryParameters: {
        'where': 'within_distance(geom,$point,${radius.inKm}km)',
        'select': '*, distance(geom,$point) as distance_m',
        'limit': '$_resultLimit',
      },
    );
  }
}
