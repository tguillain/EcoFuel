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
        SearchRadiusButton(
          selectedRadius: selectedRadius,
          onRadiusChanged: onRadiusChanged,
        ),
      ],
    );
  }
}
