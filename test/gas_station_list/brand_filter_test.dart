import 'package:ecofuel/gas_station_list/model/brand_filter.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  final List<GasStation> stations = [
    buildGasStation(id: 'total1', price: 1.7, distanceInKm: 1, brand: 'Total'),
    buildGasStation(id: 'avia', price: 1.7, distanceInKm: 1, brand: 'Avia'),
    buildGasStation(id: 'inconnue', price: 1.7, distanceInKm: 1),
    buildGasStation(id: 'total2', price: 1.7, distanceInKm: 1, brand: 'Total'),
  ];

  group('BrandFilter.availableBrands', () {
    test('compte les stations, les plus représentées d\'abord', () {
      expect(BrandFilter.availableBrands(stations), [
        (brand: 'Total', count: 2),
        (brand: 'Avia', count: 1),
        (brand: BrandFilter.unknownBrand, count: 1),
      ]);
    });
  });

  group('BrandFilter.apply', () {
    List<String> idsFor(String? brand) =>
        BrandFilter.apply(stations, brand).map((s) => s.id).toList();

    test('laisse tout passer sans enseigne choisie', () {
      expect(idsFor(null), ['total1', 'avia', 'inconnue', 'total2']);
    });

    test('ne garde que l\'enseigne choisie', () {
      expect(idsFor('Total'), ['total1', 'total2']);
    });

    test('permet de choisir les stations sans enseigne', () {
      expect(idsFor(BrandFilter.unknownBrand), ['inconnue']);
    });
  });
}
