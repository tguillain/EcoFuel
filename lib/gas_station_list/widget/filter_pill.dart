import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Pastille de la barre de filtres : sombre quand elle est sélectionnée.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.radius,
    required this.padding,
    required this.foreground,
    required this.onTap,
    this.background = AppColors.surfaceMuted,
  });

  final String label;
  final bool isSelected;
  final double radius;
  final EdgeInsets padding;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.onSurface : background,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
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
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.onPrimary : foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
