import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_gas_station_service.dart';
import 'gas_station_fixture.dart';

void main() {
  group('GasStationListPage', () {
    testWidgets('affiche un indicateur puis la liste', (tester) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
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

    // Deux E.Leclerc dans la même commune n'ont aucun champ qui les
    // distingue : l'adresse revient sur ces cartes-là, et sur elles seules.
    testWidgets('désambiguïse deux stations de même enseigne et commune', (
      tester,
    ) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
          stations: [
            // Deux kilomètres les séparent : trop loin pour être regroupées,
            // assez semblables pour être indiscernables sans leur adresse.
            buildGasStation(
              id: 'paris',
              price: 2.169,
              distanceInKm: 4.5,
              brand: 'E.Leclerc',
              city: 'Nantes',
              address: '14 ROUTE DE PARIS',
              latitude: 47.251,
              longitude: -1.518,
            ),
            buildGasStation(
              id: 'perray',
              price: 2.169,
              distanceInKm: 4.5,
              brand: 'E.Leclerc',
              city: 'Nantes',
              address: '95 RUE DU PERRAY',
              latitude: 47.269,
              longitude: -1.518,
            ),
            buildGasStation(
              id: 'seule',
              price: 2.20,
              distanceInKm: 3,
              brand: 'Avia',
              city: 'Nantes',
              address: '1 RUE DU CROISSANT',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('14 route de Paris'), findsOneWidget);
      expect(find.textContaining('95 rue du Perray'), findsOneWidget);

      // La station sans homonyme garde une ligne secondaire épurée.
      expect(find.textContaining('1 rue du Croissant'), findsNothing);
    });

    // La licence ODbL impose de créditer OpenStreetMap dès qu'on affiche les
    // enseignes : les crédits ferment la liste.
    testWidgets('crédite les sources en fin de liste', (tester) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
          stations: [buildGasStation(id: 'a', price: 1.70, distanceInKm: 1)],
        ),
      );
      await tester.pumpAndSettle();
      await expandStationList(tester);

      // La carte en fond crédite aussi OpenStreetMap, pour ses tuiles.
      expect(
        find.textContaining('Enseignes : © les contributeurs OpenStreetMap'),
        findsOneWidget,
      );
      expect(find.textContaining('data.economie.gouv.fr'), findsOneWidget);
    });

    // Le glisser n'est pas à la portée du clavier ni d'un lecteur d'écran :
    // le tap sur la poignée fait passer la feuille d'un bout à l'autre.
    testWidgets('déploie puis replie la liste d\'un tap sur la poignée', (
      tester,
    ) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
          stations: [buildGasStation(id: 'a', price: 1.70, distanceInKm: 1)],
        ),
      );
      await tester.pumpAndSettle();

      double sheetTop() => tester.getTopLeft(find.byType(CustomScrollView)).dy;

      final collapsedTop = sheetTop();

      await expandStationList(tester);

      expect(sheetTop(), lessThan(collapsedTop));

      await tester.tap(find.bySemanticsLabel('Afficher la carte'));
      await tester.pumpAndSettle();

      expect(sheetTop(), collapsedTop);
    });

    // L'artboard « Carte · cartes flottantes » ne pose que deux stations sur
    // la carte : les suivantes n'apparaissent qu'une fois la liste tirée.
    testWidgets('ne montre que deux stations sur la carte', (tester) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
          stations: [
            buildGasStation(id: 'a', price: 1.70, distanceInKm: 1),
            buildGasStation(id: 'b', price: 1.75, distanceInKm: 2),
            buildGasStation(id: 'c', price: 1.80, distanceInKm: 3),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GasStationCard).hitTestable(), findsNWidgets(2));

      await expandStationList(tester);

      expect(find.byType(GasStationCard).hitTestable(), findsNWidgets(3));
    });

    testWidgets('met en avant la station la moins chère', (tester) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
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
      final service = FakeGasStationService(
        error: Exception('La localisation est désactivée.'),
      );

      await pumpGasStationListPage(tester, service);
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
      final service = FakeGasStationService(
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

      await pumpGasStationListPage(tester, service);
      await tester.pumpAndSettle();

      expect(find.byType(GasStationCard), findsOneWidget);
      expect(service.callCount, 1);

      await expandStationList(tester);

      await tester.tap(find.text('SP98').hitTestable());
      await tester.pumpAndSettle();

      expect(service.callCount, 1);
      expect(
        tester.widget<GasStationCard>(find.byType(GasStationCard)).station.id,
        'sp98',
      );
    });

    // Sur la carte, la piste des carburants se resserre en une pastille qui
    // ouvre un menu.
    testWidgets('change de carburant depuis la carte', (tester) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
          stations: [
            buildGasStation(id: 'e10', price: 1.70, distanceInKm: 1),
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

      await tester.tap(find.text('E10').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('SP98').hitTestable());
      await tester.pumpAndSettle();

      expect(
        tester.widget<GasStationCard>(find.byType(GasStationCard)).station.id,
        'sp98',
      );
    });

    testWidgets('affiche un état vide sans station pour le carburant', (
      tester,
    ) async {
      await pumpGasStationListPage(
        tester,
        FakeGasStationService(
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
