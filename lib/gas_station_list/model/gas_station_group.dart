import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/geo_distance.dart';

/// Un site et ses points de distribution. Les grandes surfaces en déclarent
/// parfois plusieurs — un portique de chaque côté du parking — enregistrés
/// comme autant de stations distinctes avec des adresses différentes.
class GasStationGroup {
  const GasStationGroup(this.stations);

  final List<GasStation> stations;

  /// La mieux classée du groupe selon le tri courant, donc celle qui porte
  /// l'affichage de la carte.
  GasStation get representative => stations.first;

  int get pointCount => stations.length;
}

abstract final class GasStationGrouper {
  /// Deux portiques d'un même site restent proches ; 543 m séparent ceux du
  /// Leclerc de Nantes. Le seuil est donc large, et c'est l'enseigne et le
  /// prix identiques qui rendent le regroupement sûr : à 288 m de là
  /// cohabitent un Total et un Esso, que la distance seule fusionnerait.
  static const double maxDistanceInMeters = 700;

  /// Conserve l'ordre reçu : chaque groupe prend le rang de son meilleur
  /// élément, le tri ayant déjà été appliqué en amont.
  static List<GasStationGroup> group(
    List<GasStation> stations, {
    required FuelType fuel,
  }) {
    final groups = <List<GasStation>>[];

    for (final station in stations) {
      final site = groups
          .where((group) => _isSameSite(group.first, station, fuel: fuel))
          .firstOrNull;

      if (site != null) {
        site.add(station);
      } else {
        groups.add([station]);
      }
    }

    return [for (final group in groups) GasStationGroup(group)];
  }

  static bool _isSameSite(
    GasStation a,
    GasStation b, {
    required FuelType fuel,
  }) {
    final brand = a.brand;

    // Sans enseigne connue, rien ne permet d'affirmer qu'il s'agit d'un même
    // site : on préfère deux cartes à une fusion abusive.
    if (brand == null || brand != b.brand || a.city != b.city) {
      return false;
    }

    // Des prix différents sont deux offres différentes, quand bien même elles
    // partageraient le site : les fusionner en masquerait une.
    if (a.priceFor(fuel) != b.priceFor(fuel)) {
      return false;
    }

    return _distanceBetween(a, b) <= maxDistanceInMeters;
  }

  /// `double.infinity` quand une coordonnée manque : sans position, on ne peut
  /// rien affirmer, donc on ne regroupe pas.
  static double _distanceBetween(GasStation a, GasStation b) {
    final latitudeA = a.latitude;
    final longitudeA = a.longitude;
    final latitudeB = b.latitude;
    final longitudeB = b.longitude;

    if (latitudeA == null ||
        longitudeA == null ||
        latitudeB == null ||
        longitudeB == null) {
      return double.infinity;
    }

    return GeoDistance.betweenInMeters(
      latitudeA: latitudeA,
      longitudeA: longitudeA,
      latitudeB: latitudeB,
      longitudeB: longitudeB,
    );
  }
}
