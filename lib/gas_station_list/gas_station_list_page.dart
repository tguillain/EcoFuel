import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_filter_bar.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_list_header.dart';
import 'package:ecofuel/theme/app_colors.dart';
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
  /// Métriques de l'artboard « Liste seule · cartes + filtres » : le panneau
  /// d'en-tête est blanc sur le fond de l'écran, la liste respire davantage.
  static const EdgeInsets _panelPadding = EdgeInsets.fromLTRB(20, 18, 20, 14);
  static const EdgeInsets _listPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );
  static const double _panelGap = 14;

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

  String get _headerTitle {
    if (_isLoading) {
      return 'Recherche…';
    }

    final count = _visibleStations.length;

    return '$count station${count > 1 ? 's' : ''}';
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
      body: SafeArea(
        child: _errorMessage != null
            ? _MessageState(
                icon: Icons.error_outline,
                iconColor: Theme.of(context).colorScheme.error,
                message: _errorMessage!,
                onRetry: _loadStations,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: _panelPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: _panelGap,
                      children: [
                        GasStationListHeader(
                          title: _headerTitle,
                          selectedRadius: _selectedRadius,
                          onRadiusChanged: _onRadiusChanged,
                        ),
                        GasStationFilterBar(
                          sortCriterion: _sortCriterion,
                          selectedFuel: _selectedFuel,
                          onSortChanged: _onSortChanged,
                          onFuelChanged: _onFuelChanged,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildList()),
                ],
              ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stations = _visibleStations;

    // Le tiré-pour-rafraîchir remplace le bouton Actualiser de l'ancienne
    // AppBar : il doit rester atteignable même sans station à faire défiler.
    return RefreshIndicator(
      onRefresh: _loadStations,
      child: stations.isEmpty
          ? _MessageState(
              icon: Icons.local_gas_station_outlined,
              message:
                  'Aucune station proposant du ${_selectedFuel.label} '
                  'dans un rayon de ${_selectedRadius.label}.',
              onRetry: _loadStations,
              isScrollable: true,
            )
          : _buildStationList(stations),
    );
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

    return ListView.builder(
      padding: _listPadding,
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

        return GasStationCard.standard(station, fuel: _selectedFuel, key: key);
      },
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.onRetry,
    this.iconColor,
    this.isScrollable = false,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  final Color? iconColor;

  /// Un `RefreshIndicator` n'arme son geste que sur un enfant défilable :
  /// l'état vide doit donc défiler, même quand son contenu tient à l'écran.
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 55, color: iconColor ?? AppColors.onSurfaceMuted),
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
    );

    if (!isScrollable) {
      return Center(child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: content),
        ),
      ),
    );
  }
}
