import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter/material.dart';

/// Couleur du marqueur d'une station sur la carte.
///
/// Seul un prix bas est coloré : le vert signale les stations qui valent le
/// détour, tout le reste reste gris. Colorer aussi les stations chères ferait
/// trois familles de couleurs à comparer alors que l'utilisateur ne cherche
/// que les moins chères.
///
/// La distance n'intervient pas ici : elle est déjà lisible sur la carte par
/// la position du marqueur, la couleur ne parle que du prix.
enum StationMarkerColor {
  /// Le prix le plus bas parmi les stations affichées.
  best(Color.fromRGBO(27, 94, 32, 1)),

  /// À quelques centimes du meilleur prix : encore intéressant.
  cheap(Color.fromRGBO(67, 160, 71, 1)),

  /// Tout le reste, y compris les stations sans prix connu.
  regular(Color.fromRGBO(117, 124, 130, 1));

  const StationMarkerColor(this.color);

  final Color color;

  /// Écart maximal avec le meilleur prix, en euros par litre, au-delà duquel
  /// une station n'est plus mise en avant.
  static const double _cheapThreshold = 0.03;

  /// Tolérance d'égalité : deux stations au même prix affiché doivent être
  /// vertes toutes les deux, malgré les arrondis en virgule flottante.
  static const double _tiePrecision = 0.001;

  bool get isHighlighted => this != StationMarkerColor.regular;

  static StationMarkerColor forStation({
    required GasStation station,
    required List<GasStation> stations,
    required FuelType fuel,
  }) {
    final double? price = station.priceFor(fuel);

    if (price == null) {
      return StationMarkerColor.regular;
    }

    final double? cheapestPrice = _cheapestPrice(stations, fuel);

    if (cheapestPrice == null) {
      return StationMarkerColor.regular;
    }

    final double difference = price - cheapestPrice;

    if (difference <= _tiePrecision) {
      return StationMarkerColor.best;
    }

    if (difference <= _cheapThreshold) {
      return StationMarkerColor.cheap;
    }

    return StationMarkerColor.regular;
  }

  static double? _cheapestPrice(List<GasStation> stations, FuelType fuel) {
    final List<double> prices = stations
        .map((station) => station.priceFor(fuel))
        .whereType<double>()
        .toList();

    if (prices.isEmpty) {
      return null;
    }

    return prices.reduce((a, b) => a < b ? a : b);
  }
}
