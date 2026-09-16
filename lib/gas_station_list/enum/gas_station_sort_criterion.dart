import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/effective_price.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';

enum GasStationSortCriterion {
  price('Prix'),
  distance('Distance'),

  /// Meilleur compromis entre prix et détour, limité aux dix premières.
  ///
  /// Au-delà de dix, les stations retenues sont trop loin pour que le gain
  /// couvre encore le déplacement : la troncature fait partie du critère.
  bestValue('Top 10', maxResults: 10);

  const GasStationSortCriterion(this.label, {this.maxResults});

  final String label;

  /// Nombre de stations à conserver, ou `null` pour toutes les afficher.
  final int? maxResults;

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
    GasStationSortCriterion.bestValue => EffectivePrice.comparatorFor(fuel),
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
