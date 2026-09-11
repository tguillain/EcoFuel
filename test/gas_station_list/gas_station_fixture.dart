import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';

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
}) {
  return GasStation(
    id: id,
    address: address,
    city: city,
    pricesByFuel: {fuel: price},
    distanceInKm: distanceInKm,
    isOpen24h: isOpen24h,
    closingTime: closingTime,
    isClosed: isClosed,
  );
}
