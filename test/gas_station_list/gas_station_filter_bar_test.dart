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
    FuelType selectedFuel = FuelType.e10,
    ThemeData? theme,
    GasStationSortCriterion sortCriterion = GasStationSortCriterion.price,
    ValueChanged<GasStationSortCriterion>? onSortChanged,
    ValueChanged<FuelType>? onFuelChanged,
    ValueChanged<String?>? onBrandChanged,
    String? selectedBrand,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: GasStationFilterBar(
              sortCriterion: sortCriterion,
              selectedFuel: selectedFuel,
              onSortChanged: onSortChanged ?? (_) {},
              onFuelChanged: onFuelChanged ?? (_) {},
              brands: const [
                (brand: 'TotalEnergies', count: 6),
                (brand: 'Avia', count: 2),
              ],
              selectedBrand: selectedBrand,
              onBrandChanged: onBrandChanged ?? (_) {},
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

      for (final fuel in FuelType.popular) {
        expect(find.text(fuel.label), findsOneWidget);
      }

      expect(find.text('Autres'), findsOneWidget);

      // Le prix est l'ordre par défaut : seule la distance se choisit.
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Prix croissant'), findsNothing);
    });

    // Le carburant sélectionné se lit à la couleur seule : c'est le seul
    // marqueur de sélection, il ne doit pas se confondre avec les autres.
    testWidgets('marque la sélection par une pastille sombre', (tester) async {
      await pumpFilterBar(tester);

      expect(pillColor(tester, 'E10'), AppColors.light.selected);
      expect(labelColor(tester, 'E10'), AppColors.light.onSelected);

      expect(labelColor(tester, 'SP98'), AppColors.light.onSurfaceMuted);
      expect(labelColor(tester, 'Distance'), AppColors.light.onSurfaceSubtle);
      expect(pillColor(tester, 'SP98'), isNot(AppColors.light.selected));

      expect(pillColor(tester, 'Distance'), AppColors.light.surfaceMuted);
    });

    // En sombre, une pastille sélectionnée s'inverse : fond clair, libellé
    // foncé. Garder le fond de la couleur du texte la rendrait invisible.
    testWidgets('inverse la pastille sélectionnée en mode sombre', (
      tester,
    ) async {
      await pumpFilterBar(tester, theme: AppTheme.dark);

      expect(pillColor(tester, 'E10'), AppColors.dark.selected);
      expect(labelColor(tester, 'E10'), AppColors.dark.onSelected);
      expect(labelColor(tester, 'SP98'), AppColors.dark.onSurfaceMuted);
    });

    testWidgets(
      'étale les cases de carburant sur toute la largeur, à largeur égale',
      (tester) async {
        const width = 390.0;
        await pumpFilterBar(tester, width: width);

        final labels = [
          for (final fuel in FuelType.popular) fuel.label,
          'Autres',
        ];
        final widths = labels
            .map((label) => pillRect(tester, label).width)
            .toSet();

        expect(widths, hasLength(1));

        final first = pillRect(tester, labels.first);
        final last = pillRect(tester, labels.last);

        // La piste ajoute 3 px de rembourrage à l'intérieur de la marge.
        expect(first.left, horizontalPadding + 3);
        expect(last.right, width - horizontalPadding - 3);
      },
    );

    // La pastille Distance se dimensionne sur son libellé et ouvre la ligne.
    testWidgets('dimensionne la pastille Distance sur son libellé', (
      tester,
    ) async {
      await pumpFilterBar(tester);

      final distance = pillRect(tester, 'Distance');

      expect(distance.left, horizontalPadding);
      expect(distance.right, lessThan(390 - horizontalPadding));
    });

    testWidgets('revient au prix quand on désactive la distance', (
      tester,
    ) async {
      GasStationSortCriterion? sort;

      await pumpFilterBar(
        tester,
        sortCriterion: GasStationSortCriterion.distance,
        onSortChanged: (value) => sort = value,
      );

      expect(pillColor(tester, 'Distance'), AppColors.light.selected);

      await tester.tap(find.text('Distance'));
      await tester.pump();

      expect(sort, GasStationSortCriterion.price);
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

  group('GasStationFilterBar · marque', () {
    // Les carburants moins distribués se rangent derrière la quatrième case,
    // pour garder à la piste des cases lisibles sur un téléphone.
    testWidgets('propose les autres carburants dans un menu', (tester) async {
      FuelType? fuel;

      await pumpFilterBar(tester, onFuelChanged: (value) => fuel = value);

      for (final other in FuelType.others) {
        expect(find.text(other.label), findsNothing);
      }

      await tester.tap(find.text('Autres'));
      await tester.pumpAndSettle();

      for (final other in FuelType.others) {
        expect(find.text(other.label), findsOneWidget);
      }

      await tester.tap(find.text('GPLc'));
      await tester.pumpAndSettle();

      expect(fuel, FuelType.gplc);
    });

    testWidgets('affiche dans la quatrième case le carburant rare choisi', (
      tester,
    ) async {
      await pumpFilterBar(tester, selectedFuel: FuelType.e85);

      expect(find.text('Autres'), findsNothing);
      expect(pillColor(tester, 'E85'), AppColors.light.selected);
      expect(labelColor(tester, 'E85'), AppColors.light.onSelected);
    });

    testWidgets('propose les marques du rayon et remonte le choix', (
      tester,
    ) async {
      String? chosen = 'pas encore';

      await pumpFilterBar(tester, onBrandChanged: (brand) => chosen = brand);

      await tester.tap(find.text('Toutes les marques'));
      await tester.pumpAndSettle();

      expect(find.text('TotalEnergies'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('8'), findsOneWidget, reason: 'total des stations');

      await tester.tap(find.text('Avia'));
      await tester.pumpAndSettle();

      expect(chosen, 'Avia');
    });

    testWidgets('revient à toutes les marques', (tester) async {
      String? chosen = 'pas encore';

      await pumpFilterBar(
        tester,
        selectedBrand: 'Avia',
        onBrandChanged: (brand) => chosen = brand,
      );

      await tester.tap(find.text('Avia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Toutes les marques'));
      await tester.pumpAndSettle();

      expect(chosen, isNull);
    });
  });
}
