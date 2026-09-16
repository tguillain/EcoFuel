import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_list_header.dart';
import 'package:ecofuel/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    String title = '12 stations',
    SearchRadius selectedRadius = SearchRadius.fiveKm,
    ValueChanged<SearchRadius>? onRadiusChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: GasStationListHeader(
            title: title,
            selectedRadius: selectedRadius,
            onRadiusChanged: onRadiusChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('GasStationListHeader', () {
    testWidgets('affiche le titre et le rayon courant', (tester) async {
      await pumpHeader(tester, selectedRadius: SearchRadius.tenKm);

      expect(find.text('12 stations'), findsOneWidget);
      expect(find.text('AUTOUR DE MOI · 10 KM'), findsOneWidget);
    });

    testWidgets('propose tous les rayons et remonte le choix', (tester) async {
      SearchRadius? selected;

      await pumpHeader(tester, onRadiusChanged: (value) => selected = value);

      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pumpAndSettle();

      for (final radius in SearchRadius.values) {
        expect(
          find.text(radius.label),
          findsOneWidget,
          reason: 'rayon « ${radius.label} » absent du menu',
        );
      }

      await tester.tap(find.text('25 km'));
      await tester.pumpAndSettle();

      expect(selected, SearchRadius.twentyFiveKm);
    });
  });
}
