import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Poignée épinglée en tête de la feuille des stations.
///
/// Elle appartient au défilement de la feuille : la saisir et la tirer passe
/// donc par le même geste que la liste, avec l'aimantation de la feuille. Le
/// tap, lui, offre une alternative au glisser pour le clavier et les lecteurs
/// d'écran.
class GasStationSheetHandle extends SliverPersistentHeaderDelegate {
  const GasStationSheetHandle({
    required this.isExpanded,
    required this.background,
    required this.onTap,
  });

  static const double height = 28;
  static const double _barWidth = 36;
  static const double _barHeight = 5;

  /// Vrai quand la feuille recouvre la carte : le tap la replie, sinon il la
  /// déploie.
  final bool isExpanded;

  /// Fond de la feuille sous la poignée, transparent tant que la feuille
  /// flotte sur la carte.
  final Color background;

  final VoidCallback onTap;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Semantics(
      button: true,
      label: isExpanded ? 'Afficher la carte' : 'Afficher la liste',
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Container(
              width: _barWidth,
              height: _barHeight,
              decoration: BoxDecoration(
                // Opaque : sur la carte, la barre doit se détacher des tuiles.
                color: AppColors.onSurfaceFaint,
                borderRadius: BorderRadius.circular(_barHeight / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(GasStationSheetHandle oldDelegate) =>
      isExpanded != oldDelegate.isExpanded ||
      background != oldDelegate.background ||
      onTap != oldDelegate.onTap;
}
