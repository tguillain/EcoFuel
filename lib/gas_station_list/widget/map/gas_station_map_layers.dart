import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/route_result.dart';
import 'package:ecofuel/gas_station_list/widget/map/cluster_marker.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_marker.dart';
import 'package:ecofuel/gas_station_list/widget/map/map_station_selection.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_cluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Fond OpenStreetMap, itinéraire, utilisateur et stations.
///
/// Les stations trop proches à l'écran se regroupent en un rond ; le
/// regroupement suit le zoom, donc la vue en garde le niveau courant.
class GasStationMapLayers extends StatefulWidget {
  const GasStationMapLayers({
    super.key,
    required this.mapController,
    required this.userPosition,
    required this.initialZoom,
    required this.initialCameraFit,
    required this.markerEntries,
    required this.fuel,
    required this.onStationTap,
    this.route,
  });

  final MapController mapController;
  final LatLng userPosition;
  final double initialZoom;
  final CameraFit? initialCameraFit;
  final List<MapMarkerEntry> markerEntries;
  final FuelType fuel;
  final ValueChanged<GasStation> onStationTap;
  final RouteResult? route;

  @override
  State<GasStationMapLayers> createState() => _GasStationMapLayersState();
}

class _GasStationMapLayersState extends State<GasStationMapLayers> {
  /// Pas de zoom en deçà duquel les groupes ne sont pas recalculés : un
  /// pincement continu reconstruirait sinon la couche à chaque image.
  static const double _zoomStep = 0.5;

  late double _zoom = widget.initialZoom;

  void _onZoomChanged(double zoom) {
    final double stepped = (zoom / _zoomStep).floorToDouble() * _zoomStep;

    if (stepped == _zoom) {
      return;
    }

    // La carte signale ses mouvements pendant sa propre mise en page, où un
    // setState est interdit : la mise à jour attend l'image suivante.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _zoom = stepped);
      }
    });
  }

  /// Zoome sur les stations du groupe, qui se séparent alors.
  void _zoomInto(StationCluster cluster) {
    widget.mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          for (final station in cluster.stations)
            LatLng(station.latitude, station.longitude),
        ]),
        padding: const EdgeInsets.all(80),
        maxZoom: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RouteResult? route = widget.route;
    final List<StationCluster> clusters = StationClusterer.cluster(
      widget.markerEntries,
      zoom: _zoom,
    );

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.userPosition,
        initialZoom: widget.initialZoom,
        initialCameraFit: widget.initialCameraFit,
        onMapReady: () => _onZoomChanged(widget.mapController.camera.zoom),
        onPositionChanged: (camera, _) => _onZoomChanged(camera.zoom),
      ),
      children: [
        // =============================
        // CARTE OPENSTREETMAP
        // =============================
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/'
              '{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecofuel',
        ),

        // =============================
        // ROUTE
        // =============================
        if (route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.points,
                strokeWidth: 6,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),

        // =============================
        // STATIONS + UTILISATEUR
        // =============================
        MarkerLayer(
          markers: [
            _buildUserMarker(),

            // Dessinés dans l'ordre reçu, les meilleurs prix en dernier donc
            // au-dessus des autres.
            for (final cluster in clusters.reversed)
              cluster.isSingle
                  ? buildGasStationMarker(
                      context: context,
                      station: cluster.best.station,
                      fuel: widget.fuel,
                      markerColor: cluster.best.color,
                      onTap: () => widget.onStationTap(cluster.best.station),
                    )
                  : buildClusterMarker(
                      cluster: cluster,
                      fuel: widget.fuel,
                      onTap: () => _zoomInto(cluster),
                    ),
          ],
        ),

        RichAttributionWidget(
          attributions: const [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  /// Position de l'utilisateur.
  Marker _buildUserMarker() {
    return Marker(
      point: widget.userPosition,
      width: 56,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.my_location, size: 28, color: Colors.blue),
        ),
      ),
    );
  }
}
