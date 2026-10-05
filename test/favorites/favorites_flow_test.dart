import 'package:ecofuel/favorites/favorites_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../gas_station_list/fake_gas_station_service.dart';
import '../gas_station_list/gas_station_fixture.dart';

void main() {
  testWidgets('une étoile touchée dans la liste se retrouve dans les favoris', (
    tester,
  ) async {
    final store = InMemoryFavoriteStationsStore();

    await pumpGasStationListPage(
      tester,
      FakeGasStationService(
        stations: [
          buildGasStation(
            id: 'total',
            price: 2.104,
            distanceInKm: 1,
            brand: 'TotalEnergies',
          ),
        ],
      ),
      favoritesStore: store,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ajouter aux favoris').hitTestable().first);
    await tester.pumpAndSettle();

    expect(store.ids, {'total'});

    await tester.tap(find.byTooltip('Mes favoris'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.text('TotalEnergies'), findsOneWidget);
  });

  testWidgets('la marque choisie sur la carte filtre les stations', (
    tester,
  ) async {
    await pumpGasStationListPage(
      tester,
      FakeGasStationService(
        stations: [
          buildGasStation(
            id: 'total',
            price: 2.104,
            distanceInKm: 1,
            brand: 'TotalEnergies',
          ),
          buildGasStation(
            id: 'avia',
            price: 2.139,
            distanceInKm: 3,
            brand: 'Avia',
            latitude: 47.25,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toutes les marques').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Avia'));
    await tester.pumpAndSettle();

    await expandStationList(tester);

    expect(find.text('1 station'), findsOneWidget);
    expect(find.text('TotalEnergies'), findsNothing);
  });
}
