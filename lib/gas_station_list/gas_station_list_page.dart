import 'dart:async';

import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/gas_station_group.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_filter_bar.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_list_header.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum _DisplayMode { list, map }

class GasStationListPage extends StatefulWidget {
  const GasStationListPage({
    super.key,
    this.service = const GasStationService(),
  });

  final GasStationService service;

  @override
  State<GasStationListPage> createState() => _GasStationListPageState();
}

class _GasStationListPageState extends State<GasStationListPage>
    with WidgetsBindingObserver {
  /// Période du rafraîchissement automatique.
  ///
  /// Les prix ne bougent que quelques fois par jour, mais la position de
  /// l'utilisateur change en permanence : c'est surtout elle que cette cadence
  /// suit.
  static const Duration _refreshInterval = Duration(minutes: 1);

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

  UserCoordinates? _userCoordinates;

  FuelType _selectedFuel = FuelType.e10;

  SearchRadius _selectedRadius = SearchRadius.fiveKm;

  GasStationSortCriterion _sortCriterion = GasStationSortCriterion.price;

  _DisplayMode _displayMode = _DisplayMode.list;

  bool _isLoading = false;

  String? _errorMessage;

  Timer? _refreshTimer;

  /// Heure du dernier chargement réussi.
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadStations();

    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  /// Une application en arrière-plan n'a personne pour lire
  /// la liste : continuer à interroger l'API y dépenserait
  /// batterie et données pour rien.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();

      _loadStations(silent: true);

      return;
    }

    _refreshTimer?.cancel();

    _refreshTimer = null;
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => _loadStations(silent: true),
    );
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

  /// Stations proposant le carburant sélectionné, triées puis regroupées par
  /// site — un site déclarant plusieurs points de distribution ne compte que
  /// pour une carte.
  ///
  List<GasStationGroup> get _visibleGroups {
    final stations = _stations
        .where((station) => station.priceFor(_selectedFuel) != null)
        .toList();

    stations.sort(_sortCriterion.comparatorFor(_selectedFuel));

    return GasStationGrouper.group(stations, fuel: _selectedFuel);
  }

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

  /// Changement Prix / Distance.
  ///
  /// Il n'est pas nécessaire de refaire
  /// un appel API.
  void _onSortChanged(GasStationSortCriterion criterion) {
    setState(() {
      _sortCriterion = criterion;
    });
  }

  /// Changement de rayon.
  ///
  /// Ici on recharge les stations car la zone
  /// de recherche est différente.
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
                          trailing: _DisplayModeButton(
                            mode: _displayMode,
                            onChanged: (mode) =>
                                setState(() => _displayMode = mode),
                          ),
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

    if (_displayMode == _DisplayMode.map) {
      return _buildMap(_visibleStations);
    }

    final groups = _visibleGroups;

    // Le tiré-pour-rafraîchir remplace le bouton Actualiser de l'ancienne
    // AppBar : il doit rester atteignable même sans station à faire défiler.
    return RefreshIndicator(
      onRefresh: _loadStations,
      child: groups.isEmpty
          ? _MessageState(
              icon: Icons.local_gas_station_outlined,
              message:
                  'Aucune station proposant du ${_selectedFuel.label} '
                  'dans un rayon de ${_selectedRadius.label}.',
              onRetry: _loadStations,
              isScrollable: true,
            )
          : _buildStationList(groups),
    );
  }

  /// Deux sites de la même enseigne dans la même commune n'affichent aucune
  /// différence : mêmes titre, ville et horaires, et des distances qui
  /// s'arrondissent souvent au même dixième. La liste est seule à pouvoir le
  /// constater, puisqu'elle voit toutes les cartes.
  static Set<String> _collidingLabels(List<GasStationGroup> groups) {
    final seen = <String>{};
    final colliding = <String>{};

    for (final group in groups) {
      if (!seen.add(_labelOf(group))) {
        colliding.add(_labelOf(group));
      }
    }

    return colliding;
  }

  static String _labelOf(GasStationGroup group) =>
      '${GasStationCard.titleFor(group.representative)}'
      '|${group.representative.city}';

  Widget _buildStationList(List<GasStationGroup> groups) {
    final cheapestId = groups
        .map((group) => group.representative)
        .reduce(
          (cheapest, station) =>
              station.priceFor(_selectedFuel)! <
                  cheapest.priceFor(_selectedFuel)!
              ? station
              : cheapest,
        )
        .id;

    final colliding = _collidingLabels(groups);

    return ListView.builder(
      padding: _listPadding,
      // Une entrée de plus que de cartes : les crédits ferment la liste.
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == groups.length) {
          return _Attribution(updatedAt: _lastUpdatedAt);
        }

        final group = groups[index];
        final station = group.representative;
        final key = ValueKey(station.id);
        final showAddress = colliding.contains(_labelOf(group));

        if (station.id == cheapestId) {
          return GasStationCard.highlighted(
            station,
            fuel: _selectedFuel,
            key: key,
            showAddress: showAddress,
            pointCount: group.pointCount,
          );
        }

        return GasStationCard.standard(
          station,
          fuel: _selectedFuel,
          key: key,
          showAddress: showAddress,
          pointCount: group.pointCount,
        );
      },
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
    );
  }
}

/// Bascule liste / carte, au gabarit du bouton de rayon.
///
/// Solution transitoire : l'écran cible superpose la liste à la carte dans une
/// feuille glissante, ce qui rendra ce bouton inutile.
class _DisplayModeButton extends StatelessWidget {
  const _DisplayModeButton({required this.mode, required this.onChanged});

  static const double _size = 42;
  static const double _radius = 12;

  final _DisplayMode mode;
  final ValueChanged<_DisplayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final showsList = mode == _DisplayMode.list;

    return Semantics(
      button: true,
      label: showsList ? 'Afficher la carte' : 'Afficher la liste',
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          onTap: () =>
              onChanged(showsList ? _DisplayMode.map : _DisplayMode.list),
          borderRadius: BorderRadius.circular(_radius),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              showsList ? Icons.map_outlined : Icons.list,
              size: 18,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// La licence ODbL d'OpenStreetMap impose de créditer les contributeurs dès
/// lors qu'on affiche leurs données — ici les enseignes des stations. L'heure
/// du dernier chargement les accompagne, faute de barre supérieure depuis que
/// l'en-tête suit le design.
class _Attribution extends StatelessWidget {
  const _Attribution({this.updatedAt});

  final DateTime? updatedAt;

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final time = updatedAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      child: Text(
        [
          if (time != null)
            'Mis à jour à ${_twoDigits(time.hour)}:${_twoDigits(time.minute)}',
          'Prix : data.economie.gouv.fr',
          'Enseignes : © les contributeurs OpenStreetMap',
        ].join(' · '),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceFaint),
      ),
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
