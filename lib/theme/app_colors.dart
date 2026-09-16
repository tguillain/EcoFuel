import 'package:flutter/material.dart';

/// Valeurs reprises telles quelles de l'artboard « Liste seule · cartes +
/// filtres » du design Prix Essence.
abstract final class AppColors {
  static const Color primary = Color.fromRGBO(10, 132, 255, 1);
  static const Color onPrimary = Color.fromRGBO(255, 255, 255, 1);

  /// Fond de l'écran, sous le panneau d'en-tête blanc.
  static const Color background = Color.fromRGBO(242, 241, 236, 1);

  static const Color surface = Color.fromRGBO(255, 255, 255, 1);
  static const Color onSurface = Color.fromRGBO(14, 18, 17, 1);

  /// Piste du sélecteur de carburant, pastilles de tri non sélectionnées et
  /// bouton de rayon.
  static const Color surfaceMuted = Color.fromRGBO(240, 238, 231, 1);

  /// Libellé d'un carburant non sélectionné.
  static const Color onSurfaceMuted = Color.fromRGBO(107, 106, 100, 1);

  /// Libellé d'une pastille de tri non sélectionnée.
  static const Color onSurfaceSubtle = Color.fromRGBO(85, 84, 79, 1);

  /// Surtitre du compteur et informations secondaires des cartes.
  static const Color onSurfaceFaint = Color.fromRGBO(138, 137, 131, 1);
}
