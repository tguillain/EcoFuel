import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/gas_station_sort_criterion.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter/material.dart';

/// Gère la couleur des marqueurs selon le critère choisi.
///
/// Si le tri est sur PRIX :
/// - vert = station la moins chère
/// - orange = prix intermédiaire
/// - rouge = station plus chère
///
/// Si le tri est sur DISTANCE :
/// - vert = station proche
/// - orange = distance intermédiaire
/// - rouge = station plus éloignée
class StationMarkerColor {
  const StationMarkerColor._();

  static Color forStation({
    required GasStation station,
    required List<GasStation> stations,
    required FuelType fuel,
    required GasStationSortCriterion sortCriterion,
  }) {
    if (sortCriterion == GasStationSortCriterion.distance) {
      return _forDistance(
        station: station,
        stations: stations,
      );
    }

    return _forPrice(
      station: station,
      stations: stations,
      fuel: fuel,
    );
  }

  /// Couleur basée sur le prix.
  static Color _forPrice({
    required GasStation station,
    required List<GasStation> stations,
    required FuelType fuel,
  }) {
    final double? stationPrice =
        station.priceFor(fuel);

    if (stationPrice == null) {
      return Colors.grey;
    }

    final List<double> prices = stations
        .map(
          (station) => station.priceFor(fuel),
        )
        .whereType<double>()
        .toList();

    if (prices.isEmpty) {
      return Colors.grey;
    }

    final double cheapestPrice =
        prices.reduce(
      (a, b) => a < b ? a : b,
    );

    final double difference =
        stationPrice - cheapestPrice;

    // Meilleur prix.
    if (difference <= 0.001) {
      return Colors.green.shade800;
    }

    // Jusqu'à 3 centimes de plus.
    if (difference <= 0.03) {
      return Colors.green.shade500;
    }

    // Jusqu'à 8 centimes de plus.
    if (difference <= 0.08) {
      return Colors.orange.shade700;
    }

    // Plus cher.
    return Colors.red.shade700;
  }

  /// Couleur basée sur la distance.
  static Color _forDistance({
    required GasStation station,
    required List<GasStation> stations,
  }) {
    if (stations.isEmpty) {
      return Colors.grey;
    }

    final List<GasStation> sortedStations =
        List<GasStation>.from(
      stations,
    );

    sortedStations.sort(
      (a, b) => a.distanceInKm.compareTo(
        b.distanceInKm,
      ),
    );

    final int index =
        sortedStations.indexWhere(
      (item) => item.id == station.id,
    );

    if (index == -1) {
      return Colors.grey;
    }

    // Station la plus proche.
    if (index == 0) {
      return Colors.green.shade800;
    }

    final double position =
        (index + 1) /
            sortedStations.length;

    // Premier tiers = proche.
    if (position <= 0.33) {
      return Colors.green.shade500;
    }

    // Deuxième tiers.
    if (position <= 0.66) {
      return Colors.orange.shade700;
    }

    // Dernier tiers = loin.
    return Colors.red.shade700;
  }
}