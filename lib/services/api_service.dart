import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/station.dart';

class ApiService {
  static Future<List<Station>> fetchNearbyStations() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Le service GPS est désactivé.');
        return [];
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Permissions GPS refusées.');
          return [];
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Permissions GPS refusées définitivement.');
        return [];
      }

      // 3. Récupérer la vraie position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lon = position.longitude;

      final url = Uri.parse(
        'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/prix-des-carburants-en-france-flux-instantane-v2/records?where=within_distance(geom,geom\'POINT($lon $lat)\',5km)',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List results = data['results'] ?? [];
        return results.map((jsonItem) => Station.fromJson(jsonItem)).toList();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération GPS ou API : $e');
    }

    return [];
  }
}
