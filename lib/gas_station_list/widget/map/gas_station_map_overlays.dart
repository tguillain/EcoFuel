import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/widget/map/map_price_legend.dart';
import 'package:flutter/material.dart';

/// Commandes posées sur la carte : légende et bouton de recentrage.
///
/// Seuls ses enfants captent les gestes : le reste de la surface laisse passer
/// glissements et zooms jusqu'à la carte.
class GasStationMapOverlays extends StatelessWidget {
  const GasStationMapOverlays({
    super.key,
    required this.fuel,
    required this.stationLimit,
    required this.onRecenter,
  });

  final FuelType fuel;
  final int stationLimit;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // =============================
        // LÉGENDE DES COULEURS
        // =============================
        Positioned(
          left: 12,
          top: 12,
          child: MapPriceLegend(fuel: fuel, count: stationLimit),
        ),

        // =============================
        // RECENTRER
        // =============================
        Positioned(
          right: 16,
          bottom: 22,
          child: FloatingActionButton.small(
            heroTag: 'mapCenterButton',
            tooltip: 'Recentrer',
            onPressed: onRecenter,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
