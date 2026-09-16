import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/route_result.dart';
import 'package:ecofuel/gas_station_list/service/route_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_marker.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_route_panel.dart';
import 'package:ecofuel/gas_station_list/widget/map/map_zoom.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_marker_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GasStationMap
    extends StatefulWidget {
  const GasStationMap({
    super.key,
    required this.stations,
    required this.fuel,
    required this.userCoordinates,
    required this.radius,
    required this.sortCriterion,
    this.routeService =
        const RouteService(),
  });

  final List<GasStation> stations;
  final FuelType fuel;
  final UserCoordinates userCoordinates;
  final SearchRadius radius;

  /// Critère sélectionné dans la barre :
  /// Prix ou Distance.
  final GasStationSortCriterion
      sortCriterion;

  final RouteService routeService;

  @override
  State<GasStationMap>
      createState() =>
          _GasStationMapState();
}

class _GasStationMapState
    extends State<GasStationMap> {
  final MapController _mapController =
      MapController();

  RouteResult? _route;

  GasStation? _routeDestination;

  bool _isLoadingRoute = false;

  String? _routeError;

  /// Position GPS de l'utilisateur.
  LatLng get _userPosition {
    return LatLng(
      widget.userCoordinates.latitude,
      widget.userCoordinates.longitude,
    );
  }

  /// Zoom adapté au rayon.
  double get _zoom {
    return MapZoom.forRadius(
      widget.radius,
    );
  }

  @override
  void didUpdateWidget(
    covariant GasStationMap oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    final bool radiusChanged =
        oldWidget.radius !=
        widget.radius;

    final bool positionChanged =
        oldWidget.userCoordinates.latitude !=
                widget
                    .userCoordinates
                    .latitude ||
            oldWidget
                    .userCoordinates
                    .longitude !=
                widget
                    .userCoordinates
                    .longitude;

    // Lors d'un changement de rayon ou de position,
    // on supprime l'itinéraire précédent.
    if (radiusChanged ||
        positionChanged) {
      _route = null;
      _routeDestination = null;

      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          _centerMap();
        },
      );
    }
  }

  /// Recentre la carte.
  void _centerMap() {
    _mapController.move(
      _userPosition,
      _zoom,
    );
  }

  /// Calcule la route vers la station sélectionnée.
  Future<void> _showRoute(
    GasStation station,
  ) async {
    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
      _routeDestination = station;
    });

    try {
      final RouteResult route =
          await widget.routeService
              .fetchRoute(
        start:
            widget.userCoordinates,
        destinationLatitude:
            station.latitude,
        destinationLongitude:
            station.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _route = route;
        _isLoadingRoute = false;
      });

      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          _fitRoute(route);
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _route = null;
        _isLoadingRoute = false;
        _routeError = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  /// Ajuste automatiquement la caméra
  /// pour afficher toute la route.
  void _fitRoute(
    RouteResult route,
  ) {
    if (route.points.isEmpty) {
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds:
            LatLngBounds.fromPoints(
          route.points,
        ),
        padding:
            const EdgeInsets.all(
          65,
        ),
      ),
    );
  }

  /// Arrête l'itinéraire.
  void _stopRoute() {
    setState(() {
      _route = null;
      _routeDestination = null;
      _routeError = null;
    });

    _centerMap();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    // Seulement les stations :
    // - possédant des coordonnées ;
    // - proposant le carburant sélectionné.
    final List<GasStation>
        visibleStations =
        widget.stations
            .where(
              (station) =>
                  station.latitude != 0 &&
                  station.longitude != 0 &&
                  station.priceFor(
                        widget.fuel,
                      ) !=
                      null,
            )
            .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController:
              _mapController,
          options: MapOptions(
            initialCenter:
                _userPosition,
            initialZoom:
                _zoom,
          ),
          children: [
            // =============================
            // CARTE OPENSTREETMAP
            // =============================
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/'
                  '{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.example.ecofuel',
            ),

            // =============================
            // RAYON DE RECHERCHE
            // =============================
            if (_route == null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point:
                        _userPosition,
                    radius:
                        widget.radius.inKm *
                            1000,
                    useRadiusInMeter:
                        true,
                    color:
                        Colors.blue
                            .withValues(
                      alpha: 0.06,
                    ),
                    borderColor:
                        Colors.blue
                            .withValues(
                      alpha: 0.55,
                    ),
                    borderStrokeWidth:
                        2,
                  ),
                ],
              ),

            // =============================
            // ROUTE
            // =============================
            if (_route != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points:
                        _route!.points,
                    strokeWidth: 6,
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primary,
                  ),
                ],
              ),

            // =============================
            // STATIONS + UTILISATEUR
            // =============================
            MarkerLayer(
              markers: [
                _buildUserMarker(),

                ...visibleStations.map(
                  (station) {
                    // La couleur est calculée
                    // en fonction du bouton
                    // Prix ou Distance.
                    final Color color =
                        StationMarkerColor
                            .forStation(
                      station:
                          station,
                      stations:
                          visibleStations,
                      fuel:
                          widget.fuel,
                      sortCriterion:
                          widget
                              .sortCriterion,
                    );

                    return buildGasStationMarker(
                      context: context,
                      station:
                          station,
                      fuel:
                          widget.fuel,
                      markerColor:
                          color,
                      onShowRoute: () {
                        _showRoute(
                          station,
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            RichAttributionWidget(
              attributions: const [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                ),
              ],
            ),
          ],
        ),

        // =============================
        // INDICATION DU CRITÈRE
        // =============================
        if (_route == null)
          Positioned(
            left: 12,
            top: 12,
            child:
                _CriterionLegend(
              criterion:
                  widget.sortCriterion,
            ),
          ),

        // =============================
        // CHARGEMENT ROUTE
        // =============================
        if (_isLoadingRoute)
          const Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Calcul de l’itinéraire...',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // =============================
        // PANNEAU ROUTE
        // =============================
        if (_route != null &&
            _routeDestination != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 15,
            child:
                GasStationRoutePanel(
              route:
                  _route!,
              station:
                  _routeDestination!,
              onStop:
                  _stopRoute,
            ),
          ),

        // =============================
        // ERREUR ROUTE
        // =============================
        if (_routeError != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 15,
            child:
                _buildRouteError(),
          ),

        // =============================
        // RECENTRER
        // =============================
        if (_route == null)
          Positioned(
            right: 16,
            bottom: 22,
            child:
                FloatingActionButton.small(
              heroTag:
                  'mapCenterButton',
              tooltip:
                  'Recentrer',
              onPressed:
                  _centerMap,
              child: const Icon(
                Icons.my_location,
              ),
            ),
          ),
      ],
    );
  }

  /// Message affiché si le calcul
  /// d'itinéraire échoue.
  Widget _buildRouteError() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          12,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                _routeError!,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _routeError = null;
                });
              },
              icon:
                  const Icon(
                Icons.close,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Position de l'utilisateur.
  Marker _buildUserMarker() {
    return Marker(
      point:
          _userPosition,
      width: 56,
      height: 56,
      child: Container(
        decoration:
            BoxDecoration(
          color:
              Colors.blue.withValues(
            alpha: 0.15,
          ),
          shape:
              BoxShape.circle,
          border: Border.all(
            color:
                Colors.blue,
            width:
                2,
          ),
        ),
        child:
            const Center(
          child: Icon(
            Icons.my_location,
            size: 28,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}

/// Indique à quoi correspondent les couleurs.
///
/// Le texte change automatiquement selon
/// Prix ou Distance.
class _CriterionLegend
    extends StatelessWidget {
  const _CriterionLegend({
    required this.criterion,
  });

  final GasStationSortCriterion
      criterion;

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool isPrice =
        criterion ==
            GasStationSortCriterion.price;

    return Container(
      padding:
          const EdgeInsets.all(
        9,
      ),
      decoration:
          BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surface,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color:
                Colors.black26,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            isPrice
                ? 'Prix'
                : 'Distance',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          _LegendLine(
            color:
                Colors.green,
            text: isPrice
                ? 'Moins cher'
                : 'Plus proche',
          ),
          const _LegendLine(
            color:
                Colors.orange,
            text:
                'Intermédiaire',
          ),
          _LegendLine(
            color:
                Colors.red,
            text: isPrice
                ? 'Plus cher'
                : 'Plus éloigné',
          ),
        ],
      ),
    );
  }
}

class _LegendLine
    extends StatelessWidget {
  const _LegendLine({
    required this.color,
    required this.text,
  });

  final Color color;
  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 1,
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration:
                BoxDecoration(
              color: color,
              shape:
                  BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            text,
            style:
                const TextStyle(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}