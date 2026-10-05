import 'package:ecofuel/gas_station_list/model/gas_station.dart';

/// Une enseigne présente dans le rayon, et son nombre de stations.
typedef BrandCount = ({String brand, int count});

/// Filtre des stations par enseigne, une seule à la fois comme le carburant.
///
/// Sans enseigne choisie, toutes les stations passent.
abstract final class BrandFilter {
  /// Regroupe les stations dont l'enseigne est inconnue, pour qu'elles restent
  /// choisissables comme les autres.
  static const String unknownBrand = 'Sans enseigne';

  /// Libellé de la pastille quand aucune enseigne n'est choisie.
  static const String allBrands = 'Toutes les marques';

  static String brandOf(GasStation station) => station.brand ?? unknownBrand;

  /// Enseignes présentes parmi [stations], les plus représentées d'abord, puis
  /// par ordre alphabétique. « Sans enseigne » ferme toujours la liste.
  static List<BrandCount> availableBrands(List<GasStation> stations) {
    final counts = <String, int>{};

    for (final station in stations) {
      counts.update(brandOf(station), (count) => count + 1, ifAbsent: () => 1);
    }

    final brands = [
      for (final MapEntry(:key, :value) in counts.entries)
        (brand: key, count: value),
    ];

    brands.sort((a, b) {
      if ((a.brand == unknownBrand) != (b.brand == unknownBrand)) {
        return a.brand == unknownBrand ? 1 : -1;
      }

      final byCount = b.count.compareTo(a.count);

      return byCount != 0
          ? byCount
          : a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
    });

    return brands;
  }

  static List<GasStation> apply(List<GasStation> stations, String? brand) {
    if (brand == null) {
      return stations;
    }

    return stations.where((station) => brandOf(station) == brand).toList();
  }
}
