import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/station.dart';

class ApiService {
  static const String _baseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/'
      'catalog/datasets/'
      'prix-des-carburants-en-france-flux-instantane-v2/'
      'records';

  static Future<List<Station>> fetchNearbyStations({
    required int rayonKm,
  }) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('La localisation est désactivée.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('La permission GPS a été refusée.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('La permission GPS est définitivement refusée.');
      }

      // Correction du warning deprecated en utilisant LocationSettings
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      final double latitude = position.latitude;

      final double longitude = position.longitude;

      debugPrint('Position : $latitude / $longitude');

      final String point = "geom'POINT($longitude $latitude)'";

      final String where =
          "within_distance("
          "geom,"
          "$point,"
          "${rayonKm}km"
          ")";

      final String select =
          "*, "
          "distance(geom,$point) "
          "as distance_m";

      final Uri uri = Uri.parse(_baseUrl).replace(
        queryParameters: {'where': where, 'select': select, 'limit': '100'},
      );

      debugPrint('URL : $uri');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint(response.body);

        throw Exception('Erreur API : ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      final List<dynamic> results = data['results'] ?? [];

      return results
          .map((item) => Station.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erreur : $e');

      rethrow;
    }
  }
}
