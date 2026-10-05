import 'package:ecofuel/gas_station_detail/gas_station_detail_page.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/route_result.dart';
import 'package:ecofuel/gas_station_list/service/route_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map_layers.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map_overlays.dart';
import 'package:ecofuel/gas_station_list/widget/map/map_station_selection.dart';
import 'package:ecofuel/gas_station_list/widget/map/map_zoom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GasStationMap extends StatefulWidget {
  const GasStationMap({
    super.key,
    required this.stations,
    required this.fuel,
    required this.userCoordinates,
    required this.radius,
    this.routeService = const RouteService(),
    this.routeDestination,
    this.onRouteRequestHandled,
  });

  final List<GasStation> stations;
  final FuelType fuel;
  final UserCoordinates userCoordinates;
  final SearchRadius radius;

  final RouteService routeService;

  /// Station vers laquelle tracer l'itinéraire dès l'affichage, quand il a été
  /// demandé depuis une fiche ouverte par la liste.
  final GasStation? routeDestination;

  /// Prévient l'appelant que [routeDestination] est pris en compte, pour qu'il
  /// ne la redemande pas à chaque reconstruction.
  final VoidCallback? onRouteRequestHandled;

  @override
  State<GasStationMap> createState() => _GasStationMapState();
}

class _GasStationMapState extends State<GasStationMap> {
  final MapController _mapController = MapController();

  RouteResult? _route;

  GasStation? _routeDestination;

  bool _isLoadingRoute = false;

  String? _routeError;

  /// En deçà de ce seuil, un déplacement relève de la dérive du GPS. Recadrer
  /// la carte ou effacer l'itinéraire à chaque rafraîchissement automatique
  /// la rendrait inutilisable.
  static const double _significantMoveInMetres = 200;

  /// Position GPS de l'utilisateur.
  LatLng get _userPosition =>
      LatLng(widget.userCoordinates.latitude, widget.userCoordinates.longitude);

  /// Zoom de repli, utilisé tant qu'aucune station n'est affichée.
  double get _zoom => MapZoom.forRadius(widget.radius);

  MapStationSelection get _selection => MapStationSelection(
    stations: widget.stations,
    fuel: widget.fuel,
    limit: widget.radius.mapStationLimit,
    routeDestination: _routeDestination,
  );

  /// Cadrage englobant l'utilisateur et ses stations.
  ///
  /// Remplace le cercle de rayon : la zone couverte se lit dans ce que la carte
  /// montre, sans poser un disque bleu par-dessus les rues.
  CameraFit? get _stationsFit {
    final List<GasStation> stations = _selection.visible;

    if (stations.isEmpty) {
      return null;
    }

    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints([
        _userPosition,
        ...stations.map(
          (station) => LatLng(station.latitude, station.longitude),
        ),
      ]),
      padding: const EdgeInsets.all(55),
      maxZoom: 15,
    );
  }

  @override
  void initState() {
    super.initState();

    _handleRouteRequest();
  }

  /// Trace l'itinéraire demandé par l'appelant, une seule fois.
  void _handleRouteRequest() {
    final GasStation? destination = widget.routeDestination;

    if (destination == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      widget.onRouteRequestHandled?.call();

      _showRoute(destination);
    });
  }

  /// Ouvre la fiche de la station, puis trace l'itinéraire si elle le demande.
  Future<void> _openDetail(GasStation station) async {
    final bool wantsRoute = await GasStationDetailPage.open(
      context,
      station: station,
      fuel: widget.fuel,
      radius: widget.radius,
      userCoordinates: widget.userCoordinates,
      isCheapest: station.id == _selection.cheapest?.id,
      routeService: widget.routeService,
    );

    if (wantsRoute && mounted) {
      await _showRoute(station);
    }
  }

  @override
  void didUpdateWidget(covariant GasStationMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.routeDestination != oldWidget.routeDestination) {
      _handleRouteRequest();
    }

    final bool radiusChanged = oldWidget.radius != widget.radius;

    final bool positionChanged = _hasMovedSignificantly(
      oldWidget.userCoordinates,
      widget.userCoordinates,
    );

    final bool fuelChanged = oldWidget.fuel != widget.fuel;

    // Lors d'un changement de rayon ou de position, on supprime l'itinéraire.
    if (radiusChanged || positionChanged) {
      _route = null;
      _routeDestination = null;
    }

    // Le cadrage suit les stations affichées : changer de carburant change la
    // liste, donc l'étendue à montrer. Un itinéraire en cours garde sa vue.
    if ((radiusChanged || positionChanged || fuelChanged) && _route == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMap();
      });
    }
  }

  /// Vrai si l'utilisateur s'est vraiment déplacé, par opposition au
  /// tremblement de quelques mètres que renvoie un GPS immobile.
  bool _hasMovedSignificantly(UserCoordinates from, UserCoordinates to) {
    final double metres = const Distance().as(
      LengthUnit.Meter,
      LatLng(from.latitude, from.longitude),
      LatLng(to.latitude, to.longitude),
    );

    return metres >= _significantMoveInMetres;
  }

  /// Recadre la carte sur l'utilisateur et ses stations.
  void _centerMap() {
    final CameraFit? fit = _stationsFit;

    if (fit == null) {
      _mapController.move(_userPosition, _zoom);

      return;
    }

    _mapController.fitCamera(fit);
  }

  /// Calcule la route vers la station sélectionnée.
  Future<void> _showRoute(GasStation station) async {
    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
      _routeDestination = station;
    });

    try {
      final RouteResult route = await widget.routeService.fetchRoute(
        start: widget.userCoordinates,
        destinationLatitude: station.latitude,
        destinationLongitude: station.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _route = route;
        _isLoadingRoute = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitRoute(route);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _route = null;
        _isLoadingRoute = false;
        _routeError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Ajuste automatiquement la caméra pour afficher toute la route.
  void _fitRoute(RouteResult route) {
    if (route.points.isEmpty) {
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(route.points),
        padding: const EdgeInsets.all(65),
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GasStationMapLayers(
          mapController: _mapController,
          userPosition: _userPosition,
          initialZoom: _zoom,
          initialCameraFit: _stationsFit,
          markerEntries: _selection.markerEntries,
          fuel: widget.fuel,
          route: _route,
          onStationTap: _openDetail,
        ),

        Positioned.fill(
          child: GasStationMapOverlays(
            fuel: widget.fuel,
            stationLimit: widget.radius.mapStationLimit,
            route: _route,
            routeDestination: _routeDestination,
            isLoadingRoute: _isLoadingRoute,
            routeError: _routeError,
            onStopRoute: _stopRoute,
            onDismissRouteError: () => setState(() => _routeError = null),
            onRecenter: _centerMap,
          ),
        ),
      ],
    );
  }
}
