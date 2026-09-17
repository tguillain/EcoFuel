import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_marker_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  group('StationMarkerColor.forStation', () {
    // Prix choisis pour tomber sur des points connus du dégradé : 1,650 et
    // 1,850 en sont les extrémités, 1,750 le milieu exact et 1,700 le quart.
    final List<GasStation> stations = [
      buildGasStation(id: 'moins-chere', price: 1.650, distanceInKm: 9),
      buildGasStation(id: 'quart', price: 1.700, distanceInKm: 4),
      buildGasStation(id: 'milieu', price: 1.750, distanceInKm: 2),
      buildGasStation(id: 'plus-chere', price: 1.850, distanceInKm: 1),
    ];

    Color colorOf(String id) {
      return StationMarkerColor.forStation(
        station: stations.firstWhere((station) => station.id == id),
        stations: stations,
        fuel: FuelType.e10,
      );
    }

    test('peint la station la moins chère en vert', () {
      expect(colorOf('moins-chere'), StationMarkerColor.cheapest);
    });

    test('peint la station la plus chère en rouge', () {
      expect(colorOf('plus-chere'), StationMarkerColor.dearest);
    });

    test('peint le prix médian de la couleur intermédiaire', () {
      expect(colorOf('milieu'), StationMarkerColor.middle);
    });

    test('interpole les prix entre deux teintes du dégradé', () {
      expect(
        colorOf('quart'),
        Color.lerp(StationMarkerColor.cheapest, StationMarkerColor.middle, 0.5),
      );
    });

    test('ignore la distance', () {
      // La station la plus proche est la plus chère : elle reste rouge.
      expect(colorOf('plus-chere'), StationMarkerColor.dearest);
    });

    test('peint tout en vert quand les prix sont identiques', () {
      final List<GasStation> tied = [
        buildGasStation(id: 'a', price: 1.712, distanceInKm: 1),
        buildGasStation(id: 'b', price: 1.712, distanceInKm: 9),
      ];

      for (final GasStation station in tied) {
        expect(
          StationMarkerColor.forStation(
            station: station,
            stations: tied,
            fuel: FuelType.e10,
          ),
          StationMarkerColor.cheapest,
        );
      }
    });

    test('grise une station sans prix pour le carburant', () {
      final GasStation withoutPrice = buildGasStation(
        id: 'sans-prix',
        price: null,
        distanceInKm: 2,
      );

      expect(
        StationMarkerColor.forStation(
          station: withoutPrice,
          stations: [withoutPrice, ...stations],
          fuel: FuelType.e10,
        ),
        StationMarkerColor.unknown,
      );
    });
  });

  group('StationMarkerColor.atRatio', () {
    test('parcourt le dégradé du vert au rouge', () {
      expect(StationMarkerColor.atRatio(0), StationMarkerColor.cheapest);
      expect(StationMarkerColor.atRatio(0.5), StationMarkerColor.middle);
      expect(StationMarkerColor.atRatio(1), StationMarkerColor.dearest);
    });

    test('borne les valeurs hors de l\'intervalle', () {
      expect(StationMarkerColor.atRatio(-3), StationMarkerColor.cheapest);
      expect(StationMarkerColor.atRatio(42), StationMarkerColor.dearest);
    });
  });
}
