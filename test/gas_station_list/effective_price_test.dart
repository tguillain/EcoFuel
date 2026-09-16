import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/model/effective_price.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  group('EffectivePrice.forStation', () {
    test('rend le prix affiché pour une station sur place', () {
      final GasStation station = buildGasStation(
        id: 'surPlace',
        price: 1.700,
        distanceInKm: 0,
      );

      expect(
        EffectivePrice.forStation(station, FuelType.e10),
        closeTo(1.700, 0.0001),
      );
    });

    test('majore le prix du carburant brûlé pour l\'aller-retour', () {
      final GasStation station = buildGasStation(
        id: 'loin',
        price: 1.700,
        distanceInKm: 10,
      );

      // 10 km à vol d'oiseau font 13 km de route, soit 26 km aller-retour
      // et 1,82 L brûlés, répartis sur les 40 L du plein.
      expect(
        EffectivePrice.forStation(station, FuelType.e10),
        closeTo(1.700 * (1 + 1.82 / 40), 0.0001),
      );
    });

    test('vaut null sans prix pour le carburant', () {
      final GasStation station = buildGasStation(
        id: 'sansPrix',
        price: null,
        distanceInKm: 2,
      );

      expect(EffectivePrice.forStation(station, FuelType.e10), isNull);
    });

    test('un centime au litre s\'amortit sur 1,3 km à vol d\'oiseau', () {
      final GasStation nearby = buildGasStation(
        id: 'surPlace',
        price: 1.700,
        distanceInKm: 0,
      );

      final GasStation cheaperButFurther = buildGasStation(
        id: 'unCentimeMoinsCher',
        price: 1.690,
        distanceInKm: 1.3,
      );

      expect(
        EffectivePrice.forStation(cheaperButFurther, FuelType.e10),
        closeTo(EffectivePrice.forStation(nearby, FuelType.e10)!, 0.001),
      );
    });
  });

  group('GasStationSortCriterion.bestValue', () {
    test('préfère une station un peu plus chère mais bien plus proche', () {
      final List<GasStation> stations = [
        buildGasStation(id: 'loinEtPasChere', price: 1.650, distanceInKm: 20),
        buildGasStation(id: 'procheEtChere', price: 1.720, distanceInKm: 1),
      ]..sort(GasStationSortCriterion.bestValue.comparatorFor(FuelType.e10));

      expect(stations.first.id, 'procheEtChere');
    });

    test('garde la station la moins chère quand le détour est identique', () {
      final List<GasStation> stations = [
        buildGasStation(id: 'chere', price: 1.900, distanceInKm: 3),
        buildGasStation(id: 'pasChere', price: 1.700, distanceInKm: 3),
      ]..sort(GasStationSortCriterion.bestValue.comparatorFor(FuelType.e10));

      expect(stations.first.id, 'pasChere');
    });

    test('relègue en fin de liste les stations sans prix', () {
      final List<GasStation> stations = [
        buildGasStation(id: 'sansPrix', price: null, distanceInKm: 1),
        buildGasStation(id: 'avecPrix', price: 1.900, distanceInKm: 30),
      ]..sort(GasStationSortCriterion.bestValue.comparatorFor(FuelType.e10));

      expect(stations.map((station) => station.id), ['avecPrix', 'sansPrix']);
    });

    test('limite l\'affichage à dix stations, les autres critères non', () {
      expect(GasStationSortCriterion.bestValue.maxResults, 10);
      expect(GasStationSortCriterion.price.maxResults, isNull);
      expect(GasStationSortCriterion.distance.maxResults, isNull);
    });
  });
}
