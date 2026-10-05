import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Étoile qui ajoute une station aux favoris ou l'en retire, posée au-dessus
/// du prix sur les cartes de station.
///
/// Pleine pour une station favorite, en contour sinon. Sur la carte bleue de
/// la meilleure station, elle passe en blanc pour rester lisible.
class FavoriteStarButton extends StatelessWidget {
  const FavoriteStarButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.onPrimary = false,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  /// Vrai sur un fond bleu.
  final bool onPrimary;

  Color get _color {
    if (onPrimary) {
      return AppColors.onPrimary;
    }

    return isFavorite ? AppColors.favorite : AppColors.onSurfaceFaint;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      isSelected: isFavorite,
      icon: Icon(Icons.star_border_rounded, color: _color),
      selectedIcon: Icon(Icons.star_rounded, color: _color),
      iconSize: 24,
      // Cible de 44 px de large, mais à peine plus haute que l'étoile : la
      // carte ne doit pas grandir pour elle.
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 30),
      visualDensity: VisualDensity.compact,
    );
  }
}
