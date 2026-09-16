import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_details_sheet.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_marker_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Construit le marqueur d'une station sur la carte.
///
/// Les stations au meilleur prix sont dessinées en plus gros et en couleur,
/// les autres en gris et en retrait : sur une carte dense, c'est le contraste
/// qui fait ressortir les bonnes affaires, pas la couleur seule.
Marker buildGasStationMarker({
  required BuildContext context,
  required GasStation station,
  required FuelType fuel,
  required StationMarkerColor markerColor,
  required VoidCallback onShowRoute,
}) {
  final double? price = station.priceFor(fuel);

  final bool isHighlighted = markerColor.isHighlighted;

  return Marker(
    point: LatLng(
      station.latitude,
      station.longitude,
    ),
    width: 108,
    height: 74,
    child: GestureDetector(
      // Clic sur la station :
      // affichage de la fiche détaillée.
      onTap: () {
        showGasStationDetailsSheet(
          context: context,
          station: station,
          fuel: fuel,
          onShowRoute: onShowRoute,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // =============================
          // PRIX
          // =============================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),

              // La bordure signale les stations à retenir.
              border: Border.all(
                color: markerColor.color,
                width: isHighlighted ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: isHighlighted ? 4 : 2,
                  color: Colors.black26,
                ),
              ],
            ),
            child: Text(
              price == null
                  ? '--'
                  : '${price.toStringAsFixed(3)} €',
              style: TextStyle(
                fontSize: isHighlighted ? 13 : 12,
                fontWeight: isHighlighted
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: markerColor.color,
              ),
            ),
          ),

          // =============================
          // POSITION DE LA STATION
          // =============================
          Icon(
            Icons.location_on,
            size: isHighlighted ? 39 : 30,
            color: markerColor.color,
          ),
        ],
      ),
    ),
  );
}
