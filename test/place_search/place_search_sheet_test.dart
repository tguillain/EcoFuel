import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:ecofuel/place_search/model/station_search.dart';
import 'package:ecofuel/place_search/service/place_search_service.dart';
import 'package:ecofuel/place_search/widget/place_search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lyon = SearchPlace(
    name: 'Lyon',
    context: '69, Rhône, Auvergne-Rhône-Alpes',
    latitude: 45.758,
    longitude: 4.835,
  );

  const aroundMe = StationSearch(
    place: null,
    radius: SearchRadius.fiveKm,
    fuel: FuelType.e10,
  );

  /// Ouvre le panneau et rend un accès à la recherche validée, `null` tant
  /// qu'il reste ouvert.
  Future<StationSearch? Function()> openSheet(
    WidgetTester tester,
    PlaceSearchService service, {
    StationSearch initial = aroundMe,
  }) async {
    StationSearch? search;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => search = await showPlaceSearchSheet(
              context,
              initial: initial,
              service: service,
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    return () => search;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
  }

  group('PlaceSearchSheet', () {
    testWidgets('valide le lieu, le rayon et le carburant choisis', (
      tester,
    ) async {
      final search = await openSheet(
        tester,
        const _FakePlaceSearchService([lyon]),
      );

      await type(tester, 'lyon');
      expect(find.text('69, Rhône, Auvergne-Rhône-Alpes'), findsOneWidget);
      await tester.tap(find.text('Lyon'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('25 km'));
      await tester.tap(find.text('SP98'));
      await tester.pump();
      await tester.tap(find.text('Voir les stations'));
      await tester.pumpAndSettle();

      expect(search()!.place, lyon);
      expect(search()!.radius, SearchRadius.twentyFiveKm);
      expect(search()!.fuel, FuelType.sp98);
    });

    testWidgets('reprend la recherche en cours', (tester) async {
      final search = await openSheet(
        tester,
        const _FakePlaceSearchService([lyon]),
        initial: const StationSearch(
          place: lyon,
          radius: SearchRadius.tenKm,
          fuel: FuelType.diesel,
        ),
      );

      expect(find.text('Lyon'), findsOneWidget);

      await tester.tap(find.text('Voir les stations'));
      await tester.pumpAndSettle();

      expect(search()!.radius, SearchRadius.tenKm);
      expect(search()!.fuel, FuelType.diesel);
    });

    testWidgets('revient à la position de l\'utilisateur', (tester) async {
      final search = await openSheet(
        tester,
        const _FakePlaceSearchService([lyon]),
        initial: const StationSearch(
          place: lyon,
          radius: SearchRadius.fiveKm,
          fuel: FuelType.e10,
        ),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Autour de moi'));
      await tester.pump();
      await tester.tap(find.text('Voir les stations'));
      await tester.pumpAndSettle();

      expect(search()!.place, isNull);
    });

    testWidgets('demande au moins 3 lettres', (tester) async {
      await openSheet(tester, const _FakePlaceSearchService([lyon]));

      await type(tester, 'ly');

      expect(find.textContaining('au moins 3 lettres'), findsOneWidget);
    });

    testWidgets('prévient quand la recherche échoue', (tester) async {
      await openSheet(tester, const _FakePlaceSearchService(null));

      await type(tester, 'lyon');

      expect(find.textContaining('n\'a pas abouti'), findsOneWidget);
    });

    testWidgets('dit quand aucun lieu ne correspond', (tester) async {
      await openSheet(tester, const _FakePlaceSearchService([]));

      await type(tester, 'zzzz');

      expect(
        find.text('Aucun lieu trouvé. Essaie un autre nom.'),
        findsOneWidget,
      );
    });
  });
}

/// Rend [places], ou échoue quand elles valent `null`.
class _FakePlaceSearchService implements PlaceSearchService {
  const _FakePlaceSearchService(this.places);

  final List<SearchPlace>? places;

  @override
  Future<List<SearchPlace>> search(String query) async {
    final places = this.places;

    if (places == null) {
      throw Exception('Recherche de lieu impossible (503).');
    }

    return query.trim().length < PlaceSearchService.minQueryLength
        ? const []
        : places;
  }
}
