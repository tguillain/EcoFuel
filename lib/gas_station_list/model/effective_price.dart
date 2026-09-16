import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';

/// Prix au litre ramené au coût réel d'un plein, détour compris.
///
/// Comparer un prix affiché à une distance n'a pas de sens tant que les deux
/// ne sont pas exprimés dans la même unité. Un détour se paie en carburant :
/// l'essence brûlée pour aller chercher la station est répartie sur les litres
/// du plein, ce qui donne un prix au litre directement comparable d'une
/// station à l'autre.
///
/// Avec les valeurs retenues ici, un centime gagné au litre vaut environ
/// 1,7 km de détour routier, soit 1,3 km à vol d'oiseau : en deçà, le
/// déplacement coûte plus qu'il ne rapporte.
abstract final class EffectivePrice {
  /// Contenance de réservoir retenue pour répartir le coût du détour.
  ///
  /// Plus le plein est grand, mieux il amortit un détour ; 40 L correspond à
  /// une citadine ou une compacte courante.
  static const double tankInLitres = 40;

  /// Consommation moyenne retenue, en litres aux 100 km.
  static const double consumptionPerHundredKm = 7;

  /// L'API ne fournit que la distance à vol d'oiseau. Le trajet routier est
  /// plus long — un relevé sur Nantes donne 2,6 km de route pour 1,9 km à vol
  /// d'oiseau. Ce coefficient évite d'appeler le calculateur d'itinéraire pour
  /// chacune des cent stations d'un rayon.
  static const double roadDetourFactor = 1.3;

  /// Prix effectif de [station], ou `null` si elle ne propose pas [fuel].
  static double? forStation(GasStation station, FuelType fuel) {
    final double? price = station.priceFor(fuel);

    if (price == null) {
      return null;
    }

    return price * (1 + _detourInLitres(station) / tankInLitres);
  }

  /// Compare deux stations sur leur prix effectif, la plus proche l'emportant
  /// à égalité. Les stations sans prix pour [fuel] sont reléguées en fin de
  /// liste.
  static Comparator<GasStation> comparatorFor(FuelType fuel) {
    return (a, b) {
      final double priceA = forStation(a, fuel) ?? double.infinity;
      final double priceB = forStation(b, fuel) ?? double.infinity;

      final int comparison = priceA.compareTo(priceB);

      if (comparison != 0) {
        return comparison;
      }

      return a.distanceInKm.compareTo(b.distanceInKm);
    };
  }

  /// Carburant brûlé pour l'aller-retour jusqu'à [station], en litres.
  ///
  /// L'aller-retour est l'hypothèse honnête : une station située sur le trajet
  /// habituel ne coûte aucun détour, mais rien dans les données ne permet de
  /// le savoir.
  static double _detourInLitres(GasStation station) {
    final double roadDistanceInKm = station.distanceInKm * roadDetourFactor;

    return 2 * roadDistanceInKm * consumptionPerHundredKm / 100;
  }
}
