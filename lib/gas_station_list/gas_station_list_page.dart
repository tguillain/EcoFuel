import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_filter_bar.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map.dart';
import 'package:flutter/material.dart';

enum _DisplayMode {
  list,
  map,
}

class GasStationListPage
    extends StatefulWidget {
  const GasStationListPage({
    super.key,
    this.service =
        const GasStationService(),
  });

  final GasStationService service;

  @override
  State<GasStationListPage>
      createState() =>
          _GasStationListPageState();
}

class _GasStationListPageState
    extends State<GasStationListPage> {
  List<GasStation> _stations = [];

  UserCoordinates?
      _userCoordinates;

  FuelType _selectedFuel =
      FuelType.e10;

  SearchRadius _selectedRadius =
      SearchRadius.fiveKm;

  GasStationSortCriterion
      _sortCriterion =
      GasStationSortCriterion.price;

  _DisplayMode _displayMode =
      _DisplayMode.list;

  bool _isLoading = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadStations();
  }

  /// Charge la position puis les stations.
  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserCoordinates coordinates =
          await widget.service
              .currentCoordinates();

      final List<GasStation> stations =
          await widget.service
              .fetchNearbyStations(
        radius:
            _selectedRadius,
        coordinates:
            coordinates,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _userCoordinates =
            coordinates;

        _stations =
            stations;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _stations = [];

        _errorMessage = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading =
              false;
        });
      }
    }
  }

  /// Stations proposant le carburant sélectionné,
  /// triées selon Prix ou Distance.
  List<GasStation>
      get _visibleStations {
    final List<GasStation> stations =
        _stations
            .where(
              (station) =>
                  station.priceFor(
                    _selectedFuel,
                  ) !=
                  null,
            )
            .toList();

    stations.sort(
      _sortCriterion
          .comparatorFor(
        _selectedFuel,
      ),
    );

    return stations;
  }

  /// Changement du carburant.
  void _onFuelChanged(
    FuelType fuel,
  ) {
    setState(() {
      _selectedFuel =
          fuel;
    });
  }

  /// Changement Prix / Distance.
  ///
  /// Il n'est pas nécessaire de refaire
  /// un appel API.
  void _onSortChanged(
    GasStationSortCriterion
        criterion,
  ) {
    setState(() {
      _sortCriterion =
          criterion;
    });
  }

  /// Changement de rayon.
  ///
  /// Ici on recharge les stations car la zone
  /// de recherche est différente.
  Future<void> _onRadiusChanged(
    SearchRadius radius,
  ) async {
    if (radius ==
        _selectedRadius) {
      return;
    }

    setState(() {
      _selectedRadius =
          radius;
    });

    await _loadStations();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'EcoFuel',
        ),
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
        bottom:
            GasStationFilterBar(
          sortCriterion:
              _sortCriterion,
          selectedFuel:
              _selectedFuel,
          selectedRadius:
              _selectedRadius,
          onSortChanged:
              _onSortChanged,
          onFuelChanged:
              _onFuelChanged,
          onRadiusChanged:
              _onRadiusChanged,
        ),
      ),
      body:
          _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _MessageState(
        icon:
            Icons.error_outline,
        iconColor:
            Theme.of(context)
                .colorScheme
                .error,
        message:
            _errorMessage!,
        onRetry:
            _loadStations,
      );
    }

    final List<GasStation> stations =
        _visibleStations;

    if (stations.isEmpty) {
      return _MessageState(
        icon:
            Icons
                .local_gas_station_outlined,
        message:
            'Aucune station proposant du '
            '${_selectedFuel.label} '
            'dans un rayon de '
            '${_selectedRadius.label}.',
        onRetry:
            _loadStations,
      );
    }

    return Column(
      children: [
        _TopBar(
          stationCount:
              stations.length,
          fuel:
              _selectedFuel,
          radius:
              _selectedRadius,
          displayMode:
              _displayMode,
          onDisplayModeChanged:
              (mode) {
            setState(() {
              _displayMode =
                  mode;
            });
          },
        ),

        Expanded(
          child:
              _displayMode ==
                      _DisplayMode.list
                  ? _buildStationList(
                      stations,
                    )
                  : _buildMap(
                      stations,
                    ),
        ),
      ],
    );
  }

  /// Construit la carte.
  Widget _buildMap(
    List<GasStation> stations,
  ) {
    final UserCoordinates?
        coordinates =
        _userCoordinates;

    if (coordinates == null) {
      return const Center(
        child: Text(
          'Position utilisateur indisponible.',
        ),
      );
    }

    return GasStationMap(
      stations:
          stations,
      fuel:
          _selectedFuel,
      userCoordinates:
          coordinates,
      radius:
          _selectedRadius,

      // IMPORTANT :
      // la carte sait maintenant si
      // Prix ou Distance est sélectionné.
      sortCriterion:
          _sortCriterion,
    );
  }

  /// Construit la liste.
  Widget _buildStationList(
    List<GasStation> stations,
  ) {
    final String cheapestId =
        stations
            .reduce(
              (
                cheapest,
                station,
              ) =>
                  station
                              .priceFor(
                                _selectedFuel,
                              )! <
                          cheapest
                              .priceFor(
                                _selectedFuel,
                              )!
                      ? station
                      : cheapest,
            )
            .id;

    return ListView.builder(
      padding:
          const EdgeInsets.all(
        14,
      ),
      itemCount:
          stations.length,
      itemBuilder: (
        context,
        index,
      ) {
        final GasStation station =
            stations[index];

        final ValueKey<String> key =
            ValueKey<String>(
          station.id,
        );

        if (station.id ==
            cheapestId) {
          return GasStationCard
              .highlighted(
            station,
            fuel:
                _selectedFuel,
            key:
                key,
          );
        }

        return GasStationCard
            .standard(
          station,
          fuel:
              _selectedFuel,
          key:
              key,
        );
      },
    );
  }
}

class _TopBar
    extends StatelessWidget {
  const _TopBar({
    required this.stationCount,
    required this.fuel,
    required this.radius,
    required this.displayMode,
    required this.onDisplayModeChanged,
  });

  final int stationCount;
  final FuelType fuel;
  final SearchRadius radius;

  final _DisplayMode displayMode;

  final ValueChanged<_DisplayMode>
      onDisplayModeChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$stationCount '
                'station'
                '${stationCount > 1 ? 's' : ''}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${fuel.label}'
                ' • '
                '${radius.label}',
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                SegmentedButton<
                    _DisplayMode>(
              segments: const [
                ButtonSegment(
                  value:
                      _DisplayMode.list,
                  icon:
                      Icon(
                    Icons.list,
                  ),
                  label:
                      Text(
                    'Liste',
                  ),
                ),
                ButtonSegment(
                  value:
                      _DisplayMode.map,
                  icon:
                      Icon(
                    Icons.map_outlined,
                  ),
                  label:
                      Text(
                    'Carte',
                  ),
                ),
              ],
              selected: {
                displayMode,
              },
              onSelectionChanged:
                  (selection) {
                onDisplayModeChanged(
                  selection.first,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState
    extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.onRetry,
    this.iconColor,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  final Color? iconColor;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 55,
              color:
                  iconColor,
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              onPressed:
                  onRetry,
              icon:
                  const Icon(
                Icons.refresh,
              ),
              label:
                  const Text(
                'Réessayer',
              ),
            ),
          ],
        ),
      ),
    );
  }
}