import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/widget/filter_pill.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Piste segmentée des carburants : un choix unique dans un ensemble fermé,
/// d'où les largeurs égales. Les trois carburants les plus distribués y sont
/// en accès direct, les autres derrière la quatrième case.
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
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(_trackRadius),
      ),
      child: Row(
        children: [
          for (final fuel in FuelType.popular)
            Expanded(
              child: FilterPill(
                label: fuel.label,
                isSelected: fuel == selected,
                radius: _pillRadius,
                padding: _pillPadding,
                // La piste porte déjà un fond : une pastille non sélectionnée
                // doit rester transparente pour ne pas s'en détacher.
                background: Colors.transparent,
                foreground: context.colors.onSurfaceMuted,
                onTap: () => onSelected(fuel),
              ),
            ),
          Expanded(
            child: _OtherFuelsPill(
              selected: selected,
              radius: _pillRadius,
              padding: _pillPadding,
              onSelected: onSelected,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quatrième case de la piste : les carburants moins distribués, derrière un
/// menu. Elle affiche celui qui est choisi, ou « Autres » tant qu'aucun ne
/// l'est.
class _OtherFuelsPill extends StatelessWidget {
  const _OtherFuelsPill({
    required this.selected,
    required this.radius,
    required this.padding,
    required this.onSelected,
  });

  final FuelType selected;
  final double radius;
  final EdgeInsets padding;
  final ValueChanged<FuelType> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = !selected.isPopular;

    return PopupMenuButton<FuelType>(
      initialValue: isSelected ? selected : null,
      onSelected: onSelected,
      tooltip: 'Autres carburants',
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        for (final fuel in FuelType.others)
          PopupMenuItem<FuelType>(value: fuel, child: Text(fuel.label)),
      ],
      // Le menu capte le tap : la pastille ne fait que se dessiner.
      child: FilterPill(
        label: isSelected ? selected.label : 'Autres',
        trailingIcon: Icons.expand_more,
        isSelected: isSelected,
        radius: radius,
        padding: padding,
        background: Colors.transparent,
        foreground: context.colors.onSurfaceMuted,
      ),
    );
  }
}
