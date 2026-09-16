import 'dart:convert';

import 'package:ecofuel/gas_station_list/model/route_result.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Service permettant de calculer un itinéraire routier.
///
/// OSRM calcule ici une route automobile entre :
/// - la position de l'utilisateur ;
/// - la station sélectionnée.
class RouteService {
  const RouteService();

  static const String _baseUrl =
      'https://router.project-osrm.org';

  /// Calcule un itinéraire en voiture.
  Future<RouteResult> fetchRoute({
    required UserCoordinates start,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    // OSRM demande les coordonnées dans l'ordre :
    //
    // longitude,latitude
    //
    // Attention à ne pas inverser les deux.
    final String coordinates =
        '${start.longitude},${start.latitude};'
        '$destinationLongitude,$destinationLatitude';

    final Uri uri = Uri.parse(
      '$_baseUrl/route/v1/driving/$coordinates',
    ).replace(
      queryParameters: {
        // Retourne toute la géométrie de la route.
        'overview': 'full',

        // Format simple à exploiter dans Flutter.
        'geometries': 'geojson',

        // On demande la meilleure route uniquement.
        'alternatives': 'false',

        // Pas besoin des instructions virage par virage pour l'instant.
        'steps': 'false',
      },
    );

    final http.Response response =
        await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de calculer l’itinéraire.',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body);

    // OSRM renvoie "Ok" lorsque le calcul s'est bien passé.
    if (body['code'] != 'Ok') {
      throw Exception(
        'Aucun itinéraire disponible.',
      );
    }

    final List<dynamic> routes =
        body['routes'] ?? [];

    if (routes.isEmpty) {
      throw Exception(
        'Aucun itinéraire trouvé.',
      );
    }

    final Map<String, dynamic> route =
        routes.first as Map<String, dynamic>;

    final Map<String, dynamic> geometry =
        route['geometry'] as Map<String, dynamic>;

    final List<dynamic> coordinatesList =
        geometry['coordinates'] ?? [];

    // Transformation des coordonnées GeoJSON
    // en points compatibles avec flutter_map.
    final List<LatLng> points =
        coordinatesList.map(
      (dynamic coordinate) {
        final List<dynamic> values =
            coordinate as List<dynamic>;

        final double longitude =
            (values[0] as num).toDouble();

        final double latitude =
            (values[1] as num).toDouble();

        return LatLng(
          latitude,
          longitude,
        );
      },
    ).toList();

    // OSRM donne la distance en mètres.
    final double distanceInMeters =
        (route['distance'] as num).toDouble();

    // OSRM donne la durée en secondes.
    final double durationInSeconds =
        (route['duration'] as num).toDouble();

    return RouteResult(
      points: points,
      distanceInKm:
          distanceInMeters / 1000,
      durationInMinutes:
          durationInSeconds / 60,
    );
  }
}