import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
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

  group('EffectivePrice.best', () {
    List<String> bestIds(List<GasStation> stations, {int count = 10}) =>
        EffectivePrice.best(
          stations,
          fuel: FuelType.e10,
          count: count,
        ).map((station) => station.id).toList();

    test('préfère une station un peu plus chère mais bien plus proche', () {
      expect(
        bestIds([
          buildGasStation(id: 'loinEtPasChere', price: 1.650, distanceInKm: 20),
          buildGasStation(id: 'procheEtChere', price: 1.720, distanceInKm: 1),
        ]),
        ['procheEtChere', 'loinEtPasChere'],
      );
    });

    test('garde la moins chère quand le détour est identique', () {
      expect(
        bestIds([
          buildGasStation(id: 'chere', price: 1.900, distanceInKm: 3),
          buildGasStation(id: 'pasChere', price: 1.700, distanceInKm: 3),
        ]),
        ['pasChere', 'chere'],
      );
    });

    test('écarte les stations sans prix pour le carburant', () {
      expect(
        bestIds([
          buildGasStation(id: 'sansPrix', price: null, distanceInKm: 1),
          buildGasStation(id: 'avecPrix', price: 1.900, distanceInKm: 30),
        ]),
        ['avecPrix'],
      );
    });

    test('ne garde que le nombre de stations demandé', () {
      final List<GasStation> stations = [
        for (var index = 0; index < 15; index++)
          buildGasStation(
            id: 'station$index',
            price: 1.700 + index / 100,
            distanceInKm: 2,
          ),
      ];

      expect(bestIds(stations), [
        for (var index = 0; index < 10; index++) 'station$index',
      ]);
    });

    test('rend toutes les stations quand il y en a moins', () {
      expect(
        bestIds([
          buildGasStation(id: 'a', price: 1.700, distanceInKm: 1),
          buildGasStation(id: 'b', price: 1.800, distanceInKm: 1),
        ]),
        ['a', 'b'],
      );
    });
  });
}
