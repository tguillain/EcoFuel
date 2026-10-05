import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_cluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Rond regroupant plusieurs stations : leur nombre au centre, et le meilleur
/// prix du groupe dessous pour qu'il vaille la peine de zoomer.
Marker buildClusterMarker({
  required StationCluster cluster,
  required FuelType fuel,
  required VoidCallback onTap,
}) {
  final Color color = cluster.best.color;
  final double? price = cluster.best.station.priceFor(fuel);

  return Marker(
    point: LatLng(cluster.latitude, cluster.longitude),
    width: 96,
    height: 74,
    child: Semantics(
      button: true,
      label: '${cluster.entries.length} stations, zoomer',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, color: Colors.black26),
                ],
              ),
              child: Text(
                '${cluster.entries.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Le marqueur a une taille fixe : avec un texte agrandi par
            // l'utilisateur, l'étiquette rapetisse plutôt que de passer à la
            // ligne et déborder.
            if (price != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(blurRadius: 3, color: Colors.black26),
                    ],
                  ),
                  child: Text(
                    'dès ${price.toStringAsFixed(3)} €',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
