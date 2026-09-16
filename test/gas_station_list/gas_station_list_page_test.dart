import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/gas_station_list_page.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
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

    // Deux E.Leclerc dans la même commune n'ont aucun champ qui les
    // distingue : l'adresse revient sur ces cartes-là, et sur elles seules.
    testWidgets('désambiguïse deux stations de même enseigne et commune', (
      tester,
    ) async {
      await pumpPage(
        tester,
        _FakeGasStationService(
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
      await pumpPage(
        tester,
        _FakeGasStationService(
          stations: [buildGasStation(id: 'a', price: 1.70, distanceInKm: 1)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('OpenStreetMap'), findsOneWidget);
      expect(find.textContaining('data.economie.gouv.fr'), findsOneWidget);
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

      await tester.tap(find.text('SP98'));
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

      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25 km'));
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

      testWidgets(
        'recharge les stations chaque minute sans indicateur',
        (tester) async {
          final service =
              _FakeGasStationService(
            stations: [
              buildGasStation(
                id: 'a',
                price: 1.70,
                distanceInKm: 1,
              ),
            ],
          );

          await pumpPage(tester, service);
          await tester.pumpAndSettle();

          expect(service.callCount, 1);

          // L'API renvoie une station de plus au passage suivant.
          service.stations = [
            ...service.stations,
            buildGasStation(
              id: 'b',
              price: 1.65,
              distanceInKm: 3,
            ),
          ];

          await tester.pump(
            const Duration(minutes: 1),
          );

          // Le rafraîchissement est silencieux : la liste reste
          // à l'écran pendant l'appel, sans tourniquet.
          expect(
            find.byType(
              CircularProgressIndicator,
            ),
            findsNothing,
          );

          await tester.pumpAndSettle();

          expect(service.callCount, 2);

          expect(
            find.byType(
              GasStationCard,
            ),
            findsNWidgets(2),
          );
        },
      );

      testWidgets(
        'garde la liste quand le rafraîchissement échoue',
        (tester) async {
          final service =
              _FakeGasStationService(
            stations: [
              buildGasStation(
                id: 'a',
                price: 1.70,
                distanceInKm: 1,
              ),
            ],
          );

          await pumpPage(tester, service);
          await tester.pumpAndSettle();

          service.error = Exception(
            'Erreur API : 503',
          );

          await tester.pump(
            const Duration(minutes: 1),
          );

          await tester.pumpAndSettle();

          // L'échec de fond ne vide pas l'écran et n'affiche
          // pas de message d'erreur.
          expect(
            find.byType(
              GasStationCard,
            ),
            findsOneWidget,
          );

          expect(
            find.textContaining(
              'Erreur API',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'affiche l\'heure du dernier chargement',
        (tester) async {
          await pumpPage(
            tester,
            _FakeGasStationService(
              stations: [
                buildGasStation(
                  id: 'a',
                  price: 1.70,
                  distanceInKm: 1,
                ),
              ],
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.textContaining(
              'Mis à jour à',
            ),
            findsOneWidget,
          );
        },
      );
  });
}

/// Faux GasStationService utilisé uniquement pendant les tests.
///
/// Aucun GPS réel et aucun appel Internet n'est effectué.
class _FakeGasStationService
    implements GasStationService {
  _FakeGasStationService({
    this.stations = const [],
    this.error,
  });

  List<GasStation> stations;

  Object? error;

  /// Nombre de fois où les stations
  /// ont été demandées.
  int callCount = 0;

  /// Dernier rayon reçu.
  SearchRadius? lastRadius;

  /// Simule la position GPS de l'utilisateur.
  @override
  Future<UserCoordinates>
      currentCoordinates() async {
    if (error != null) {
      throw error!;
    }

    return const UserCoordinates(
      latitude: 47.2184,
      longitude: -1.5536,
    );
  }

  /// Simule la récupération des stations.
  @override
  Future<List<GasStation>>
      fetchNearbyStations({
    required SearchRadius radius,
    UserCoordinates? coordinates,
  }) async {
    callCount++;

    lastRadius = radius;

    if (error != null) {
      throw error!;
    }

    return stations;
  }
}