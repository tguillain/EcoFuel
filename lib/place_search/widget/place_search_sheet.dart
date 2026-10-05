import 'dart:async';

import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:ecofuel/place_search/model/station_search.dart';
import 'package:ecofuel/place_search/service/place_search_service.dart';
import 'package:ecofuel/place_search/widget/place_suggestions.dart';
import 'package:ecofuel/place_search/widget/search_option_chips.dart';
import 'package:ecofuel/place_search/widget/search_sheet_parts.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Ouvre la recherche de stations, préremplie avec la recherche en cours.
/// Résout à `null` si l'utilisateur ferme le panneau sans valider.
Future<StationSearch?> showPlaceSearchSheet(
  BuildContext context, {
  required StationSearch initial,
  PlaceSearchService service = const PlaceSearchService(),
}) {
  return showModalBottomSheet<StationSearch>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => PlaceSearchSheet(initial: initial, service: service),
  );
}

/// Où chercher, dans quel rayon et pour quel carburant, validés ensemble.
class PlaceSearchSheet extends StatefulWidget {
  const PlaceSearchSheet({
    super.key,
    required this.initial,
    required this.service,
  });

  final StationSearch initial;
  final PlaceSearchService service;

  @override
  State<PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<PlaceSearchSheet> {
  /// Attente après la dernière frappe : interroger le service à chaque lettre
  /// gaspillerait des appels dont la réponse serait aussitôt périmée.
  static const Duration _debounce = Duration(milliseconds: 350);

  final TextEditingController _controller = TextEditingController();

  late SearchPlace? _place = widget.initial.place;
  late SearchRadius _radius = widget.initial.radius;
  late FuelType _fuel = widget.initial.fuel;

  Timer? _timer;

  /// Numéro de la dernière recherche lancée : une réponse plus ancienne,
  /// arrivée en retard, est ignorée.
  int _searchId = 0;

  String _query = '';
  bool _isLoading = false;
  bool _hasFailed = false;
  List<SearchPlace> _places = const [];

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();

    super.dispose();
  }

  void _onChanged(String query) {
    _timer?.cancel();

    setState(() => _query = query);

    _timer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final int searchId = ++_searchId;

    setState(() {
      _isLoading = true;
      _hasFailed = false;
    });

    try {
      final List<SearchPlace> places = await widget.service.search(query);

      if (mounted && searchId == _searchId) {
        setState(() => _places = places);
      }
    } catch (_) {
      if (mounted && searchId == _searchId) {
        setState(() {
          _places = const [];
          _hasFailed = true;
        });
      }
    } finally {
      if (mounted && searchId == _searchId) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Retient le lieu et referme les suggestions pour laisser voir le rayon et
  /// le carburant.
  void _choose(SearchPlace? place) {
    _timer?.cancel();
    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _place = place;
      _query = '';
      _places = const [];
    });
  }

  void _submit() {
    Navigator.of(context)
        .pop(StationSearch(place: _place, radius: _radius, fuel: _fuel));
  }

  @override
  Widget build(BuildContext context) {
    final bool isTyping = _query.isNotEmpty;

    return Padding(
      // Le clavier ne doit pas masquer les suggestions.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  const Text(
                    'Chercher des stations',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  _buildField(),
                ],
              ),
            ),
            Expanded(
              child: isTyping
                  ? PlaceSuggestions(
                      query: _query,
                      places: _places,
                      isLoading: _isLoading,
                      hasFailed: _hasFailed,
                      onSelected: _choose,
                    )
                  : _buildOptions(),
            ),
            SearchSubmitBar(onPressed: isTyping ? null : _submit),
          ],
        ),
      ),
    );
  }

  Widget _buildField() {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Ville ou adresse, ex. Lyon',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildOptions() {
    final SearchPlace? place = _place;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        ChosenPlace(
          place: place,
          onReset: place == null ? null : () => _choose(null),
        ),
        const SizedBox(height: 22),
        SearchOptionChips<SearchRadius>(
          title: 'Rayon',
          values: SearchRadius.values,
          labelOf: (radius) => radius.label,
          selected: _radius,
          onSelected: (radius) => setState(() => _radius = radius),
        ),
        const SizedBox(height: 22),
        SearchOptionChips<FuelType>(
          title: 'Carburant',
          values: FuelType.values,
          labelOf: (fuel) => fuel.label,
          selected: _fuel,
          onSelected: (fuel) => setState(() => _fuel = fuel),
        ),
      ],
    );
  }
}
