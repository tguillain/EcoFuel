import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/route_result.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_route_panel.dart';
import 'package:ecofuel/gas_station_list/widget/map/map_price_legend.dart';
import 'package:ecofuel/gas_station_list/widget/map/route_status_cards.dart';
import 'package:flutter/material.dart';

/// Commandes et panneaux posés sur la carte : légende, état de l'itinéraire
/// et bouton de recentrage.
///
/// Seuls ses enfants captent les gestes : le reste de la surface laisse passer
/// glissements et zooms jusqu'à la carte.
class GasStationMapOverlays extends StatelessWidget {
  const GasStationMapOverlays({
    super.key,
    required this.fuel,
    required this.stationLimit,
    required this.isLoadingRoute,
    required this.onStopRoute,
    required this.onDismissRouteError,
    required this.onRecenter,
    this.route,
    this.routeDestination,
    this.routeError,
  });

  final FuelType fuel;
  final int stationLimit;
  final bool isLoadingRoute;
  final VoidCallback onStopRoute;
  final VoidCallback onDismissRouteError;
  final VoidCallback onRecenter;
  final RouteResult? route;
  final GasStation? routeDestination;
  final String? routeError;

  @override
  Widget build(BuildContext context) {
    final RouteResult? route = this.route;
    final GasStation? routeDestination = this.routeDestination;
    final String? routeError = this.routeError;

    return Stack(
      children: [
        // =============================
        // LÉGENDE DES COULEURS
        // =============================
        if (route == null)
          Positioned(
            left: 12,
            top: 12,
            child: MapPriceLegend(fuel: fuel, count: stationLimit),
          ),

        // =============================
        // CHARGEMENT ROUTE
        // =============================
        if (isLoadingRoute)
          const Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(child: RouteLoadingCard()),
          ),

        // =============================
        // PANNEAU ROUTE
        // =============================
        if (route != null && routeDestination != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 15,
            child: GasStationRoutePanel(
              route: route,
              station: routeDestination,
              onStop: onStopRoute,
            ),
          ),

        // =============================
        // ERREUR ROUTE
        // =============================
        if (routeError != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 15,
            child: RouteErrorCard(
              message: routeError,
              onDismiss: onDismissRouteError,
            ),
          ),

        // =============================
        // RECENTRER
        // =============================
        if (route == null)
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
