import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_marker_color.dart';
import 'package:flutter/material.dart';

/// Rappelle ce que signale la couleur d'un marqueur.
///
/// Le dégradé est relatif aux stations affichées : la légende en nomme les
/// deux extrémités, sans prétendre à un prix absolu.
class MapPriceLegend extends StatelessWidget {
  const MapPriceLegend({super.key, required this.fuel, required this.count});

  static const double _barWidth = 104;

  final FuelType fuel;

  /// Nombre maximal de stations affichées, que la légende annonce.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count meilleures · ${fuel.label}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('prix et distance', style: TextStyle(fontSize: 10)),
          const SizedBox(height: 6),
          Container(
            width: _barWidth,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [
                  StationMarkerColor.cheapest,
                  StationMarkerColor.middle,
                  StationMarkerColor.dearest,
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          const SizedBox(
            width: _barWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Moins cher', style: TextStyle(fontSize: 10)),
                Text('Plus cher', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
