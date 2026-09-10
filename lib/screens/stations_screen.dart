import 'package:flutter/material.dart';

import '../models/station.dart';
import '../services/api_service.dart';
import '../widgets/filters_bar.dart';
import '../widgets/station_card.dart';

class StationsScreen
    extends StatefulWidget {
  const StationsScreen({
    super.key,
  });

  @override
  State<StationsScreen>
      createState() =>
          _StationsScreenState();
}

class _StationsScreenState
    extends State<StationsScreen> {
  List<Station> _stations = [];

  bool _isLoading = false;

  String? _errorMessage;

  String _carburant = 'E10';

  int _rayon = 5;

  String _tri = 'prix';

  @override
  void initState() {
    super.initState();

    _loadStations();
  }

  Future<void>
      _loadStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Station>
          stations =
          await ApiService
              .fetchNearbyStations(
        rayonKm: _rayon,
      );

      final List<Station>
          filtered =
          stations.where(
        (Station station) {
          return station.getPrix(
                _carburant,
              ) !=
              null;
        },
      ).toList();

      _sortStations(
        filtered,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stations = filtered;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _stations = [];

        _errorMessage =
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sortStations(
    List<Station> stations,
  ) {
    if (_tri == 'prix') {
      stations.sort(
        (
          Station a,
          Station b,
        ) {
          final double prixA =
              a.getPrix(
                    _carburant,
                  ) ??
                  double.infinity;

          final double prixB =
              b.getPrix(
                    _carburant,
                  ) ??
                  double.infinity;

          return prixA.compareTo(
            prixB,
          );
        },
      );
    } else {
      stations.sort(
        (
          Station a,
          Station b,
        ) {
          return a.distanceKm
              .compareTo(
            b.distanceKm,
          );
        },
      );
    }
  }

  Future<void>
      _changeCarburant(
    String carburant,
  ) async {
    setState(() {
      _carburant = carburant;
    });

    await _loadStations();
  }

  Future<void> _changeRayon(
    int rayon,
  ) async {
    setState(() {
      _rayon = rayon;
    });

    await _loadStations();
  }

  void _changeTri(
    String tri,
  ) {
    setState(() {
      _tri = tri;

      _sortStations(
        _stations,
      );
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              Icons.local_gas_station,
            ),

            SizedBox(
              width: 8,
            ),

            Text(
              'EcoFuel',
            ),
          ],
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip:
                'Actualiser',

            icon:
                const Icon(
              Icons.refresh,
            ),

            onPressed:
                _isLoading
                    ? null
                    : _loadStations,
          ),
        ],
      ),

      body: Column(
        children: [
          FiltersBar(
            carburant:
                _carburant,

            rayon:
                _rayon,

            tri:
                _tri,

            onCarburantChanged:
                _changeCarburant,

            onRayonChanged:
                _changeRayon,

            onTriChanged:
                _changeTri,
          ),

          Expanded(
            child:
                _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,

            children: [
              const Icon(
                Icons.error_outline,
                size: 55,
                color: Colors.red,
              ),

              const SizedBox(
                height: 15,
              ),

              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 20,
              ),

              ElevatedButton.icon(
                onPressed:
                    _loadStations,

                icon: const Icon(
                  Icons.refresh,
                ),

                label: const Text(
                  'Réessayer',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_stations.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,

            children: [
              const Icon(
                Icons
                    .local_gas_station_outlined,
                size: 60,
              ),

              const SizedBox(
                height: 15,
              ),

              Text(
                'Aucune station proposant '
                '$_carburant trouvée dans '
                'un rayon de $_rayon km.',

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 18,
            vertical: 8,
          ),

          child: Row(
            children: [
              Text(
                '${_stations.length} '
                'station'
                '${_stations.length > 1 ? 's' : ''}',

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const Spacer(),

              Text(
                '$_carburant • $_rayon km',
              ),
            ],
          ),
        ),

        Expanded(
          child:
              ListView.builder(
            itemCount:
                _stations.length,

            itemBuilder:
                (
              BuildContext context,
              int index,
            ) {
              return StationCard(
                station:
                    _stations[index],

                carburant:
                    _carburant,
              );
            },
          ),
        ),
      ],
    );
  }
}