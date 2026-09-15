import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
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
  });

  static const double _gap = 3;

  final SearchRadius selectedRadius;
  final ValueChanged<SearchRadius> onRadiusChanged;
  final String title;

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
              Text(
                'AUTOUR DE MOI · ${selectedRadius.label.toUpperCase()}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  letterSpacing: 11 * 0.12,
                  color: AppColors.onSurfaceFaint,
                ),
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
        _RadiusButton(
          selectedRadius: selectedRadius,
          onRadiusChanged: onRadiusChanged,
        ),
      ],
    );
  }
}

class _RadiusButton extends StatelessWidget {
  const _RadiusButton({
    required this.selectedRadius,
    required this.onRadiusChanged,
  });

  static const double _size = 42;
  static const double _radius = 12;

  final SearchRadius selectedRadius;
  final ValueChanged<SearchRadius> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Rayon de recherche : ${selectedRadius.label}',
      child: PopupMenuButton<SearchRadius>(
        initialValue: selectedRadius,
        onSelected: onRadiusChanged,
        tooltip: 'Changer le rayon de recherche',
        position: PopupMenuPosition.under,
        itemBuilder: (context) => [
          for (final radius in SearchRadius.values)
            PopupMenuItem<SearchRadius>(
              value: radius,
              child: Text(radius.label),
            ),
        ],
        // Le bouton dessine lui-même son fond : le rembourrage par défaut du
        // PopupMenuButton déborderait du carré de 42 px.
        padding: EdgeInsets.zero,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: const Icon(
            Icons.my_location_rounded,
            size: 15,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
