import 'dart:math';

import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/widget/map/map_station_selection.dart';

/// Stations assez proches à l'écran pour n'occuper qu'un marqueur.
class StationCluster {
  StationCluster(MapMarkerEntry first) : entries = [first];

  /// La première est la mieux classée : elle donne sa couleur au rond.
  final List<MapMarkerEntry> entries;

  MapMarkerEntry get best => entries.first;

  bool get isSingle => entries.length == 1;

  List<GasStation> get stations => [for (final entry in entries) entry.station];

  double get latitude =>
      stations.map((station) => station.latitude).reduce((a, b) => a + b) /
      entries.length;

  double get longitude =>
      stations.map((station) => station.longitude).reduce((a, b) => a + b) /
      entries.length;
}

/// Regroupe les marqueurs qui se chevaucheraient au zoom courant.
///
/// Les distances sont mesurées en pixels de la projection Web Mercator, celle
/// des tuiles OpenStreetMap : deux stations à 300 m se séparent dès qu'on
/// zoome, alors qu'un seuil en mètres les laisserait fusionnées.
abstract final class StationClusterer {
  /// Écart en dessous duquel deux marqueurs se gênent : un peu plus que la
  /// largeur d'une étiquette de prix.
  static const double defaultRadiusInPixels = 70;

  static const double _tileSize = 256;

  /// [entries] arrivent de la plus chère à la moins chère, ordre de dessin de
  /// la carte : on les parcourt à l'envers pour que chaque groupe naisse
  /// autour de sa meilleure station.
  static List<StationCluster> cluster(
    List<MapMarkerEntry> entries, {
    required double zoom,
    double radiusInPixels = defaultRadiusInPixels,
  }) {
    final clusters = <StationCluster>[];
    final centers = <Point<double>>[];

    for (final entry in entries.reversed) {
      final point = _project(
        entry.station.latitude,
        entry.station.longitude,
        zoom,
      );

      final index = centers.indexWhere(
        (center) => center.distanceTo(point) < radiusInPixels,
      );

      if (index == -1) {
        clusters.add(StationCluster(entry));
        centers.add(point);
      } else {
        clusters[index].entries.add(entry);
      }
    }

    return clusters;
  }

  static Point<double> _project(
    double latitude,
    double longitude,
    double zoom,
  ) {
    final scale = _tileSize * pow(2, zoom);
    final sinLatitude = sin(latitude * pi / 180);

    return Point(
      (longitude + 180) / 360 * scale,
      (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * pi)) * scale,
    );
  }
}
