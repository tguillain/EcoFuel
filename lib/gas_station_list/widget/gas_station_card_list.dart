import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/gas_station_group.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_list_attribution.dart';
import 'package:flutter/material.dart';

/// Appelée au clic sur une carte, avec la station et le fait qu'elle soit la
/// moins chère de la liste.
typedef GasStationTapCallback = void Function(
  GasStation station, {
  required bool isCheapest,
});

/// Cartes des stations, la moins chère mise en avant, les crédits en pied.
class GasStationCardList extends StatelessWidget {
  const GasStationCardList({
    super.key,
    required this.groups,
    required this.fuel,
    required this.onStationTap,
    this.updatedAt,
  });

  /// Métriques de l'artboard « Liste seule · cartes + filtres » : la liste
  /// respire davantage que le panneau d'en-tête.
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  /// Jamais vide : l'appelant affiche un état vide à la place.
  final List<GasStationGroup> groups;
  final FuelType fuel;
  final GasStationTapCallback onStationTap;
  final DateTime? updatedAt;

  /// Deux sites de la même enseigne dans la même commune n'affichent aucune
  /// différence : mêmes titre, ville et horaires, et des distances qui
  /// s'arrondissent souvent au même dixième. La liste est seule à pouvoir le
  /// constater, puisqu'elle voit toutes les cartes.
  static Set<String> _collidingLabels(List<GasStationGroup> groups) {
    final seen = <String>{};
    final colliding = <String>{};

    for (final group in groups) {
      if (!seen.add(_labelOf(group))) {
        colliding.add(_labelOf(group));
      }
    }

    return colliding;
  }

  static String _labelOf(GasStationGroup group) =>
      '${GasStationCard.titleFor(group.representative)}'
      '|${group.representative.city}';

  String get _cheapestId => groups
      .map((group) => group.representative)
      .reduce(
        (cheapest, station) =>
            station.priceFor(fuel)! < cheapest.priceFor(fuel)!
            ? station
            : cheapest,
      )
      .id;

  @override
  Widget build(BuildContext context) {
    final cheapestId = _cheapestId;
    final colliding = _collidingLabels(groups);

    return ListView.builder(
      padding: _padding,
      // Une entrée de plus que de cartes : les crédits ferment la liste.
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == groups.length) {
          return GasStationListAttribution(updatedAt: updatedAt);
        }

        final group = groups[index];
        final station = group.representative;
        final key = ValueKey(station.id);
        final showAddress = colliding.contains(_labelOf(group));
        final isCheapest = station.id == cheapestId;

        void onTap() => onStationTap(station, isCheapest: isCheapest);

        if (isCheapest) {
          return GasStationCard.highlighted(
            station,
            fuel: fuel,
            key: key,
            onTap: onTap,
            showAddress: showAddress,
            pointCount: group.pointCount,
          );
        }

        return GasStationCard.standard(
          station,
          fuel: fuel,
          key: key,
          onTap: onTap,
          showAddress: showAddress,
          pointCount: group.pointCount,
        );
      },
    );
  }
}
