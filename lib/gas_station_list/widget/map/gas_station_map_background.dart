import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// La carte, en fond sous l'en-tête et la feuille des stations.
class GasStationMapBackground extends StatelessWidget {
  const GasStationMapBackground({
    super.key,
    required this.stations,
    required this.fuel,
    required this.radius,
    required this.coveredInsets,
    required this.framingInsets,
    this.userCoordinates,
    this.searchCenter,
  });

  final List<GasStation> stations;
  final FuelType fuel;
  final SearchRadius radius;
  final ValueListenable<EdgeInsets> coveredInsets;
  final EdgeInsets framingInsets;
  final UserCoordinates? userCoordinates;
  final UserCoordinates? searchCenter;

  @override
  Widget build(BuildContext context) {
    final UserCoordinates? coordinates = userCoordinates;

    // Seul le premier chargement n'a pas encore de position : un échec
    // remplace tout l'écran par son message, et les suivants gardent la
    // dernière position connue.
    if (coordinates == null) {
      return ColoredBox(color: context.colors.surfaceMuted);
    }

    return GasStationMap(
      stations: stations,
      fuel: fuel,
      userCoordinates: coordinates,
      searchCenter: searchCenter,
      radius: radius,
      coveredInsets: coveredInsets,
      framingInsets: framingInsets,
    );
  }
}
