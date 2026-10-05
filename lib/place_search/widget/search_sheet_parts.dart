import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Le lieu retenu, avec de quoi revenir à la position de l'utilisateur.
class ChosenPlace extends StatelessWidget {
  const ChosenPlace({super.key, required this.place, this.onReset});

  final SearchPlace? place;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final SearchPlace? place = this.place;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 10,
        children: [
          Icon(
            place == null ? Icons.my_location : Icons.place,
            color: AppColors.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place?.name ?? 'Autour de moi',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  place?.context ?? 'Ma position actuelle',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onReset != null)
            TextButton(onPressed: onReset, child: const Text('Autour de moi')),
        ],
      ),
    );
  }
}

class SearchSubmitBar extends StatelessWidget {
  const SearchSubmitBar({super.key, required this.onPressed});

  /// `null` pendant la saisie : le lieu tapé n'est pas encore choisi.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Voir les stations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
