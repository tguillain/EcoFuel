import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GasStationCard extends StatelessWidget {
  const GasStationCard._({
    super.key,
    required this.station,
    required this.fuel,
    required this.isHighlighted,
    this.onTap,
  });

  factory GasStationCard.standard(
    GasStation station, {
    required FuelType fuel,
    Key? key,
    VoidCallback? onTap,
  }) => GasStationCard._(
    key: key,
    station: station,
    fuel: fuel,
    isHighlighted: false,
    onTap: onTap,
  );

  factory GasStationCard.highlighted(
    GasStation station, {
    required FuelType fuel,
    Key? key,
    VoidCallback? onTap,
  }) => GasStationCard._(
    key: key,
    station: station,
    fuel: fuel,
    isHighlighted: true,
    onTap: onTap,
  );

  static final NumberFormat _distanceFormat = NumberFormat('0.#', 'fr_FR');
  static final NumberFormat _priceFormat = NumberFormat('0.000', 'fr_FR');

  final GasStation station;
  final FuelType fuel;
  final bool isHighlighted;
  final VoidCallback? onTap;

  String get _subtitle {
    final distance = '${_distanceFormat.format(station.distanceInKm)} km';

    if (station.isOpen24h) {
      return '$distance - 24h/24';
    }

    if (station.closingTime != null) {
      return '$distance - ouvert jusqu\'à ${station.closingTime}';
    }

    if (station.isClosed) {
      return '$distance - fermé';
    }

    return distance;
  }

  @override
  Widget build(BuildContext context) {
    final price = station.priceFor(fuel);
    final foreground = isHighlighted
        ? AppColors.onPrimary
        : AppColors.onSurface;

    return Card(
      elevation: 5,
      color: isHighlighted ? AppColors.primary : AppColors.surface,
      shadowColor: isHighlighted ? AppColors.primary : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: ListTile(
        textColor: foreground,
        title: Text(
          station.address,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        subtitle: Text(
          '${station.city}\n$_subtitle',
          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price != null ? _priceFormat.format(price) : '—',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 26,
                color: foreground,
              ),
            ),
            Text(
              price != null ? '€/L' : 'indisponible',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: foreground,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
