import 'package:ecofuel/gas_station_list/gas_station_list.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const stations = <GasStation>[
    GasStation(
      id: 'intermarche-reze',
      name: 'Intermarché Rezé',
      priceInEuros: 1.669,
      distanceInKm: 1.2,
      openingHours: '20',
    ),
    GasStation(
      id: 'leclerc-atlantis',
      name: 'Leclerc Atlantis',
      priceInEuros: 1.674,
      distanceInKm: 2.8,
      openingHours: null,
    ),
    GasStation(
      id: 'total-access-pirmil',
      name: 'Total Access Pirmil',
      priceInEuros: 1.712,
      distanceInKm: 0.6,
      openingHours: null,
    ),
    GasStation(
      id: 'avia-saint-herblain',
      name: 'Avia Saint-Herblain',
      priceInEuros: 1.729,
      distanceInKm: 4.1,
      openingHours: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GasStationList(
        stations: stations,
        highlightedStationId: 'intermarche-reze',
      ),
    );
  }
}
