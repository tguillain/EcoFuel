import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Fond, ombre et coins de la feuille des stations.
///
/// Repliée sur la carte, la feuille n'a ni fond ni ombre : ses cartes
/// flottent. Déployée, elle couvre la carte jusque dans ses angles, sans
/// laisser deux pointes de carte sous l'en-tête.
class SheetSurface extends StatelessWidget {
  const SheetSurface({
    super.key,
    required this.opacity,
    required this.squareness,
    required this.child,
  });

  static const double _radius = 22;

  /// Opacité du fond et de l'ombre, de 0 (cartes flottantes) à 1.
  final double opacity;

  /// De 0 (coins arrondis) à 1 (coins carrés).
  final double squareness;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.vertical(
      top: Radius.circular(_radius * (1 - squareness)),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: opacity),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(14, 18, 17, .25 * opacity),
            offset: const Offset(0, -6),
            blurRadius: 24,
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}
