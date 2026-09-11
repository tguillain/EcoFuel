import 'package:ecofuel/gas_station_list/model/gas_station.dart';

enum GasStationSortCriterion {
  distance('Distance'),
  price('Prix');

  const GasStationSortCriterion(this.label);

  final String label;

  Comparator<GasStation> get comparator => switch (this) {
    GasStationSortCriterion.distance => (a, b) => a.distanceInKm.compareTo(
      b.distanceInKm,
    ),
    GasStationSortCriterion.price => (a, b) => a.priceInEuros.compareTo(
      b.priceInEuros,
    ),
  };
}
