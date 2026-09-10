import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:flutter/material.dart';

class GasStationListView extends StatelessWidget {
  const GasStationListView({
    super.key,
    required this.stations,
    this.highlightedStationId,
  });

  final List<GasStation> stations;
  final String? highlightedStationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Station List')),
      body: ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          final key = ValueKey(station.id);

          if (station.id == highlightedStationId) {
            return GasStationCard.highlighted(station, key: key);
          } else {
            return GasStationCard.standard(station, key: key);
          }
        },
      ),
    );
  }
}
