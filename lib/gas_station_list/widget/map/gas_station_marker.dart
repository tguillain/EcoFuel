import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Construit le marqueur d'une station sur la carte.
///
/// La couleur est calculée dans GasStationMap
/// en fonction du critère Prix / Distance.
Marker buildGasStationMarker({
  required BuildContext context,
  required GasStation station,
  required FuelType fuel,
  required Color markerColor,
  required VoidCallback onShowRoute,
}) {
  final double? price =
      station.priceFor(fuel);

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
          onShowRoute:
              onShowRoute,
        );
      },
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          // =============================
          // PRIX
          // =============================
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration:
                BoxDecoration(
              color:
                  Theme.of(context)
                      .colorScheme
                      .surface,
              borderRadius:
                  BorderRadius.circular(
                8,
              ),

              // La bordure indique le niveau
              // d'intérêt de la station.
              border: Border.all(
                color: markerColor,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color:
                      Colors.black26,
                ),
              ],
            ),
            child: Text(
              price == null
                  ? '--'
                  : '${price.toStringAsFixed(3)} €',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                color:
                    markerColor,
              ),
            ),
          ),

          // =============================
          // POSITION DE LA STATION
          // =============================
          Icon(
            Icons.location_on,
            size: 39,
            color: markerColor,
          ),
        ],
      ),
    ),
  );
}