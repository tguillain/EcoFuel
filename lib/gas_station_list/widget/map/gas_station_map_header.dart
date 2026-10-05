import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/widget/map/map_location_pill.dart';
import 'package:ecofuel/gas_station_list/widget/search_radius_button.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// En-tête de la vue carte, aux valeurs de l'artboard « Carte · cartes
/// flottantes » : des éléments blancs posés sur la carte plutôt qu'un panneau
/// qui la masque.
///
/// Les filtres sont ceux de la liste, resserrés : la piste segmentée des
/// carburants prendrait toute une rangée, elle devient une pastille qui
/// n'affiche que le carburant choisi et ouvre les autres au tap.
class GasStationMapHeader extends StatelessWidget {
  const GasStationMapHeader({
    super.key,
    required this.selectedRadius,
    required this.onRadiusChanged,
    required this.selectedFuel,
    required this.onFuelChanged,
    required this.sortCriterion,
    required this.onSortChanged,
    required this.onPlaceTap,
    this.placeName,
    this.onPlaceCleared,
  });

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(18, 16, 18, 0);
  static const double _gap = 10;
  static const double _chipGap = 8;

  final SearchRadius selectedRadius;
  final ValueChanged<SearchRadius> onRadiusChanged;
  final FuelType selectedFuel;
  final ValueChanged<FuelType> onFuelChanged;
  final GasStationSortCriterion sortCriterion;
  final ValueChanged<GasStationSortCriterion> onSortChanged;

  /// Lieu cherché ; `null` autour de l'utilisateur.
  final String? placeName;
  final VoidCallback onPlaceTap;

  /// Revient à la position de l'utilisateur.
  final VoidCallback? onPlaceCleared;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _gap,
        children: [
          Row(
            spacing: _gap,
            children: [
              Expanded(
                child: MapLocationPill(
                  radius: selectedRadius,
                  placeName: placeName,
                  onTap: onPlaceTap,
                  onCleared: onPlaceCleared,
                ),
              ),
              SearchRadiusButton(
                selectedRadius: selectedRadius,
                onRadiusChanged: onRadiusChanged,
                isFloating: true,
              ),
            ],
          ),
          // Défile plutôt que de passer à la ligne quand le texte est agrandi :
          // une seconde rangée de pastilles mangerait la carte. Sans découpe,
          // pour ne pas rogner les ombres.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              spacing: _chipGap,
              children: [
                _FuelChip(selected: selectedFuel, onSelected: onFuelChanged),
                for (final criterion in GasStationSortCriterion.values)
                  _Chip(
                    isSelected: criterion == sortCriterion,
                    onTap: () => onSortChanged(criterion),
                    child: Text(criterion.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelChip extends StatelessWidget {
  const _FuelChip({required this.selected, required this.onSelected});

  final FuelType selected;
  final ValueChanged<FuelType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carburant : ${selected.label}',
      child: PopupMenuButton<FuelType>(
        initialValue: selected,
        onSelected: onSelected,
        tooltip: 'Changer de carburant',
        position: PopupMenuPosition.under,
        padding: EdgeInsets.zero,
        itemBuilder: (context) => [
          for (final fuel in FuelType.values)
            PopupMenuItem<FuelType>(value: fuel, child: Text(fuel.label)),
        ],
        child: _Chip(
          isSelected: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Text(selected.label),
              const Icon(Icons.expand_more, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille flottante : noire quand elle est active, blanche et ombrée sinon.
class _Chip extends StatelessWidget {
  const _Chip({required this.isSelected, required this.child, this.onTap});

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 8,
  );

  static const BoxShadow _shadow = BoxShadow(
    color: Color.fromRGBO(14, 18, 17, .3),
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: -6,
  );

  final bool isSelected;
  final Widget child;

  /// Absent quand un parent capte déjà le tap, comme le menu des carburants.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isSelected
        ? AppColors.onPrimary
        : AppColors.onSurfaceSubtle;
    final BorderRadius borderRadius = BorderRadius.circular(999);

    final Widget content = Padding(
      padding: _padding,
      child: IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: DefaultTextStyle.merge(
          maxLines: 1,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: foreground,
          ),
          child: child,
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: isSelected ? null : const [_shadow],
        ),
        child: Material(
          color: isSelected ? AppColors.onSurface : AppColors.surface,
          borderRadius: borderRadius,
          child: onTap == null
              ? content
              : InkWell(
                  onTap: onTap,
                  borderRadius: borderRadius,
                  child: content,
                ),
        ),
      ),
    );
  }
}
