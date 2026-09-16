import 'dart:convert';

import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GasStationService {
  const GasStationService([
    this._locator =
        const GeolocatorUserLocator(),
  ]);

  final UserLocator _locator;

  static const String _baseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/'
      'catalog/datasets/'
      'prix-des-carburants-en-france-flux-instantane-v2/'
      'records';

  static const int _resultLimit = 100;

  Future<UserCoordinates>
      currentCoordinates() {
    return _locator
        .currentCoordinates();
  }

  Future<List<GasStation>>
      fetchNearbyStations({
    required SearchRadius radius,
    UserCoordinates? coordinates,
  }) async {
    final currentCoordinates =
        coordinates ??
        await _locator
            .currentCoordinates();

    final uri = _buildUri(
      coordinates:
          currentCoordinates,
      radius: radius,
    );

    debugPrint(
      'Position utilisateur : '
      '${currentCoordinates.latitude} / '
      '${currentCoordinates.longitude}',
    );

    debugPrint(
      'Rayon : ${radius.inKm} km',
    );

    debugPrint(
      'URL : $uri',
    );

    final response =
        await http.get(uri);

    if (response.statusCode != 200) {
      debugPrint(response.body);

      throw Exception(
        'Erreur API : '
        '${response.statusCode}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body);

    final List<dynamic> results =
        body['results'] ?? [];

    debugPrint(
      'Stations récupérées : '
      '${results.length}',
    );

    return results
        .map(
          (item) =>
              GasStation.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Uri _buildUri({
    required UserCoordinates coordinates,
    required SearchRadius radius,
  }) {
    final point =
        "geom'POINT("
        "${coordinates.longitude} "
        "${coordinates.latitude}"
        ")'";

    return Uri.parse(
      _baseUrl,
    ).replace(
      queryParameters: {
        'where':
            'within_distance('
            'geom,'
            '$point,'
            '${radius.inKm}km'
            ')',
        'select':
            '*, '
            'distance('
            'geom,'
            '$point'
            ') as distance_m',
        'limit':
            '$_resultLimit',
      },
    );
  }
}