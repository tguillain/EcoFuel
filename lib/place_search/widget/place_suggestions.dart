import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:ecofuel/place_search/service/place_search_service.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Lieux proposés pour le texte tapé, ou ce qui empêche d'en proposer.
class PlaceSuggestions extends StatelessWidget {
  const PlaceSuggestions({
    super.key,
    required this.query,
    required this.places,
    required this.isLoading,
    required this.hasFailed,
    required this.onSelected,
  });

  final String query;
  final List<SearchPlace> places;
  final bool isLoading;
  final bool hasFailed;
  final ValueChanged<SearchPlace> onSelected;

  @override
  Widget build(BuildContext context) {
    if (hasFailed) {
      return const _Hint(
        'La recherche n\'a pas abouti. Vérifie ta connexion et réessaie.',
      );
    }

    if (query.trim().length < PlaceSearchService.minQueryLength) {
      return const _Hint(
        'Tape au moins 3 lettres d\'une ville ou une adresse.',
      );
    }

    if (places.isEmpty) {
      return isLoading
          ? const SizedBox.shrink()
          : const _Hint('Aucun lieu trouvé. Essaie un autre nom.');
    }

    return ListView(
      children: [
        for (final place in places)
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(place.name),
            subtitle: place.context == null ? null : Text(place.context!),
            onTap: () => onSelected(place),
          ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.onSurfaceMuted),
      ),
    );
  }
}
