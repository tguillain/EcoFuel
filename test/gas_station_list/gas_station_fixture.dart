import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';

/// Crée une fausse station pour les tests.
///
/// Cela évite de répéter la création complète
/// d'une GasStation dans tous les tests.
GasStation buildGasStation({
  required String id,
  required double? price,
  required double distanceInKm,
  FuelType fuel = FuelType.e10,
  String address = '1 rue de la Paix',
  String city = 'Nantes',
  bool isOpen24h = false,
  String? closingTime,
  bool isClosed = false,
  String? brand,

  // Coordonnées par défaut : centre de Nantes, comme en développement.
  double latitude = 47.2184,
  double longitude = -1.5536,
}) {
  return GasStation(
    id: id,
    address: address,
    city: city,

    // On crée une entrée pour chaque carburant.
    //
    // Seul le carburant demandé possède le prix fourni.
    // Les autres valent null.
    pricesByFuel: {
      for (final FuelType currentFuel in FuelType.values)
        currentFuel:
            currentFuel == fuel
                ? price
                : null,
    },

    distanceInKm: distanceInKm,

    latitude: latitude,
    longitude: longitude,

    isOpen24h: isOpen24h,
    closingTime: closingTime,
    isClosed: isClosed,
    brand: brand,
  );
}