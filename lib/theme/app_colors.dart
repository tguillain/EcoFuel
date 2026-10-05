import 'package:flutter/material.dart';

/// Palette de l'application, en clair et en sombre.
///
/// Les valeurs claires reprennent l'artboard « Liste seule · cartes +
/// filtres » du design Prix Essence ; les sombres en gardent les rôles et les
/// contrastes. Les widgets la lisent par `context.colors`, jamais en dur :
/// elle change avec le thème du téléphone.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.surfaceMuted,
    required this.onSurfaceMuted,
    required this.onSurfaceSubtle,
    required this.onSurfaceFaint,
    required this.outline,
    required this.divider,
    required this.selected,
    required this.onSelected,
    required this.shadow,
  });

  static const AppColors light = AppColors(
    primary: Color.fromRGBO(10, 132, 255, 1),
    onPrimary: Color.fromRGBO(255, 255, 255, 1),
    background: Color.fromRGBO(242, 241, 236, 1),
    surface: Color.fromRGBO(255, 255, 255, 1),
    onSurface: Color.fromRGBO(14, 18, 17, 1),
    surfaceMuted: Color.fromRGBO(240, 238, 231, 1),
    onSurfaceMuted: Color.fromRGBO(107, 106, 100, 1),
    onSurfaceSubtle: Color.fromRGBO(85, 84, 79, 1),
    onSurfaceFaint: Color.fromRGBO(138, 137, 131, 1),
    outline: Color.fromRGBO(228, 226, 219, 1),
    divider: Color.fromRGBO(236, 234, 227, 1),
    selected: Color.fromRGBO(14, 18, 17, 1),
    onSelected: Color.fromRGBO(255, 255, 255, 1),
    shadow: Color.fromRGBO(14, 18, 17, 1),
  );

  /// Les surfaces s'éclaircissent à mesure qu'elles montent, comme sur
  /// iOS : le fond est le plus sombre, les cartes et panneaux un cran
  /// au-dessus, les pistes et pastilles encore un cran.
  static const AppColors dark = AppColors(
    primary: Color.fromRGBO(10, 132, 255, 1),
    onPrimary: Color.fromRGBO(255, 255, 255, 1),
    background: Color.fromRGBO(16, 18, 20, 1),
    surface: Color.fromRGBO(30, 33, 36, 1),
    onSurface: Color.fromRGBO(244, 243, 239, 1),
    surfaceMuted: Color.fromRGBO(44, 48, 52, 1),
    onSurfaceMuted: Color.fromRGBO(168, 167, 159, 1),
    onSurfaceSubtle: Color.fromRGBO(196, 195, 188, 1),
    onSurfaceFaint: Color.fromRGBO(138, 137, 131, 1),
    outline: Color.fromRGBO(52, 56, 60, 1),
    divider: Color.fromRGBO(44, 48, 52, 1),
    selected: Color.fromRGBO(244, 243, 239, 1),
    onSelected: Color.fromRGBO(14, 18, 17, 1),
    shadow: Color.fromRGBO(0, 0, 0, 1),
  );

  final Color primary;
  final Color onPrimary;

  /// Fond de l'écran, sous le panneau d'en-tête.
  final Color background;

  final Color surface;
  final Color onSurface;

  /// Piste du sélecteur de carburant, pastilles de tri non sélectionnées et
  /// bouton de rayon.
  final Color surfaceMuted;

  /// Libellé d'un carburant non sélectionné.
  final Color onSurfaceMuted;

  /// Libellé d'une pastille de tri non sélectionnée.
  final Color onSurfaceSubtle;

  /// Surtitre du compteur et informations secondaires des cartes.
  final Color onSurfaceFaint;

  /// Bordure séparant les panneaux de la fiche station.
  final Color outline;

  /// Filet entre deux lignes de prix de la fiche station.
  final Color divider;

  /// Fond d'une pastille sélectionnée : sombre sur clair, clair sur sombre.
  final Color selected;
  final Color onSelected;

  /// Teinte des ombres portées, que chaque ombre dose par son opacité.
  final Color shadow;

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? surfaceMuted,
    Color? onSurfaceMuted,
    Color? onSurfaceSubtle,
    Color? onSurfaceFaint,
    Color? outline,
    Color? divider,
    Color? selected,
    Color? onSelected,
    Color? shadow,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      onSurfaceSubtle: onSurfaceSubtle ?? this.onSurfaceSubtle,
      onSurfaceFaint: onSurfaceFaint ?? this.onSurfaceFaint,
      outline: outline ?? this.outline,
      divider: divider ?? this.divider,
      selected: selected ?? this.selected,
      onSelected: onSelected ?? this.onSelected,
      shadow: shadow ?? this.shadow,
    );
  }

  /// Fondu entre les deux palettes quand le thème bascule.
  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) {
      return this;
    }

    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppColors(
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      onSurface: mix(onSurface, other.onSurface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      onSurfaceMuted: mix(onSurfaceMuted, other.onSurfaceMuted),
      onSurfaceSubtle: mix(onSurfaceSubtle, other.onSurfaceSubtle),
      onSurfaceFaint: mix(onSurfaceFaint, other.onSurfaceFaint),
      outline: mix(outline, other.outline),
      divider: mix(divider, other.divider),
      selected: mix(selected, other.selected),
      onSelected: mix(onSelected, other.onSelected),
      shadow: mix(shadow, other.shadow),
    );
  }
}

/// Palette du thème courant. Hors d'un thème de l'application, comme dans un
/// test qui pompe un widget seul, retombe sur la palette claire.
extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
