import 'dart:convert';

import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class GasStationService {
  const GasStationService();

  static const String _baseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/'
      'catalog/datasets/'
      'prix-des-carburants-en-france-flux-instantane-v2/'
      'records';

  static const int _resultLimit = 100;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  Future<List<GasStation>> fetchNearbyStations({
    required SearchRadius radius,
  }) async {
    final position = await _currentPosition();
    final uri = _buildUri(position: position, radius: radius);

    debugPrint('URL : $uri');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      debugPrint(response.body);

      throw Exception('Erreur API : ${response.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> results = body['results'] ?? [];

    return results
        .map((item) => GasStation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Position> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('La localisation est désactivée.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('La permission GPS a été refusée.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('La permission GPS est définitivement refusée.');
    }

    return Geolocator.getCurrentPosition(locationSettings: _locationSettings);
  }

  Uri _buildUri({required Position position, required SearchRadius radius}) {
    final point = "geom'POINT(${position.longitude} ${position.latitude})'";

    return Uri.parse(_baseUrl).replace(
      queryParameters: {
        'where': 'within_distance(geom,$point,${radius.inKm}km)',
        'select': '*, distance(geom,$point) as distance_m',
        'limit': '$_resultLimit',
      },
    );
  }
}
