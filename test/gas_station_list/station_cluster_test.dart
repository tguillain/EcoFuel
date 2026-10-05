import 'package:ecofuel/gas_station_list/widget/map/map_station_selection.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_cluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  /// Décale un point vers le nord, un degré de latitude valant environ
  /// 111 320 m.
  double latitudeShiftedBy(double meters) => 47.2184 + meters / 111320;

  MapMarkerEntry entry(String id, {required double metersNorth}) => (
    station: buildGasStation(
      id: id,
      price: 1.700,
      distanceInKm: 1,
      latitude: latitudeShiftedBy(metersNorth),
    ),
    color: Colors.green,
  );

  List<List<String>> idsOf(List<StationCluster> clusters) => [
    for (final cluster in clusters)
      [for (final station in cluster.stations) station.id],
  ];

  group('StationClusterer.cluster', () {
    // Ordre de dessin : de la plus chère à la moins chère.
    final entries = [
      entry('chere', metersNorth: 300),
      entry('moyenne', metersNorth: 3000),
      entry('meilleure', metersNorth: 0),
    ];

    test('regroupe les stations proches quand on dézoome', () {
      // À ce zoom, 300 m font une dizaine de pixels : les deux se chevauchent.
      expect(idsOf(StationClusterer.cluster(entries, zoom: 12)), [
        ['meilleure', 'chere'],
        ['moyenne'],
      ]);
    });

    test('sépare les mêmes stations quand on zoome', () {
      expect(idsOf(StationClusterer.cluster(entries, zoom: 17)), [
        ['meilleure'],
        ['moyenne'],
        ['chere'],
      ]);
    });

    test('place la meilleure station en tête de son groupe', () {
      final clusters = StationClusterer.cluster(entries, zoom: 12);

      expect(clusters.first.best.station.id, 'meilleure');
      expect(clusters.first.isSingle, isFalse);
      expect(clusters.last.isSingle, isTrue);
    });

    test('centre le groupe entre ses stations', () {
      final cluster = StationClusterer.cluster(entries, zoom: 12).first;

      expect(cluster.latitude, closeTo(latitudeShiftedBy(150), 1e-9));
    });
  });
}
