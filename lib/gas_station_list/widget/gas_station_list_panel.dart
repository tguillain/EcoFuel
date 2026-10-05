import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_filter_bar.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_list_header.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Panneau blanc en tête de l'écran : lieu, compteur et rayon, puis carburant
/// et tri.
class GasStationListPanel extends StatelessWidget {
  const GasStationListPanel({
    super.key,
    required this.title,
    required this.selectedRadius,
    required this.onRadiusChanged,
    required this.sortCriterion,
    required this.selectedFuel,
    required this.onSortChanged,
    required this.onFuelChanged,
    this.placeName,
    this.onPlaceTap,
  });

  /// Métriques de l'artboard « Liste seule · cartes + filtres » : le panneau
  /// d'en-tête est blanc sur le fond de l'écran.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(20, 18, 20, 14);
  static const double _gap = 14;

  final String title;
  final SearchRadius selectedRadius;
  final ValueChanged<SearchRadius> onRadiusChanged;
  final GasStationSortCriterion sortCriterion;
  final FuelType selectedFuel;
  final ValueChanged<GasStationSortCriterion> onSortChanged;
  final ValueChanged<FuelType> onFuelChanged;
  final String? placeName;
  final VoidCallback? onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _gap,
        children: [
          GasStationListHeader(
            title: title,
            selectedRadius: selectedRadius,
            onRadiusChanged: onRadiusChanged,
            placeName: placeName,
            onPlaceTap: onPlaceTap,
          ),
          GasStationFilterBar(
            sortCriterion: sortCriterion,
            selectedFuel: selectedFuel,
            onSortChanged: onSortChanged,
            onFuelChanged: onFuelChanged,
          ),
        ],
      ),
    );
  }
}
