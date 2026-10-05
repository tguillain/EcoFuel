import 'package:flutter/material.dart';

/// En-tête de l'écran des stations : flottant sur la carte, puis panneau
/// blanc de la liste à mesure que la feuille monte.
///
/// Le panneau fixe la hauteur de l'en-tête dans les deux vues : la feuille
/// garde ainsi la même place, sans saut quand l'un remplace l'autre.
class SheetHeaderCrossFade extends StatelessWidget {
  const SheetHeaderCrossFade({
    super.key,
    required this.progress,
    required this.mapHeader,
    required this.listHeader,
  });

  /// L'en-tête flottant s'efface au début de la montée, le panneau de la
  /// liste n'apparaît qu'ensuite : les deux ne se superposent jamais en
  /// pleine opacité.
  static const Interval mapHeaderFade = Interval(0.2, 0.5);
  static const Interval listHeaderFade = Interval(0.5, 1);

  /// Avancement de la feuille, de 0 pour la vue carte à 1 pour la liste.
  final double progress;

  final Widget mapHeader;
  final Widget listHeader;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _fade(listHeaderFade.transform(progress), listHeader),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _fade(1 - mapHeaderFade.transform(progress), mapHeader),
        ),
      ],
    );
  }

  /// Un en-tête à demi effacé ne répond plus : sinon le panneau invisible de
  /// la liste capterait les gestes destinés à la carte.
  static Widget _fade(double opacity, Widget child) {
    final bool isHidden = opacity < 0.5;

    return IgnorePointer(
      ignoring: isHidden,
      child: ExcludeSemantics(
        excluding: isHidden,
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }
}
