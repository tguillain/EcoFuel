import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  group('GasStationSortCriterion.comparatorFor', () {
    test('trie par prix puis par distance à prix égal', () {
      final stations = [
        buildGasStation(id: 'loin', price: 1.70, distanceInKm: 8),
        buildGasStation(id: 'cher', price: 1.90, distanceInKm: 1),
        buildGasStation(id: 'proche', price: 1.70, distanceInKm: 2),
      ]..sort(GasStationSortCriterion.price.comparatorFor(FuelType.e10));

      expect(stations.map((station) => station.id), ['proche', 'loin', 'cher']);
    });

    test('trie par distance puis par prix à distance équivalente', () {
      final stations = [
        buildGasStation(id: 'loin', price: 1.60, distanceInKm: 9),
        buildGasStation(id: 'cher', price: 1.90, distanceInKm: 2.31),
        buildGasStation(id: 'pasCher', price: 1.70, distanceInKm: 2.34),
      ]..sort(GasStationSortCriterion.distance.comparatorFor(FuelType.e10));

      expect(stations.map((station) => station.id), [
        'pasCher',
        'cher',
        'loin',
      ]);
    });

    test(
      'relègue en fin de liste les stations sans prix pour le carburant',
      () {
        final stations = <GasStation>[
          buildGasStation(id: 'sansPrix', price: null, distanceInKm: 1),
          buildGasStation(id: 'avecPrix', price: 1.90, distanceInKm: 5),
        ]..sort(GasStationSortCriterion.price.comparatorFor(FuelType.e10));

        expect(stations.first.id, 'avecPrix');
      },
    );
  });
}
