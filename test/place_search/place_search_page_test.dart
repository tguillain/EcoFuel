import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:ecofuel/place_search/service/place_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../gas_station_list/fake_gas_station_service.dart';
import '../gas_station_list/gas_station_fixture.dart';

void main() {
  const lyon = SearchPlace(name: 'Lyon', latitude: 45.758, longitude: 4.835);

  testWidgets('cherche les stations autour du lieu choisi, puis revient', (
    tester,
  ) async {
    final service = FakeGasStationService(
      stations: [buildGasStation(id: 'a', price: 1.70, distanceInKm: 1)],
    );

    await pumpGasStationListPage(
      tester,
      service,
      placeSearch: const _FakePlaceSearchService([lyon]),
    );
    await tester.pumpAndSettle();

    expect(service.lastCoordinates!.latitude, 47.2184);

    await tester.tap(find.text('Autour de moi · 5 km'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'lyon');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.tap(find.text('Lyon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25 km'));
    await tester.pump();
    await tester.tap(find.text('Voir les stations'));
    await tester.pumpAndSettle();

    expect(service.lastCoordinates!.latitude, 45.758);
    expect(service.lastCoordinates!.longitude, 4.835);
    expect(service.lastRadius, SearchRadius.twentyFiveKm);
    expect(find.text('Lyon · 25 km'), findsOneWidget);

    await tester.tap(find.byTooltip('Revenir à ma position'));
    await tester.pumpAndSettle();

    expect(service.lastCoordinates!.latitude, 47.2184);
    expect(find.text('Autour de moi · 25 km'), findsOneWidget);
  });
}

class _FakePlaceSearchService implements PlaceSearchService {
  const _FakePlaceSearchService(this.places);

  final List<SearchPlace> places;

  @override
  Future<List<SearchPlace>> search(String query) async => places;
}
