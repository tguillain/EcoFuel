import 'package:ecofuel/favorites/favorites_page.dart';
import 'package:ecofuel/favorites/model/favorite_stations.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../gas_station_list/fake_gas_station_service.dart';
import '../gas_station_list/gas_station_fixture.dart';

void main() {
  Future<FavoriteStations> pumpFavorites(
    WidgetTester tester,
    Set<String> favoriteIds,
  ) async {
    final favorites = FavoriteStations(
      InMemoryFavoriteStationsStore(favoriteIds),
    );
    await favorites.load();

    await tester.pumpWidget(
      MaterialApp(
        home: FavoritesPage(
          favorites: favorites,
          service: FakeGasStationService(
            stations: [
              buildGasStation(
                id: 'chere',
                price: 2.159,
                distanceInKm: 1,
                brand: 'Esso',
              ),
              buildGasStation(
                id: 'pasChere',
                price: 1.999,
                distanceInKm: 9,
                brand: 'Intermarché',
                latitude: 47.3,
              ),
              buildGasStation(
                id: 'pasFavorite',
                price: 1.5,
                distanceInKm: 1,
                brand: 'Avia',
                latitude: 47.1,
              ),
            ],
          ),
          fuel: FuelType.e10,
          radius: SearchRadius.fiveKm,
          userCoordinates: const UserCoordinates(
            latitude: 47.2184,
            longitude: -1.5536,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return favorites;
  }

  group('FavoritesPage', () {
    testWidgets('liste les favoris du moins cher au plus cher', (tester) async {
      await pumpFavorites(tester, {'chere', 'pasChere'});

      final titles = tester
          .widgetList<GasStationCard>(find.byType(GasStationCard))
          .map((card) => card.station.id);

      expect(titles, ['pasChere', 'chere']);
      expect(find.text('Avia'), findsNothing);
      expect(find.text('E10 · 2 STATIONS'), findsOneWidget);
    });

    testWidgets('retire une station d\'un tap sur son étoile', (tester) async {
      final favorites = await pumpFavorites(tester, {'chere', 'pasChere'});

      await tester.tap(find.byTooltip('Retirer des favoris').first);
      await tester.pumpAndSettle();

      expect(favorites.ids, {'chere'});
      expect(find.byType(GasStationCard), findsOneWidget);
    });

    testWidgets('explique comment ajouter un favori quand il n\'y en a pas', (
      tester,
    ) async {
      await pumpFavorites(tester, {});

      expect(find.textContaining('Aucune station en favori'), findsOneWidget);
    });
  });
}
