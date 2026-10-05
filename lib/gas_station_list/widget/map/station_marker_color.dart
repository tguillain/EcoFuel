import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter/material.dart';

/// Couleur du marqueur d'une station, du vert au rouge selon son prix.
///
/// Le dégradé situe chaque station entre le meilleur et le pire prix
/// affichés : vert au moins cher, rouge au plus cher. L'orange au milieu n'est
/// pas décoratif — interpoler directement du vert au rouge traverse des bruns
/// ternes où deux prix voisins deviennent indistinguables.
///
/// L'échelle est relative à la liste du moment, pas absolue. Si toutes les
/// stations se tiennent en deux centimes, l'écart est quand même étalé sur
/// toute la palette : c'est justement ce qui permet de les départager.
abstract final class StationMarkerColor {
  /// Le prix le plus bas de la liste.
  static const Color cheapest = Color.fromRGBO(27, 94, 32, 1);

  /// À mi-chemin entre les deux extrêmes.
  static const Color middle = Color.fromRGBO(239, 138, 0, 1);

  /// Le prix le plus haut de la liste.
  static const Color dearest = Color.fromRGBO(183, 28, 28, 1);

  /// Station dont le prix est inconnu pour le carburant choisi.
  static const Color unknown = Color.fromRGBO(117, 124, 130, 1);

  /// En deçà de cet écart entre le prix le plus bas et le plus haut, la liste
  /// est tenue pour uniforme : un dixième de centime ne se lit pas à
  /// l'affichage, et l'étaler sur toute la palette ferait passer pour chère
  /// une station au même prix que les autres.
  static const double _flatSpread = 0.001;

  static Color forStation({
    required GasStation station,
    required List<GasStation> stations,
    required FuelType fuel,
  }) {
    final double? price = station.priceFor(fuel);

    if (price == null) {
      return unknown;
    }

    final List<double> prices = stations
        .map((station) => station.priceFor(fuel))
        .whereType<double>()
        .toList();

    if (prices.isEmpty) {
      return unknown;
    }

    final double lowest = prices.reduce((a, b) => a < b ? a : b);
    final double highest = prices.reduce((a, b) => a > b ? a : b);
    final double spread = highest - lowest;

    if (spread <= _flatSpread) {
      return cheapest;
    }

    return atRatio((price - lowest) / spread);
  }

  /// Couleur du dégradé à [ratio], de 0 pour le moins cher à 1 pour le plus
  /// cher. La palette est parcourue en deux moitiés pour passer par l'orange.
  static Color atRatio(double ratio) {
    final double clamped = ratio.clamp(0.0, 1.0);

    if (clamped <= 0.5) {
      return Color.lerp(cheapest, middle, clamped * 2)!;
    }

    return Color.lerp(middle, dearest, (clamped - 0.5) * 2)!;
  }
}
