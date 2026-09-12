import 'package:ecofuel/config/app_config.dart';
import 'package:ecofuel/gas_station_list/gas_station_list_page.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(EcoFuelApp(service: GasStationService(_buildLocator())));
}

/// Sans `--dart-define`, l'application interroge le GPS comme en production :
/// figer la position doit rester un choix explicite, sous peine de masquer une
/// panne réelle de localisation pendant tout le développement.
UserLocator _buildLocator() {
  if (!AppConfig.hasFixedLocation) {
    return const GeolocatorUserLocator();
  }

  final latitude = AppConfig.fixedLatitude;
  final longitude = AppConfig.fixedLongitude;

  if (latitude == null || longitude == null) {
    throw ArgumentError(
      'FIXED_LATITUDE et FIXED_LONGITUDE doivent être fournis ensemble et '
      'être des nombres décimaux (reçu "${AppConfig.rawFixedLatitude}" et '
      '"${AppConfig.rawFixedLongitude}").',
    );
  }

  debugPrint('Position figée : $latitude, $longitude');

  return FixedUserLocator(
    UserCoordinates(latitude: latitude, longitude: longitude),
  );
}

class EcoFuelApp extends StatelessWidget {
  const EcoFuelApp({super.key, required this.service});

  final GasStationService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoFuel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: GasStationListPage(service: service),
    );
  }
}
