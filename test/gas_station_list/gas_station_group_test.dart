import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/gas_station_group.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  // Coordonnées réelles des deux portiques du Leclerc de Nantes, distants de
  // 543 m, et de leurs voisins : à 288 m de là cohabitent un Total et un Esso.
  GasStation leclercRouteDeParis({double price = 2.169}) => buildGasStation(
    id: '44300017',
    price: price,
    distanceInKm: 4.5,
    brand: 'E.Leclerc',
    city: 'Nantes',
    address: '14 route de Paris',
    latitude: 47.251,
    longitude: -1.518,
  );

  GasStation leclercRueDuPerray({double price = 2.169}) => buildGasStation(
    id: '44300018',
    price: price,
    distanceInKm: 4.5,
    brand: 'E.Leclerc',
    city: 'Nantes',
    address: '95 rue du Perray',
    latitude: 47.248,
    longitude: -1.512,
  );

  List<GasStationGroup> groupsOf(List<GasStation> stations) =>
      GasStationGrouper.group(stations, fuel: FuelType.e10);

  group('GasStationGrouper.group', () {
    test('réunit deux points de distribution du même site', () {
      final groups = groupsOf([leclercRouteDeParis(), leclercRueDuPerray()]);

      expect(groups, hasLength(1));
      expect(groups.single.pointCount, 2);
      expect(groups.single.representative.id, '44300017');
    });

    // Des prix différents sont deux offres différentes : les fusionner en
    // masquerait une, ce qui est exactement ce que l'application doit éviter.
    test('sépare deux points aux prix différents', () {
      final groups = groupsOf([
        leclercRouteDeParis(price: 2.169),
        leclercRueDuPerray(price: 2.199),
      ]);

      expect(groups, hasLength(2));
    });

    // Le cas qui interdit de regrouper sur la seule distance : un Total et un
    // Esso cohabitent à 288 m route de Vannes.
    test('sépare deux enseignes différentes, même très proches', () {
      final groups = groupsOf([
        buildGasStation(
          id: 'total',
          price: 1.99,
          distanceInKm: 3.9,
          brand: 'Total',
          city: 'Orvault',
          latitude: 47.2601,
          longitude: -1.5901,
        ),
        buildGasStation(
          id: 'esso',
          price: 1.99,
          distanceInKm: 3.7,
          brand: 'Esso Express',
          city: 'Orvault',
          latitude: 47.2625,
          longitude: -1.5885,
        ),
      ]);

      expect(groups, hasLength(2));
    });

    test('sépare deux points au-delà du seuil de distance', () {
      final groups = groupsOf([
        leclercRouteDeParis(),
        buildGasStation(
          id: 'loin',
          price: 2.169,
          distanceInKm: 4.5,
          brand: 'E.Leclerc',
          city: 'Nantes',
          latitude: 47.271,
          longitude: -1.518,
        ),
      ]);

      expect(groups, hasLength(2));
    });

    // Sans enseigne, rien ne permet d'affirmer qu'il s'agit d'un même site.
    test('ne regroupe jamais des stations sans enseigne connue', () {
      final groups = groupsOf([
        buildGasStation(
          id: 'a',
          price: 2.0,
          distanceInKm: 1,
          city: 'Nantes',
          latitude: 47.251,
          longitude: -1.518,
        ),
        buildGasStation(
          id: 'b',
          price: 2.0,
          distanceInKm: 1,
          city: 'Nantes',
          latitude: 47.2511,
          longitude: -1.5181,
        ),
      ]);

      expect(groups, hasLength(2));
    });

    test('conserve l\'ordre de tri reçu', () {
      final groups = groupsOf([
        buildGasStation(
          id: 'moinsCher',
          price: 1.90,
          distanceInKm: 9,
          brand: 'Avia',
          city: 'Rezé',
          latitude: 47.18,
          longitude: -1.55,
        ),
        leclercRouteDeParis(),
        leclercRueDuPerray(),
      ]);

      expect(groups.map((g) => g.representative.id), [
        'moinsCher',
        '44300017',
      ]);
    });
  });
}
