import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/gas_station_list_page.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/place_search/service/place_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpGasStationListPage(
  WidgetTester tester,
  GasStationService service, {
  PlaceSearchService placeSearch = const PlaceSearchService(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GasStationListPage(service: service, placeSearch: placeSearch),
    ),
  );
}

/// La page s'ouvre sur la carte : la liste complète se déploie d'un tap sur
/// la poignée de la feuille.
Future<void> expandStationList(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Afficher la liste'));
  await tester.pumpAndSettle();
}

/// Faux GasStationService utilisé uniquement pendant les tests.
///
/// Aucun GPS réel et aucun appel Internet n'est effectué.
class FakeGasStationService implements GasStationService {
  FakeGasStationService({this.stations = const [], this.error});

  List<GasStation> stations;

  Object? error;

  /// Nombre de fois où les stations
  /// ont été demandées.
  int callCount = 0;

  /// Dernier rayon reçu.
  SearchRadius? lastRadius;

  /// Dernier centre de recherche reçu.
  UserCoordinates? lastCoordinates;

  /// Simule la position GPS de l'utilisateur.
  @override
  Future<UserCoordinates> currentCoordinates() async {
    if (error != null) {
      throw error!;
    }

    return const UserCoordinates(latitude: 47.2184, longitude: -1.5536);
  }

  /// Simule la récupération des stations.
  @override
  Future<List<GasStation>> fetchNearbyStations({
    required SearchRadius radius,
    UserCoordinates? coordinates,
  }) async {
    callCount++;

    lastRadius = radius;

    lastCoordinates = coordinates;

    if (error != null) {
      throw error!;
    }

    return stations;
  }
}
