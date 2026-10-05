import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Bouton carré ouvrant le choix du rayon de recherche.
///
/// Sur la liste, il se fond dans le panneau blanc de l'en-tête ; sur la carte,
/// il flotte, blanc et ombré, comme les autres commandes de l'artboard
/// « Carte · cartes flottantes ».
class SearchRadiusButton extends StatelessWidget {
  const SearchRadiusButton({
    super.key,
    required this.selectedRadius,
    required this.onRadiusChanged,
    this.isFloating = false,
  });

  static const double _flatSize = 42;
  static const double _flatRadius = 12;
  static const double _floatingSize = 46;
  static const double _floatingRadius = 16;

  static const BoxShadow floatingShadow = BoxShadow(
    color: Color.fromRGBO(14, 18, 17, .3),
    offset: Offset(0, 6),
    blurRadius: 18,
    spreadRadius: -8,
  );

  final SearchRadius selectedRadius;
  final ValueChanged<SearchRadius> onRadiusChanged;
  final bool isFloating;

  @override
  Widget build(BuildContext context) {
    final double size = isFloating ? _floatingSize : _flatSize;

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
        // PopupMenuButton déborderait du carré.
        padding: EdgeInsets.zero,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFloating ? AppColors.surface : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(
              isFloating ? _floatingRadius : _flatRadius,
            ),
            boxShadow: isFloating ? const [floatingShadow] : null,
          ),
          child: Icon(
            Icons.my_location_rounded,
            size: isFloating ? 16 : 15,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
