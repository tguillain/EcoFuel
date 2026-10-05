import 'package:ecofuel/gas_station_detail/gas_station_detail_page.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
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
  });

  final List<GasStation> stations;
  final FuelType fuel;
  final UserCoordinates userCoordinates;
  final SearchRadius radius;

  /// Donne à la fiche d'une station la durée du trajet.
  final RouteService routeService;

  @override
  State<GasStationMap> createState() => _GasStationMapState();
}

class _GasStationMapState extends State<GasStationMap> {
  final MapController _mapController = MapController();

  /// En deçà de ce seuil, un déplacement relève de la dérive du GPS. Recadrer
  /// la carte à chaque rafraîchissement automatique la rendrait inutilisable.
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

  /// Ouvre la fiche de la station, d'où part l'itinéraire Google Maps.
  void _openDetail(GasStation station) {
    GasStationDetailPage.open(
      context,
      station: station,
      fuel: widget.fuel,
      radius: widget.radius,
      userCoordinates: widget.userCoordinates,
      isCheapest: station.id == _selection.cheapest?.id,
      routeService: widget.routeService,
    );
  }

  @override
  void didUpdateWidget(covariant GasStationMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool radiusChanged = oldWidget.radius != widget.radius;

    final bool positionChanged = _hasMovedSignificantly(
      oldWidget.userCoordinates,
      widget.userCoordinates,
    );

    final bool fuelChanged = oldWidget.fuel != widget.fuel;

    // Le cadrage suit les stations affichées : changer de carburant change la
    // liste, donc l'étendue à montrer.
    if (radiusChanged || positionChanged || fuelChanged) {
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
          onStationTap: _openDetail,
        ),

        Positioned.fill(
          child: GasStationMapOverlays(
            fuel: widget.fuel,
            stationLimit: widget.radius.mapStationLimit,
            onRecenter: _centerMap,
          ),
        ),
      ],
    );
  }
}
