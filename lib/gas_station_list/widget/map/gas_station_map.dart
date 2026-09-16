import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
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
    this.routeService =
        const RouteService(),
  });

  final List<GasStation> stations;
  final FuelType fuel;
  final UserCoordinates userCoordinates;
  final SearchRadius radius;

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

  /// En deçà de ce seuil, un déplacement relève de la dérive
  /// du GPS. Recadrer la carte ou effacer l'itinéraire à chaque
  /// rafraîchissement automatique la rendrait inutilisable.
  static const double
      _significantMoveInMetres = 200;

  /// Position GPS de l'utilisateur.
  LatLng get _userPosition {
    return LatLng(
      widget.userCoordinates.latitude,
      widget.userCoordinates.longitude,
    );
  }

  /// Zoom de repli, utilisé tant qu'aucune
  /// station n'est affichée.
  double get _zoom {
    return MapZoom.forRadius(
      widget.radius,
    );
  }

  /// Stations affichables : celles qui ont des
  /// coordonnées et un prix pour le carburant choisi.
  List<GasStation> get _visibleStations {
    return widget.stations
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
  }

  /// Cadrage englobant l'utilisateur et ses stations.
  ///
  /// Remplace le cercle de rayon : la zone couverte se lit
  /// dans ce que la carte montre, sans poser un disque
  /// bleu par-dessus les rues.
  CameraFit? get _stationsFit {
    final List<GasStation> stations =
        _visibleStations;

    if (stations.isEmpty) {
      return null;
    }

    return CameraFit.bounds(
      bounds:
          LatLngBounds.fromPoints([
        _userPosition,
        ...stations.map(
          (station) => LatLng(
            station.latitude,
            station.longitude,
          ),
        ),
      ]),
      padding:
          const EdgeInsets.all(
        55,
      ),
      maxZoom: 15,
    );
  }

  /// Stations et leur couleur, triées du gris vers le vert.
  ///
  /// L'ordre de la liste est l'ordre de dessin : les
  /// meilleurs prix passent ainsi au-dessus des autres.
  List<({GasStation station, StationMarkerColor color})>
      _markerEntries() {
    final List<GasStation> stations =
        _visibleStations;

    final List<({GasStation station, StationMarkerColor color})>
        entries = stations
            .map(
              (station) => (
                station: station,
                color:
                    StationMarkerColor.forStation(
                  station: station,
                  stations: stations,
                  fuel: widget.fuel,
                ),
              ),
            )
            .toList();

    entries.sort(
      (a, b) => b.color.index.compareTo(
        a.color.index,
      ),
    );

    return entries;
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
        _hasMovedSignificantly(
      oldWidget.userCoordinates,
      widget.userCoordinates,
    );

    final bool fuelChanged =
        oldWidget.fuel != widget.fuel;

    // Lors d'un changement de rayon ou de position,
    // on supprime l'itinéraire précédent.
    if (radiusChanged ||
        positionChanged) {
      _route = null;
      _routeDestination = null;
    }

    // Le cadrage suit les stations affichées : changer
    // de carburant change la liste, donc l'étendue à
    // montrer. Un itinéraire en cours garde sa vue.
    if ((radiusChanged ||
            positionChanged ||
            fuelChanged) &&
        _route == null) {
      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          _centerMap();
        },
      );
    }
  }

  /// Vrai si l'utilisateur s'est vraiment déplacé, par
  /// opposition au tremblement de quelques mètres que renvoie
  /// un GPS immobile.
  bool _hasMovedSignificantly(
    UserCoordinates from,
    UserCoordinates to,
  ) {
    final double metres =
        const Distance().as(
      LengthUnit.Meter,
      LatLng(
        from.latitude,
        from.longitude,
      ),
      LatLng(
        to.latitude,
        to.longitude,
      ),
    );

    return metres >=
        _significantMoveInMetres;
  }

  /// Recadre la carte sur l'utilisateur et ses stations.
  void _centerMap() {
    final CameraFit? fit =
        _stationsFit;

    if (fit == null) {
      _mapController.move(
        _userPosition,
        _zoom,
      );

      return;
    }

    _mapController.fitCamera(
      fit,
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
    final List<({GasStation station, StationMarkerColor color})>
        markerEntries =
        _markerEntries();

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
            initialCameraFit:
                _stationsFit,
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

                ...markerEntries.map(
                  (entry) {
                    return buildGasStationMarker(
                      context: context,
                      station:
                          entry.station,
                      fuel:
                          widget.fuel,
                      markerColor:
                          entry.color,
                      onShowRoute: () {
                        _showRoute(
                          entry.station,
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
        // LÉGENDE DES COULEURS
        // =============================
        if (_route == null)
          Positioned(
            left: 12,
            top: 12,
            child:
                _PriceLegend(
              fuel: widget.fuel,
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

/// Rappelle ce que signale la couleur d'un marqueur.
///
/// Seules les stations au bon prix sont colorées, la
/// légende n'a donc que deux niveaux à expliquer.
class _PriceLegend
    extends StatelessWidget {
  const _PriceLegend({
    required this.fuel,
  });

  final FuelType fuel;

  @override
  Widget build(
    BuildContext context,
  ) {
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
            'Prix ${fuel.label}',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          const _LegendLine(
            color:
                StationMarkerColor.best,
            text:
                'Meilleur prix',
          ),
          const _LegendLine(
            color:
                StationMarkerColor.cheap,
            text:
                'À 3 centimes près',
          ),
          const _LegendLine(
            color:
                StationMarkerColor.regular,
            text:
                'Au-dessus',
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

  final StationMarkerColor color;
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
              color: color.color,
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