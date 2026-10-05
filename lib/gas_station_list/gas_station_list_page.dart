import 'package:ecofuel/gas_station_detail/gas_station_detail_page.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/gas_station_group.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/lifecycle_refresher.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_list_panel.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map_background.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map_header.dart';
import 'package:ecofuel/gas_station_list/widget/map_list_sheet.dart';
import 'package:ecofuel/gas_station_list/widget/message_state.dart';
import 'package:ecofuel/gas_station_list/widget/station_sheet_content.dart';
import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:ecofuel/place_search/model/station_search.dart';
import 'package:ecofuel/place_search/service/place_search_service.dart';
import 'package:ecofuel/place_search/widget/place_search_sheet.dart';
import 'package:flutter/material.dart';

class GasStationListPage extends StatefulWidget {
  const GasStationListPage({
    super.key,
    this.service = const GasStationService(),
    this.placeSearch = const PlaceSearchService(),
  });

  final GasStationService service;
  final PlaceSearchService placeSearch;

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

  /// Lieu cherché à la place de la position de l'utilisateur ; `null` autour
  /// de lui. Le rafraîchissement automatique y reste fixé.
  SearchPlace? _searchPlace;

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

  /// Charge la position puis les stations, autour du lieu cherché s'il y en a.
  ///
  /// Un rafraîchissement [silent] n'affiche ni indicateur ni erreur : il part
  /// tout seul chaque minute, et remplacer la liste par un tourniquet ou un
  /// message d'échec serait pire que garder les dernières données connues.
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
            coordinates: _searchPlace?.coordinates ?? coordinates,
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
        setState(() => _isLoading = false);
      }
    }
  }

  List<GasStationGroup> get _visibleGroups => GasStationGrouper.forDisplay(
    _stations,
    fuel: _selectedFuel,
    sortCriterion: _sortCriterion,
  );

  String _headerTitle(int count) =>
      _isLoading ? 'Recherche…' : '$count station${count > 1 ? 's' : ''}';

  void _onFuelChanged(FuelType fuel) => setState(() => _selectedFuel = fuel);

  /// Changement Prix / Distance : inutile de refaire un appel API.
  void _onSortChanged(GasStationSortCriterion criterion) =>
      setState(() => _sortCriterion = criterion);

  /// Changement de rayon : la zone de recherche change, on recharge.
  Future<void> _onRadiusChanged(SearchRadius radius) async {
    if (radius == _selectedRadius) {
      return;
    }

    setState(() => _selectedRadius = radius);

    await _loadStations();
  }

  /// Change le lieu, le rayon et le carburant de la recherche d'un coup.
  Future<void> _choosePlace() async {
    final StationSearch? search = await showPlaceSearchSheet(
      context,
      service: widget.placeSearch,
      initial: StationSearch(
        place: _searchPlace,
        radius: _selectedRadius,
        fuel: _selectedFuel,
      ),
    );

    if (search != null && mounted) {
      _selectedRadius = search.radius;
      _selectedFuel = search.fuel;

      await _searchAround(search.place);
    }
  }

  Future<void> _searchAround(SearchPlace? place) async {
    setState(() => _searchPlace = place);

    await _loadStations();
  }

  /// Ouvre la fiche d'une station.
  void _openDetail(GasStation station, {required bool isCheapest}) {
    final UserCoordinates? coordinates = _userCoordinates;

    if (coordinates == null) {
      return;
    }

    GasStationDetailPage.open(
      context,
      station: station,
      fuel: _selectedFuel,
      radius: _selectedRadius,
      userCoordinates: coordinates,
      isCheapest: isCheapest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<GasStationGroup> groups = _visibleGroups;

    return Scaffold(
      body: SafeArea(
        child: _errorMessage != null
            ? MessageState(
                icon: Icons.error_outline,
                iconColor: Theme.of(context).colorScheme.error,
                message: _errorMessage!,
                onRetry: _loadStations,
              )
            : MapListSheet(
                floatsOnMap: !_isLoading && groups.isNotEmpty,
                onRefresh: _loadStations,
                listHeader: GasStationListPanel(
                  title: _headerTitle(groups.length),
                  selectedRadius: _selectedRadius,
                  onRadiusChanged: _onRadiusChanged,
                  sortCriterion: _sortCriterion,
                  selectedFuel: _selectedFuel,
                  onSortChanged: _onSortChanged,
                  onFuelChanged: _onFuelChanged,
                  placeName: _searchPlace?.name,
                  onPlaceTap: _choosePlace,
                ),
                mapHeader: GasStationMapHeader(
                  placeName: _searchPlace?.name,
                  onPlaceTap: _choosePlace,
                  onPlaceCleared: _searchPlace == null
                      ? null
                      : () => _searchAround(null),
                  selectedRadius: _selectedRadius,
                  onRadiusChanged: _onRadiusChanged,
                  selectedFuel: _selectedFuel,
                  onFuelChanged: _onFuelChanged,
                  sortCriterion: _sortCriterion,
                  onSortChanged: _onSortChanged,
                ),
                // La carte place un repère par point de distribution : le
                // regroupement est une commodité de lecture propre à la
                // liste, pas une réalité du terrain.
                mapBuilder: (coveredInsets, framingInsets) =>
                    GasStationMapBackground(
                      stations: [for (final group in groups) ...group.stations],
                      fuel: _selectedFuel,
                      radius: _selectedRadius,
                      userCoordinates: _userCoordinates,
                      searchCenter: _searchPlace?.coordinates,
                      coveredInsets: coveredInsets,
                      framingInsets: framingInsets,
                    ),
                sliverBuilder: (peekKey) => StationSheetContent(
                  isLoading: _isLoading,
                  groups: groups,
                  fuel: _selectedFuel,
                  radius: _selectedRadius,
                  peekKey: peekKey,
                  updatedAt: _lastUpdatedAt,
                  onRetry: _loadStations,
                  onStationTap: _openDetail,
                ),
              ),
      ),
    );
  }
}
