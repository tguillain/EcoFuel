import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/gas_station.dart';

class GasStationCard extends StatelessWidget {
  const GasStationCard._({
    super.key,
    required this.station,
    required this.isHighlighted,
    this.onTap,
  });

  factory GasStationCard.standard(
    GasStation station, {
    Key? key,
    VoidCallback? onTap,
  }) => GasStationCard._(
    key: key,
    station: station,
    isHighlighted: false,
    onTap: onTap,
  );

  factory GasStationCard.highlighted(
    GasStation gasStation, {
    Key? key,
    VoidCallback? onTap,
  }) => GasStationCard._(
    key: key,
    station: gasStation,
    isHighlighted: true,
    onTap: onTap,
  );

  static final NumberFormat _distanceFormat = NumberFormat('0.#', 'fr_FR');

  final GasStation station;
  final bool isHighlighted;
  final VoidCallback? onTap;

  String get _subtitle {
    final distance = '${_distanceFormat.format(station.distanceInKm)} km';

    if (station.openingHours != null) {
      return '$distance - ouvert jusqu\'à ${station.openingHours}h';
    } else {
      return distance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 5,
      color: isHighlighted ? Color.fromRGBO(10, 132, 255, 1) : null,
      shadowColor: isHighlighted ? Color.fromRGBO(10, 132, 255, 1) : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: ListTile(
        textColor: isHighlighted ? colors.onPrimary : null,
        title: Text(station.name),
        subtitle: Text(_subtitle),
        trailing: Text('${station.priceInEuros} €/L'),
        onTap: onTap,
      ),
    );
  }
}
