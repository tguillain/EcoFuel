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
///
/// Sliver destiné à la feuille posée sur la carte : les premières cartes y
/// forment un bloc à part, que la feuille mesure pour ne montrer qu'elles
/// une fois repliée. Les suivantes se construisent à la demande.
class GasStationCardList extends StatelessWidget {
  const GasStationCardList({
    super.key,
    required this.groups,
    required this.fuel,
    required this.onStationTap,
    required this.peekKey,
    this.peekCount = 2,
    this.updatedAt,
  });

  /// Marges de la liste. Le haut est réduit : la poignée de la feuille, juste
  /// au-dessus, fait déjà respirer la première carte.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(16, 2, 16, 14);

  /// Jamais vide : l'appelant affiche un état vide à la place.
  final List<GasStationGroup> groups;
  final FuelType fuel;
  final GasStationTapCallback onStationTap;

  /// Posée sur le bloc des [peekCount] premières cartes, marge haute
  /// comprise.
  final Key peekKey;

  /// Stations visibles sur la carte, feuille repliée, comme sur l'artboard
  /// « Carte · cartes flottantes ».
  final int peekCount;

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

    Widget buildCard(GasStationGroup group) {
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
    }

    final int shown = groups.length < peekCount ? groups.length : peekCount;
    final List<GasStationGroup> others = groups.sublist(shown);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            key: peekKey,
            padding: _padding.copyWith(bottom: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in groups.take(shown)) buildCard(group),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: _padding.copyWith(top: 0),
          sliver: SliverList.builder(
            // Une entrée de plus que de cartes : les crédits ferment la liste.
            itemCount: others.length + 1,
            itemBuilder: (context, index) {
              if (index == others.length) {
                return GasStationListAttribution(updatedAt: updatedAt);
              }

              return buildCard(others[index]);
            },
          ),
        ),
      ],
    );
  }
}
