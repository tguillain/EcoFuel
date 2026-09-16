import 'package:latlong2/latlong.dart';

/// Résultat d'un calcul d'itinéraire.
///
/// Il contient :
/// - les points permettant de dessiner la route ;
/// - la distance totale ;
/// - la durée estimée.
class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceInKm,
    required this.durationInMinutes,
  });

  /// Liste des points constituant la route.
  final List<LatLng> points;

  /// Distance totale en kilomètres.
  final double distanceInKm;

  /// Durée estimée en minutes.
  final double durationInMinutes;
}
