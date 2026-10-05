import 'dart:math' as math;

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
import 'package:flutter/foundation.dart';
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
    this.searchCenter,
    this.onFavoritesTap,
    this.routeService = const RouteService(),
    this.coveredInsets = const AlwaysStoppedAnimation(EdgeInsets.zero),
    this.framingInsets = EdgeInsets.zero,
  });

  final List<GasStation> stations;
  final FuelType fuel;
  final UserCoordinates userCoordinates;
  final SearchRadius radius;

  /// Lieu cherché à la place de la position de l'utilisateur : la carte se
  /// cadre sur lui, le repère de l'utilisateur restant à sa place.
  final UserCoordinates? searchCenter;

  /// Ouvre l'écran des favoris, depuis le bouton à gauche du recentrage.
  final VoidCallback? onFavoritesTap;

  /// Donne à la fiche d'une station la durée du trajet.
  final RouteService routeService;

  /// Bords de la carte masqués en ce moment par l'interface posée dessus :
  /// en-tête en haut, feuille des stations en bas. Les commandes de la carte
  /// les suivent, jusque pendant le glisser de la feuille.
  final ValueListenable<EdgeInsets> coveredInsets;

  /// Bords masqués quand la carte est au repos, feuille repliée. Le cadrage
  /// des stations s'y tient, plutôt qu'aux [coveredInsets] du moment : la
  /// carte se recadre aussi pendant que la liste la recouvre, pour le jour où
  /// on la retrouve.
  final EdgeInsets framingInsets;

  @override
  State<GasStationMap> createState() => _GasStationMapState();
}

class _GasStationMapState extends State<GasStationMap> {
  final MapController _mapController = MapController();

  /// En deçà de ce seuil, un déplacement relève de la dérive du GPS. Recadrer
  /// la carte à chaque rafraîchissement automatique la rendrait inutilisable.
  static const double _significantMoveInMetres = 200;

  /// Hauteur minimale de la bande où cadrer les stations. Une interface qui
  /// ne laisse qu'un liseré de carte arrête le cadrage plutôt que de
  /// demander une marge plus grande que la carte.
  static const double _minFramedHeight = 120;

  static const double _framePadding = 55;

  /// Hauteur de la carte au dernier rendu.
  double _height = 0;

  /// Position GPS de l'utilisateur.
  LatLng get _userPosition =>
      LatLng(widget.userCoordinates.latitude, widget.userCoordinates.longitude);

  /// Centre de la recherche : le lieu cherché, sinon l'utilisateur.
  UserCoordinates get _center => widget.searchCenter ?? widget.userCoordinates;

  LatLng get _centerPosition => LatLng(_center.latitude, _center.longitude);

  /// Zoom de repli, utilisé tant qu'aucune station n'est affichée.
  double get _zoom => MapZoom.forRadius(widget.radius);

  MapStationSelection get _selection => MapStationSelection(
    stations: widget.stations,
    fuel: widget.fuel,
    limit: widget.radius.mapStationLimit,
  );

  /// Marges de cadrage : une marge fixe tout autour, plus ce que l'interface
  /// masque en haut et en bas au repos.
  EdgeInsets get _framingPadding {
    const double padding = _framePadding;
    final EdgeInsets covered = widget.framingInsets;

    final double top = math.min(
      covered.top,
      math.max(0, _height - 2 * padding - _minFramedHeight),
    );

    final double bottom = math.min(
      covered.bottom,
      math.max(0, _height - top - 2 * padding - _minFramedHeight),
    );

    return EdgeInsets.fromLTRB(
      padding,
      padding + top,
      padding,
      padding + bottom,
    );
  }

  /// Cadrage englobant le centre de la recherche et ses stations.
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
        _centerPosition,
        ...stations.map(
          (station) => LatLng(station.latitude, station.longitude),
        ),
      ]),
      padding: _framingPadding,
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
      oldWidget.searchCenter ?? oldWidget.userCoordinates,
      _center,
    );

    final bool fuelChanged = oldWidget.fuel != widget.fuel;

    // La feuille repliée prend la hauteur de ses cartes une fois celles-ci
    // mesurées : la place libre a changé.
    final bool framingChanged = oldWidget.framingInsets != widget.framingInsets;

    // Le cadrage suit les stations affichées : changer de carburant change la
    // liste, donc l'étendue à montrer.
    if (radiusChanged || positionChanged || fuelChanged || framingChanged) {
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

  /// Recadre la carte sur le centre de la recherche et ses stations.
  void _centerMap() {
    final CameraFit? fit = _stationsFit;

    if (fit == null) {
      _mapController.move(_centerPosition, _zoom);

      return;
    }

    _mapController.fitCamera(fit);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _height = constraints.maxHeight;

        return Stack(
          children: [
            GasStationMapLayers(
              mapController: _mapController,
              userPosition: _userPosition,
              initialZoom: _zoom,
              initialCameraFit: _stationsFit,
              markerEntries: _selection.markerEntries,
              fuel: widget.fuel,
              coveredInsets: widget.coveredInsets,
              onStationTap: _openDetail,
            ),

            // Les commandes suivent la feuille sans reconstruire la carte
            // entière à chaque image du glisser.
            Positioned.fill(
              child: ValueListenableBuilder<EdgeInsets>(
                valueListenable: widget.coveredInsets,
                builder: (context, insets, child) =>
                    Padding(padding: insets, child: child),
                child: GasStationMapOverlays(
                  onRecenter: _centerMap,
                  onFavoritesTap: widget.onFavoritesTap,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
