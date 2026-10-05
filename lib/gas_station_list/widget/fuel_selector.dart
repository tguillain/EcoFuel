import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/widget/filter_pill.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Piste segmentée des carburants : un choix unique dans un ensemble fermé,
/// d'où les largeurs égales.
class FuelSelector extends StatelessWidget {
  const FuelSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const double _trackPadding = 3;
  static const double _trackRadius = 11;
  static const double _pillRadius = 9;
  static const EdgeInsets _pillPadding = EdgeInsets.all(8);

  final FuelType selected;
  final ValueChanged<FuelType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_trackPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(_trackRadius),
      ),
      child: Row(
        children: [
          for (final fuel in FuelType.values)
            Expanded(
              child: FilterPill(
                label: fuel.label,
                isSelected: fuel == selected,
                radius: _pillRadius,
                padding: _pillPadding,
                // La piste porte déjà un fond : une pastille non sélectionnée
                // doit rester transparente pour ne pas s'en détacher.
                background: Colors.transparent,
                foreground: AppColors.onSurfaceMuted,
                onTap: () => onSelected(fuel),
              ),
            ),
        ],
      ),
    );
  }
}
