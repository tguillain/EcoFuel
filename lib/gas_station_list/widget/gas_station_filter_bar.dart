import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:flutter/material.dart';

class GasStationFilterBar extends StatelessWidget
    implements PreferredSizeWidget {
  const GasStationFilterBar({
    super.key,
    required this.sortCriterion,
    required this.selectedFuel,
    required this.onSortChanged,
    required this.onFuelChanged,
  });

  static const double _rowHeight = 48;
  static const double _gap = 8;

  final GasStationSortCriterion sortCriterion;
  final FuelType selectedFuel;
  final ValueChanged<GasStationSortCriterion> onSortChanged;
  final ValueChanged<FuelType> onFuelChanged;

  @override
  Size get preferredSize => const Size.fromHeight(_rowHeight * 2 + _gap * 2);

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
                  (criterion) => ChoiceChip(
                    label: Text(criterion.label),
                    selected: criterion == sortCriterion,
                    onSelected: (_) => onSortChanged(criterion),
                  ),
                )
                .toList(),
          ),
          _FilterRow(
            children: FuelType.values
                .map(
                  (fuel) => ChoiceChip(
                    label: Text(fuel.label),
                    selected: fuel == selectedFuel,
                    onSelected: (isSelected) {
                      if (isSelected) {
                        onFuelChanged(fuel);
                      }
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GasStationFilterBar._rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}
