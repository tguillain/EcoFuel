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
import 'package:ecofuel/gas_station_list/widget/gas_station_sheet_handle.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map.dart';
import 'package:ecofuel/gas_station_list/widget/map/gas_station_map_header.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  static const EdgeInsets _listPadding = EdgeInsets.fromLTRB(16, 2, 16, 14);
  static const double _panelGap = 14;

  /// Stations posées sur la vue carte, comme sur l'artboard « Carte · cartes
  /// flottantes ». Les suivantes attendent qu'on tire la liste.
  static const int _mapStationCount = 2;

  /// Bornes de la feuille repliée, en part de la hauteur sous l'en-tête. Sa
  /// taille réelle est celle des stations de la vue carte, mesurée après
  /// rendu : ces bornes ne jouent que sur un écran trop petit pour elles.
  static const double _minCollapsedSize = 0.1;
  static const double _maxCollapsedSize = 0.9;
  static const double _expandedSize = 1;

  /// L'en-tête flottant s'efface au début de la montée, le panneau de la
  /// liste n'apparaît qu'ensuite : les deux ne se superposent jamais en
  /// pleine opacité.
  static const Interval _mapHeaderFade = Interval(0.2, 0.5);
  static const Interval _panelFade = Interval(0.5, 1);

  /// Le fond de la feuille revient dès qu'on la tire, avant que les stations
  /// suivantes ne se mêlent aux repères de la carte.
  static const Interval _sheetFade = Interval(0, 0.25, curve: Curves.easeOut);

  static const double _sheetRadius = 22;

  static const Duration _sheetAnimation = Duration(milliseconds: 300);

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final GlobalKey _mapHeaderKey = GlobalKey();
  final GlobalKey _sheetAreaKey = GlobalKey();

  /// Ce que la feuille repliée doit laisser voir : les stations de la vue
  /// carte, ou l'indicateur et le message qui en tiennent lieu.
  final GlobalKey _peekKey = GlobalKey();

  /// Taille de la feuille repliée, provisoire jusqu'à la première mesure.
  double _collapsedSize = 0.3;

  /// Hauteurs relevées après rendu, dont dépend la place laissée à la carte.
  double _mapHeaderHeight = 0;
  double _sheetAreaHeight = 0;

  /// Taille de la feuille, en part de la hauteur sous l'en-tête. L'en-tête et
  /// le fond de la feuille la suivent plutôt que le contrôleur, qui peut
  /// notifier en pleine construction de l'arbre.
  late final ValueNotifier<double> _sheetSize = ValueNotifier(_collapsedSize);

  /// Bords de la carte masqués en ce moment, que ses commandes suivent
  /// pendant le glisser de la feuille.
  final ValueNotifier<EdgeInsets> _coveredInsets = ValueNotifier(
    EdgeInsets.zero,
  );

  /// Stations telles que renvoyées par l'API : le filtre carburant et le tri
  /// sont appliqués à l'affichage, seul un changement de rayon relance l'appel.
  List<GasStation> _stations = [];

  UserCoordinates? _userCoordinates;

  FuelType _selectedFuel = FuelType.e10;

  SearchRadius _selectedRadius = SearchRadius.fiveKm;

  GasStationSortCriterion _sortCriterion = GasStationSortCriterion.price;

  bool _isLoading = false;

  String? _errorMessage;

  Timer? _refreshTimer;

  /// Heure du dernier chargement réussi.
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _sheetController.addListener(_onSheetMoved);

    _loadStations();

    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();

    _sheetController.removeListener(_onSheetMoved);

    _sheetController.dispose();

    _sheetSize.dispose();

    _coveredInsets.dispose();

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

  String _headerTitle(int count) {
    if (_isLoading) {
      return 'Recherche…';
    }

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

  /// Avancement de la feuille, de 0 pour la vue carte à 1 pour la liste
  /// seule.
  double get _sheetProgress {
    final double progress =
        (_sheetSize.value - _collapsedSize) / (_expandedSize - _collapsedSize);

    return progress.clamp(0.0, 1.0);
  }

  bool get _isSheetExpanded => _sheetProgress >= 0.5;

  /// Opacité du fond de la feuille. Repliée sur des stations, elle n'en a
  /// pas : les cartes flottent sur la carte. Un message ou un indicateur
  /// garde le sien, illisible sinon par-dessus les tuiles.
  double _sheetOpacity({required bool showsStations}) =>
      showsStations ? _sheetFade.transform(_sheetProgress) : 1;

  /// Bords masqués quand la carte est au repos, feuille repliée.
  EdgeInsets get _framingInsets => EdgeInsets.only(
    top: _mapHeaderHeight,
    bottom: _collapsedSize * _sheetAreaHeight,
  );

  /// Tap sur la poignée : la feuille passe d'un bout à l'autre.
  void _toggleSheet() {
    _sheetController.animateTo(
      _isSheetExpanded ? _collapsedSize : _expandedSize,
      duration: _sheetAnimation,
      curve: Curves.easeOutCubic,
    );
  }

  /// La feuille signale aussi les changements de taille que provoque sa
  /// propre reconstruction, en pleine construction de l'arbre : y
  /// reconstruire l'en-tête ou la carte, ses voisins, est interdit. Ces
  /// signaux-là attendent la fin de l'image.
  void _onSheetMoved() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncSheetSize());

      return;
    }

    _syncSheetSize();
  }

  /// La hauteur vient de la fraction et non de `pixels` : juste après une
  /// reconstruction, la feuille ne connaît pas encore la place dont elle
  /// dispose et `pixels` vaut l'infini.
  void _syncSheetSize() {
    if (!mounted) {
      return;
    }

    final double size = _sheetController.isAttached
        ? _sheetController.size
        : _collapsedSize;

    _sheetSize.value = size;

    _coveredInsets.value = EdgeInsets.only(
      top: _mapHeaderHeight,
      bottom: size * _sheetAreaHeight,
    );
  }

  /// Relève après rendu les hauteurs dont dépendent la feuille repliée et la
  /// place laissée à la carte : elles suivent le texte des cartes, la taille
  /// de police choisie par l'utilisateur et celle de l'écran.
  void _measureLayout() {
    if (!mounted) {
      return;
    }

    final double? headerHeight = _mapHeaderKey.currentContext?.size?.height;
    final double? areaHeight = _sheetAreaKey.currentContext?.size?.height;
    final double? peekHeight = _peekKey.currentContext?.size?.height;

    if (headerHeight == null ||
        areaHeight == null ||
        peekHeight == null ||
        areaHeight == 0) {
      return;
    }

    final double collapsedSize =
        ((GasStationSheetHandle.height + _listPadding.top + peekHeight) /
                areaHeight)
            .clamp(_minCollapsedSize, _maxCollapsedSize);

    final bool changed =
        (collapsedSize - _collapsedSize).abs() > 0.001 ||
        (headerHeight - _mapHeaderHeight).abs() > 0.5 ||
        (areaHeight - _sheetAreaHeight).abs() > 0.5;

    if (changed) {
      final bool wasCollapsed = _sheetProgress < 0.001;

      setState(() {
        _collapsedSize = collapsedSize;
        _mapHeaderHeight = headerHeight;
        _sheetAreaHeight = areaHeight;
      });

      // Une feuille déjà manipulée garde sa position quand ses bornes
      // changent : repliée, elle doit suivre la nouvelle hauteur de ses
      // cartes.
      if (wasCollapsed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _sheetController.isAttached) {
            _sheetController.jumpTo(collapsedSize);
          }
        });
      }
    }

    _syncSheetSize();
  }

  @override
  Widget build(BuildContext context) {
    // Lus pour reconstruire la page, et donc refaire les mesures, quand
    // l'écran change de taille ou l'utilisateur de taille de texte.
    MediaQuery.sizeOf(context);
    MediaQuery.textScalerOf(context);

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureLayout());

    final List<GasStationGroup> groups = _visibleGroups;

    return Scaffold(
      body: SafeArea(
        child: _errorMessage != null
            ? _MessageState(
                icon: Icons.error_outline,
                iconColor: Theme.of(context).colorScheme.error,
                message: _errorMessage!,
                onRetry: _loadStations,
              )
            : Stack(
                children: [
                  // La carte place un repère par point de distribution : le
                  // regroupement est une commodité de lecture propre à la
                  // liste, pas une réalité du terrain.
                  Positioned.fill(
                    child: _buildMap([
                      for (final group in groups) ...group.stations,
                    ]),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(groups.length),
                      Expanded(
                        child: SizedBox.expand(
                          key: _sheetAreaKey,
                          child: _buildSheet(groups),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  /// La vue carte pose ses filtres sur la carte ; la liste les range dans un
  /// panneau blanc. L'un cède la place à l'autre à mesure que la feuille
  /// monte.
  Widget _buildHeader(int stationCount) {
    final Widget panel = Container(
      color: AppColors.surface,
      padding: _panelPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _panelGap,
        children: [
          GasStationListHeader(
            title: _headerTitle(stationCount),
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
    );

    final Widget mapHeader = GasStationMapHeader(
      key: _mapHeaderKey,
      selectedRadius: _selectedRadius,
      onRadiusChanged: _onRadiusChanged,
      selectedFuel: _selectedFuel,
      onFuelChanged: _onFuelChanged,
      sortCriterion: _sortCriterion,
      onSortChanged: _onSortChanged,
    );

    // Le panneau fixe la hauteur de l'en-tête dans les deux vues : la
    // feuille garde ainsi la même place, sans saut quand l'un remplace
    // l'autre.
    return ListenableBuilder(
      listenable: _sheetSize,
      builder: (context, _) {
        final double progress = _sheetProgress;

        return Stack(
          children: [
            _fade(_panelFade.transform(progress), panel),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _fade(1 - _mapHeaderFade.transform(progress), mapHeader),
            ),
          ],
        );
      },
    );
  }

  /// Un en-tête à demi effacé ne répond plus : sinon le panneau invisible de
  /// la liste capterait les gestes destinés à la carte.
  static Widget _fade(double opacity, Widget child) {
    final bool isHidden = opacity < 0.5;

    return IgnorePointer(
      ignoring: isHidden,
      child: ExcludeSemantics(
        excluding: isHidden,
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }

  /// Repliée, la feuille ne montre que les premières stations, sans fond,
  /// posées sur la carte. La tirer vers le haut la déploie en liste jusqu'à
  /// masquer la carte ; la tirer vers le bas rend la carte.
  Widget _buildSheet(List<GasStationGroup> groups) {
    final bool showsStations = !_isLoading && groups.isNotEmpty;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _collapsedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _expandedSize,
      snap: true,
      builder: (context, scrollController) => ListenableBuilder(
        listenable: _sheetSize,
        builder: (context, child) {
          final double opacity = _sheetOpacity(showsStations: showsStations);

          // Les coins s'équarrissent à mesure que le panneau de la liste
          // apparaît : déployée, la feuille couvre la carte jusque dans ses
          // angles, sans laisser deux pointes de carte sous l'en-tête.
          final BorderRadius borderRadius = BorderRadius.vertical(
            top: Radius.circular(
              _sheetRadius * (1 - _panelFade.transform(_sheetProgress)),
            ),
          );

          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: opacity),
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(14, 18, 17, .25 * opacity),
                  offset: const Offset(0, -6),
                  blurRadius: 24,
                  spreadRadius: -12,
                ),
              ],
            ),
            child: ClipRRect(borderRadius: borderRadius, child: child),
          );
        },
        child: _buildSheetContent(
          scrollController,
          groups,
          showsStations: showsStations,
        ),
      ),
    );
  }

  Widget _buildSheetContent(
    ScrollController scrollController,
    List<GasStationGroup> groups, {
    required bool showsStations,
  }) {
    // Le tiré-pour-rafraîchir remplace le bouton Actualiser de l'ancienne
    // AppBar : il doit rester atteignable même sans station à faire défiler.
    return RefreshIndicator(
      onRefresh: _loadStations,
      // Flutter ne fait défiler qu'au doigt par défaut : sur le web de bureau,
      // la feuille ne se tirerait pas à la souris.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ListenableBuilder(
              listenable: _sheetSize,
              builder: (context, _) => SliverPersistentHeader(
                pinned: true,
                delegate: GasStationSheetHandle(
                  isExpanded: _isSheetExpanded,
                  background: AppColors.background.withValues(
                    alpha: _sheetOpacity(showsStations: showsStations),
                  ),
                  onTap: _toggleSheet,
                ),
              ),
            ),
            if (_isLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  key: _peekKey,
                  height: 120,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            else if (groups.isEmpty)
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _peekKey,
                  child: _MessageState(
                    icon: Icons.local_gas_station_outlined,
                    message:
                        'Aucune station proposant du ${_selectedFuel.label} '
                        'dans un rayon de ${_selectedRadius.label}.',
                    onRetry: _loadStations,
                  ),
                ),
              )
            else
              ..._buildStationList(groups),
          ],
        ),
      ),
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

  /// Les stations de la vue carte forment un bloc à part, mesuré pour régler
  /// la feuille repliée ; les suivantes se construisent à la demande.
  List<Widget> _buildStationList(List<GasStationGroup> groups) {
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

    Widget buildCard(GasStationGroup group) {
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
    }

    final int peekCount = groups.length < _mapStationCount
        ? groups.length
        : _mapStationCount;
    final List<GasStationGroup> others = groups.sublist(peekCount);

    return [
      SliverPadding(
        padding: _listPadding.copyWith(bottom: 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            key: _peekKey,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final group in groups.take(peekCount)) buildCard(group),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: _listPadding.copyWith(top: 0),
        sliver: SliverList.builder(
          // Une entrée de plus que de cartes : les crédits ferment la liste.
          itemCount: others.length + 1,
          itemBuilder: (context, index) {
            if (index == others.length) {
              return _Attribution(updatedAt: _lastUpdatedAt);
            }

            return buildCard(others[index]);
          },
        ),
      ),
    ];
  }

  /// Construit la carte, en fond sous l'en-tête et la feuille.
  Widget _buildMap(List<GasStation> stations) {
    final UserCoordinates? coordinates = _userCoordinates;

    // Seul le premier chargement n'a pas encore de position : un échec
    // remplace tout l'écran par son message, et les suivants gardent la
    // dernière position connue.
    if (coordinates == null) {
      return const ColoredBox(color: AppColors.surfaceMuted);
    }

    return GasStationMap(
      stations: stations,
      fuel: _selectedFuel,
      userCoordinates: coordinates,
      radius: _selectedRadius,
      coveredInsets: _coveredInsets,
      framingInsets: _framingInsets,
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
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
