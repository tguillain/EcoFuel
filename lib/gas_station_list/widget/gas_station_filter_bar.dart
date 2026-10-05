import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/model/brand_filter.dart';
import 'package:ecofuel/gas_station_list/widget/brand_menu_button.dart';
import 'package:ecofuel/gas_station_list/widget/filter_pill.dart';
import 'package:ecofuel/gas_station_list/widget/fuel_selector.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Carburant, tri et marque, aux valeurs de l'artboard « Liste seule · cartes +
/// filtres ». Les deux contrôles ne se lisent pas pareil : le carburant est un
/// choix unique dans un ensemble fermé, d'où la piste segmentée à largeurs
/// égales ; le tri est une liste de critères, d'où les pastilles libres.
class GasStationFilterBar extends StatelessWidget {
  const GasStationFilterBar({
    super.key,
    required this.sortCriterion,
    required this.selectedFuel,
    required this.onSortChanged,
    required this.onFuelChanged,
    required this.brands,
    required this.onBrandChanged,
    this.selectedBrand,
  });

  static const double _rowGap = 14;

  final GasStationSortCriterion sortCriterion;
  final FuelType selectedFuel;
  final ValueChanged<GasStationSortCriterion> onSortChanged;
  final ValueChanged<FuelType> onFuelChanged;
  final List<BrandCount> brands;
  final String? selectedBrand;
  final ValueChanged<String?> onBrandChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _rowGap,
      children: [
        FuelSelector(selected: selectedFuel, onSelected: onFuelChanged),
        _SortPills(
          selected: sortCriterion,
          onSelected: onSortChanged,
          trailing: BrandMenuButton(
            brands: brands,
            selectedBrand: selectedBrand,
            onBrandChanged: onBrandChanged,
            child: _BrandPill(selectedBrand: selectedBrand),
          ),
        ),
      ],
    );
  }
}

class _SortPills extends StatelessWidget {
  const _SortPills({
    required this.selected,
    required this.onSelected,
    required this.trailing,
  });

  /// Le design arrondit complètement ces pastilles (`border-radius: 999px`).
  static const double _pillRadius = 999;
  static const double _gap = 8;
  static const EdgeInsets _pillPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 7,
  );

  final GasStationSortCriterion selected;
  final ValueChanged<GasStationSortCriterion> onSelected;

  /// Pastille posée après les critères de tri : celle de la marque.
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: [
        FilterPill(
          label: GasStationSortCriterion.distance.label,
          isSelected: selected == GasStationSortCriterion.distance,
          radius: _pillRadius,
          padding: _pillPadding,
          foreground: context.colors.onSurfaceSubtle,
          onTap: () => onSelected(selected.withDistanceToggled),
        ),
        trailing,
      ],
    );
  }
}

/// Pastille de la marque, au gabarit des pastilles de tri. Le menu qui
/// l'entoure capte le tap : elle ne fait que se dessiner.
class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.selectedBrand});

  final String? selectedBrand;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedBrand != null;
    final Color foreground = isSelected
        ? context.colors.onSelected
        : context.colors.onSurfaceSubtle;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      decoration: BoxDecoration(
        color: isSelected
            ? context.colors.selected
            : context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Text(
            selectedBrand ?? BrandFilter.allBrands,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: foreground,
            ),
          ),
          Icon(Icons.expand_more, size: 16, color: foreground),
        ],
      ),
    );
  }
}
