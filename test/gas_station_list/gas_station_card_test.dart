import 'package:ecofuel/theme/app_colors.dart';
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

    // Le fichier de l'État ne porte pas d'enseigne : quand une source tierce
    // la fournit, elle prend le titre. La commune reste en ligne secondaire,
    // l'adresse complète appartenant à la fiche de la station.
    testWidgets('titre par l\'enseigne quand elle est connue', (tester) async {
      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(
            id: 'station',
            price: 1.669,
            distanceInKm: 1.2,
            address: '205 ROUTE DE VANNES',
            city: 'Orvault',
            brand: 'Intermarché',
          ),
          fuel: FuelType.e10,
        ),
      );

      expect(find.text('Intermarché'), findsOneWidget);
      expect(find.textContaining('Orvault'), findsOneWidget);
      expect(find.textContaining('ROUTE DE VANNES'), findsNothing);
    });

    // Sans enseigne, l'adresse fait office de titre — remise en forme, la
    // casse du flux de l'État étant irrégulière.
    testWidgets('retombe sur l\'adresse remise en forme', (tester) async {
      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(
            id: 'station',
            price: 1.669,
            distanceInKm: 1.2,
            address: '205 ROUTE DE VANNES',
            city: 'Orvault',
          ),
          fuel: FuelType.e10,
        ),
      );

      expect(find.text('205 route de Vannes'), findsOneWidget);
      expect(find.textContaining('Orvault'), findsOneWidget);
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
      final highlighted = tester
          .widget<Material>(find.byType(Material).last)
          .color;

      await pumpCard(
        tester,
        GasStationCard.standard(station, fuel: FuelType.e10),
      );
      final standard = tester
          .widget<Material>(find.byType(Material).last)
          .color;

      expect(highlighted, AppColors.primary);
      expect(standard, AppColors.surface);
    });

    // Le prix occupe la largeur restante après l'adresse : il doit tenir sur
    // une seule ligne au gabarit d'écran du design, sans déborder.
    testWidgets('garde le prix sur une ligne au gabarit du design', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpCard(
        tester,
        GasStationCard.standard(
          buildGasStation(
            id: 'station',
            price: 1.669,
            distanceInKm: 1.2,
            address: 'Une adresse particulièrement longue pour la carte',
          ),
          fuel: FuelType.e10,
        ),
      );

      expect(tester.takeException(), isNull);

      final price = tester.renderObject<RenderBox>(find.byType(RichText).last);

      expect(price.size.height, lessThan(40));
    });
  });
}
