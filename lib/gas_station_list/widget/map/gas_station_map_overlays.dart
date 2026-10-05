import 'package:flutter/material.dart';

/// Commandes posées sur la carte : les favoris en bas à gauche, le recentrage
/// en miroir en bas à droite.
///
/// Seuls ses enfants captent les gestes : le reste de la surface laisse passer
/// glissements et zooms jusqu'à la carte.
class GasStationMapOverlays extends StatelessWidget {
  const GasStationMapOverlays({
    super.key,
    required this.onRecenter,
    this.onFavoritesTap,
  });

  final VoidCallback onRecenter;

  /// Ouvre l'écran des favoris ; sans lui, pas de bouton.
  final VoidCallback? onFavoritesTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // =============================
        // FAVORIS
        // =============================
        if (onFavoritesTap != null)
          Positioned(
            left: 16,
            bottom: 0,
            child: FloatingActionButton.small(
              heroTag: 'mapFavoritesButton',
              tooltip: 'Mes favoris',
              onPressed: onFavoritesTap,
              child: const Icon(Icons.star_rounded),
            ),
          ),

        // =============================
        // RECENTRER
        // =============================
        Positioned(
          right: 16,
          bottom: 0,
          child: FloatingActionButton.small(
            heroTag: 'mapCenterButton',
            tooltip: 'Recentrer',
            onPressed: onRecenter,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
