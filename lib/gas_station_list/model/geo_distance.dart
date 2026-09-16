import 'dart:math';

abstract final class GeoDistance {
  static const double _metersPerDegree = 111320;

  /// Approximation équirectangulaire : à l'échelle de quelques centaines de
  /// mètres, l'écart avec la formule de haversine est négligeable.
  static double betweenInMeters({
    required double latitudeA,
    required double longitudeA,
    required double latitudeB,
    required double longitudeB,
  }) {
    final deltaLatitude = (latitudeB - latitudeA) * _metersPerDegree;
    final deltaLongitude =
        (longitudeB - longitudeA) *
        _metersPerDegree *
        cos(latitudeA * pi / 180);

    return sqrt(
      deltaLatitude * deltaLatitude + deltaLongitude * deltaLongitude,
    );
  }
}
