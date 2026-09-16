import 'package:ecofuel/gas_station_list/enum/search_radius.dart';

/// Centralise les niveaux de zoom de la carte.
///
/// L'objectif est que la carte affiche approximativement
/// toute la zone correspondant au rayon choisi par l'utilisateur.
class MapZoom {
  const MapZoom._();

  /// Retourne le niveau de zoom adapté au rayon.
  static double forRadius(
    SearchRadius radius,
  ) {
    final int km = radius.inKm;

    // Rayon de 5 km :
    // vue assez proche de l'utilisateur.
    if (km <= 5) {
      return 12.8;
    }

    // Rayon de 10 km :
    // léger dézoom.
    if (km <= 10) {
      return 11.8;
    }

    // Rayon de 25 km :
    // vue plus large.
    if (km <= 25) {
      return 10.5;
    }

    // Rayon de 50 km :
    // vue encore plus éloignée.
    return 9.5;
  }
}