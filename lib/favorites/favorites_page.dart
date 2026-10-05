import 'package:ecofuel/favorites/model/favorite_stations.dart';
import 'package:ecofuel/favorites/widget/favorites_header.dart';
import 'package:ecofuel/gas_station_detail/gas_station_detail_page.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/gas_station_list/widget/message_state.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Les stations mises en favori, avec leur prix à jour, même hors du rayon de
/// recherche, de la moins chère à la plus chère.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.favorites,
    required this.service,
    required this.fuel,
    required this.radius,
    required this.userCoordinates,
  });

  final FavoriteStations favorites;
  final GasStationService service;
  final FuelType fuel;

  /// Rayon de la recherche en cours, que la fiche d'une station rappelle.
  final SearchRadius radius;

  /// Point de départ des distances affichées.
  final UserCoordinates userCoordinates;

  static Future<void> open(
    BuildContext context, {
    required FavoriteStations favorites,
    required GasStationService service,
    required FuelType fuel,
    required SearchRadius radius,
    required UserCoordinates userCoordinates,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FavoritesPage(
          favorites: favorites,
          service: service,
          fuel: fuel,
          radius: radius,
          userCoordinates: userCoordinates,
        ),
      ),
    );
  }

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late FuelType _fuel = widget.fuel;

  List<GasStation> _stations = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Une étoile retirée ici fait disparaître la station sans rien recharger.
    widget.favorites.addListener(_onFavoritesChanged);

    _load();
  }

  @override
  void dispose() {
    widget.favorites.removeListener(_onFavoritesChanged);

    super.dispose();
  }

  void _onFavoritesChanged() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Set<String> ids = widget.favorites.ids;
      final List<GasStation> stations = ids.isEmpty
          ? const []
          : await widget.service.fetchStationsByIds(
              ids,
              from: widget.userCoordinates,
            );

      if (mounted) {
        setState(() => _stations = stations);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _errorMessage = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Les favoris encore étoilés, triés au prix du carburant choisi. Une
  /// station qui ne le vend pas passe en dernier.
  List<GasStation> get _visibleStations =>
      _stations
          .where((station) => widget.favorites.contains(station.id))
          .toList()
        ..sort(GasStationSortCriterion.price.comparatorFor(_fuel));

  void _openDetail(GasStation station) {
    GasStationDetailPage.open(
      context,
      station: station,
      fuel: _fuel,
      radius: widget.radius,
      userCoordinates: widget.userCoordinates,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<GasStation> stations = _visibleStations;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FavoritesHeader(
              count: stations.length,
              fuel: _fuel,
              onFuelChanged: (fuel) => setState(() => _fuel = fuel),
            ),
            Expanded(child: _buildBody(stations)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<GasStation> stations) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String? errorMessage = _errorMessage;

    if (errorMessage != null) {
      return MessageState(
        icon: Icons.error_outline,
        iconColor: Theme.of(context).colorScheme.error,
        message: errorMessage,
        onRetry: _load,
      );
    }

    if (stations.isEmpty) {
      return const _FavoritesHint(
        'Aucune station en favori pour l\'instant. Touche l\'étoile d\'une '
        'station dans la liste pour la retrouver ici.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final station in stations)
          GasStationCard.standard(
            station,
            fuel: _fuel,
            key: ValueKey(station.id),
            onTap: () => _openDetail(station),
            isFavorite: true,
            onFavoriteTap: () => widget.favorites.toggle(station.id),
          ),
        const _FavoritesHint(
          'Touche l\'étoile d\'une station dans la liste pour l\'ajouter ici.',
        ),
      ],
    );
  }
}

class _FavoritesHint extends StatelessWidget {
  const _FavoritesHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 10,
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 20,
            color: context.colors.onSurfaceSubtle,
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.colors.onSurfaceSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
