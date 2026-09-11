import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_filter_bar.dart';
import 'package:flutter/material.dart';

class GasStationList extends StatefulWidget {
  const GasStationList({
    super.key,
    required this.stations,
    this.highlightedStationId,
  });

  final List<GasStation> stations;
  final String? highlightedStationId;

  @override
  State<GasStationList> createState() => _GasStationListState();
}

class _GasStationListState extends State<GasStationList> {
  FuelType _selectedFuel = FuelType.e10;
  GasStationSortCriterion _sortCriterion = GasStationSortCriterion.distance;
  late List<GasStation> _sortedStations;

  @override
  void initState() {
    super.initState();
    _sortedStations = _sorted();
  }

  List<GasStation> _sorted() {
    final stations = [...widget.stations];
    stations.sort(_sortCriterion.comparator);

    return stations;
  }

  void _onSortChanged(GasStationSortCriterion criterion) {
    setState(() {
      _sortCriterion = criterion;
      _sortedStations = _sorted();
    });
  }

  void _onFuelChanged(FuelType fuel) {
    setState(() {
      _selectedFuel = fuel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station List'),
        bottom: GasStationFilterBar(
          sortCriterion: _sortCriterion,
          selectedFuel: _selectedFuel,
          onSortChanged: _onSortChanged,
          onFuelChanged: _onFuelChanged,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _sortedStations.length,
        itemBuilder: (context, index) {
          final station = _sortedStations[index];
          final key = ValueKey(station.id);

          if (station.id == widget.highlightedStationId) {
            return GasStationCard.highlighted(station, key: key);
          } else {
            return GasStationCard.standard(station, key: key);
          }
        },
      ),
    );
  }
}
