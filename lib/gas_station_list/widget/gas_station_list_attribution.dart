import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// La licence ODbL d'OpenStreetMap impose de créditer les contributeurs dès
/// lors qu'on affiche leurs données — ici les enseignes des stations. L'heure
/// du dernier chargement les accompagne, faute de barre supérieure depuis que
/// l'en-tête suit le design.
class GasStationListAttribution extends StatelessWidget {
  const GasStationListAttribution({super.key, this.updatedAt});

  final DateTime? updatedAt;

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final time = updatedAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      child: Text(
        [
          if (time != null)
            'Mis à jour à ${_twoDigits(time.hour)}:${_twoDigits(time.minute)}',
          'Prix : data.economie.gouv.fr',
          'Enseignes : © les contributeurs OpenStreetMap',
        ].join(' · '),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceFaint),
      ),
    );
  }
}
