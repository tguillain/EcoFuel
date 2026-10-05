import 'package:ecofuel/gas_station_detail/gas_station_detail_page.dart';
import 'package:ecofuel/gas_station_detail/service/directions_launcher.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/route_result.dart';
import 'package:ecofuel/gas_station_list/service/route_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 5, 14);

  const coordinates = UserCoordinates(latitude: 47.2184, longitude: -1.5536);

  final station = GasStation(
    id: '44400001',
    address: '12 RUE DE LA JAGUERE',
    city: 'Rezé',
    postalCode: '44400',
    brand: 'Intermarché',
    distanceInKm: 1.2,
    latitude: 47.18,
    longitude: -1.55,
    isOpen24h: true,
    closingTime: null,
    isClosed: false,
    pricesByFuel: const {
      FuelType.e10: 1.669,
      FuelType.sp95: 1.729,
      FuelType.sp98: null,
      FuelType.diesel: 1.639,
    },
    priceUpdatedAtByFuel: {
      FuelType.e10: now.subtract(const Duration(minutes: 8)),
    },
    services: const [
      'Station de gonflage',
      'Lavage automatique',
      'Lavage manuel',
      'Aire de camping-cars',
    ],
  );

  Future<void> pumpDetail(
    WidgetTester tester, {
    RouteService routeService = const _FakeRouteService(minutes: 4),
    bool isCheapest = true,
    DirectionsLauncher directionsLauncher = const DirectionsLauncher(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GasStationDetailPage(
          station: station,
          fuel: FuelType.e10,
          radius: SearchRadius.fiveKm,
          userCoordinates: coordinates,
          isCheapest: isCheapest,
          routeService: routeService,
          directionsLauncher: directionsLauncher,
          now: now,
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('GasStationDetailPage', () {
    testWidgets('affiche la station et le prix du carburant choisi', (
      tester,
    ) async {
      await pumpDetail(tester);

      expect(find.text('E10 · LA MOINS CHÈRE À 5 KM'), findsOneWidget);
      expect(find.text('1,669'), findsOneWidget);
      expect(find.text('Intermarché'), findsOneWidget);
      expect(find.textContaining(', 44400 Rezé\n'), findsOneWidget);
      expect(
        find.textContaining('1,2 km · 4 min · ouvert 24h/24'),
        findsOneWidget,
      );
    });

    // Un carburant courant reste listé même absent : savoir qu'il manque
    // évite d'y aller pour rien. Les carburants plus rares ne s'affichent que
    // si la station les vend, sans quoi la plupart des fiches aligneraient
    // E85 et GPLc indisponibles.
    testWidgets(
      'liste les carburants courants, et les rares s\'ils sont vendus',
      (tester) async {
        await pumpDetail(tester);

        expect(find.text('Gazole'), findsOneWidget);
        expect(find.text('1,639 €'), findsOneWidget);
        expect(find.text('SP98'), findsOneWidget);
        expect(find.text('Indisponible'), findsOneWidget);
        expect(find.text('SP95'), findsOneWidget);
        expect(find.text('1,729 €'), findsOneWidget);
        expect(find.text('E85'), findsNothing);
        expect(find.text('GPLc'), findsNothing);
      },
    );

    testWidgets('résume les services et l\'ancienneté du relevé', (
      tester,
    ) async {
      await pumpDetail(tester);

      expect(find.text('24/7'), findsOneWidget);
      expect(find.text('Gonflage'), findsOneWidget);
      expect(find.text('Lavage'), findsOneWidget);
      expect(find.text('Relevé il y a 8 min'), findsOneWidget);
    });

    testWidgets('situe une station qui n\'est pas la moins chère', (
      tester,
    ) async {
      await pumpDetail(tester, isCheapest: false);

      expect(find.text('E10 · À 1,2 KM'), findsOneWidget);
    });

    testWidgets('se passe de la durée quand l\'itinéraire échoue', (
      tester,
    ) async {
      await pumpDetail(tester, routeService: const _FailingRouteService());

      expect(find.text('Itinéraire'), findsOneWidget);
    });

    testWidgets('ouvre l\'itinéraire dans Google Maps', (tester) async {
      final launcher = _FakeDirectionsLauncher(opens: true);

      await pumpDetail(tester, directionsLauncher: launcher);

      await tester.tap(find.text('Itinéraire · 4 min'));
      await tester.pumpAndSettle();

      expect(launcher.openedStations, [station]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('prévient quand Google Maps ne s\'ouvre pas', (tester) async {
      await pumpDetail(
        tester,
        directionsLauncher: _FakeDirectionsLauncher(opens: false),
      );

      await tester.tap(find.text('Itinéraire · 4 min'));
      await tester.pump();

      expect(find.text('Impossible d\'ouvrir Google Maps.'), findsOneWidget);
    });
  });

  test('vise la station en voiture dans Google Maps', () {
    final uri = DirectionsLauncher.uriFor(station);

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, {
      'api': '1',
      'destination': '47.18,-1.55',
      'travelmode': 'driving',
    });
  });
}

class _FakeDirectionsLauncher implements DirectionsLauncher {
  _FakeDirectionsLauncher({required this.opens});

  final bool opens;
  final List<GasStation> openedStations = [];

  @override
  Future<bool> open(GasStation station) async {
    openedStations.add(station);

    return opens;
  }
}

class _FakeRouteService implements RouteService {
  const _FakeRouteService({required this.minutes});

  final int minutes;

  @override
  Future<RouteResult> fetchRoute({
    required UserCoordinates start,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async => RouteResult(
    points: const [],
    distanceInKm: 1.4,
    durationInMinutes: minutes.toDouble(),
  );
}

class _FailingRouteService implements RouteService {
  const _FailingRouteService();

  @override
  Future<RouteResult> fetchRoute({
    required UserCoordinates start,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async => throw Exception('Aucun itinéraire disponible.');
}
