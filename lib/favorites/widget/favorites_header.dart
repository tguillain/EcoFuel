import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/widget/fuel_selector.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// En-tête blanc de l'écran des favoris : retour à la carte, titre et
/// carburant comparé.
class FavoritesHeader extends StatelessWidget {
  const FavoritesHeader({
    super.key,
    required this.count,
    required this.fuel,
    required this.onFuelChanged,
  });

  final int count;
  final FuelType fuel;
  final ValueChanged<FuelType> onFuelChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Carte'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3,
                        children: [
                          Text(
                            '${fuel.label} · $count station'
                                    '${count > 1 ? 's' : ''}'
                                .toUpperCase(),
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 11,
                              letterSpacing: 11 * 0.12,
                              color: AppColors.onSurfaceFaint,
                            ),
                          ),
                          const Text(
                            'Mes favoris',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 28 * -0.025,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      size: 30,
                      color: AppColors.favorite,
                    ),
                  ],
                ),
                FuelSelector(selected: fuel, onSelected: onFuelChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
