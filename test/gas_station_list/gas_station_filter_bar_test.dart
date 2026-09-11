import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_filter_bar.dart';
import 'package:ecofuel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpFilterBar(
    WidgetTester tester, {
    double width = 390,
    ValueChanged<GasStationSortCriterion>? onSortChanged,
    ValueChanged<FuelType>? onFuelChanged,
    ValueChanged<SearchRadius>? onRadiusChanged,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('EcoFuel'),
            bottom: GasStationFilterBar(
              sortCriterion: GasStationSortCriterion.price,
              selectedFuel: FuelType.e10,
              selectedRadius: SearchRadius.fiveKm,
              onSortChanged: onSortChanged ?? (_) {},
              onFuelChanged: onFuelChanged ?? (_) {},
              onRadiusChanged: onRadiusChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  Rect chipRect(WidgetTester tester, String label) {
    return tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
    );
  }

  group('GasStationFilterBar', () {
    testWidgets('affiche un chip par critère, carburant et rayon', (
      tester,
    ) async {
      await pumpFilterBar(tester);

      expect(
        find.byType(ChoiceChip),
        findsNWidgets(
          GasStationSortCriterion.values.length +
              FuelType.values.length +
              SearchRadius.values.length,
        ),
      );
    });

    testWidgets('étale chaque rangée sur toute la largeur', (tester) async {
      const width = 390.0;
      await pumpFilterBar(tester, width: width);

      for (final row in [
        ['Prix', 'Distance'],
        ['Gazole', 'E10'],
        ['5 km', '50 km'],
      ]) {
        final first = chipRect(tester, row.first);
        final last = chipRect(tester, row.last);

        // La barre garde 14 px de marge de chaque côté.
        expect(first.left, 14);
        expect(last.right, width - 14);
      }
    });

    testWidgets('donne la même largeur à tous les chips d\'une rangée', (
      tester,
    ) async {
      await pumpFilterBar(tester);

      final widths = FuelType.values
          .map((fuel) => chipRect(tester, fuel.label).width)
          .toSet();

      expect(widths, hasLength(1));
    });

    // Les chips sélectionnés n'affichent pas de coche : elle décalerait leur
    // libellé vers la droite alors que celui des autres reste centré.
    testWidgets('centre les libellés, sélectionnés ou non', (tester) async {
      await pumpFilterBar(tester);

      for (final label in ['Prix', 'Distance', 'Gazole', 'E10', '5 km']) {
        final chip = chipRect(tester, label);
        final text = tester.getRect(find.text(label));

        expect(
          text.center.dx,
          moreOrLessEquals(chip.center.dx, epsilon: 0.5),
          reason: 'libellé « $label » décentré',
        );
      }
    });

    // Le FittedBox réduit le libellé plutôt que de le couper : « Gazole » est
    // le plus long et sert de témoin sur un écran étroit.
    testWidgets('réduit les libellés trop longs au lieu de les tronquer', (
      tester,
    ) async {
      await pumpFilterBar(tester, width: 320);
      final narrow = tester.getRect(find.text('Gazole')).width;

      await pumpFilterBar(tester, width: 430);
      final wide = tester.getRect(find.text('Gazole')).width;

      expect(narrow, lessThan(wide));
      expect(narrow, lessThan(chipRect(tester, 'Gazole').width));
      expect(find.textContaining('…'), findsNothing);
    });

    testWidgets('remonte les changements de critère, carburant et rayon', (
      tester,
    ) async {
      GasStationSortCriterion? sort;
      FuelType? fuel;
      SearchRadius? radius;

      await pumpFilterBar(
        tester,
        onSortChanged: (value) => sort = value,
        onFuelChanged: (value) => fuel = value,
        onRadiusChanged: (value) => radius = value,
      );

      await tester.tap(find.text('Distance'));
      await tester.tap(find.text('SP98'));
      await tester.tap(find.text('25 km'));
      await tester.pump();

      expect(sort, GasStationSortCriterion.distance);
      expect(fuel, FuelType.sp98);
      expect(radius, SearchRadius.twentyFiveKm);
    });
  });
}
