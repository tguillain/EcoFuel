import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gas_station_fixture.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: card),
      ),
    );
  }

  group('GasStationCard', () {
    testWidgets('affiche adresse, ville, distance et prix', (tester) async {
      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(
            id: 'station',
            price: 1.669,
            distanceInKm: 1.2,
            address: '1 rue de la Paix',
            city: 'Nantes',
          ),
          fuel: FuelType.e10,
        ),
      );

      expect(find.text('1 rue de la Paix'), findsOneWidget);
      expect(find.textContaining('Nantes'), findsOneWidget);
      expect(find.textContaining('1,2 km'), findsOneWidget);
      expect(find.text('1,669 €/L', findRichText: true), findsOneWidget);
    });

    testWidgets('annonce une station ouverte 24h/24', (tester) async {
      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(
            id: 'station',
            price: 1.669,
            distanceInKm: 1,
            isOpen24h: true,
          ),
          fuel: FuelType.e10,
        ),
      );

      expect(find.textContaining('24h/24'), findsOneWidget);
    });

    testWidgets('annonce l\'heure de fermeture', (tester) async {
      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(
            id: 'station',
            price: 1.669,
            distanceInKm: 1,
            closingTime: '20h30',
          ),
          fuel: FuelType.e10,
        ),
      );

      expect(find.textContaining('ouvert jusqu\'à 20h30'), findsOneWidget);
    });

    testWidgets('annonce une station fermée', (tester) async {
      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(
            id: 'station',
            price: 1.669,
            distanceInKm: 1,
            isClosed: true,
          ),
          fuel: FuelType.e10,
        ),
      );

      expect(find.textContaining('fermé'), findsOneWidget);
    });

    testWidgets('signale un prix indisponible pour le carburant', (
      tester,
    ) async {
      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(id: 'station', price: null, distanceInKm: 1),
          fuel: FuelType.sp98,
        ),
      );

      expect(find.text('— €/L', findRichText: true), findsOneWidget);
    });

    testWidgets('met en avant la variante highlighted', (tester) async {
      final station = buildGasStation(
        id: 'station',
        price: 1.669,
        distanceInKm: 1,
      );

      await pumpCard(
        tester,
        GasStationCard.highlighted(station, fuel: FuelType.e10),
      );
      final highlighted = tester.widget<Card>(find.byType(Card)).color;

      await pumpCard(
        tester,
        GasStationCard.standard(station, fuel: FuelType.e10),
      );
      final standard = tester.widget<Card>(find.byType(Card)).color;

      expect(highlighted, isNot(standard));
    });

    // ListTile plafonne son `trailing` à 56 px de haut (mode non dense) : un
    // prix sur deux lignes tenait de justesse avec la police de repli des tests
    // mais débordait avec Archivo chargée dans l'app. On garde donc une marge.
    testWidgets('garde un prix assez court pour le gabarit du ListTile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(id: 'station', price: 1.669, distanceInKm: 1.2),
          fuel: FuelType.e10,
        ),
      );

      final trailing = tester.getSize(
        find
            .descendant(
              of: find.byType(ListTile),
              matching: find.byType(RichText),
            )
            .last,
      );

      expect(trailing.height, lessThan(40));
    });
  });
}
