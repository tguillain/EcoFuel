import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Pastille de la barre de filtres : inversée quand elle est sélectionnée,
/// sombre sur clair, claire sur sombre.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
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
