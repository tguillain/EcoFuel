import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Construit le marqueur d'une station sur la carte.
///
/// La couleur est calculée dans GasStationMap : elle situe la station sur le
/// dégradé vert-rouge des prix affichés, ce qui suffit à la classer sans avoir
/// à jouer aussi sur la taille du marqueur.
Marker buildGasStationMarker({
  required BuildContext context,
  required GasStation station,
  required FuelType fuel,
  required Color markerColor,
  required VoidCallback onTap,
}) {
  final double? price = station.priceFor(fuel);

  return Marker(
    point: LatLng(station.latitude, station.longitude),
    width: 108,
    height: 74,
    child: GestureDetector(
      // Clic sur la station : ouverture de sa fiche.
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // =============================
          // PRIX
          // =============================
          // Le marqueur a une taille fixe : avec un texte agrandi par
          // l'utilisateur, l'étiquette rapetisse plutôt que de passer à la
          // ligne et déborder.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: markerColor, width: 2),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, color: Colors.black26),
                ],
              ),
              child: Text(
                price == null ? '--' : '${price.toStringAsFixed(3)} €',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: markerColor,
                ),
              ),
            ),
          ),

          // =============================
          // POSITION DE LA STATION
          // =============================
          Icon(Icons.location_on, size: 39, color: markerColor),
        ],
      ),
    ),
  );
}
