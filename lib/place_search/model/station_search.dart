import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/place_search/model/search_place.dart';

/// Recherche validée dans le panneau : où, dans quel rayon, pour quel
/// carburant.
class StationSearch {
  const StationSearch({
    required this.place,
    required this.radius,
    required this.fuel,
  });

  /// `null` autour de la position de l'utilisateur.
  final SearchPlace? place;

  final SearchRadius radius;
  final FuelType fuel;
}
