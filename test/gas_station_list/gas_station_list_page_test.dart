import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/gas_station_list_page.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, GasStationService service) async {
    await tester.pumpWidget(
      MaterialApp(home: GasStationListPage(service: service)),
    );
  }

  group('GasStationListPage', () {
    testWidgets('affiche un indicateur puis la liste', (tester) async {
      await pumpPage(
        tester,
        _FakeGasStationService(
          stations: [
            buildGasStation(id: 'a', price: 1.70, distanceInKm: 1),
            buildGasStation(id: 'b', price: 1.65, distanceInKm: 4),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(GasStationCard), findsNWidgets(2));
      expect(find.text('2 stations'), findsOneWidget);
    });

    testWidgets('met en avant la station la moins chère', (tester) async {
      await pumpPage(
        tester,
        _FakeGasStationService(
          stations: [
            buildGasStation(id: 'chere', price: 1.90, distanceInKm: 1),
            buildGasStation(id: 'moinsChere', price: 1.65, distanceInKm: 4),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<GasStationCard>(find.byType(GasStationCard))
          .toList();

      expect(cards.where((card) => card.isHighlighted).length, 1);
      expect(
        cards.firstWhere((card) => card.isHighlighted).station.id,
        'moinsChere',
      );
    });

    testWidgets('affiche le message d\'erreur et permet de réessayer', (
      tester,
    ) async {
      final service = _FakeGasStationService(
        error: Exception('La localisation est désactivée.'),
      );

      await pumpPage(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('La localisation est désactivée.'), findsOneWidget);

      service.stations = [
        buildGasStation(id: 'a', price: 1.70, distanceInKm: 1),
      ];
      service.error = null;

      await tester.tap(find.widgetWithText(ElevatedButton, 'Réessayer'));
      await tester.pumpAndSettle();

      expect(find.byType(GasStationCard), findsOneWidget);
    });

    testWidgets('change de carburant sans rappeler le service', (tester) async {
      final service = _FakeGasStationService(
        stations: [
          buildGasStation(id: 'e10', price: 1.70, distanceInKm: 1),
          buildGasStation(
            id: 'sp98',
            price: 1.90,
            distanceInKm: 2,
            fuel: FuelType.sp98,
          ),
        ],
      );

      await pumpPage(tester, service);
      await tester.pumpAndSettle();

      expect(find.byType(GasStationCard), findsOneWidget);
      expect(service.callCount, 1);

      await tester.tap(find.widgetWithText(ChoiceChip, 'SP98'));
      await tester.pumpAndSettle();

      expect(service.callCount, 1);
      expect(
        tester.widget<GasStationCard>(find.byType(GasStationCard)).station.id,
        'sp98',
      );
    });

    testWidgets('recharge les stations quand le rayon change', (tester) async {
      final service = _FakeGasStationService(
        stations: [buildGasStation(id: 'a', price: 1.70, distanceInKm: 1)],
      );

      await pumpPage(tester, service);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '25 km'));
      await tester.pumpAndSettle();

      expect(service.callCount, 2);
      expect(service.lastRadius, SearchRadius.twentyFiveKm);
    });

    testWidgets('affiche un état vide sans station pour le carburant', (
      tester,
    ) async {
      await pumpPage(
        tester,
        _FakeGasStationService(
          stations: [
            buildGasStation(
              id: 'sp98',
              price: 1.90,
              distanceInKm: 2,
              fuel: FuelType.sp98,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GasStationCard), findsNothing);
      expect(find.textContaining('Aucune station'), findsOneWidget);
    });
  });
}

class _FakeGasStationService implements GasStationService {
  _FakeGasStationService({this.stations = const [], this.error});

  List<GasStation> stations;
  Object? error;

  int callCount = 0;
  SearchRadius? lastRadius;

  @override
  Future<List<GasStation>> fetchNearbyStations({
    required SearchRadius radius,
  }) async {
    callCount++;
    lastRadius = radius;

    if (error != null) {
      throw error!;
    }

    return stations;
  }
}
