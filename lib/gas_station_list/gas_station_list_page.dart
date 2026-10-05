import 'package:ecofuel/favorites/favorites_page.dart';
import 'package:ecofuel/favorites/model/favorite_stations.dart';
import 'package:ecofuel/favorites/service/favorite_stations_store.dart';
import 'package:ecofuel/gas_station_detail/gas_station_detail_page.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/model/brand_filter.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/gas_station_group.dart';
import 'package:ecofuel/gas_station_list/model/nearby_stations.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/lifecycle_refresher.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_list_panel.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map_background.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map_header.dart';
import 'package:ecofuel/gas_station_list/widget/map_list_sheet.dart';
import 'package:ecofuel/gas_station_list/widget/message_state.dart';
import 'package:ecofuel/gas_station_list/widget/station_sheet_content.dart';
import 'package:ecofuel/place_search/model/station_search.dart';
import 'package:ecofuel/place_search/service/place_search_service.dart';
import 'package:ecofuel/place_search/widget/place_search_sheet.dart';
import 'package:flutter/material.dart';

class GasStationListPage extends StatefulWidget {
  const GasStationListPage({
    super.key,
    this.service = const GasStationService(),
    this.placeSearch = const PlaceSearchService(),
    this.favoritesStore,
  });

  final GasStationService service;
  final PlaceSearchService placeSearch;

  /// Où garder les favoris ; sans lui, les préférences de l'appareil.
  final FavoriteStationsStore? favoritesStore;

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

  late final NearbyStations _nearby = NearbyStations(widget.service);

  late final FavoriteStations _favorites = FavoriteStations(
    widget.favoritesStore ?? PreferencesFavoriteStationsStore(),
  );

  FuelType _selectedFuel = FuelType.e10;

  GasStationSortCriterion _sortCriterion = GasStationSortCriterion.price;

  /// Enseigne retenue ; `null`, toutes passent.
  String? _selectedBrand;

  late final LifecycleRefresher _refresher = LifecycleRefresher(
    interval: _refreshInterval,
    onRefresh: () => _nearby.load(silent: true),
  );

  @override
  void initState() {
    super.initState();

    _nearby.addListener(_rebuild);
    _favorites.addListener(_rebuild);

    _nearby.load();
    _favorites.load();

    _refresher.start();
  }

  @override
  void dispose() {
    _refresher.dispose();
    _nearby.dispose();
    _favorites.dispose();

    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// Stations proposant le carburant choisi.
  List<GasStation> get _offeringStations => _nearby.stations
      .where((station) => station.priceFor(_selectedFuel) != null)
      .toList();

  List<GasStationGroup> get _visibleGroups => GasStationGrouper.forDisplay(
    BrandFilter.apply(_nearby.stations, _selectedBrand),
    fuel: _selectedFuel,
    sortCriterion: _sortCriterion,
  );

  String _headerTitle(int count) => _nearby.isLoading
      ? 'Recherche…'
      : '$count station${count > 1 ? 's' : ''}';

  void _onFuelChanged(FuelType fuel) => setState(() => _selectedFuel = fuel);

  /// Changement Prix / Distance : inutile de refaire un appel API.
  void _onSortChanged(GasStationSortCriterion criterion) =>
      setState(() => _sortCriterion = criterion);

  void _onBrandChanged(String? brand) => setState(() => _selectedBrand = brand);

  /// Change le lieu, le rayon et le carburant de la recherche d'un coup.
  Future<void> _choosePlace() async {
    final StationSearch? search = await showPlaceSearchSheet(
      context,
      service: widget.placeSearch,
      initial: StationSearch(
        place: _nearby.place,
        radius: _nearby.radius,
        fuel: _selectedFuel,
      ),
    );

    if (search != null && mounted) {
      setState(() => _selectedFuel = search.fuel);

      await _nearby.searchAround(search.place, newRadius: search.radius);
    }
  }

  /// Ouvre la fiche d'une station.
  void _openDetail(GasStation station, {required bool isCheapest}) {
    final UserCoordinates? coordinates = _nearby.userCoordinates;

    if (coordinates == null) {
      return;
    }

    GasStationDetailPage.open(
      context,
      station: station,
      fuel: _selectedFuel,
      radius: _nearby.radius,
      userCoordinates: coordinates,
      isCheapest: isCheapest,
    );
  }

  void _openFavorites() {
    final UserCoordinates? coordinates = _nearby.userCoordinates;

    if (coordinates == null) {
      return;
    }

    FavoritesPage.open(
      context,
      favorites: _favorites,
      service: widget.service,
      fuel: _selectedFuel,
      radius: _nearby.radius,
      userCoordinates: coordinates,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<GasStationGroup> groups = _visibleGroups;
    final List<BrandCount> brands = BrandFilter.availableBrands(
      _offeringStations,
    );
    final String? errorMessage = _nearby.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: errorMessage != null
            ? MessageState(
                icon: Icons.error_outline,
                iconColor: Theme.of(context).colorScheme.error,
                message: errorMessage,
                onRetry: _nearby.load,
              )
            : MapListSheet(
                floatsOnMap: !_nearby.isLoading && groups.isNotEmpty,
                onRefresh: _nearby.load,
                listHeader: GasStationListPanel(
                  title: _headerTitle(groups.length),
                  selectedRadius: _nearby.radius,
                  onRadiusChanged: _nearby.changeRadius,
                  sortCriterion: _sortCriterion,
                  selectedFuel: _selectedFuel,
                  onSortChanged: _onSortChanged,
                  onFuelChanged: _onFuelChanged,
                  brands: brands,
                  selectedBrand: _selectedBrand,
                  onBrandChanged: _onBrandChanged,
                  placeName: _nearby.place?.name,
                  onPlaceTap: _choosePlace,
                ),
                mapHeader: GasStationMapHeader(
                  placeName: _nearby.place?.name,
                  onPlaceTap: _choosePlace,
                  onPlaceCleared: _nearby.place == null
                      ? null
                      : () => _nearby.searchAround(null),
                  selectedRadius: _nearby.radius,
                  onRadiusChanged: _nearby.changeRadius,
                  selectedFuel: _selectedFuel,
                  onFuelChanged: _onFuelChanged,
                  sortCriterion: _sortCriterion,
                  onSortChanged: _onSortChanged,
                  brands: brands,
                  selectedBrand: _selectedBrand,
                  onBrandChanged: _onBrandChanged,
                ),
                // La carte place un repère par point de distribution : le
                // regroupement est une commodité de lecture propre à la
                // liste, pas une réalité du terrain.
                mapBuilder: (coveredInsets, framingInsets) =>
                    GasStationMapBackground(
                      stations: [for (final group in groups) ...group.stations],
                      fuel: _selectedFuel,
                      radius: _nearby.radius,
                      userCoordinates: _nearby.userCoordinates,
                      searchCenter: _nearby.place?.coordinates,
                      coveredInsets: coveredInsets,
                      framingInsets: framingInsets,
                      onFavoritesTap: _openFavorites,
                    ),
                sliverBuilder: (peekKey) => StationSheetContent(
                  isLoading: _nearby.isLoading,
                  groups: groups,
                  fuel: _selectedFuel,
                  radius: _nearby.radius,
                  peekKey: peekKey,
                  updatedAt: _nearby.lastUpdatedAt,
                  onRetry: _nearby.load,
                  onStationTap: _openDetail,
                  favoriteIds: _favorites.ids,
                  onFavoriteTap: (station) => _favorites.toggle(station.id),
                ),
              ),
      ),
    );
  }
}
