import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station_group.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card_list.dart';
import 'package:ecofuel/gas_station_list/widget/message_state.dart';
import 'package:flutter/material.dart';

/// Liste des stations, ou état vide quand aucune ne propose le carburant.
///
/// Le tiré-pour-rafraîchir remplace le bouton Actualiser de l'ancienne
/// AppBar : il doit rester atteignable même sans station à faire défiler.
class RefreshableStationList extends StatelessWidget {
  const RefreshableStationList({
    super.key,
    required this.groups,
    required this.fuel,
    required this.radius,
    required this.onRefresh,
    required this.onStationTap,
    this.updatedAt,
  });

  final List<GasStationGroup> groups;
  final FuelType fuel;
  final SearchRadius radius;
  final Future<void> Function() onRefresh;
  final GasStationTapCallback onStationTap;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: groups.isEmpty
          ? MessageState(
              icon: Icons.local_gas_station_outlined,
              message:
                  'Aucune station proposant du ${fuel.label} '
                  'dans un rayon de ${radius.label}.',
              onRetry: onRefresh,
              isScrollable: true,
            )
          : GasStationCardList(
              groups: groups,
              fuel: fuel,
              updatedAt: updatedAt,
              onStationTap: onStationTap,
            ),
    );
  }
}
