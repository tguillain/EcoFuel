import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_marker_color.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  group('StationMarkerColor', () {
    final List<GasStation> stations = [
      buildGasStation(
        id: 'la-moins-chere',
        price: 1.679,
        distanceInKm: 4.8,
      ),
      buildGasStation(
        id: 'a-deux-centimes',
        price: 1.699,
        distanceInKm: 1.2,
      ),
      buildGasStation(
        id: 'a-cinq-centimes',
        price: 1.729,
        distanceInKm: 0.4,
      ),
    ];

    StationMarkerColor colorOf(String id) {
      return StationMarkerColor.forStation(
        station: stations.firstWhere((station) => station.id == id),
        stations: stations,
        fuel: FuelType.e10,
      );
    }

    test('colore le meilleur prix', () {
      expect(colorOf('la-moins-chere'), StationMarkerColor.best);
    });

    test('colore encore une station à moins de trois centimes', () {
      expect(colorOf('a-deux-centimes'), StationMarkerColor.cheap);
    });

    test('laisse en gris une station au-delà du seuil', () {
      expect(colorOf('a-cinq-centimes'), StationMarkerColor.regular);
    });

    test('ignore la distance', () {
      // La station la plus proche est la plus chère : la couleur ne doit
      // pas la mettre en avant pour autant.
      expect(colorOf('a-cinq-centimes').isHighlighted, isFalse);
    });

    test('colore les deux stations à égalité de prix', () {
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
          StationMarkerColor.best,
        );
      }
    });

    test('laisse en gris une station sans prix pour le carburant', () {
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
        StationMarkerColor.regular,
      );
    });
  });
}
