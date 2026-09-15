import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';

enum GasStationSortCriterion {
  price('Prix croissant'),
  distance('Distance');

  const GasStationSortCriterion(this.label);

  final String label;

  /// Le prix ne peut être comparé qu'à carburant donné, d'où le paramètre.
  /// Chaque critère retombe sur l'autre en cas d'égalité.
  Comparator<GasStation> comparatorFor(FuelType fuel) => switch (this) {
    GasStationSortCriterion.price => (a, b) {
      final comparison = _comparePrices(a, b, fuel);

      if (comparison != 0) {
        return comparison;
      }

      return a.distanceInKm.compareTo(b.distanceInKm);
    },
    GasStationSortCriterion.distance => (a, b) {
      final comparison = _roundedDistance(a).compareTo(_roundedDistance(b));

      if (comparison != 0) {
        return comparison;
      }

      return _comparePrices(a, b, fuel);
    },
  };

  static int _comparePrices(GasStation a, GasStation b, FuelType fuel) {
    final priceA = a.priceFor(fuel) ?? double.infinity;
    final priceB = b.priceFor(fuel) ?? double.infinity;

    return priceA.compareTo(priceB);
  }

  /// Arrondi à 100 m : deux stations à 2,31 et 2,34 km sont « aussi proches »,
  /// on les départage alors au prix.
  static double _roundedDistance(GasStation station) {
    return double.parse(station.distanceInKm.toStringAsFixed(1));
  }
}
