import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Carburant et tri, aux valeurs de l'artboard « Liste seule · cartes +
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
  });

  static const double _rowGap = 14;

  final GasStationSortCriterion sortCriterion;
  final FuelType selectedFuel;
  final ValueChanged<GasStationSortCriterion> onSortChanged;
  final ValueChanged<FuelType> onFuelChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _rowGap,
      children: [
        _FuelSelector(selected: selectedFuel, onSelected: onFuelChanged),
        _SortPills(selected: sortCriterion, onSelected: onSortChanged),
      ],
    );
  }
}

class _FuelSelector extends StatelessWidget {
  const _FuelSelector({required this.selected, required this.onSelected});

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
              child: _Pill(
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
      child: _Pill(
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

class _SortPills extends StatelessWidget {
  const _SortPills({required this.selected, required this.onSelected});

  /// Le design arrondit complètement ces pastilles (`border-radius: 999px`).
  static const double _pillRadius = 999;
  static const double _gap = 8;
  static const EdgeInsets _pillPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 7,
  );

  final GasStationSortCriterion selected;
  final ValueChanged<GasStationSortCriterion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: [
        for (final criterion in GasStationSortCriterion.values)
          _Pill(
            label: criterion.label,
            isSelected: criterion == selected,
            radius: _pillRadius,
            padding: _pillPadding,
            foreground: context.colors.onSurfaceSubtle,
            onTap: () => onSelected(criterion),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.radius,
    required this.padding,
    required this.foreground,
    this.onTap,
    this.trailingIcon,
    this.background,
  });

  final String label;
  final bool isSelected;
  final double radius;
  final EdgeInsets padding;
  final Color foreground;

  /// Fond d'une pastille non sélectionnée ; par défaut celui des pastilles
  /// de tri.
  final Color? background;

  /// Absent quand un parent capte déjà le tap, comme un menu.
  final VoidCallback? onTap;

  /// Signale un menu derrière la pastille.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final Color color = isSelected ? context.colors.onSelected : foreground;
    final IconData? icon = trailingIcon;

    final Widget content = Padding(
      padding: padding,
      // `widthFactor: 1` fait suivre au fond la largeur du libellé quand
      // les contraintes sont lâches (pastilles de tri), sans empêcher de
      // remplir une largeur imposée (piste segmentée).
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        // Réduit le libellé au lieu de le tronquer sur écran étroit ou en
        // grande taille de texte.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
              if (icon != null) Icon(icon, size: 15, color: color),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected
            ? context.colors.selected
            : background ?? context.colors.surfaceMuted,
        borderRadius: borderRadius,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: borderRadius, child: content),
      ),
    );
  }
}
