import 'package:ecofuel/gas_station_list/enum/display_mode.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Bascule liste / carte, au gabarit du bouton de rayon.
///
/// Solution transitoire : l'écran cible superpose la liste à la carte dans une
/// feuille glissante, ce qui rendra ce bouton inutile.
class DisplayModeButton extends StatelessWidget {
  const DisplayModeButton({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  static const double _size = 42;
  static const double _radius = 12;

  final DisplayMode mode;
  final ValueChanged<DisplayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final showsList = mode == DisplayMode.list;

    return Semantics(
      button: true,
      label: showsList ? 'Afficher la carte' : 'Afficher la liste',
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          onTap: () =>
              onChanged(showsList ? DisplayMode.map : DisplayMode.list),
          borderRadius: BorderRadius.circular(_radius),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              showsList ? Icons.map_outlined : Icons.list,
              size: 18,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
