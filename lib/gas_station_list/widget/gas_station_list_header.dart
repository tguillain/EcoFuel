import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/widget/search_radius_button.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Surtitre, compteur, et bouton de rayon à droite, aux valeurs de l'artboard
/// « Liste seule · cartes + filtres ».
class GasStationListHeader extends StatelessWidget {
  const GasStationListHeader({
    super.key,
    required this.selectedRadius,
    required this.onRadiusChanged,
    required this.title,
    this.placeName,
    this.onPlaceTap,
  });

  static const double _gap = 3;

  final SearchRadius selectedRadius;
  final ValueChanged<SearchRadius> onRadiusChanged;
  final String title;

  /// Lieu cherché à la place de la position de l'utilisateur ; `null`
  /// autour de lui.
  final String? placeName;

  /// Ouvre la recherche de lieu, depuis le surtitre qui le nomme.
  final VoidCallback? onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: _gap,
            children: [
              _PlaceEyebrow(
                text:
                    'Autour de ${placeName ?? 'moi'} · ${selectedRadius.label}'
                        .toUpperCase(),
                onTap: onPlaceTap,
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 22 * -0.025,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        SearchRadiusButton(
          selectedRadius: selectedRadius,
          onRadiusChanged: onRadiusChanged,
        ),
      ],
    );
  }
}

/// Surtitre qui nomme le lieu de recherche et, au tap, permet d'en changer.
class _PlaceEyebrow extends StatelessWidget {
  const _PlaceEyebrow({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = GoogleFonts.ibmPlexMono(
      fontSize: 11,
      letterSpacing: 11 * 0.12,
      color: onTap == null ? AppColors.onSurfaceFaint : AppColors.primary,
    );

    final Widget label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    if (onTap == null) {
      return label;
    }

    return Semantics(
      button: true,
      label: 'Changer le lieu de recherche',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Flexible(child: label),
            Icon(Icons.search, size: 13, color: style.color),
          ],
        ),
      ),
    );
  }
}
