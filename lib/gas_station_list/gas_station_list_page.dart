import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_filter_bar.dart';
import 'package:flutter/material.dart';

class GasStationListPage extends StatefulWidget {
  const GasStationListPage({
    super.key,
    this.service = const GasStationService(),
  });

  final GasStationService service;

  @override
  State<GasStationListPage> createState() => _GasStationListPageState();
}

class _GasStationListPageState extends State<GasStationListPage> {
  /// Stations telles que renvoyées par l'API : le filtre carburant et le tri
  /// sont appliqués à l'affichage, seul un changement de rayon relance l'appel.
  List<GasStation> _stations = [];

  FuelType _selectedFuel = FuelType.e10;
  SearchRadius _selectedRadius = SearchRadius.fiveKm;
  GasStationSortCriterion _sortCriterion = GasStationSortCriterion.price;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stations = await widget.service.fetchNearbyStations(
        radius: _selectedRadius,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stations = stations;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _stations = [];
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<GasStation> get _visibleStations {
    final stations = _stations
        .where((station) => station.priceFor(_selectedFuel) != null)
        .toList();

    stations.sort(_sortCriterion.comparatorFor(_selectedFuel));

    return stations;
  }

  void _onFuelChanged(FuelType fuel) {
    setState(() {
      _selectedFuel = fuel;
    });
  }

  void _onSortChanged(GasStationSortCriterion criterion) {
    setState(() {
      _sortCriterion = criterion;
    });
  }

  Future<void> _onRadiusChanged(SearchRadius radius) async {
    if (radius == _selectedRadius) {
      return;
    }

    setState(() {
      _selectedRadius = radius;
    });

    await _loadStations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoFuel'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStations,
          ),
        ],
        bottom: GasStationFilterBar(
          sortCriterion: _sortCriterion,
          selectedFuel: _selectedFuel,
          selectedRadius: _selectedRadius,
          onSortChanged: _onSortChanged,
          onFuelChanged: _onFuelChanged,
          onRadiusChanged: _onRadiusChanged,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _MessageState(
        icon: Icons.error_outline,
        iconColor: Theme.of(context).colorScheme.error,
        message: _errorMessage!,
        onRetry: _loadStations,
      );
    }

    final stations = _visibleStations;

    if (stations.isEmpty) {
      return _MessageState(
        icon: Icons.local_gas_station_outlined,
        message:
            'Aucune station proposant du ${_selectedFuel.label} '
            'dans un rayon de ${_selectedRadius.label}.',
        onRetry: _loadStations,
      );
    }

    return _buildStationList(stations);
  }

  Widget _buildStationList(List<GasStation> stations) {
    final cheapestId = stations
        .reduce(
          (cheapest, station) =>
              station.priceFor(_selectedFuel)! <
                  cheapest.priceFor(_selectedFuel)!
              ? station
              : cheapest,
        )
        .id;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Row(
            children: [
              Text(
                '${stations.length} station${stations.length > 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('${_selectedFuel.label} • ${_selectedRadius.label}'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              final key = ValueKey(station.id);

              if (station.id == cheapestId) {
                return GasStationCard.highlighted(
                  station,
                  fuel: _selectedFuel,
                  key: key,
                );
              }

              return GasStationCard.standard(
                station,
                fuel: _selectedFuel,
                key: key,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 55, color: iconColor),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
