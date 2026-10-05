import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/widget/search_radius_button.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Rappelle où porte la recherche et permet d'en changer. Le point bleu
/// reprend celui de l'utilisateur sur la carte ; une épingle le remplace
/// autour d'un lieu cherché, qu'une croix permet d'abandonner.
class MapLocationPill extends StatelessWidget {
  const MapLocationPill({
    super.key,
    required this.radius,
    required this.onTap,
    this.placeName,
    this.onCleared,
  });

  static const double _radius = 16;
  static const double _dotSize = 7;

  final SearchRadius radius;
  final String? placeName;
  final VoidCallback onTap;
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    final String? placeName = this.placeName;
    final BorderRadius borderRadius = BorderRadius.circular(_radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [SearchRadiusButton.floatingShadow],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              15,
              13,
              onCleared == null ? 15 : 4,
              13,
            ),
            child: Row(
              spacing: 9,
              children: [
                if (placeName == null)
                  Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const Icon(Icons.place, size: 16, color: AppColors.primary),
                Expanded(
                  child: Text(
                    placeName == null
                        ? 'Autour de moi · ${radius.label}'
                        : '$placeName · ${radius.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                if (onCleared != null)
                  IconButton(
                    onPressed: onCleared,
                    tooltip: 'Revenir à ma position',
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 24,
                    ),
                  )
                else
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.onSurfaceMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
