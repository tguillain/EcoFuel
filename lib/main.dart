import 'package:ecofuel/gas_station_list/gas_station_list_page.dart';
import 'package:ecofuel/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const EcoFuelApp());
}

class EcoFuelApp extends StatelessWidget {
  const EcoFuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoFuel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const GasStationListPage(),
    );
  }
}
