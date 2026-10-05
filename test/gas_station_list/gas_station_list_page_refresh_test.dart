import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_gas_station_service.dart';
import 'gas_station_fixture.dart';

void main() {
  group('GasStationListPage · rafraîchissement', () {
    testWidgets('recharge les stations chaque minute sans indicateur', (
      tester,
    ) async {
      final service = FakeGasStationService(
        stations: [buildGasStation(id: 'a', price: 1.70, distanceInKm: 1)],
      );

      await pumpGasStationListPage(tester, service);
      await tester.pumpAndSettle();

      expect(service.callCount, 1);

      // L'API renvoie une station de plus au passage suivant.
      service.stations = [
        ...service.stations,
        buildGasStation(id: 'b', price: 1.65, distanceInKm: 3),
      ];

      await tester.pump(const Duration(minutes: 1));

      // Le rafraîchissement est silencieux : la liste reste
      // à l'écran pendant l'appel, sans tourniquet.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpAndSettle();

      expect(service.callCount, 2);

      expect(find.byType(GasStationCard), findsNWidgets(2));
    });

    testWidgets('garde la liste quand le rafraîchissement échoue', (
      tester,
    ) async {
      final service = FakeGasStationService(
        stations: [buildGasStation(id: 'a', price: 1.70, distanceInKm: 1)],
      );

      await pumpGasStationListPage(tester, service);
      await tester.pumpAndSettle();

      service.error = Exception('Erreur API : 503');

      await tester.pump(const Duration(minutes: 1));

      await tester.pumpAndSettle();

      // L'échec de fond ne vide pas l'écran et n'affiche
      // pas de message d'erreur.
      expect(find.byType(GasStationCard), findsOneWidget);

      expect(find.textContaining('Erreur API'), findsNothing);
    });

    testWidgets('affiche l\'heure du dernier chargement', (tester) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
          stations: [buildGasStation(id: 'a', price: 1.70, distanceInKm: 1)],
        ),
      );

      await tester.pumpAndSettle();
      await expandStationList(tester);

      expect(find.textContaining('Mis à jour à'), findsOneWidget);
    });
  });
}
