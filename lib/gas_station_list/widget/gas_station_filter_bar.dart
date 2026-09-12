import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:flutter/material.dart';

class GasStationFilterBar extends StatelessWidget
    implements PreferredSizeWidget {
  const GasStationFilterBar({
    super.key,
    required this.sortCriterion,
    required this.selectedFuel,
    required this.selectedRadius,
    required this.onSortChanged,
    required this.onFuelChanged,
    required this.onRadiusChanged,
  });

  static const double _rowHeight = 48;
  static const double _gap = 8;
  static const int _rowCount = 3;

  final GasStationSortCriterion sortCriterion;
  final FuelType selectedFuel;
  final SearchRadius selectedRadius;
  final ValueChanged<GasStationSortCriterion> onSortChanged;
  final ValueChanged<FuelType> onFuelChanged;
  final ValueChanged<SearchRadius> onRadiusChanged;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_rowHeight * _rowCount + _gap * _rowCount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, _gap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          _FilterRow(
            children: GasStationSortCriterion.values
                .map(
                  (criterion) => _FilterChip(
                    label: criterion.label,
                    isSelected: criterion == sortCriterion,
                    onSelected: () => onSortChanged(criterion),
                  ),
                )
                .toList(),
          ),
          _FilterRow(
            children: FuelType.values
                .map(
                  (fuel) => _FilterChip(
                    label: fuel.label,
                    isSelected: fuel == selectedFuel,
                    onSelected: () => onFuelChanged(fuel),
                  ),
                )
                .toList(),
          ),
          _FilterRow(
            children: SearchRadius.values
                .map(
                  (radius) => _FilterChip(
                    label: radius.label,
                    isSelected: radius == selectedRadius,
                    onSelected: () => onRadiusChanged(radius),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      // Le chip est étiré par l'Expanded de sa rangée : le Center recentre le
      // libellé, et le FittedBox le réduit plutôt que de le tronquer sur les
      // écrans étroits ou en grande taille de texte.
      label: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      // La coche des chips sélectionnés décalerait le libellé vers la droite :
      // la sélection reste lisible par la couleur de fond.
      showCheckmark: false,
      labelPadding: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  static const double _chipGap = 6;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GasStationFilterBar._rowHeight,
      child: Row(
        spacing: _chipGap,
        children: [for (final child in children) Expanded(child: child)],
      ),
    );
  }
}
