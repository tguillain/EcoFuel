import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_filter_bar.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:ecofuel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const horizontalPadding = 18.0;

  Future<void> pumpFilterBar(
    WidgetTester tester, {
    double width = 390,
    ValueChanged<GasStationSortCriterion>? onSortChanged,
    ValueChanged<FuelType>? onFuelChanged,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: GasStationFilterBar(
              sortCriterion: GasStationSortCriterion.price,
              selectedFuel: FuelType.e10,
              onSortChanged: onSortChanged ?? (_) {},
              onFuelChanged: onFuelChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  Rect pillRect(WidgetTester tester, String label) {
    return tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
    );
  }

  Color labelColor(WidgetTester tester, String label) {
    return tester.widget<Text>(find.text(label)).style!.color!;
  }

  Color pillColor(WidgetTester tester, String label) {
    return tester
        .widget<Material>(
          find
              .ancestor(of: find.text(label), matching: find.byType(Material))
              .first,
        )
        .color!;
  }

  group('GasStationFilterBar', () {
    testWidgets('affiche une option par carburant et par critère de tri', (
      tester,
    ) async {
      await pumpFilterBar(tester);

      for (final fuel in FuelType.values) {
        expect(find.text(fuel.label), findsOneWidget);
      }

      for (final criterion in GasStationSortCriterion.values) {
        expect(find.text(criterion.label), findsOneWidget);
      }
    });

    // Le carburant sélectionné se lit à la couleur seule : c'est le seul
    // marqueur de sélection, il ne doit pas se confondre avec les autres.
    testWidgets('marque la sélection par une pastille sombre', (tester) async {
      await pumpFilterBar(tester);

      expect(pillColor(tester, 'E10'), AppColors.onSurface);
      expect(labelColor(tester, 'E10'), AppColors.onPrimary);

      expect(labelColor(tester, 'SP95'), AppColors.onSurfaceMuted);
      expect(labelColor(tester, 'Distance'), AppColors.onSurfaceSubtle);
      expect(pillColor(tester, 'SP95'), isNot(AppColors.onSurface));

      expect(pillColor(tester, 'Prix croissant'), AppColors.onSurface);
      expect(pillColor(tester, 'Distance'), AppColors.surfaceMuted);
    });

    testWidgets('étale les carburants sur toute la largeur, à largeur égale', (
      tester,
    ) async {
      const width = 390.0;
      await pumpFilterBar(tester, width: width);

      final widths = FuelType.values
          .map((fuel) => pillRect(tester, fuel.label).width)
          .toSet();

      expect(widths, hasLength(1));

      final first = pillRect(tester, FuelType.values.first.label);
      final last = pillRect(tester, FuelType.values.last.label);

      // La piste ajoute 3 px de rembourrage à l'intérieur de la marge.
      expect(first.left, horizontalPadding + 3);
      expect(last.right, width - horizontalPadding - 3);
    });

    // Les critères de tri se dimensionnent sur leur libellé : « Prix
    // croissant » est bien plus long que « Distance », les étaler à largeur
    // égale gaspillerait la ligne.
    testWidgets('dimensionne les pastilles de tri sur leur libellé', (
      tester,
    ) async {
      await pumpFilterBar(tester);

      final price = pillRect(tester, 'Prix croissant');
      final distance = pillRect(tester, 'Distance');

      expect(price.width, greaterThan(distance.width));
      expect(price.left, horizontalPadding);
      expect(distance.right, lessThan(390 - horizontalPadding));
    });

    // Le FittedBox réduit le libellé plutôt que de le couper : « Gazole » est
    // le plus long des carburants et sert de témoin sur un écran étroit.
    testWidgets('réduit les libellés trop longs au lieu de les tronquer', (
      tester,
    ) async {
      await pumpFilterBar(tester, width: 320);
      final narrow = tester.getRect(find.text('Gazole')).width;

      await pumpFilterBar(tester, width: 430);
      final wide = tester.getRect(find.text('Gazole')).width;

      expect(narrow, lessThan(wide));
      expect(find.textContaining('…'), findsNothing);
    });

    // Gabarits compacts de l'artboard. On mesure l'écart au libellé plutôt
    // qu'une hauteur absolue, qui dépendrait des métriques de la police.
    testWidgets('applique les rembourrages du design', (tester) async {
      await pumpFilterBar(tester);

      final fuel = pillRect(tester, 'E10');
      final fuelLabel = tester.getRect(find.text('E10'));

      expect(
        fuel.height - fuelLabel.height,
        moreOrLessEquals(8 * 2, epsilon: 1),
        reason: 'la pastille de carburant doit garder 8 px au-dessus/dessous',
      );

      final sort = pillRect(tester, 'Distance');
      final sortLabel = tester.getRect(find.text('Distance'));

      expect(
        sort.height - sortLabel.height,
        moreOrLessEquals(7 * 2, epsilon: 1),
        reason: 'la pastille de tri doit garder 7 px au-dessus/dessous',
      );
    });

    testWidgets('remonte les changements de carburant et de critère', (
      tester,
    ) async {
      GasStationSortCriterion? sort;
      FuelType? fuel;

      await pumpFilterBar(
        tester,
        onSortChanged: (value) => sort = value,
        onFuelChanged: (value) => fuel = value,
      );

      await tester.tap(find.text('Distance'));
      await tester.tap(find.text('SP98'));
      await tester.pump();

      expect(sort, GasStationSortCriterion.distance);
      expect(fuel, FuelType.sp98);
    });
  });
}
