import 'package:ecofuel/gas_station_detail/gas_station_detail_page.dart';
import 'package:ecofuel/gas_station_list/enum/display_mode.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/gas_station_group.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/lifecycle_refresher.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_list_panel.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map.dart';
import 'package:ecofuel/gas_station_list/widget/message_state.dart';
import 'package:ecofuel/gas_station_list/widget/refreshable_station_list.dart';
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
  /// Période du rafraîchissement automatique.
  ///
  /// Les prix ne bougent que quelques fois par jour, mais la position de
  /// l'utilisateur change en permanence : c'est surtout elle que cette cadence
  /// suit.
  static const Duration _refreshInterval = Duration(minutes: 1);

  /// Stations telles que renvoyées par l'API : le filtre carburant et le tri
  /// sont appliqués à l'affichage, seul un changement de rayon relance l'appel.
  List<GasStation> _stations = [];

  UserCoordinates? _userCoordinates;

  FuelType _selectedFuel = FuelType.e10;

  SearchRadius _selectedRadius = SearchRadius.fiveKm;

  GasStationSortCriterion _sortCriterion = GasStationSortCriterion.price;

  DisplayMode _displayMode = DisplayMode.list;

  /// Itinéraire demandé depuis la fiche d'une station de la liste, que la
  /// carte trace à son ouverture.
  GasStation? _routeDestination;

  bool _isLoading = false;

  String? _errorMessage;

  late final LifecycleRefresher _refresher = LifecycleRefresher(
    interval: _refreshInterval,
    onRefresh: () => _loadStations(silent: true),
  );

  /// Heure du dernier chargement réussi.
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();

    _loadStations();

    _refresher.start();
  }

  @override
  void dispose() {
    _refresher.dispose();

    super.dispose();
  }

  /// Charge la position puis les stations.
  ///
  /// Un rafraîchissement [silent] n'affiche ni indicateur ni
  /// erreur : il part tout seul chaque minute, et remplacer la
  /// liste par un tourniquet ou un message d'échec à chaque
  /// passage serait pire que de garder à l'écran les dernières
  /// données connues.
  Future<void> _loadStations({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final UserCoordinates coordinates = await widget.service
          .currentCoordinates();

      final List<GasStation> stations = await widget.service
          .fetchNearbyStations(
            radius: _selectedRadius,
            coordinates: coordinates,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _userCoordinates = coordinates;

        _stations = stations;

        _lastUpdatedAt = DateTime.now();

        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      // Un échec de fond ne doit rien casser à l'écran : la
      // liste précédente reste affichée jusqu'au prochain
      // passage.
      if (silent) {
        return;
      }

      setState(() {
        _stations = [];

        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<GasStationGroup> get _visibleGroups => GasStationGrouper.forDisplay(
    _stations,
    fuel: _selectedFuel,
    sortCriterion: _sortCriterion,
  );

  /// La carte place un repère par point de distribution : le regroupement est
  /// une commodité de lecture propre à la liste, pas une réalité du terrain.
  List<GasStation> get _visibleStations => [
    for (final group in _visibleGroups) ...group.stations,
  ];

  String get _headerTitle {
    if (_isLoading) {
      return 'Recherche…';
    }

    final count = _visibleGroups.length;

    return '$count station${count > 1 ? 's' : ''}';
  }

  /// Changement du carburant.
  void _onFuelChanged(FuelType fuel) {
    setState(() {
      _selectedFuel = fuel;
    });
  }

  /// Changement Prix / Distance : inutile de refaire un appel API.
  void _onSortChanged(GasStationSortCriterion criterion) {
    setState(() {
      _sortCriterion = criterion;
    });
  }

  /// Changement de rayon : la zone de recherche change, on recharge.
  Future<void> _onRadiusChanged(SearchRadius radius) async {
    if (radius == _selectedRadius) {
      return;
    }

    setState(() {
      _selectedRadius = radius;
    });

    await _loadStations();
  }

  /// Ouvre la fiche d'une station ; l'itinéraire, s'il est demandé, s'affiche
  /// sur la carte, seule à savoir le tracer.
  Future<void> _openDetail(
    GasStation station, {
    required bool isCheapest,
  }) async {
    final UserCoordinates? coordinates = _userCoordinates;

    if (coordinates == null) {
      return;
    }

    final bool wantsRoute = await GasStationDetailPage.open(
      context,
      station: station,
      fuel: _selectedFuel,
      radius: _selectedRadius,
      userCoordinates: coordinates,
      isCheapest: isCheapest,
    );

    if (!wantsRoute || !mounted) {
      return;
    }

    setState(() {
      _displayMode = DisplayMode.map;
      _routeDestination = station;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _errorMessage != null
            ? MessageState(
                icon: Icons.error_outline,
                iconColor: Theme.of(context).colorScheme.error,
                message: _errorMessage!,
                onRetry: _loadStations,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GasStationListPanel(
                    title: _headerTitle,
                    selectedRadius: _selectedRadius,
                    onRadiusChanged: _onRadiusChanged,
                    displayMode: _displayMode,
                    onDisplayModeChanged: (mode) =>
                        setState(() => _displayMode = mode),
                    sortCriterion: _sortCriterion,
                    selectedFuel: _selectedFuel,
                    onSortChanged: _onSortChanged,
                    onFuelChanged: _onFuelChanged,
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

    if (_displayMode == DisplayMode.map) {
      return _buildMap(_visibleStations);
    }

    return RefreshableStationList(
      groups: _visibleGroups,
      fuel: _selectedFuel,
      radius: _selectedRadius,
      updatedAt: _lastUpdatedAt,
      onRefresh: _loadStations,
      onStationTap: _openDetail,
    );
  }

  /// Construit la carte.
  Widget _buildMap(List<GasStation> stations) {
    final UserCoordinates? coordinates = _userCoordinates;

    if (coordinates == null) {
      return const Center(child: Text('Position utilisateur indisponible.'));
    }

    return GasStationMap(
      stations: stations,
      fuel: _selectedFuel,
      userCoordinates: coordinates,
      radius: _selectedRadius,
      routeDestination: _routeDestination,
      onRouteRequestHandled: () => setState(() => _routeDestination = null),
    );
  }
}
