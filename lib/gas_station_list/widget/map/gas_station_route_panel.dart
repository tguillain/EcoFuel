import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/route_result.dart';
import 'package:flutter/material.dart';

/// Panneau affiché en bas de la carte
/// lorsqu'un itinéraire est actif.
class GasStationRoutePanel
    extends StatelessWidget {
  const GasStationRoutePanel({
    super.key,
    required this.route,
    required this.station,
    required this.onStop,
  });

  final RouteResult route;
  final GasStation station;
  final VoidCallback onStop;

  @override
  Widget build(
    BuildContext context,
  ) {
    final int minutes =
        route.durationInMinutes.ceil();

    return Card(
      elevation: 5,
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            // =============================
            // STATION
            // =============================
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 28,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        station.address,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        station.city,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(
              height: 22,
            ),

            // =============================
            // DISTANCE + DURÉE
            // =============================
            Row(
              children: [
                Expanded(
                  child: _RouteValue(
                    icon:
                        Icons.route,
                    value:
                        '${route.distanceInKm.toStringAsFixed(1)} km',
                  ),
                ),
                Expanded(
                  child: _RouteValue(
                    icon:
                        Icons.access_time,
                    value:
                        '$minutes min',
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // =============================
            // ARRÊTER
            // =============================
            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    onStop,
                icon:
                    const Icon(
                  Icons.close,
                ),
                label:
                    const Text(
                  'Arrêter l’itinéraire',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petite donnée de l'itinéraire :
/// distance ou durée.
class _RouteValue
    extends StatelessWidget {
  const _RouteValue({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 19,
        ),
        const SizedBox(
          width: 6,
        ),
        Text(
          value,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}