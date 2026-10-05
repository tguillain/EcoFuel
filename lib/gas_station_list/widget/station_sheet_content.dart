import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station_group.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card_list.dart';
import 'package:ecofuel/gas_station_list/widget/message_state.dart';
import 'package:flutter/material.dart';

/// Contenu de la feuille des stations : indicateur de chargement, état vide,
/// ou les cartes des stations.
///
/// Sliver, posé sous la poignée de la feuille. [peekKey] désigne dans chaque
/// cas ce que la feuille repliée doit laisser voir.
class StationSheetContent extends StatelessWidget {
  const StationSheetContent({
    super.key,
    required this.isLoading,
    required this.groups,
    required this.fuel,
    required this.radius,
    required this.peekKey,
    required this.onRetry,
    required this.onStationTap,
    this.updatedAt,
  });

  static const double _loadingHeight = 120;

  final bool isLoading;
  final List<GasStationGroup> groups;
  final FuelType fuel;
  final SearchRadius radius;
  final Key peekKey;
  final VoidCallback onRetry;
  final GasStationTapCallback onStationTap;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SliverToBoxAdapter(
        child: SizedBox(
          key: peekKey,
          height: _loadingHeight,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (groups.isEmpty) {
      return SliverToBoxAdapter(
        child: KeyedSubtree(
          key: peekKey,
          child: MessageState(
            icon: Icons.local_gas_station_outlined,
            message:
                'Aucune station proposant du ${fuel.label} '
                'dans un rayon de ${radius.label}.',
            onRetry: onRetry,
          ),
        ),
      );
    }

    return GasStationCardList(
      groups: groups,
      fuel: fuel,
      peekKey: peekKey,
      updatedAt: updatedAt,
      onStationTap: onStationTap,
    );
  }
}
